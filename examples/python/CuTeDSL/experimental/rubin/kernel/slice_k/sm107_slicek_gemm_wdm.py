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

"""One-TC-warp Rubin Slice-K GEMM with A read directly from SMEM.

SliceK packs K stripes into physical tcgen05 MMA-M rows so a CTA can own a
small logical-M tile while still issuing a 128-row MMA.  TMA stages
``B(N,K)`` into SMEM, while four cp.async producer warps write ``A(M,K)``
directly into the MMA-visible SMEM diagpack.  WDM MMA accumulates FP32
partials; the epilogue selects each row's Kb window, shuffle-reduces physical
K-stripe rows in registers, and stores the logical ``D(N,M)`` output.  The
default layout keeps M contiguous for Petrick compatibility; an optional
N-contiguous fast path writes each reduced row with 8-element vector stores.
One TC warp serializes the two native 64B-K MMA issues that the original Rubin
example distributed across two TC warps.  Every helper, kernel, and host path
used by this example is defined in this file.

For this Rubin implementation, a **128B K block (Kb)** is the layout and
scheduling unit along logical K.  A tcgen05 instruction has a 64B K span, so a
Kb contains two such spans; it is neither one instruction nor the whole CTA K
tile.  Reducing ``cta_m`` increases the number of adjacent Kb groups represented
by the physical MMA rows, while the epilogue restores the logical-M result.

Let ``f=(1,1,2,4,8)`` for ``cta_m=(128,64,32,16,8)``.  Each native MMA has
``inst_N=cta_n*f`` and covers one 64B half across all ``f`` adjacent Kb.  The
sole TC warp issues it twice: B+0 for the first halves, then B+64 for the second.
Both target the same ``inst_N`` C-TMEM columns.  Folding both halves into the N
dimension of one K64 MMA would instead require ``inst_N=2*cta_n*f``, double the
C-TMEM footprint, and require a different B layout plus extra epilogue
selection; it would not create a true K128 instruction.

Configure a CuTe DSL runtime with Rubin ``sm_107a`` support, then run this
example from the directory containing the examples/ tree.

.. code-block:: bash

    # A-from-SMEM exact FP8 check with manual stages and vectorized output.
    python examples/CuTeDSL/experimental/rubin/kernel/slice_k/sm107_slicek_gemm_wdm.py \\
      --mnk 128,8,512 --cta-m 16 --cta-n 8 --cta-k 512 \\
      --scheduler nonpersistent --ab-dtype fp8 --cd-dtype fp8 \\
      --manual-stages --operand-stage 2 --c-major n --exact-fp8

CLI parameters
--------------
* ``--mnk M,N,K``: logical GEMM dimensions.  A is ``(M,K)`` and B is
  ``(N,K)``.
* ``--cta-m``, ``--cta-n``, ``--cta-k``: use a canonical pair
  ``cta_k=128*f(cta_m)`` for ``f(128,64,32,16,8)=(1,1,2,4,8)``.  M<128 is
  packed as 128 physical 64B SMEM rows; M=128 uses 128 physical 128B rows.
  ``cta_n`` is 8 times a nonnegative power of two, subject to
  ``cta_n*f(cta_m)<=504`` and the TMEM budget.
* ``--mtiles-num``: number of adjacent logical-M tiles owned by one CTA;
  ``cta_m*mtiles_num<=256``.  Each operand stage holds one independent A
  diagpack per mtile and one B tile shared by all mtiles.
* ``--scheduler {nonpersistent,clc}``: select one fixed work tile per CTA or a
  CLC-persistent CTA that reuses its TMEM allocation across scheduled tiles.
* ``--ab-dtype``: fixed to FP8 E4M3.  ``--cd-dtype {fp8,fp16,fp32}`` still
  selects the global output conversion after FP32 accumulation.
* ``--acc-stage``: number of accumulator pipeline stages; it must be positive.
* ``--smem-percentage``, ``--tmem-percentage``: percentages of available SMEM
  and TMEM used by automatic stage selection (each in ``[1,100]``).
* ``--manual-stages``: disable automatic stage selection.  Then
  ``--operand-stage`` selects the positive shared A/B ring depth.  Any count
  whose A-diagpack and B-tile footprint fits the SMEM budget is accepted by
  both schedulers.
* ``--use-pdl``: request programmatic dependent launch for the kernel launch.
* ``--emulate-rubin``: enable the original emulation-only second MMA issue.
* ``--use-scales``: enable the epilogue encode/decode scale path.  It is off
  by default, so all three scale arguments must remain 1.0 unless enabled.
* ``--c-major {m,n}``: choose the global output layout.  ``m`` (default)
  preserves the Petrick-compatible ``(N,M)`` tensor with M contiguous.
  ``n`` uses an ``(M,N)`` tensor with N contiguous and writes full 8-element
  chunks with vector stores; N tails fall back to guarded scalar stores.
* ``--encode-a-scale``, ``--encode-b-scale``, ``--decode-d-scale``: scalar
  factors applied as ``encode_a_scale * encode_b_scale * decode_d_scale`` to
  the FP32 reference and epilogue result.
* ``--tolerance``: absolute numeric-check tolerance for non-exact validation.
* ``--exact-fp8``: compare FP8 output bytes exactly; valid only with
  ``--cd-dtype fp8``.
* ``--benchmark``: compile once and report CUDA-event kernel time instead of
  running the numerical check.  ``--warmup`` and ``--iterations`` control the
  number of untimed and timed launches.

This A-from-SMEM entry exposes canonical FP8 CTA-M/K pairs, legal power-of-two
CTA-N tiles, and multiple adjacent M tiles for both schedulers.  Resource and
layout guards reject unsupported combinations before JIT.  The sections below
follow dataflow order, then kernel scheduling and the standalone driver.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from functools import lru_cache
from typing import Callable, Tuple, TypeAlias

import cuda.bindings.driver as cuda_driver
import cutlass
import cutlass.cute as cute
import cutlass.experimental.cuda as cutlass_cuda
import cutlass.torch as cutlass_torch
from cutlass._mlir import ir
from cutlass.base_dsl.array import LoadCacheModifier
from cutlass.cute.runtime import from_dlpack, make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims
import torch

# CuTe compile-time values used in layout and kernel contracts.
Constexpr = cutlass.Constexpr

# A-from-SMEM diagpack: physical rows are the tcgen05 A rows.  For cta_m
# below 128 they are 64B s64b rows; cta_m=128 uses 128B s128b rows.
_A_FROM_SMEM_SWIZZLE_64B = cutlass.Swizzle.from_name("s64b")
_A_FROM_SMEM_SWIZZLE_128B = cutlass.Swizzle.from_name("s128b")
_OUTPUT_VECTOR_SIZE = 8


@cute.jit
def _issue_cp_async_a_diagpack_64b(
    a_base: cute.Pointer,
    sA_diagpack: cute.Pointer,
    *,
    problem_m: cutlass.Int32,
    problem_k: cutlass.Int32,
    logical_m_base: cutlass.Int32,
    logical_k_base: cutlass.Int32,
    lane_idx: cutlass.Int32,
    producer_warp_rank: cutlass.Int32,
    fundamental_k_blocks: cutlass.Constexpr,
    logical_m_per_tile: cutlass.Constexpr,
    producer_copy_count: cutlass.Constexpr,
) -> None:
    """Copy adjacent Rubin SliceK A tiles into 64B-row MMA SMEM views.

    Two physical rows split one 128B K block.  In general,
    ``physical_row = (logical_m * fundamental_k_blocks + k_block) * 2 + half``.
    Each mtile owns one independent 128-row diagpack.  Four producer warps
    flatten all of those diagpacks into one sequence of 16B copy segments.
    """
    for copy_idx in cutlass.range_constexpr(producer_copy_count):
        segment = (producer_warp_rank * producer_copy_count + copy_idx) * 32 + lane_idx
        flattened_row = segment >> 2
        mtile_iter = flattened_row // 128
        physical_row = flattened_row % 128
        byte_in_row = (segment & 3) * 16
        row_before_half = physical_row >> 1
        logical_m = row_before_half // fundamental_k_blocks
        k_block = row_before_half % fundamental_k_blocks
        half = physical_row & 1
        logical_k = logical_k_base + k_block * 128 + half * 64 + byte_in_row

        source_m = logical_m_base + mtile_iter * logical_m_per_tile + logical_m
        source = a_base + source_m * problem_k + logical_k
        destination = (sA_diagpack + flattened_row * 64 + byte_in_row).apply_swizzle(
            _A_FROM_SMEM_SWIZZLE_64B
        )
        cp_size = (source_m < problem_m) * (logical_k < problem_k) * 16
        prims.cp_async_shared_global(
            destination,
            source,
            16,
            LoadCacheModifier.CG,
            cp_size=cp_size,
        )


@cute.jit
def _issue_cp_async_a_diagpack_128b(
    a_base: cute.Pointer,
    sA_diagpack: cute.Pointer,
    *,
    problem_m: cutlass.Int32,
    problem_k: cutlass.Int32,
    logical_m_base: cutlass.Int32,
    logical_k_base: cutlass.Int32,
    lane_idx: cutlass.Int32,
    producer_warp_rank: cutlass.Int32,
    producer_copy_count: cutlass.Constexpr,
) -> None:
    """Copy adjacent cta_m=128 A tiles into 128x128B SMEM views."""
    for copy_idx in cutlass.range_constexpr(producer_copy_count):
        segment = (producer_warp_rank * producer_copy_count + copy_idx) * 32 + lane_idx
        flattened_row = segment >> 3
        mtile_iter = flattened_row // 128
        physical_row = flattened_row % 128
        byte_in_row = (segment & 7) * 16
        logical_m = physical_row
        logical_k = logical_k_base + byte_in_row

        source_m = logical_m_base + mtile_iter * 128 + logical_m
        source = a_base + source_m * problem_k + logical_k
        destination = (sA_diagpack + flattened_row * 128 + byte_in_row).apply_swizzle(
            _A_FROM_SMEM_SWIZZLE_128B
        )
        cp_size = (source_m < problem_m) * (logical_k < problem_k) * 16
        prims.cp_async_shared_global(
            destination,
            source,
            16,
            LoadCacheModifier.CG,
            cp_size=cp_size,
        )


# ===== BEGIN: arch_helper =====
# Rubin architecture facts used by resource accounting and instruction selection.


class SliceKArchHelper:
    def __init__(self) -> None:
        raise TypeError("SliceKArchHelper is a namespace-only class")

    @staticmethod
    def get_fundamental_k_tile_128bytes_num(
        mtile_size: cutlass.Constexpr | int,
    ) -> cutlass.Constexpr | int:
        if mtile_size == 128 or mtile_size == 64:
            return 1
        elif mtile_size == 32:
            return 2
        elif mtile_size == 16:
            return 4
        elif mtile_size == 8:
            return 8
        elif mtile_size == 4:
            return 16
        else:
            raise ValueError(f"Unsupported mtile_size: {mtile_size}")

    @staticmethod
    def get_tc_inst_K_bytes() -> cutlass.Constexpr:
        return 64


OperandAArchHelper: TypeAlias = type[SliceKArchHelper]
# ===== END: arch_helper =====

# ===== BEGIN: shuffle_reduction =====
# The four epilogue warps load one physical MMA row per lane from TMEM.  Physical rows
# belonging to one logical-M output are contiguous, so a width-limited SHFL
# tree can sum their K64 partials entirely in registers.  This is the same
# reduction model as the Blackwell SliceK epilogue and needs no TMEM
# redistribution workspace.


@cute.jit
def _shuffle_reduce_rows(
    rf_in: cutlass.Array,
    reduction_width: cutlass.Constexpr,
) -> cutlass.Array:
    """Reduce contiguous physical-row groups with a subwarp SHFL tree."""
    rf_out = cutlass.Array(cutlass.Float32, rf_in.shape)
    shfl_clamp = ((32 - reduction_width) << 8) | (reduction_width - 1)
    for elem in cutlass.range_constexpr(rf_in.shape[0]):
        value = rf_in[elem]
        shift = reduction_width // 2
        while shift >= 1:
            value = value + cute.arch.shuffle_sync_down(
                value,
                shift,
                mask_and_clamp=shfl_clamp,
            )
            shift //= 2
        rf_out[elem] = value
    return rf_out


# ===== END: shuffle_reduction =====

# ===== BEGIN: pipeline =====
# Reusable producer/consumer ring-buffer protocol.  TMA producers publish a
# ready stage, consumers release it only after their SMEM/TMEM use is complete.
# The same phase discipline prevents a later K tile from overwriting operands.
# Acquires use one blocking mbarrier wait.  There is no speculative pretest:
# probing before the release/commit path only adds SYNCS pressure here.


class GeneralRingBufferState:
    def __init__(self, stage_: cutlass.Constexpr, init_offset_cnt_: cutlass.Int32 = 0):
        self.max_stage: cutlass.Constexpr = stage_
        self.current_stage: cutlass.Int32 = init_offset_cnt_

    def __extract_mlir_values__(self):
        return cutlass.extract_mlir_values(self.current_stage)

    def __new_from_mlir_values__(self, values):
        self.current_stage = cutlass.new_from_mlir_values(self.current_stage, values)
        return self

    @cute.jit
    def advance(self, step: cutlass.Int32 = 1) -> Tuple[cutlass.Int32, cutlass.Int32]:
        next_stage: cutlass.Int32 = self.current_stage + step
        loop_back: cutlass.Boolean = next_stage >= self.max_stage
        if loop_back:
            self.current_stage = next_stage - self.max_stage
        else:
            self.current_stage = next_stage
        return (cutlass.Int32(loop_back), self.current_stage)

    @cute.jit
    def get_stage(self) -> cutlass.Int32:
        return self.current_stage


class SignalsRingBuffer(GeneralRingBufferState):
    def __init__(
        self,
        *,
        stage_: cutlass.Constexpr,
        full_signal_: cutlass.Array,
        empty_signal_: cutlass.Array,
        init_offset_cnt_: cutlass.Int32 = cutlass.Int32(0),
        empty_parity_init_: cutlass.Int32 = cutlass.Int32(1),
    ):
        super().__init__(stage_=stage_, init_offset_cnt_=init_offset_cnt_)
        self.full_signal_base: cutlass.Array = full_signal_
        self.empty_signal_base: cutlass.Array = empty_signal_
        self.full_signal_now: cutlass.Array = self.full_signal_base.subview(
            init_offset_cnt_
        )
        self.empty_signal_now: cutlass.Array = self.empty_signal_base.subview(
            init_offset_cnt_
        )
        self.empty_parity: cutlass.Int32 = empty_parity_init_
        self.full_parity: cutlass.Int32 = cutlass.Int32(0)
        self.skip_empty_check: cutlass.Boolean = cutlass.Boolean(True)

    def __extract_mlir_values__(self):
        values = super().__extract_mlir_values__()
        values.extend(cutlass.extract_mlir_values(self.full_signal_base))
        values.extend(cutlass.extract_mlir_values(self.empty_signal_base))
        values.extend(cutlass.extract_mlir_values(self.full_signal_now))
        values.extend(cutlass.extract_mlir_values(self.empty_signal_now))
        values.extend(cutlass.extract_mlir_values(self.empty_parity))
        values.extend(cutlass.extract_mlir_values(self.full_parity))
        values.extend(cutlass.extract_mlir_values(self.skip_empty_check))
        return values

    def __new_from_mlir_values__(self, values):
        offset = 0
        base_count = len(super().__extract_mlir_values__())
        super().__new_from_mlir_values__(values[offset : offset + base_count])
        offset += base_count

        def take(template):
            nonlocal offset
            count = len(cutlass.extract_mlir_values(template))
            new_value = cutlass.new_from_mlir_values(
                template, values[offset : offset + count]
            )
            offset += count
            return new_value

        self.full_signal_base = take(self.full_signal_base)
        self.empty_signal_base = take(self.empty_signal_base)
        self.full_signal_now = take(self.full_signal_now)
        self.empty_signal_now = take(self.empty_signal_now)
        self.empty_parity = take(self.empty_parity)
        self.full_parity = take(self.full_parity)
        self.skip_empty_check = take(self.skip_empty_check)
        return self

    @cute.jit
    def advance(self, step: cutlass.Int32 = 1):
        loop_back, stage = super().advance(step)
        self.full_signal_now = self.full_signal_base.subview(stage)
        self.empty_signal_now = self.empty_signal_base.subview(stage)
        self.empty_parity = self.empty_parity ^ loop_back
        self.full_parity = self.full_parity ^ loop_back
        if loop_back:
            self.skip_empty_check = cutlass.Boolean(False)

    @cute.jit
    def get_full_signal(self) -> cutlass.Array:
        return self.full_signal_now

    @cute.jit
    def get_empty_signal(self) -> cutlass.Array:
        return self.empty_signal_now

    @cute.jit
    def final_spin_wait(self, signal: cutlass.Array, parity: cutlass.Int32) -> None:
        # Use the canonical acquire-CTA wait primitive so producer writes are
        # visible when the phase completes.  A timeout only ends one hardware
        # wait attempt; the loop keeps this a blocking pipeline wait.
        while not prims.mbarrier_try_wait_parity(signal, parity, time_limit=10_000_000):
            pass

    @cute.jit
    def wait_full(self) -> None:
        self.final_spin_wait(self.full_signal_now, self.full_parity)

    @cute.jit
    def wait_empty(self) -> None:
        # Initial ring slots have no prior consumer.  Start checking empty
        # barriers only after the first wrap toggles skip_empty_check.
        if not self.skip_empty_check:
            self.final_spin_wait(self.empty_signal_now, self.empty_parity)


@dataclass(frozen=True)
class GeneralRelease:
    @cute.jit
    def release(self, signal: cutlass.Array, dst_cta: cutlass.Int32 = None):
        prims.mbarrier_arrive(signal)


@dataclass(frozen=True)
class Tc1CtaRelease:
    cta_mask: cutlass.Int32 | cutlass.Constexpr = 1

    @cute.jit
    def release(self, signal: cutlass.Array, dst_cta: cutlass.Int32 = None):
        if prims.elect_sync():
            prims.tcgen05_commit(signal, multicast_mask=self.cta_mask, group="cta_1")


class ProducerConsumerPipeline:
    def __init__(
        self,
        signals_ring_buffer: SignalsRingBuffer,
        *,
        producer_release_op_=None,
        consumer_release_op_=None,
    ):
        self.signals_ring_buffer = signals_ring_buffer
        self.prod_release = producer_release_op_
        self.cons_release = consumer_release_op_

    def __extract_mlir_values__(self):
        return [self.signals_ring_buffer.__extract_mlir_values__()]

    def __new_from_mlir_values__(self, values):
        return ProducerConsumerPipeline(
            signals_ring_buffer=self.signals_ring_buffer.__new_from_mlir_values__(
                values[0]
            ),
            producer_release_op_=self.prod_release,
            consumer_release_op_=self.cons_release,
        )

    @cute.jit
    def get_stage(self) -> cutlass.Int32:
        return self.signals_ring_buffer.get_stage()

    @cute.jit
    def get_full_signal(self) -> cutlass.Array:
        return self.signals_ring_buffer.get_full_signal()

    @cute.jit
    def get_empty_signal(self) -> cutlass.Array:
        return self.signals_ring_buffer.get_empty_signal()

    @cute.jit
    def advance(self, step: cutlass.Int32 = 1) -> None:
        self.signals_ring_buffer.advance(step)

    @cute.jit
    def producer_acquire(self):
        self.signals_ring_buffer.wait_empty()

    @cute.jit
    def producer_release(self):
        if cutlass.const_expr(self.prod_release is not None):
            self.prod_release.release(self.signals_ring_buffer.get_full_signal())

    @cute.jit
    def consumer_acquire(self):
        self.signals_ring_buffer.wait_full()

    @cute.jit
    def consumer_release(self):
        if cutlass.const_expr(self.cons_release is not None):
            self.cons_release.release(self.signals_ring_buffer.get_empty_signal())


class RingDataBuffer:
    def __init__(
        self,
        data_base: cutlass.Int32 | cutlass.Array,
        stage: cutlass.Constexpr,
        stride: cutlass.Constexpr,
        *,
        offset: cutlass.Int32 = 0,
    ):
        if cutlass.const_expr(isinstance(data_base, cutlass.Array)):
            self.data_base = data_base.subview(offset)
        else:
            self.data_base = data_base + offset
        self.stage = stage
        self.stride = stride

    @cute.jit
    def get_data_with_stage(self, idx: cutlass.Int32):
        if cutlass.const_expr(isinstance(self.data_base, cutlass.Array)):
            return self.data_base.subview(idx * self.stride)
        else:
            return self.data_base + idx * self.stride

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return cutlass.extract_mlir_values(self.data_base)

    def __new_from_mlir_values__(self, values: list[ir.Value]):
        new = RingDataBuffer.__new__(RingDataBuffer)
        new.data_base = cutlass.new_from_mlir_values(self.data_base, [values[0]])
        new.stage = self.stage
        new.stride = self.stride
        return new


# ===== END: pipeline =====


# ===== BEGIN: tensor_b_tma =====
# B tensor-map construction and TMA issue policy.  Each SW128 atom contains
# two adjacent K64 halves.  The MMA keeps this TMA-friendly layout and selects
# the halves with descriptor offsets +0 and +64B.  Packing both halves along
# MMA-N instead would double accumulator columns and complicate the epilogue.


@dataclass(frozen=True)
class OperandB_TMA:
    ntile_size: cutlass.Constexpr
    ktile_bytes: cutlass.Constexpr
    element_bits: cutlass.Constexpr
    pad_with_tma: cutlass.Constexpr
    swizzle_type = cutlass_cuda.TensorMapSwizzle.s128b

    @property
    def ktile_elements(self):
        return self.ktile_bytes * 8 // self.element_bits

    def create_tma_descriptor(
        self, b: cute.Tensor, b_dtype=cutlass.Float4E2M1FN
    ) -> cutlass_cuda.TensorMap:
        shape_mn = b.shape[0]
        shape_k = b.shape[1]
        problem_k_in_8bits = shape_k * b_dtype.width // 8
        K_chunks_in_128B = problem_k_in_8bits // 128
        if self.pad_with_tma:
            tensor_shape = [128, shape_mn, K_chunks_in_128B]
            tensor_stride = [problem_k_in_8bits, 128]
            tensor_stride_16B = [stride // 16 for stride in tensor_stride]
            box_shape = [128, self.ntile_size, self.ktile_bytes // 128]
            tma_desc = cutlass_cuda.create_tensor_map_tiled(
                global_address=b.iterator.toint(),
                dtype=cutlass.Uint8,
                global_dims=tensor_shape,
                global_strides=tensor_stride_16B,
                box_dims=box_shape,
                swizzle=self.swizzle_type,
                l2_promotion=cutlass_cuda.TensorMapL2Promotion.l2_256b,
            )
            return tma_desc
        else:
            tensor_shape = [problem_k_in_8bits, shape_mn]
            tensor_stride = [problem_k_in_8bits]
            tensor_stride_16B = [stride // 16 for stride in tensor_stride]
            box_shape = (128, shape_mn)
            tma_desc = cutlass_cuda.create_tensor_map_tiled(
                global_address=b.iterator.toint(),
                dtype=cutlass.Uint8,
                global_dims=tensor_shape,
                global_strides=tensor_stride_16B,
                box_dims=box_shape,
                swizzle=self.swizzle_type,
                l2_promotion=cutlass_cuda.TensorMapL2Promotion.l2_256b,
            )
            return tma_desc

    @cute.jit
    def prefetch_tma_descriptor(self, tma_desc: cutlass.Pointer):
        if prims.elect_sync():
            prims.prefetch_tensormap(tma_desc)

    @cute.jit
    def tma_load_and_arrive(
        self,
        smem_B: cutlass.Array,
        tma_desc: cutlass.Pointer,
        mbar_full: cutlass.Array,
        n_coord: cutlass.Int32,
        k_coord_in_bytes: cutlass.Int32,
    ):
        if cutlass.const_expr(self.pad_with_tma):
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    mbar_full, self.ktile_bytes * self.ntile_size
                )
                coords = (0, n_coord, k_coord_in_bytes // 128)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_B, tma_desc, coords, mbar_full
                )
        elif prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(
                mbar_full, self.ktile_bytes * self.ntile_size
            )
            for k in cutlass.range_constexpr(self.ktile_bytes // 128):
                coords = (k_coord_in_bytes + k * 128, n_coord)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_B.subview(k * self.ntile_size * 128),
                    tma_desc,
                    coords,
                    mbar_full,
                )

    @cute.jit
    def tma_prefetch_data(
        self,
        tma_desc: cutlass.Pointer,
        n_coord: cutlass.Int32,
        k_coord_in_bytes: cutlass.Int32,
    ):
        if cutlass.const_expr(self.pad_with_tma):
            if prims.elect_sync():
                coords = (0, n_coord, k_coord_in_bytes // 128)
                prims.cp_async_bulk_tensor_prefetch(tma_desc, coords, [])
        elif prims.elect_sync():
            for k in cutlass.range_constexpr(self.ktile_bytes // 128):
                coords = (k_coord_in_bytes + k * 128, n_coord)
                prims.cp_async_bulk_tensor_prefetch(tma_desc, coords, [])


@dataclass(frozen=True)
class OperandB_16B_aligned_TMA(OperandB_TMA):
    @cute.jit
    def create_tma_descriptor(
        self, b: cute.Tensor, b_dtype=cutlass.Float4E2M1FN
    ) -> cutlass_cuda.TensorMap:
        shape_mn = b.shape[0]
        shape_k = b.shape[1]
        problem_k_in_8bits = shape_k * b_dtype.width // 8
        tensor_shape = [problem_k_in_8bits, shape_mn]
        tensor_stride = [problem_k_in_8bits]
        tensor_stride_16B = [stride // 16 for stride in tensor_stride]
        box_shape = [128, self.ntile_size if self.pad_with_tma else shape_mn]
        tma_desc = cutlass_cuda.create_tensor_map_tiled(
            global_address=b.iterator.toint(),
            dtype=cutlass.Uint8,
            global_dims=tensor_shape,
            global_strides=tensor_stride_16B,
            box_dims=box_shape,
            swizzle=self.swizzle_type,
            l2_promotion=cutlass_cuda.TensorMapL2Promotion.l2_256b,
        )
        return tma_desc

    @cute.jit
    def tma_load_and_arrive(
        self,
        smem_B: cutlass.Array,
        tma_desc: cutlass.Pointer,
        mbar_full: cutlass.Array,
        n_coord: cutlass.Int32,
        k_coord_in_bytes: cutlass.Int32,
    ):
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(
                mbar_full, self.ktile_bytes * self.ntile_size
            )
            for k in cutlass.range_constexpr(self.ktile_bytes // 128):
                coords = (k_coord_in_bytes + k * 128, n_coord)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_B.subview(k * self.ntile_size * 128),
                    tma_desc,
                    coords,
                    mbar_full,
                )

    @cute.jit
    def tma_prefetch_data(
        self,
        tma_desc: cutlass.Pointer,
        n_coord: cutlass.Int32,
        k_coord_in_bytes: cutlass.Int32,
    ):
        if prims.elect_sync():
            for k in cutlass.range_constexpr(self.ktile_bytes // 128):
                coords = (k_coord_in_bytes + k * 128, n_coord)
                prims.cp_async_bulk_tensor_prefetch(tma_desc, coords, [])


# ===== END: tensor_b_tma =====

# ===== BEGIN: tcgen05_mma_wdm =====
# SliceK MMA mapping.  A logical-M tile is represented in physical MMA-M rows
# together with K stripes; WDM enables only the rows whose A stripe matches the
# B stripe for an issue.  Their TMEM partials are reduced by the epilogue.
emulate_rubin = True


@dataclass(frozen=True)
class SlicekInfo:
    wdm_mask: int
    fundamental_k_tile_128bytes_num: int
    rerun_times: int
    inst_N: int


@dataclass(frozen=True)
class TensorCoreConfig:
    warp_num: cutlass.Constexpr | int
    cta_M: cutlass.Constexpr | int
    cta_N: cutlass.Constexpr | int
    inst_K_bytes: cutlass.Constexpr | int
    k_dim_128bytes_num: cutlass.Constexpr | int
    a_input_format: int
    b_input_format: int
    c_output_format: int
    tc_mma_kind: int | prims.Tcgen05MMAKind = field(init=False)

    def __post_init__(self):
        mma_kind = prims.Tcgen05MMAKind.F16
        fp8_like = {
            cutlass.Float8E4M3,
            cutlass.Float8E4M3FN,
            cutlass.Float8E4M3B11FNUZ,
            cutlass.Float8E5M2,
        }
        if self.a_input_format in fp8_like:
            mma_kind = prims.Tcgen05MMAKind.F8F6F4
        object.__setattr__(self, "tc_mma_kind", mma_kind)


@dataclass(frozen=True)
class Tcgen05_TS_WDM_1CTA:
    @staticmethod
    def get_rubin_slicek_info(cta_M: int, cta_N: int) -> SlicekInfo:
        if cta_M == 8:
            return SlicekInfo(
                wdm_mask=1431655765,
                fundamental_k_tile_128bytes_num=1024 // 128,
                rerun_times=2,
                inst_N=cta_N * 8,
            )
        elif cta_M == 16:
            return SlicekInfo(
                wdm_mask=1431655765,
                fundamental_k_tile_128bytes_num=512 // 128,
                rerun_times=2,
                inst_N=cta_N * 4,
            )
        elif cta_M == 32:
            return SlicekInfo(
                wdm_mask=1431655765,
                fundamental_k_tile_128bytes_num=256 // 128,
                rerun_times=2,
                inst_N=cta_N * 2,
            )
        elif cta_M == 64:
            return SlicekInfo(
                wdm_mask=1431655765,
                fundamental_k_tile_128bytes_num=128 // 128,
                rerun_times=2,
                inst_N=cta_N,
            )
        elif cta_M == 128:
            return SlicekInfo(
                wdm_mask=4294967295,
                fundamental_k_tile_128bytes_num=128 // 128,
                rerun_times=1,
                inst_N=cta_N,
            )
        else:
            raise ValueError(f"Invalid cta_M: {cta_M} and cta_N: {cta_N}")

    config: TensorCoreConfig
    MMA_M: cutlass.Constexpr = 128
    mtile_num: cutlass.Constexpr = 1
    slicek_info: SlicekInfo = field(init=False)
    iterations_to_scan_B: cutlass.Constexpr = field(init=False)
    instruction_nums: cutlass.Constexpr = field(init=False)

    def __post_init__(self):
        assert self.config.inst_K_bytes == 64, (
            "Rubin tcgen05 SliceK requires inst_K_bytes=64"
        )
        assert self.config.warp_num == 1, "this Rubin variant requires one MMA warp"
        object.__setattr__(
            self,
            "slicek_info",
            self.get_rubin_slicek_info(self.config.cta_M, self.config.cta_N),
        )
        object.__setattr__(
            self,
            "iterations_to_scan_B",
            self.config.k_dim_128bytes_num * 128 // self.config.inst_K_bytes,
        )
        instruction_nums = self.iterations_to_scan_B // (
            self.config.warp_num * self.slicek_info.fundamental_k_tile_128bytes_num
        )
        assert instruction_nums == 2, (
            "canonical Rubin SliceK requires two native K64 issues"
        )
        object.__setattr__(self, "instruction_nums", instruction_nums)

    @cute.jit
    def create_instr_desc(self) -> prims.Tcgen05InstrDesc:
        InstrDesc = prims.Tcgen05InstrDesc.build(
            a_dtype=self.config.a_input_format,
            b_dtype=self.config.b_input_format,
            c_dtype=self.config.c_output_format,
            n_dim=self.slicek_info.inst_N,
            m_dim=self.MMA_M,
            k_dim=1,
        )
        return InstrDesc

    @cute.jit
    def create_wdm_mask(self) -> cutlass.Array:
        """Return the two masks issued serially by the sole TC warp."""
        write_disable_mask = cutlass.Array(cutlass.Uint32, self.instruction_nums)
        for i in cutlass.range_constexpr(self.instruction_nums):
            # CTA-M<128 uses two complementary row sets.  The original
            # two-warp kernel selected run 0/1 with its warp rank; this variant
            # serializes exactly those two runs in one warp.
            run = i % self.slicek_info.rerun_times
            write_disable_mask[i] = ~(self.slicek_info.wdm_mask << run)
        return write_disable_mask

    @cute.jit
    def prepare_smem_a_smem_b_operands(
        self,
        smem_a_operand_base: prims.Tcgen05SmemDesc,
        smem_b_operand_base: prims.Tcgen05SmemDesc,
    ) -> tuple[cutlass.Array, cutlass.Array]:
        """Prepare the two native 64B-K issues for the sole Rubin TC warp.

        CTA-M<128 reuses one A diagpack descriptor and pairs it with B+0/B+64;
        complementary WDM masks select the matching K-stripe rows.  CTA-M=128
        has no packed K rows, so the second issue advances both A and B by 64B.
        """
        smem_a_operands = cutlass.Array(prims.Tcgen05SmemDesc, self.instruction_nums)
        smem_b_operands = cutlass.Array(prims.Tcgen05SmemDesc, self.instruction_nums)
        for iter in cutlass.range_constexpr(self.instruction_nums):
            a_k_span = iter // self.slicek_info.rerun_times
            smem_a_operands[iter] = smem_a_operand_base + (
                a_k_span * self.config.inst_K_bytes >> 4
            )
            smem_b_operands[iter] = smem_b_operand_base + (
                iter * self.config.inst_K_bytes >> 4
            )
        return (smem_a_operands, smem_b_operands)

    @cute.jit
    def mma_from_smem(
        self,
        tmem_accum: cutlass.Array,
        smem_a_operands: cutlass.Array,
        smem_b_operands: cutlass.Array,
        write_disable_mask_32b: cutlass.Array,
        instr_desc: prims.Tcgen05InstrDesc,
        scale_d: cutlass.Boolean,
        a_mtile_stride_16b: cutlass.Constexpr,
    ) -> cutlass.Boolean:
        """Issue Rubin A-from-SMEM MMA and return the accumulator mode.

        CTA-M<128 gives the two native issues disjoint physical row sets, so
        both inherit ``scale_d``: on the first K tile each replaces its own
        rows.  CTA-M=128 gives both issues the same rows, so issue 1 must
        accumulate after issue 0.  Once both issues finish, later K tiles
        always accumulate.  Both issues use the same ``inst_N`` destination
        columns; serializing them does not double the C-TMEM footprint.  For
        native FP8 with packed rows, FILL/LASTUSE retains the shared A K64
        descriptor across the two B-half issues.
        """
        if prims.elect_sync():
            # Complete both K64 issues for one mtile before selecting the next
            # A diagpack.  This keeps each FILL/LASTUSE collector pair local to
            # one A operand while every mtile reuses the same staged B tile.
            for mtile_iter in cutlass.range_constexpr(self.mtile_num):
                for i in cutlass.range_constexpr(self.instruction_nums):
                    wdm_128b = cutlass.Array(cutlass.Uint32, 4)
                    for j in cutlass.range_constexpr(4):
                        wdm_128b[j] = write_disable_mask_32b[i]
                    issue_scale_d = scale_d
                    if cutlass.const_expr(self.config.cta_M == 128 and i > 0):
                        issue_scale_d = cutlass.Boolean(True)

                    collector_op = prims.Tcgen05MMACollectorOp.DISCARD
                    if cutlass.const_expr(
                        self.config.cta_M < 128
                        and not emulate_rubin
                        and self.config.tc_mma_kind != prims.Tcgen05MMAKind.F16
                    ):
                        # Both K64 issues read the same 128x64B A descriptor;
                        # retain it while B advances from its +0 to +64B half.
                        collector_op = (
                            prims.Tcgen05MMACollectorOp.FILL
                            if i == 0
                            else prims.Tcgen05MMACollectorOp.LASTUSE
                        )

                    smem_a_operand = (
                        smem_a_operands[i] + mtile_iter * a_mtile_stride_16b
                    )
                    prims.tcgen05_mma(
                        self.config.tc_mma_kind,
                        "cta_1",
                        cutlass.inttoptr(
                            tmem_accum + mtile_iter * self.slicek_info.inst_N,
                            6,
                            cutlass.Uint32,
                        ),
                        smem_a_operand,
                        smem_b_operands[i],
                        instr_desc,
                        issue_scale_d,
                        collector_op=collector_op,
                        write_disable_mask=wdm_128b[0:4],
                    )
                    # Preserve the existing Rubin-emulation/F16 two-issue
                    # contract.  A +32B and B +32B select the matching second
                    # 64B-K half; real FP8 Rubin does not take this branch.
                    if cutlass.const_expr(
                        emulate_rubin
                        or self.config.tc_mma_kind == prims.Tcgen05MMAKind.F16
                    ):
                        prims.tcgen05_mma(
                            self.config.tc_mma_kind,
                            "cta_1",
                            cutlass.inttoptr(
                                tmem_accum + mtile_iter * self.slicek_info.inst_N,
                                6,
                                cutlass.Uint32,
                            ),
                            smem_a_operand + (32 >> 4),
                            smem_b_operands[i] + (32 >> 4),
                            instr_desc,
                            cutlass.Boolean(True),
                            write_disable_mask=wdm_128b[0:4],
                        )
        return cutlass.Boolean(True)


# ===== END: tcgen05_mma_wdm =====

# ===== BEGIN: task_scheduler =====
# Work-tile ownership.  The nonpersistent scheduler maps one CTA to its grid
# coordinate; the CLC scheduler supplies successive logical (M, N, batch)
# tiles to a resident CTA without changing the per-tile math.


class NonPersistentScheduler:
    def __init__(self, workload_per_cta: cutlass.Int32 = cutlass.Int32(1)):
        self.next_task_vaild = cutlass.Int32(0)
        self.workload_per_cta = workload_per_cta

    @cute.jit
    def get_task_info(
        self,
    ) -> Tuple[cutlass.Boolean, cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        is_canceled = cutlass.Boolean(self.next_task_vaild)
        cta_x = cute.arch.block_idx()[0]
        cta_y = cute.arch.block_idx()[1]
        cta_z = cute.arch.block_idx()[2]
        return (is_canceled, cta_x, cta_y, cta_z)

    def __extract_mlir_values__(self):
        return [self.next_task_vaild, self.workload_per_cta]

    def __new_from_mlir_values__(self, values):
        return NonPersistentScheduler(workload_per_cta=values[1])


@dataclass(frozen=True)
class ClcPersistentScheduler:
    @cute.jit
    def fetch_next_task(self, smem_address: cutlass.Array, mbarrier: cutlass.Array):
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(mbarrier, 16)
            prims.clusterlaunchcontrol_try_cancel(smem_address, mbarrier)

    @cute.jit
    def get_task_info(
        self, response: cutlass.Array
    ) -> Tuple[cutlass.Boolean, cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        response_16B = response.load()
        is_canceled = prims.clusterlaunchcontrol_query_cancel(
            prims.ClusterLaunchControlQueryType.IS_CANCELED, response_16B
        )
        cta_x = prims.clusterlaunchcontrol_query_cancel(
            prims.ClusterLaunchControlQueryType.GET_FIRST_CTA_ID_X, response_16B
        )
        cta_y = prims.clusterlaunchcontrol_query_cancel(
            prims.ClusterLaunchControlQueryType.GET_FIRST_CTA_ID_Y, response_16B
        )
        cta_z = prims.clusterlaunchcontrol_query_cancel(
            prims.ClusterLaunchControlQueryType.GET_FIRST_CTA_ID_Z, response_16B
        )
        prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
        return (is_canceled, cta_x, cta_y, cta_z)


# ===== END: task_scheduler =====

# ===== BEGIN: misc_helper =====
# Warp roles, resource limits, named-barrier initialization, and the CUDA/CuTe
# tensor adapter used by the two kernels and their host launchers.


class WarpsRole:
    def __init__(self, warps: list[int]):
        self.warps = warps
        self.begin_id = warps[0]
        self.end_id = warps[-1]
        self.warps_count = len(warps)


class StageManagement:
    def __init__(self, smem_capacity: int = 220 * 1024, tmem_capacity: int = 512):
        self.smem_capacity = smem_capacity
        self.tmem_capacity = tmem_capacity


@dataclass(frozen=True)
class MbarrierInit:
    @staticmethod
    @cute.jit
    def sts_init(
        configs: Tuple[Tuple[cutlass.Array, cutlass.Constexpr], ...],
        stage: cutlass.Constexpr,
    ):
        lane_idx = cute.arch.thread_idx()[0] % 32
        for i in range((stage + 31) // 32):
            idx = i * 32 + lane_idx
            if idx < stage:
                for mbar, arrive_cnt in configs:
                    prims.mbarrier_init(mbar.subview(idx), arrive_cnt)


class NamedBarriers:
    def __init__(self, bar_id: int, participants: tuple):
        self.bar_id = bar_id
        self.participants = participants
        self.participants_warps = 0
        for wg in participants:
            self.participants_warps = self.participants_warps + len(wg)
        self.participants_threads = self.participants_warps * 32

    @staticmethod
    @cute.jit
    def wait(bar_id: cutlass.Constexpr, threads_num: cutlass.Constexpr):
        prims.barrier_cta_sync(thread_count=threads_num, barrier_id=bar_id)

    @cute.jit
    def arrive(bar_id: cutlass.Constexpr, threads_num: cutlass.Constexpr):
        prims.barrier_cta_arrive(thread_count=threads_num, barrier_id=bar_id)


def cute_tensor_from_torch(
    torch_tensor: torch.Tensor,
    element_type: type | None,
    leading_dim: int = 0,
    assumed_align: int = 16,
) -> cute.Tensor:
    """Create CUTE tensor from PyTorch tensor via DLPack.

    Wraps from_dlpack with common setup: marking layout as dynamic and
    setting the element type for narrow precision types not supported by DLPack.

    Args:
        torch_tensor: Source PyTorch tensor (must be on CUDA).
        element_type: CUTLASS element type (e.g., cutlass.Float8E4M3FN).
            Use None for types that don't need explicit setting (e.g., Float16).
        leading_dim: Dimension index with stride 1 for mark_layout_dynamic.
            Default 0 for K-major tensors, use 1 for N-major output tensor.
        assumed_align: Memory alignment hint in bytes. Default 16.

    Returns:
        CUTE tensor with dynamic layout marked and element type set.
    """
    tensor = from_dlpack(torch_tensor, assumed_align=assumed_align).mark_layout_dynamic(
        leading_dim=leading_dim
    )
    if element_type is not None:
        tensor.element_type = element_type
    return tensor


# ===== END: misc_helper =====

# ===== BEGIN: tmem_managment =====
# A-from-SMEM keeps only staged FP32 accumulators in TMEM; A never consumes
# TMEM columns, and the shuffle epilogue needs no redistribution workspace.


@dataclass(frozen=True)
class CentralizedTmemManagment:
    mtile_size: cutlass.Constexpr
    ntile_size: cutlass.Constexpr
    acc_stage: cutlass.Constexpr
    mtiles_num: cutlass.Constexpr = 1
    Arch: OperandAArchHelper = SliceKArchHelper

    @property
    def slice_k_factors(self):
        return self.Arch.get_fundamental_k_tile_128bytes_num(self.mtile_size)

    @property
    def accum_ncols_per_stage(self):
        return self.ntile_size * self.slice_k_factors * self.mtiles_num

    @property
    def get_total_tmem_ncols(self) -> cutlass.Constexpr:
        request_cols = self.accum_ncols_per_stage * self.acc_stage
        request_cols = max(32, min(request_cols, 512))
        return min(512, 1 << (request_cols - 1).bit_length())

    @cute.jit
    def get_accum_base_stride_end(self):
        accum_end = self.accum_ncols_per_stage * self.acc_stage
        return (0, self.accum_ncols_per_stage, accum_end)


# ===== END: tmem_managment =====

# ===== BEGIN: tcgen05_epilogue =====
# Consumer side of SliceK: load TMEM accumulators, reduce the physical-M
# K-stripe representation to logical outputs, apply A/B encode and D decode
# scales, convert to the requested output dtype, then store D to GMEM.


@dataclass(frozen=True)
class Tcgen05_Epilogue:
    mtile_size: cutlass.Constexpr
    ntile_size: cutlass.Constexpr
    mtiles_num: cutlass.Constexpr = 1
    arch_helper: OperandAArchHelper = SliceKArchHelper
    use_scales: cutlass.Constexpr = False
    n_contiguous: cutlass.Constexpr = False
    slicek_factor: cutlass.Constexpr = field(init=False)
    row_reduction_width: cutlass.Constexpr = field(init=False)
    real_Inst_N: cutlass.Constexpr = field(init=False)

    def __post_init__(self):
        object.__setattr__(
            self,
            "slicek_factor",
            self.arch_helper.get_fundamental_k_tile_128bytes_num(self.mtile_size),
        )
        object.__setattr__(self, "row_reduction_width", 128 // self.mtile_size)
        object.__setattr__(self, "real_Inst_N", self.slicek_factor * self.ntile_size)

    @cute.jit
    def load_selected_partials(self, tmem_accum: cutlass.Uint32) -> cutlass.Array:
        """Load the Kb window selected by this physical-row lane from TMEM.

        For CTA-M below 128, physical row
        ``((m * f + k_block) * 2 + half)`` maps to one lane.  Both K64 half
        lanes select column window ``k_block``; the following SHFL tree sums
        all ``2*f`` lanes for one logical-M row.
        """
        rf_native_accum = cutlass.Array(cutlass.Float32, shape=(self.ntile_size,))
        if cutlass.const_expr(self.slicek_factor == 1):
            rf_native_accum_vector = prims.tcgen05_ld(
                "32x32b",
                cutlass.inttoptr(tmem_accum, 6, cutlass.Float32),
                num=self.ntile_size,
            )
            for i in cutlass.range_constexpr(self.ntile_size):
                rf_native_accum[i] = rf_native_accum_vector[i]
        else:
            lane_idx = cute.arch.thread_idx()[0] % 32
            group_idx = lane_idx // 2
            duplicate_num = self.slicek_factor
            rf_native_accum_vector_base = prims.tcgen05_ld(
                "32x32b",
                cutlass.inttoptr(tmem_accum, 6, cutlass.Float32),
                num=self.ntile_size,
            )
            for s in cutlass.range_constexpr(self.ntile_size):
                rf_native_accum[s] = rf_native_accum_vector_base[s]
            for i in cutlass.range_constexpr(1, duplicate_num):
                rf_native_accum_vector_temp = prims.tcgen05_ld(
                    "32x32b",
                    cutlass.inttoptr(
                        tmem_accum + i * self.ntile_size, 6, cutlass.Float32
                    ),
                    num=self.ntile_size,
                )
                for s in cutlass.range_constexpr(self.ntile_size):
                    rf_native_accum[s] = (
                        rf_native_accum_vector_temp[s]
                        if group_idx % duplicate_num == i
                        else rf_native_accum[s]
                    )
        return rf_native_accum

    @cute.jit
    def store_mtile(
        self,
        *,
        bidx: cutlass.Int32,
        bidy: cutlass.Int32,
        rf_out_scaled: cutlass.Array,
        gmem_output: cute.Pointer,
        problem_m: cutlass.Int32,
        problem_n: cutlass.Int32,
        lane_idx: cutlass.Int32,
        warp_idx_in_warp: cutlass.Int32,
        mtile_iter: cutlass.Int32,
    ) -> None:
        """Store one logical-M row from each physical-row group leader.

        The SHFL reduction leaves one leader with all CTA-N values for its
        logical-M row.  N-contiguous output makes those values adjacent, so
        each complete 8-element chunk becomes one vector store.  M-contiguous
        output retains the original scalar, strided stores.
        """
        cta_m_offset = (
            bidx * self.mtile_size * self.mtiles_num + mtile_iter * self.mtile_size
        )
        cta_n_offset = bidy * self.ntile_size
        physical_row = warp_idx_in_warp * 32 + lane_idx
        logical_m = physical_row // self.row_reduction_width
        this_m_idx = cta_m_offset + logical_m
        is_store_leader = lane_idx % self.row_reduction_width == 0
        m_guard = this_m_idx < problem_m

        if cutlass.const_expr(self.n_contiguous):
            # Row starts are vector-aligned only when the runtime N extent is
            # a multiple of eight.  Keep N-tail support by scalarizing the
            # whole row when that alignment guarantee is absent.
            if is_store_leader and m_guard:
                if problem_n % _OUTPUT_VECTOR_SIZE == 0:
                    for n_base in cutlass.range_constexpr(
                        0, self.ntile_size, _OUTPUT_VECTOR_SIZE
                    ):
                        this_n_idx = cta_n_offset + n_base
                        if this_n_idx + _OUTPUT_VECTOR_SIZE <= problem_n:
                            values = []
                            for n in cutlass.range_constexpr(_OUTPUT_VECTOR_SIZE):
                                values.append(
                                    rf_out_scaled[n_base + n].to(gmem_output._dtype)
                                )
                            output = gmem_output + this_m_idx * problem_n + this_n_idx
                            vector = cutlass.Vector.from_elements(
                                tuple(values), dtype=gmem_output._dtype
                            )
                            vector_bytes: Constexpr = (
                                _OUTPUT_VECTOR_SIZE * gmem_output._dtype.width // 8
                            )
                            output.store(vector, alignment=min(16, vector_bytes))
                else:
                    for n in cutlass.range_constexpr(self.ntile_size):
                        this_n_idx = cta_n_offset + n
                        if this_n_idx < problem_n:
                            output = gmem_output + this_m_idx * problem_n + this_n_idx
                            value = rf_out_scaled[n].to(gmem_output._dtype)
                            output.store(value, alignment=gmem_output._dtype.width // 8)
        else:
            for n in cutlass.range_constexpr(self.ntile_size):
                this_n_idx = cta_n_offset + n
                n_guard = this_n_idx < problem_n
                output = gmem_output + this_m_idx + this_n_idx * problem_m
                value = rf_out_scaled[n].to(gmem_output._dtype)
                if is_store_leader and m_guard and n_guard:
                    output.store(value, alignment=gmem_output._dtype.width // 8)

    @cute.jit
    def load_accum(self, *, tmem_accum: cutlass.Uint32) -> cutlass.Array:
        rf_all = cutlass.Array(
            cutlass.Float32, shape=(self.mtiles_num, self.ntile_size)
        )
        for mtile_iter in cutlass.range_constexpr(self.mtiles_num):
            rf_native_accum = self.load_selected_partials(
                tmem_accum + mtile_iter * self.real_Inst_N
            )
            for i in cutlass.range_constexpr(self.ntile_size):
                rf_all[mtile_iter, i] = rf_native_accum[i]
        return rf_all

    @cute.jit
    def reduction(self, *, rf_sub_accum: cutlass.Array) -> tuple[cutlass.Array, ...]:
        rf_reduced = ()
        for mtile_iter in cutlass.range_constexpr(self.mtiles_num):
            rf_out = _shuffle_reduce_rows(
                rf_sub_accum[mtile_iter, :],
                self.row_reduction_width,
            )
            rf_reduced = rf_reduced + (rf_out,)
        return rf_reduced

    @cute.jit
    def apply_scales(
        self,
        *,
        rf_reduced: tuple[cutlass.Array, ...],
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
    ) -> tuple[cutlass.Array, ...]:
        if cutlass.const_expr(not self.use_scales):
            return rf_reduced

        scale = encodeA_scale * encodeB_scale * decodeD_scale
        rf_out = ()
        for rf_out_iter in rf_reduced:
            rf_out_scaled = cutlass.Array(cutlass.Float32, rf_out_iter.shape)
            for n in cutlass.range_constexpr(self.ntile_size):
                rf_out_scaled[n] = rf_out_iter[n] * scale
            rf_out = rf_out + (rf_out_scaled,)
        return rf_out

    @cute.jit
    def store_gmem(
        self,
        *,
        lane_idx: cutlass.Int32,
        warp_idx_in_warp: cutlass.Int32,
        rf_out_scaled: tuple[cutlass.Array, ...],
        gmem_output: cute.Pointer,
        problem_m: cutlass.Int32,
        problem_n: cutlass.Int32,
        bidx: cutlass.Int32,
        bidy: cutlass.Int32,
    ) -> None:
        for mtile_iter in cutlass.range_constexpr(self.mtiles_num):
            self.store_mtile(
                bidx=bidx,
                bidy=bidy,
                rf_out_scaled=rf_out_scaled[mtile_iter],
                gmem_output=gmem_output,
                problem_m=problem_m,
                problem_n=problem_n,
                mtile_iter=mtile_iter,
                lane_idx=lane_idx,
                warp_idx_in_warp=warp_idx_in_warp,
            )


# ===== END: tcgen05_epilogue =====

# ===== BEGIN: nonpersistent =====
# One CTA owns one fixed logical output work tile.  Producers stream all K
# tiles through staged SMEM/TMEM, MMA accumulates their SliceK partials, and
# epilogue warps finalize that CTA's mtiles_num adjacent logical-M tiles.
"""Rubin A-from-SMEM SliceK prototype (10-warp shell).

Warps 0-3 issue cp.async A-diagpack copies, 4-7 run the epilogue, warp 8
serially issues both native Rubin MMAs, and warp 9 TMA-loads B.
"""
ab_dtype = cutlass.Float8E4M3FN
cd_dtype = cutlass.Float16
a_copy_warps = [0, 1, 2, 3]
epi_warps = [4, 5, 6, 7]
tc_warps = [8]
tma_b_warp = [tc_warps[-1] + 1]

a_copy_warps_role = WarpsRole(a_copy_warps)
epi_warps_role = WarpsRole(epi_warps)
tc_warps_role = WarpsRole(tc_warps)
tma_b_warp_role = WarpsRole(tma_b_warp)
total_warps = len(a_copy_warps) + len(epi_warps) + len(tc_warps) + len(tma_b_warp)

named_bar_operand_storage_init_bar_id = 1
named_bar_tmem_alloc_bar_id = 2
named_bar_epilogue_bar_id = 3
named_bar_tmem_release_bar_id = 6

bar_operand_storage_init = NamedBarriers(
    named_bar_operand_storage_init_bar_id,
    (tma_b_warp, a_copy_warps, tc_warps, epi_warps),
)
bar_tmem_alloc = NamedBarriers(named_bar_tmem_alloc_bar_id, (a_copy_warps,))
bar_epilogue = NamedBarriers(named_bar_epilogue_bar_id, (epi_warps,))
bar_tmem_release = NamedBarriers(named_bar_tmem_release_bar_id, (epi_warps, tma_b_warp))


class SliceK_WDM_NonPersistent_Implementation:
    def __init__(
        self,
        *,
        ab_dtype=cutlass.Float8E4M3FN,
        cd_dtype=cutlass.Float16,
        use_percentage: bool = True,
        acc_stage: int = 2,
        cta_tiler_mnk: Tuple[int, int, int] = (128, 8, 256),
        mtiles_num: int = 1,
        operand_stage: int = 2,
        smem_usage_percentage: int = 100,
        tmem_usage_percentage: int = 100,
        use_scales: bool = False,
        c_major: str = "m",
    ):
        self.auto_stage_management = StageManagement()
        self.mtiles_num = mtiles_num
        self.acc_stage = acc_stage
        self.cta_tiler_mnk = cta_tiler_mnk
        self.ab_dtype = ab_dtype
        self.cd_dtype = cd_dtype
        self.use_scales = use_scales
        self.c_major = c_major
        if use_percentage:
            # Unlike the TMEM-A baseline, this path keeps A and B in the same
            # SMEM-stage lifecycle.  Size a stage from the actual A
            # diagpack plus its B tile; reusing StageManagement's TMEM-A
            # accounting here could overcommit shared memory.
            smem_available = (
                self.auto_stage_management.smem_capacity * smem_usage_percentage // 100
                - 1024
            )
            a_diagpack_bytes = (
                cta_tiler_mnk[0]
                * cta_tiler_mnk[2]
                * self.mtiles_num
                * self.ab_dtype.width
                // 8
            )
            b_bytes = cta_tiler_mnk[1] * cta_tiler_mnk[2] * self.ab_dtype.width // 8
            direct_smem_stages = smem_available // (a_diagpack_bytes + b_bytes)
            if direct_smem_stages <= 0:
                raise ValueError(
                    "the A-from-SMEM staging footprint exceeds the SMEM budget"
                )
            self.operand_stage = direct_smem_stages
        else:
            self.operand_stage = operand_stage

    @cute.kernel
    def gemm_kernel(
        self,
        a: cute.Tensor,
        tma_b_desc: cutlass.GridConstant[cutlass_cuda.TensorMap],
        tma_b_op: cutlass.Constexpr[OperandB_TMA | OperandB_16B_aligned_TMA],
        mnk: Tuple[int, int, int],
        gmem_output: cute.Tensor,
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
    ) -> None:
        # The CTA coordinate fixes this nonpersistent work tile.  All warp
        # roles below traverse the same K-tile sequence through independent
        # producer/consumer pipelines.
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        lane_idx = cute.arch.thread_idx()[0] % 32
        bidx = cute.arch.block_idx()[0]
        bidy = cute.arch.block_idx()[1]
        expert_idx = cute.arch.block_idx()[2]

        operand_smem_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.operand_stage, space=cutlass.AddressSpace.smem
        )
        operand_smem_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.operand_stage, space=cutlass.AddressSpace.smem
        )
        acc_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.acc_stage, space=cutlass.AddressSpace.smem
        )
        acc_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.acc_stage, space=cutlass.AddressSpace.smem
        )
        tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

        a_row_bytes: Constexpr = 128 if self.cta_tiler_mnk[0] == 128 else 64
        # One operand-ring slot owns one A diagpack per adjacent logical-M
        # tile and one B tile shared by all of them.
        smem_matrix_a = cutlass.Array(
            cutlass.Uint8,
            (self.operand_stage, self.mtiles_num, 128, a_row_bytes),
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        smem_matrix_b = cutlass.Array(
            cutlass.Uint8,
            (
                self.operand_stage,
                self.cta_tiler_mnk[1],
                self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            ),
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        smem_workspace = cutlass.Array(
            cutlass.Uint8, 1024, space=cutlass.AddressSpace.smem, alignment=128
        )
        TmemManagment = CentralizedTmemManagment(
            mtile_size=self.cta_tiler_mnk[0],
            ntile_size=self.cta_tiler_mnk[1],
            acc_stage=self.acc_stage,
            mtiles_num=self.mtiles_num,
            Arch=SliceKArchHelper,
        )

        k_iterations = cute.ceil_div(mnk[2], self.cta_tiler_mnk[2])
        scheduler = NonPersistentScheduler()

        # One nonpersistent logical work tile has a fixed (bidx, bidy,
        # expert_idx) owner and follows this lifetime exactly once:
        #
        #   A(M,K) GMEM --cp.async--> staged physical-M / K-stripe SMEM
        #   B(N,K) GMEM --TMA--> staged SMEM
        #   A SMEM + B SMEM --WDM MMA--> FP32 TMEM accumulators
        #   TMEM physical rows --SliceK reduction/scales--> D(N,M) GMEM.
        #
        if tma_b_warp_role.begin_id <= warp_idx <= tma_b_warp_role.end_id:
            # B producer: TMA fills the matching logical-N/K SMEM stage.  It
            # shares the operand-ready handshake with the cp.async A diagpack.
            tma_b_op.prefetch_tma_descriptor(tma_b_desc.get_ptr())
            # full: 128 A-producer threads plus one TMA-B transaction.
            # empty: the sole TC warp commits after both K64 issues finish.
            MbarrierInit.sts_init(
                (
                    (operand_smem_full_mbar_ptr, 1 + 128),
                    (operand_smem_empty_mbar_ptr, len(tc_warps)),
                ),
                stage=self.operand_stage,
            )
            prims.fence_mbarrier_init()
            NamedBarriers.arrive(
                bar_operand_storage_init.bar_id,
                bar_operand_storage_init.participants_threads,
            )
            pipeline_smem_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                )
            )
            smem_b_buffer = RingDataBuffer(
                data_base=smem_matrix_b,
                stage=self.operand_stage,
                stride=self.cta_tiler_mnk[1]
                * self.cta_tiler_mnk[2]
                * self.ab_dtype.width
                // 8,
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                n_offset = bidy * self.cta_tiler_mnk[1]
                l_offset = expert_idx * mnk[1]
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    smem_stage_idx = pipeline_smem_producer.get_stage()
                    pipeline_smem_producer.producer_acquire()
                    tma_b_op.tma_load_and_arrive(
                        smem_b_buffer.get_data_with_stage(smem_stage_idx),
                        tma_b_desc.get_ptr(),
                        pipeline_smem_producer.get_full_signal(),
                        n_offset + l_offset,
                        k_iter * self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
                    )
                    pipeline_smem_producer.producer_release()
                    pipeline_smem_producer.advance()
                current_task_vaild, _, bidy, expert_idx = scheduler.get_task_info()

            NamedBarriers.wait(
                bar_tmem_release.bar_id, bar_tmem_release.participants_threads
            )
            tmem_ptr = cutlass.inttoptr(tmem_ptr_i32.load(), 6, cutlass.Uint32)
            prims.tcgen05_dealloc(
                tmem_ptr, TmemManagment.get_total_tmem_ncols, group="cta_1"
            )

        elif a_copy_warps_role.begin_id <= warp_idx <= a_copy_warps_role.end_id:
            # Four cp.async-A producer warps jointly write one diagpack per
            # stage.  M<128 uses 128x64B s64b rows, with each logical 128B K
            # block split over two rows; M=128 uses 128x128B s128b rows.
            if warp_idx == a_copy_warps[0]:
                prims.tcgen05_alloc(
                    tmem_ptr_i32, TmemManagment.get_total_tmem_ncols, group="cta_1"
                )
                prims.tcgen05_relinquish_alloc_permit(group="cta_1")
            NamedBarriers.wait(
                bar_operand_storage_init.bar_id,
                bar_operand_storage_init.participants_threads,
            )
            pipeline_a_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                )
            )
            smem_a_uint8_ptr = cutlass.inttoptr(
                smem_matrix_a.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            smem_a_buffer = RingDataBuffer(
                data_base=smem_a_uint8_ptr,
                stage=self.operand_stage,
                stride=self.mtiles_num * 128 * a_row_bytes,
            )
            producer_warp_rank = warp_idx - a_copy_warps_role.begin_id
            fundamental_k_blocks = SliceKArchHelper.get_fundamental_k_tile_128bytes_num(
                self.cta_tiler_mnk[0]
            )
            producer_copy_count = (
                self.cta_tiler_mnk[0]
                * self.cta_tiler_mnk[2]
                * self.mtiles_num
                // (len(a_copy_warps) * 32 * 16)
            )
            a_base = a.iterator.raw_ptr()
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                m_offset = bidx * self.cta_tiler_mnk[0] * self.mtiles_num
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    operand_stage_idx = pipeline_a_producer.get_stage()
                    pipeline_a_producer.producer_acquire()
                    if cutlass.const_expr(self.cta_tiler_mnk[0] == 128):
                        _issue_cp_async_a_diagpack_128b(
                            a_base,
                            smem_a_buffer.get_data_with_stage(operand_stage_idx),
                            problem_m=mnk[0],
                            problem_k=mnk[2],
                            logical_m_base=m_offset,
                            logical_k_base=k_iter * self.cta_tiler_mnk[2],
                            lane_idx=lane_idx,
                            producer_warp_rank=producer_warp_rank,
                            producer_copy_count=producer_copy_count,
                        )
                    else:
                        _issue_cp_async_a_diagpack_64b(
                            a_base,
                            smem_a_buffer.get_data_with_stage(operand_stage_idx),
                            problem_m=mnk[0],
                            problem_k=mnk[2],
                            logical_m_base=m_offset,
                            logical_k_base=k_iter * self.cta_tiler_mnk[2],
                            lane_idx=lane_idx,
                            producer_warp_rank=producer_warp_rank,
                            fundamental_k_blocks=fundamental_k_blocks,
                            logical_m_per_tile=self.cta_tiler_mnk[0],
                            producer_copy_count=producer_copy_count,
                        )
                    # The matching TMA-B producer contributes the 129th
                    # arrival with arrive_expect_tx.  This arrival is also
                    # the async-copy completion fence for the A diagpack.
                    prims.cp_async_mbarrier_arrive(
                        pipeline_a_producer.get_full_signal(), noinc=True
                    )
                    pipeline_a_producer.advance()
                current_task_vaild, _, _, _ = scheduler.get_task_info()

        elif tc_warps_role.begin_id <= warp_idx <= tc_warps_role.end_id:
            if warp_idx == tc_warps_role.begin_id:
                MbarrierInit.sts_init(
                    ((acc_full_mbar_ptr, len(tc_warps)), (acc_empty_mbar_ptr, 128)),
                    stage=self.acc_stage,
                )
            prims.fence_mbarrier_init()
            NamedBarriers.wait(
                bar_operand_storage_init.bar_id,
                bar_operand_storage_init.participants_threads,
            )
            pipeline_operand_ab_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                ),
                consumer_release_op_=Tc1CtaRelease(),
            )
            pipeline_accum_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.acc_stage,
                    full_signal_=acc_full_mbar_ptr,
                    empty_signal_=acc_empty_mbar_ptr,
                ),
                producer_release_op_=Tc1CtaRelease(),
            )
            tmem_all_ptr = tmem_ptr_i32.load()
            tmem_accum_col_offset, tmem_accum_stride, _ = (
                TmemManagment.get_accum_base_stride_end()
            )
            tmem_accum_buffer = RingDataBuffer(
                data_base=tmem_all_ptr + tmem_accum_col_offset,
                stage=self.acc_stage,
                stride=tmem_accum_stride,
            )
            smem_a_uint8_ptr = cutlass.inttoptr(
                smem_matrix_a.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            smem_b_uint8_ptr = cutlass.inttoptr(
                smem_matrix_b.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            ktile_bytes = self.cta_tiler_mnk[2] * self.ab_dtype.width // 8
            slicek_tc_config = TensorCoreConfig(
                warp_num=len(tc_warps),
                cta_M=self.cta_tiler_mnk[0],
                cta_N=self.cta_tiler_mnk[1],
                inst_K_bytes=64,
                k_dim_128bytes_num=ktile_bytes // 128,
                a_input_format=self.ab_dtype,
                b_input_format=self.ab_dtype,
                c_output_format=cutlass.Float32,
            )
            slicek_mma = Tcgen05_TS_WDM_1CTA(
                config=slicek_tc_config, mtile_num=self.mtiles_num
            )
            wdm_mask_32b = slicek_mma.create_wdm_mask()
            instr_desc = slicek_mma.create_instr_desc()
            # Build invariant MMA descriptors once, outside the K loop.  A
            # stage change is only a cheap descriptor-base advance in 16B units.
            if cutlass.const_expr(self.cta_tiler_mnk[0] == 128):
                SmemDescA_base = prims.Tcgen05SmemDesc.build(
                    start_address=smem_a_uint8_ptr,
                    leading_byte_offset=16,
                    stride_byte_offset=1024,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
                )
            else:
                SmemDescA_base = prims.Tcgen05SmemDesc.build(
                    start_address=smem_a_uint8_ptr,
                    leading_byte_offset=16,
                    stride_byte_offset=512,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_64B,
                )
            SmemDescB_base = prims.Tcgen05SmemDesc.build(
                start_address=smem_b_uint8_ptr,
                leading_byte_offset=16,
                stride_byte_offset=8 * 128,
                layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
            )
            a_mtile_stride_16b: Constexpr = 128 * a_row_bytes >> 4
            smem_a_desc_buffer = RingDataBuffer(
                data_base=SmemDescA_base,
                stage=self.operand_stage,
                stride=self.mtiles_num * a_mtile_stride_16b,
            )
            smem_b_desc_buffer = RingDataBuffer(
                data_base=SmemDescB_base,
                stage=self.operand_stage,
                stride=self.cta_tiler_mnk[1]
                * self.cta_tiler_mnk[2]
                * self.ab_dtype.width
                // 8
                >> 4,
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                accum_stage_idx = pipeline_accum_producer.get_stage()
                pipeline_accum_producer.producer_acquire()
                # The sole TC warp controls both first-tile issues, so replace
                # mode initializes every row without a separate TMEM clear.
                # mma_from_smem keeps replace for both complementary WDM runs
                # below CTA-M=128, but switches the second CTA-M=128 issue to
                # accumulate because both issues update the same rows.
                scale_d = cutlass.Boolean(False)
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    input_stage_idx = pipeline_operand_ab_consumer.get_stage()
                    pipeline_operand_ab_consumer.consumer_acquire()
                    smem_a_operand_base = smem_a_desc_buffer.get_data_with_stage(
                        input_stage_idx
                    )
                    smem_b_operand_base = smem_b_desc_buffer.get_data_with_stage(
                        input_stage_idx
                    )
                    smem_a_operands, smem_b_operands = (
                        slicek_mma.prepare_smem_a_smem_b_operands(
                            smem_a_operand_base, smem_b_operand_base
                        )
                    )
                    # One warp serially issues B+0 and B+64.  Complementary WDM
                    # masks select their K-stripe rows; both update one C tile.
                    scale_d = slicek_mma.mma_from_smem(
                        tmem_accum_buffer.get_data_with_stage(accum_stage_idx),
                        smem_a_operands,
                        smem_b_operands,
                        wdm_mask_32b,
                        instr_desc,
                        scale_d,
                        a_mtile_stride_16b,
                    )
                    # tcgen05.commit publishes empty only after both issues no
                    # longer read this A/B stage, allowing producers to reuse it.
                    pipeline_operand_ab_consumer.consumer_release()
                    pipeline_operand_ab_consumer.advance()
                # Publish one complete FP32 accumulator after every K tile;
                # the epilogue cannot reduce or store it before this commit.
                pipeline_accum_producer.producer_release()
                pipeline_accum_producer.advance()
                current_task_vaild, _, _, _ = scheduler.get_task_info()

        elif epi_warps_role.begin_id <= warp_idx <= epi_warps_role.end_id:
            NamedBarriers.wait(
                bar_operand_storage_init.bar_id,
                bar_operand_storage_init.participants_threads,
            )
            warp_id_in_wg = warp_idx % 4
            tmem_all_ptr = tmem_ptr_i32.load() + warp_id_in_wg * 32 * 65536
            tmem_accum_col_offset, tmem_accum_stride, _ = (
                TmemManagment.get_accum_base_stride_end()
            )
            tmem_accum_buffer = RingDataBuffer(
                data_base=tmem_all_ptr + tmem_accum_col_offset,
                stage=self.acc_stage,
                stride=tmem_accum_stride,
            )
            pipeline_accum_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.acc_stage,
                    full_signal_=acc_full_mbar_ptr,
                    empty_signal_=acc_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            epilogue = Tcgen05_Epilogue(
                mtile_size=self.cta_tiler_mnk[0],
                ntile_size=self.cta_tiler_mnk[1],
                mtiles_num=self.mtiles_num,
                arch_helper=SliceKArchHelper,
                use_scales=self.use_scales,
                n_contiguous=self.c_major == "n",
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                accum_stage_idx = pipeline_accum_consumer.get_stage()
                pipeline_accum_consumer.consumer_acquire()
                sub_accums = epilogue.load_accum(
                    tmem_accum=tmem_accum_buffer.get_data_with_stage(accum_stage_idx)
                )
                prims.tcgen05_wait(kind="load")
                # All four epilogue warps now hold this stage in registers.
                # Their 128 arrivals may publish acc_empty immediately, so MMA
                # can reuse TMEM while the RF-only reduction/store completes.
                pipeline_accum_consumer.consumer_release()
                next_task_vaild, nxt_bidx, nxt_bidy, nxt_expert_idx = (
                    scheduler.get_task_info()
                )
                reduced_accums = epilogue.reduction(rf_sub_accum=sub_accums)
                if not next_task_vaild:
                    NamedBarriers.arrive(
                        bar_tmem_release.bar_id, bar_tmem_release.participants_threads
                    )
                scaled_accums = epilogue.apply_scales(
                    rf_reduced=reduced_accums,
                    encodeA_scale=encodeA_scale,
                    encodeB_scale=encodeB_scale,
                    decodeD_scale=decodeD_scale,
                )
                epilogue.store_gmem(
                    rf_out_scaled=scaled_accums,
                    gmem_output=gmem_output.iterator.raw_ptr(),
                    problem_m=mnk[0],
                    problem_n=mnk[1],
                    bidx=bidx,
                    bidy=bidy,
                    lane_idx=lane_idx,
                    warp_idx_in_warp=warp_id_in_wg,
                )
                current_task_vaild = next_task_vaild
                bidx = nxt_bidx
                bidy = nxt_bidy
                expert_idx = nxt_expert_idx
                pipeline_accum_consumer.advance()

    @cute.jit
    def host_function(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        problem_size: Tuple[int, int, int],
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
        stream: cuda_driver.CUstream,
        use_pdl: bool = False,
    ) -> None:
        tma_b_16B_op = OperandB_16B_aligned_TMA(
            ntile_size=self.cta_tiler_mnk[1],
            ktile_bytes=self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            element_bits=self.ab_dtype.width,
            pad_with_tma=True,
        )
        tma_b_128B_op = OperandB_TMA(
            ntile_size=self.cta_tiler_mnk[1],
            ktile_bytes=self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            element_bits=self.ab_dtype.width,
            pad_with_tma=True,
        )
        # Select the operand from K's type constraint, not its run-time value.
        k_divisibility = cute.get_divisibility(b.shape[1])
        tma_b_op = (
            tma_b_128B_op
            if cutlass.const_expr(k_divisibility * self.ab_dtype.width % 1024 == 0)
            else tma_b_16B_op
        )
        tma_b_desc = tma_b_op.create_tma_descriptor(b, self.ab_dtype)
        grid_shape = (
            cute.ceil_div(problem_size[0], self.cta_tiler_mnk[0] * self.mtiles_num),
            cute.ceil_div(problem_size[1], self.cta_tiler_mnk[1]),
            1,
        )
        block_shape = (total_warps * 32, 1, 1)
        self.gemm_kernel(
            a,
            tma_b_desc,
            tma_b_op,
            problem_size,
            c,
            encodeA_scale,
            encodeB_scale,
            decodeD_scale,
        ).launch(
            grid=grid_shape,
            block=block_shape,
            cluster=(1, 1, 1),
            stream=stream,
            use_pdl=use_pdl,
            max_number_threads=(total_warps * 32, 1, 1),
            min_blocks_per_mp=1,
        )

    @lru_cache(maxsize=None)
    def compile(
        self,
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
        use_pdl: bool = False,
        *,
        k_alignment_bytes: int,
    ) -> Callable:
        """Compile host_function for the given K and bias flag.

        The returned function accepts PyTorch tensors directly (TVM-FFI flow).
        M and N are symbolic so a single binary handles any valid problem size.
        """
        sym_m = cute.sym_int32()
        sym_n = cute.sym_int32()
        sym_k = cute.sym_int32(
            divisibility=k_alignment_bytes * 8 // self.ab_dtype.width
        )
        fake_a = make_fake_compact_tensor(
            self.ab_dtype, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
        )
        fake_b = make_fake_compact_tensor(
            self.ab_dtype, (sym_n, sym_k), stride_order=(1, 0), assumed_align=16
        )
        c_shape = (sym_m, sym_n) if self.c_major == "n" else (sym_n, sym_m)
        fake_c = make_fake_compact_tensor(
            self.cd_dtype, c_shape, stride_order=(1, 0), assumed_align=16
        )
        compile_options = "--ptxas-options=--warning-as-error"
        if not emulate_rubin:
            compile_options = f"--gpu-arch sm_107a {compile_options}"
        return cute.compile[cute.GenerateLineInfo(True)](
            self.host_function,
            fake_a,
            fake_b,
            fake_c,
            (sym_m, sym_n, sym_k),
            encodeA_scale,
            encodeB_scale,
            decodeD_scale,
            make_fake_stream(),
            use_pdl,
            options=compile_options,
        )


# ===== END: nonpersistent =====

# ===== BEGIN: persistent =====
# CLC-persistent counterpart of the same SliceK data path.  A resident CTA
# obtains another logical work tile after epilogue completion, reusing its
# allocation and pipelines while preserving per-tile accumulator ownership.
"""Rubin CLC-persistent A-from-SMEM SliceK kernel.

The nonpersistent 10-warp data path gains one CLC scheduler warp.  The four
cp.async producers write A directly into the MMA diagpack, so no TMA-A warp or
A-TMEM staging is required.
"""
persistent_a_copy_warps = [0, 1, 2, 3]
persistent_epi_warps = [4, 5, 6, 7]
persistent_tc_warps = [8]
persistent_tma_b_warp = [persistent_tc_warps[-1] + 1]
sch_warp = [persistent_tma_b_warp[-1] + 1]

persistent_a_copy_warps_role = WarpsRole(persistent_a_copy_warps)
persistent_epi_warps_role = WarpsRole(persistent_epi_warps)
persistent_tc_warps_role = WarpsRole(persistent_tc_warps)
persistent_tma_b_warp_role = WarpsRole(persistent_tma_b_warp)
sch_warp_role = WarpsRole(sch_warp)
persistent_total_warps = (
    len(persistent_a_copy_warps)
    + len(persistent_epi_warps)
    + len(persistent_tc_warps)
    + len(persistent_tma_b_warp)
    + len(sch_warp)
)

persistent_named_bar_operand_storage_init_bar_id = 1
persistent_named_bar_tmem_alloc_bar_id = 2
persistent_named_bar_epilogue_bar_id = 3
persistent_named_bar_tmem_release_bar_id = 6
persistent_named_bar_task_handoff_id = 7

persistent_bar_operand_storage_init = NamedBarriers(
    persistent_named_bar_operand_storage_init_bar_id,
    (
        persistent_tma_b_warp,
        persistent_a_copy_warps,
        persistent_tc_warps,
        persistent_epi_warps,
        sch_warp,
    ),
)
persistent_bar_tmem_alloc = NamedBarriers(
    persistent_named_bar_tmem_alloc_bar_id, (persistent_a_copy_warps,)
)
persistent_bar_epilogue = NamedBarriers(
    persistent_named_bar_epilogue_bar_id, (persistent_epi_warps,)
)
persistent_bar_tmem_release = NamedBarriers(
    persistent_named_bar_tmem_release_bar_id,
    (persistent_epi_warps, persistent_tma_b_warp),
)

# Every role must adopt the same next CLC response before any producer starts
# another A/B stage; otherwise a deep task pipeline can pair adjacent tiles.
persistent_bar_task_handoff = NamedBarriers(
    persistent_named_bar_task_handoff_id,
    (
        persistent_tma_b_warp,
        persistent_a_copy_warps,
        persistent_tc_warps,
        persistent_epi_warps,
        sch_warp,
    ),
)


class SliceK_WDM_CLC_Persistent_Implementation:
    def __init__(
        self,
        *,
        ab_dtype=cutlass.Float8E4M3FN,
        cd_dtype=cutlass.Float16,
        use_percentage: bool = True,
        acc_stage: int = 2,
        cta_tiler_mnk: Tuple[int, int, int] = (128, 8, 256),
        mtiles_num: int = 1,
        operand_stage: int = 2,
        smem_usage_percentage: int = 100,
        tmem_usage_percentage: int = 100,
        use_scales: bool = False,
        c_major: str = "m",
    ):
        self.auto_stage_management = StageManagement()
        self.mtiles_num = mtiles_num
        self.acc_stage = acc_stage
        self.task_stage = 3
        self.cta_tiler_mnk = cta_tiler_mnk
        self.ab_dtype = ab_dtype
        self.cd_dtype = cd_dtype
        self.use_scales = use_scales
        self.c_major = c_major
        if use_percentage:
            smem_available = (
                self.auto_stage_management.smem_capacity * smem_usage_percentage // 100
                - 1024
            )
            a_diagpack_bytes = (
                cta_tiler_mnk[0]
                * cta_tiler_mnk[2]
                * self.mtiles_num
                * self.ab_dtype.width
                // 8
            )
            b_bytes = cta_tiler_mnk[1] * cta_tiler_mnk[2] * self.ab_dtype.width // 8
            direct_smem_stages = smem_available // (a_diagpack_bytes + b_bytes)
            if direct_smem_stages <= 0:
                raise ValueError(
                    "the A-from-SMEM staging footprint exceeds the SMEM budget"
                )
            self.operand_stage = direct_smem_stages
        else:
            self.operand_stage = operand_stage

    @cute.kernel
    def gemm_kernel(
        self,
        a: cute.Tensor,
        tma_b_desc: cutlass.GridConstant[cutlass_cuda.TensorMap],
        tma_b_op: cutlass.Constexpr[OperandB_TMA | OperandB_16B_aligned_TMA],
        mnk: Tuple[int, int, int],
        gmem_output: cute.Tensor,
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
    ) -> None:
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        lane_idx = cute.arch.thread_idx()[0] % 32
        bidx = cute.arch.block_idx()[0]
        bidy = cute.arch.block_idx()[1]
        expert_idx = cute.arch.block_idx()[2]

        operand_smem_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.operand_stage, space=cutlass.AddressSpace.smem
        )
        operand_smem_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.operand_stage, space=cutlass.AddressSpace.smem
        )
        acc_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.acc_stage, space=cutlass.AddressSpace.smem
        )
        acc_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.acc_stage, space=cutlass.AddressSpace.smem
        )
        task_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.task_stage, space=cutlass.AddressSpace.smem
        )
        task_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, self.task_stage, space=cutlass.AddressSpace.smem
        )
        task_response_ptr_i128 = cutlass.Array(
            cutlass.Int128, self.task_stage, space=cutlass.AddressSpace.smem
        )
        tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

        a_row_bytes: Constexpr = 128 if self.cta_tiler_mnk[0] == 128 else 64
        # One operand-ring slot owns one A diagpack per adjacent logical-M
        # tile and one B tile shared by all of them.
        smem_matrix_a = cutlass.Array(
            cutlass.Uint8,
            (self.operand_stage, self.mtiles_num, 128, a_row_bytes),
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        smem_matrix_b = cutlass.Array(
            cutlass.Uint8,
            (
                self.operand_stage,
                self.cta_tiler_mnk[1],
                self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            ),
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        smem_workspace = cutlass.Array(
            cutlass.Uint8, 1024, space=cutlass.AddressSpace.smem, alignment=128
        )
        TmemManagment = CentralizedTmemManagment(
            mtile_size=self.cta_tiler_mnk[0],
            ntile_size=self.cta_tiler_mnk[1],
            acc_stage=self.acc_stage,
            mtiles_num=self.mtiles_num,
            Arch=SliceKArchHelper,
        )

        k_iterations = cute.ceil_div(mnk[2], self.cta_tiler_mnk[2])
        scheduler = ClcPersistentScheduler()

        # A persistent CTA repeats the same per-tile SliceK lifetime as the
        # nonpersistent kernel, but CLC supplies the next (logical-M,
        # logical-N, expert) coordinate.  The task pipeline transfers that
        # ownership to every warp role; the accumulator pipeline ensures the
        # old tile's physical-M/K-stripe partials are reduced and stored before
        # its TMEM stage is reused for the next task.
        if sch_warp_role.begin_id <= warp_idx <= sch_warp_role.end_id:
            MbarrierInit.sts_init(
                (
                    (task_full_mbar_ptr, 1),
                    (task_empty_mbar_ptr, persistent_total_warps * 32),
                ),
                stage=self.task_stage,
            )
            prims.fence_mbarrier_init()
            NamedBarriers.wait(
                persistent_bar_operand_storage_init.bar_id,
                persistent_bar_operand_storage_init.participants_threads,
            )
            pipeline_task_producer_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.task_stage,
                    full_signal_=task_full_mbar_ptr,
                    empty_signal_=task_empty_mbar_ptr,
                    empty_parity_init_=cutlass.Int32(0),
                ),
                consumer_release_op_=GeneralRelease(),
            )
            for stage in cutlass.range_constexpr(self.task_stage):
                scheduler.fetch_next_task(
                    task_response_ptr_i128.subview(stage),
                    task_full_mbar_ptr.subview(stage),
                )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                current_stage = pipeline_task_producer_consumer.get_stage()
                pipeline_task_producer_consumer.consumer_acquire()
                current_task_vaild, _, _, _ = scheduler.get_task_info(
                    task_response_ptr_i128.subview(current_stage)
                )
                pipeline_task_producer_consumer.consumer_release()
                # Workers release this task-response slot before entering the
                # handoff.  Join that blocking barrier before reusing the slot:
                # a scheduler that spin-waits on task_empty first can run far
                # ahead of a deep one-warp operand pipeline and starve the very
                # workers whose arrivals complete task_empty.
                NamedBarriers.wait(
                    persistent_bar_task_handoff.bar_id,
                    persistent_bar_task_handoff.participants_threads,
                )
                if current_task_vaild:
                    pipeline_task_producer_consumer.producer_acquire()
                    scheduler.fetch_next_task(
                        task_response_ptr_i128.subview(current_stage),
                        pipeline_task_producer_consumer.get_full_signal(),
                    )
                pipeline_task_producer_consumer.advance()

        elif (
            persistent_tma_b_warp_role.begin_id
            <= warp_idx
            <= persistent_tma_b_warp_role.end_id
        ):
            tma_b_op.prefetch_tma_descriptor(tma_b_desc.get_ptr())
            # full: 128 A-producer threads plus one TMA-B transaction.
            # empty: the sole TC warp commits after both K64 issues finish.
            MbarrierInit.sts_init(
                (
                    (operand_smem_full_mbar_ptr, 1 + 128),
                    (operand_smem_empty_mbar_ptr, len(persistent_tc_warps)),
                ),
                stage=self.operand_stage,
            )
            prims.fence_mbarrier_init()
            NamedBarriers.arrive(
                persistent_bar_operand_storage_init.bar_id,
                persistent_bar_operand_storage_init.participants_threads,
            )
            pipeline_smem_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                )
            )
            smem_b_buffer = RingDataBuffer(
                data_base=smem_matrix_b,
                stage=self.operand_stage,
                stride=self.cta_tiler_mnk[1]
                * self.cta_tiler_mnk[2]
                * self.ab_dtype.width
                // 8,
            )
            pipeline_task_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.task_stage,
                    full_signal_=task_full_mbar_ptr,
                    empty_signal_=task_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            cute.arch.griddepcontrol_wait()
            while current_task_vaild:
                n_offset = bidy * self.cta_tiler_mnk[1]
                l_offset = expert_idx * mnk[1]
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    smem_stage_idx = pipeline_smem_producer.get_stage()
                    pipeline_smem_producer.producer_acquire()
                    tma_b_op.tma_load_and_arrive(
                        smem_b_buffer.get_data_with_stage(smem_stage_idx),
                        tma_b_desc.get_ptr(),
                        pipeline_smem_producer.get_full_signal(),
                        n_offset + l_offset,
                        k_iter * self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
                    )
                    pipeline_smem_producer.producer_release()
                    pipeline_smem_producer.advance()
                pipeline_task_consumer.consumer_acquire()
                task_stage_idx = pipeline_task_consumer.get_stage()
                current_task_vaild, _, bidy, expert_idx = scheduler.get_task_info(
                    task_response_ptr_i128.subview(task_stage_idx)
                )
                pipeline_task_consumer.consumer_release()
                pipeline_task_consumer.advance()
                NamedBarriers.wait(
                    persistent_bar_task_handoff.bar_id,
                    persistent_bar_task_handoff.participants_threads,
                )

            cute.arch.griddepcontrol_launch_dependents()
            NamedBarriers.wait(
                persistent_bar_tmem_release.bar_id,
                persistent_bar_tmem_release.participants_threads,
            )
            tmem_ptr = cutlass.inttoptr(tmem_ptr_i32.load(), 6, cutlass.Uint32)
            prims.tcgen05_dealloc(
                tmem_ptr, TmemManagment.get_total_tmem_ncols, group="cta_1"
            )

        elif (
            persistent_a_copy_warps_role.begin_id
            <= warp_idx
            <= persistent_a_copy_warps_role.end_id
        ):
            # Four producer warps write the current CLC tile's A values
            # directly into the physical-M/K-stripe MMA diagpack.
            if warp_idx == persistent_a_copy_warps[0]:
                prims.tcgen05_alloc(
                    tmem_ptr_i32, TmemManagment.get_total_tmem_ncols, group="cta_1"
                )
                prims.tcgen05_relinquish_alloc_permit(group="cta_1")
            NamedBarriers.wait(
                persistent_bar_operand_storage_init.bar_id,
                persistent_bar_operand_storage_init.participants_threads,
            )
            pipeline_a_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                )
            )
            smem_a_uint8_ptr = cutlass.inttoptr(
                smem_matrix_a.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            smem_a_buffer = RingDataBuffer(
                data_base=smem_a_uint8_ptr,
                stage=self.operand_stage,
                stride=self.mtiles_num * 128 * a_row_bytes,
            )
            producer_warp_rank = warp_idx - persistent_a_copy_warps_role.begin_id
            fundamental_k_blocks = SliceKArchHelper.get_fundamental_k_tile_128bytes_num(
                self.cta_tiler_mnk[0]
            )
            producer_copy_count = (
                self.cta_tiler_mnk[0]
                * self.cta_tiler_mnk[2]
                * self.mtiles_num
                // (len(persistent_a_copy_warps) * 32 * 16)
            )
            a_base = a.iterator.raw_ptr()
            pipeline_task_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.task_stage,
                    full_signal_=task_full_mbar_ptr,
                    empty_signal_=task_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                m_offset = bidx * self.cta_tiler_mnk[0] * self.mtiles_num
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    operand_stage_idx = pipeline_a_producer.get_stage()
                    pipeline_a_producer.producer_acquire()
                    if cutlass.const_expr(self.cta_tiler_mnk[0] == 128):
                        _issue_cp_async_a_diagpack_128b(
                            a_base,
                            smem_a_buffer.get_data_with_stage(operand_stage_idx),
                            problem_m=mnk[0],
                            problem_k=mnk[2],
                            logical_m_base=m_offset,
                            logical_k_base=k_iter * self.cta_tiler_mnk[2],
                            lane_idx=lane_idx,
                            producer_warp_rank=producer_warp_rank,
                            producer_copy_count=producer_copy_count,
                        )
                    else:
                        _issue_cp_async_a_diagpack_64b(
                            a_base,
                            smem_a_buffer.get_data_with_stage(operand_stage_idx),
                            problem_m=mnk[0],
                            problem_k=mnk[2],
                            logical_m_base=m_offset,
                            logical_k_base=k_iter * self.cta_tiler_mnk[2],
                            lane_idx=lane_idx,
                            producer_warp_rank=producer_warp_rank,
                            fundamental_k_blocks=fundamental_k_blocks,
                            logical_m_per_tile=self.cta_tiler_mnk[0],
                            producer_copy_count=producer_copy_count,
                        )
                    prims.cp_async_mbarrier_arrive(
                        pipeline_a_producer.get_full_signal(), noinc=True
                    )
                    pipeline_a_producer.advance()
                pipeline_task_consumer.consumer_acquire()
                task_stage_idx = pipeline_task_consumer.get_stage()
                current_task_vaild, bidx, _, expert_idx = scheduler.get_task_info(
                    task_response_ptr_i128.subview(task_stage_idx)
                )
                pipeline_task_consumer.consumer_release()
                pipeline_task_consumer.advance()
                NamedBarriers.wait(
                    persistent_bar_task_handoff.bar_id,
                    persistent_bar_task_handoff.participants_threads,
                )

        elif (
            persistent_tc_warps_role.begin_id
            <= warp_idx
            <= persistent_tc_warps_role.end_id
        ):
            # For each CLC work tile, initialize the accumulator, consume
            # matching A-SMEM/B-SMEM stages across K, and issue WDM MMA.  WDM
            # preserves only A/B pairs with the same K stripe.
            if warp_idx == persistent_tc_warps_role.begin_id:
                MbarrierInit.sts_init(
                    (
                        (acc_full_mbar_ptr, len(persistent_tc_warps)),
                        (acc_empty_mbar_ptr, 128),
                    ),
                    stage=self.acc_stage,
                )
            prims.fence_mbarrier_init()
            NamedBarriers.wait(
                persistent_bar_operand_storage_init.bar_id,
                persistent_bar_operand_storage_init.participants_threads,
            )
            pipeline_operand_ab_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.operand_stage,
                    full_signal_=operand_smem_full_mbar_ptr,
                    empty_signal_=operand_smem_empty_mbar_ptr,
                ),
                consumer_release_op_=Tc1CtaRelease(),
            )
            pipeline_accum_producer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.acc_stage,
                    full_signal_=acc_full_mbar_ptr,
                    empty_signal_=acc_empty_mbar_ptr,
                ),
                producer_release_op_=Tc1CtaRelease(),
            )
            tmem_all_ptr = tmem_ptr_i32.load()
            tmem_accum_col_offset, tmem_accum_stride, _ = (
                TmemManagment.get_accum_base_stride_end()
            )
            tmem_accum_buffer = RingDataBuffer(
                data_base=tmem_all_ptr + tmem_accum_col_offset,
                stage=self.acc_stage,
                stride=tmem_accum_stride,
            )
            smem_a_uint8_ptr = cutlass.inttoptr(
                smem_matrix_a.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            smem_b_uint8_ptr = cutlass.inttoptr(
                smem_matrix_b.data_ptr().toint(cutlass.Int32),
                cutlass.AddressSpace.smem,
                cutlass.Uint8,
            )
            ktile_bytes = self.cta_tiler_mnk[2] * self.ab_dtype.width // 8
            slicek_tc_config = TensorCoreConfig(
                warp_num=len(persistent_tc_warps),
                cta_M=self.cta_tiler_mnk[0],
                cta_N=self.cta_tiler_mnk[1],
                inst_K_bytes=64,
                k_dim_128bytes_num=ktile_bytes // 128,
                a_input_format=self.ab_dtype,
                b_input_format=self.ab_dtype,
                c_output_format=cutlass.Float32,
            )
            slicek_mma = Tcgen05_TS_WDM_1CTA(
                config=slicek_tc_config, mtile_num=self.mtiles_num
            )
            wdm_mask_32b = slicek_mma.create_wdm_mask()
            instr_desc = slicek_mma.create_instr_desc()
            # Hoist descriptors outside the whole CLC work-tile loop.  Every
            # scheduled tile reuses them and advances only the ring-stage base.
            if cutlass.const_expr(self.cta_tiler_mnk[0] == 128):
                SmemDescA_base = prims.Tcgen05SmemDesc.build(
                    start_address=smem_a_uint8_ptr,
                    leading_byte_offset=16,
                    stride_byte_offset=1024,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
                )
            else:
                SmemDescA_base = prims.Tcgen05SmemDesc.build(
                    start_address=smem_a_uint8_ptr,
                    leading_byte_offset=16,
                    stride_byte_offset=512,
                    layout=prims.Tcgen05SmemSwizzle.SWIZZLE_64B,
                )
            SmemDescB_base = prims.Tcgen05SmemDesc.build(
                start_address=smem_b_uint8_ptr,
                leading_byte_offset=16,
                stride_byte_offset=8 * 128,
                layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
            )
            a_mtile_stride_16b: Constexpr = 128 * a_row_bytes >> 4
            smem_a_desc_buffer = RingDataBuffer(
                data_base=SmemDescA_base,
                stage=self.operand_stage,
                stride=self.mtiles_num * a_mtile_stride_16b,
            )
            smem_b_desc_buffer = RingDataBuffer(
                data_base=SmemDescB_base,
                stage=self.operand_stage,
                stride=self.cta_tiler_mnk[1]
                * self.cta_tiler_mnk[2]
                * self.ab_dtype.width
                // 8
                >> 4,
            )
            pipeline_task_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.task_stage,
                    full_signal_=task_full_mbar_ptr,
                    empty_signal_=task_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                accum_stage_idx = pipeline_accum_producer.get_stage()
                pipeline_accum_producer.producer_acquire()
                # Every CLC tile starts in replace mode.  The one-warp issue
                # helper handles the CTA-M-specific transition between its two
                # native 64B-K issues, then returns accumulate mode for later
                # K tiles.
                scale_d = cutlass.Boolean(False)
                for k_iter in cutlass.range(k_iterations, unroll=1):
                    input_stage_idx = pipeline_operand_ab_consumer.get_stage()
                    pipeline_operand_ab_consumer.consumer_acquire()
                    smem_a_operand_base = smem_a_desc_buffer.get_data_with_stage(
                        input_stage_idx
                    )
                    smem_b_operand_base = smem_b_desc_buffer.get_data_with_stage(
                        input_stage_idx
                    )
                    smem_a_operands, smem_b_operands = (
                        slicek_mma.prepare_smem_a_smem_b_operands(
                            smem_a_operand_base, smem_b_operand_base
                        )
                    )
                    # The sole TC warp issues the two K64 halves into one C tile.
                    scale_d = slicek_mma.mma_from_smem(
                        tmem_accum_buffer.get_data_with_stage(accum_stage_idx),
                        smem_a_operands,
                        smem_b_operands,
                        wdm_mask_32b,
                        instr_desc,
                        scale_d,
                        a_mtile_stride_16b,
                    )
                    # Release this operand stage only after both MMA reads commit.
                    pipeline_operand_ab_consumer.consumer_release()
                    pipeline_operand_ab_consumer.advance()
                # Hand the fully accumulated work tile to the epilogue.
                pipeline_accum_producer.producer_release()
                pipeline_accum_producer.advance()
                pipeline_task_consumer.consumer_acquire()
                task_stage_idx = pipeline_task_consumer.get_stage()
                current_task_vaild, _, _, _ = scheduler.get_task_info(
                    task_response_ptr_i128.subview(task_stage_idx)
                )
                pipeline_task_consumer.consumer_release()
                pipeline_task_consumer.advance()
                NamedBarriers.wait(
                    persistent_bar_task_handoff.bar_id,
                    persistent_bar_task_handoff.participants_threads,
                )

        elif (
            persistent_epi_warps_role.begin_id
            <= warp_idx
            <= persistent_epi_warps_role.end_id
        ):
            # Epilogue reduces physical MMA rows to logical D, stores the
            # current tile, and releases the accumulator stage before the CTA
            # adopts the next CLC-scheduled tile.
            NamedBarriers.wait(
                persistent_bar_operand_storage_init.bar_id,
                persistent_bar_operand_storage_init.participants_threads,
            )
            warp_id_in_wg = warp_idx % 4
            tmem_all_ptr = tmem_ptr_i32.load() + warp_id_in_wg * 32 * 65536
            tmem_accum_col_offset, tmem_accum_stride, _ = (
                TmemManagment.get_accum_base_stride_end()
            )
            tmem_accum_buffer = RingDataBuffer(
                data_base=tmem_all_ptr + tmem_accum_col_offset,
                stage=self.acc_stage,
                stride=tmem_accum_stride,
            )
            pipeline_accum_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.acc_stage,
                    full_signal_=acc_full_mbar_ptr,
                    empty_signal_=acc_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            epilogue = Tcgen05_Epilogue(
                mtile_size=self.cta_tiler_mnk[0],
                ntile_size=self.cta_tiler_mnk[1],
                mtiles_num=self.mtiles_num,
                arch_helper=SliceKArchHelper,
                use_scales=self.use_scales,
                n_contiguous=self.c_major == "n",
            )
            pipeline_task_consumer = ProducerConsumerPipeline(
                SignalsRingBuffer(
                    stage_=self.task_stage,
                    full_signal_=task_full_mbar_ptr,
                    empty_signal_=task_empty_mbar_ptr,
                ),
                consumer_release_op_=GeneralRelease(),
            )
            current_task_vaild: cutlass.Boolean = cutlass.Boolean(True)
            while current_task_vaild:
                pipeline_task_consumer.consumer_acquire()
                accum_stage_idx = pipeline_accum_consumer.get_stage()
                pipeline_accum_consumer.consumer_acquire()
                sub_accums = epilogue.load_accum(
                    tmem_accum=tmem_accum_buffer.get_data_with_stage(accum_stage_idx)
                )
                prims.tcgen05_wait(kind="load")
                # Once all four warps finish loading from TMEM, the accumulator stage is no
                # longer read.  Publish its 128 acc_empty arrivals before the
                # RF-only reduction/store to overlap the next tile's MMA.
                pipeline_accum_consumer.consumer_release()
                next_task_vaild, nxt_bidx, nxt_bidy, nxt_expert_idx = (
                    scheduler.get_task_info(
                        task_response_ptr_i128.subview(
                            pipeline_task_consumer.get_stage()
                        )
                    )
                )
                reduced_accums = epilogue.reduction(rf_sub_accum=sub_accums)
                if not next_task_vaild:
                    NamedBarriers.arrive(
                        persistent_bar_tmem_release.bar_id,
                        persistent_bar_tmem_release.participants_threads,
                    )
                scaled_accums = epilogue.apply_scales(
                    rf_reduced=reduced_accums,
                    encodeA_scale=encodeA_scale,
                    encodeB_scale=encodeB_scale,
                    decodeD_scale=decodeD_scale,
                )
                epilogue.store_gmem(
                    rf_out_scaled=scaled_accums,
                    gmem_output=gmem_output.iterator.raw_ptr(),
                    problem_m=mnk[0],
                    problem_n=mnk[1],
                    bidx=bidx,
                    bidy=bidy,
                    lane_idx=lane_idx,
                    warp_idx_in_warp=warp_id_in_wg,
                )
                current_task_vaild = next_task_vaild
                bidx = nxt_bidx
                bidy = nxt_bidy
                expert_idx = nxt_expert_idx
                pipeline_task_consumer.consumer_release()
                pipeline_accum_consumer.advance()
                pipeline_task_consumer.advance()
                NamedBarriers.wait(
                    persistent_bar_task_handoff.bar_id,
                    persistent_bar_task_handoff.participants_threads,
                )

    @cute.jit
    def host_function(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        problem_size: Tuple[int, int, int],
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
        stream: cuda_driver.CUstream,
        use_pdl: bool = False,
    ) -> None:
        tma_b_16B_op = OperandB_16B_aligned_TMA(
            ntile_size=self.cta_tiler_mnk[1],
            ktile_bytes=self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            element_bits=self.ab_dtype.width,
            pad_with_tma=True,
        )
        tma_b_128B_op = OperandB_TMA(
            ntile_size=self.cta_tiler_mnk[1],
            ktile_bytes=self.cta_tiler_mnk[2] * self.ab_dtype.width // 8,
            element_bits=self.ab_dtype.width,
            pad_with_tma=True,
        )
        k_divisibility = cute.get_divisibility(b.shape[1])
        tma_b_op = (
            tma_b_128B_op
            if cutlass.const_expr(k_divisibility * self.ab_dtype.width % 1024 == 0)
            else tma_b_16B_op
        )
        tma_b_desc = tma_b_op.create_tma_descriptor(b, self.ab_dtype)
        grid_shape = (
            cute.ceil_div(problem_size[0], self.cta_tiler_mnk[0] * self.mtiles_num),
            cute.ceil_div(problem_size[1], self.cta_tiler_mnk[1]),
            1,
        )
        block_shape = (persistent_total_warps * 32, 1, 1)
        self.gemm_kernel(
            a,
            tma_b_desc,
            tma_b_op,
            problem_size,
            c,
            encodeA_scale,
            encodeB_scale,
            decodeD_scale,
        ).launch(
            grid=grid_shape,
            block=block_shape,
            cluster=(1, 1, 1),
            stream=stream,
            use_pdl=use_pdl,
            max_number_threads=(persistent_total_warps * 32, 1, 1),
            min_blocks_per_mp=1,
        )

    @lru_cache(maxsize=None)
    def compile(
        self,
        encodeA_scale: cutlass.Float32,
        encodeB_scale: cutlass.Float32,
        decodeD_scale: cutlass.Float32,
        use_pdl: bool = False,
        *,
        k_alignment_bytes: int,
    ) -> Callable:
        """Compile host_function for the given K and bias flag.

        The returned function accepts PyTorch tensors directly (TVM-FFI flow).
        M and N are symbolic so a single binary handles any valid problem size.
        """
        sym_m = cute.sym_int32()
        sym_n = cute.sym_int32()
        sym_k = cute.sym_int32(
            divisibility=k_alignment_bytes * 8 // self.ab_dtype.width
        )
        fake_a = make_fake_compact_tensor(
            self.ab_dtype, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
        )
        fake_b = make_fake_compact_tensor(
            self.ab_dtype, (sym_n, sym_k), stride_order=(1, 0), assumed_align=16
        )
        c_shape = (sym_m, sym_n) if self.c_major == "n" else (sym_n, sym_m)
        fake_c = make_fake_compact_tensor(
            self.cd_dtype, c_shape, stride_order=(1, 0), assumed_align=16
        )
        compile_options = "--ptxas-options=--warning-as-error"
        if not emulate_rubin:
            compile_options = f"--gpu-arch sm_107a {compile_options}"
        return cute.compile[cute.GenerateLineInfo(True)](
            self.host_function,
            fake_a,
            fake_b,
            fake_c,
            (sym_m, sym_n, sym_k),
            encodeA_scale,
            encodeB_scale,
            decodeD_scale,
            make_fake_stream(),
            use_pdl,
            options=compile_options,
        )


# ===== END: persistent =====

# ===== BEGIN: driver =====
# Standalone host surface: validates Rubin CTA/resource contracts, selects NP
# or CLC, creates FP8 inputs and FP8/FP16/FP32 output tensors, compiles,
# launches, and verifies against a Float32 reference with encode/decode scales.
"""Host entry for the Rubin A-from-SMEM SliceK prototype."""
_FUNDAMENTAL_K_128B = {128: 1, 64: 1, 32: 2, 16: 4, 8: 8}


def _k_alignment_bytes(problem_k: int, ab_dtype: type[cutlass.Numeric]) -> int:
    """K alignment class of a problem size that SliceKConfig.validate accepted."""
    k_bytes = problem_k * ab_dtype.width // 8
    return 128 if k_bytes % 128 == 0 else 16


@dataclass(frozen=True)
class SliceKConfig:
    cta_m: int
    cta_n: int
    cta_k: int
    mtiles_num: int = 1
    scheduler: str = "nonpersistent"
    acc_stage: int = 1
    use_percentage: bool = True
    smem_percentage: int = 100
    tmem_percentage: int = 100
    operand_stage: int = 2
    use_pdl: bool = False
    emulate_rubin: bool = False
    use_scales: bool = False
    c_major: str = "m"

    @property
    def fundamental_k_128b(self) -> int:
        return _FUNDAMENTAL_K_128B[self.cta_m]

    @property
    def minimum_cta_k_bytes(self) -> int:
        return 128 * self.fundamental_k_128b

    def validate(self, *, problem_k: int, ab_dtype: type[cutlass.Numeric]) -> None:
        if self.cta_m not in _FUNDAMENTAL_K_128B:
            raise ValueError("cta_m must be one of 128, 64, 32, 16, or 8")
        if self.cta_n < 8 or self.cta_n & (self.cta_n - 1):
            raise ValueError("cta_n must be 8 times a nonnegative power of two")
        if self.cta_n * self.fundamental_k_128b > 504:
            raise ValueError("derived Rubin MMA inst_N must not exceed 504")
        if self.cta_k <= 0:
            raise ValueError("cta_k must be positive")
        if self.mtiles_num <= 0 or self.cta_m * self.mtiles_num > 256:
            raise ValueError("mtiles_num must satisfy cta_m * mtiles_num <= 256")
        if self.scheduler not in ("nonpersistent", "clc"):
            raise ValueError("scheduler must be 'nonpersistent' or 'clc'")
        if self.c_major not in ("m", "n"):
            raise ValueError("c_major must be 'm' or 'n'")
        if self.acc_stage <= 0:
            raise ValueError("acc_stage must be positive")
        if self.use_percentage:
            if not 0 < self.smem_percentage <= 100:
                raise ValueError("smem_percentage must be in [1, 100]")
            if not 0 < self.tmem_percentage <= 100:
                raise ValueError("tmem_percentage must be in [1, 100]")
        elif self.operand_stage <= 0:
            raise ValueError("manual operand_stage must be positive")
        cta_k_bytes = self.cta_k * ab_dtype.width // 8
        if cta_k_bytes % self.minimum_cta_k_bytes != 0:
            raise ValueError(
                f"cta_k is invalid for Rubin cta_m={self.cta_m}: cta_k_bytes must be a multiple of {self.minimum_cta_k_bytes}"
            )
        problem_k_bytes = problem_k * ab_dtype.width // 8
        if problem_k <= 0:
            raise ValueError("problem K must be positive")
        if problem_k_bytes % 16 != 0:
            raise ValueError("the input K mode must be at least 16B aligned")
        if self.fundamental_k_128b > 1 and problem_k_bytes % 128 != 0:
            raise ValueError("cta_m <= 32 requires 128B-aligned problem K")

        if (
            self.cta_k != 128 * self.fundamental_k_128b
            or ab_dtype != cutlass.Float8E4M3FN
        ):
            raise ValueError(
                "the A-from-SMEM path currently supports canonical FP8 "
                "CTA pairs with cta_k=128*f(cta_m)"
            )


def _configure_rubin(*, emulate: bool) -> None:
    global emulate_rubin
    emulate_rubin = emulate


def make_implementation(
    config: SliceKConfig,
    *,
    ab_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    cd_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
):
    """Construct a Rubin implementation with the requested global-output type."""
    _configure_rubin(emulate=config.emulate_rubin)
    implementation = (
        SliceK_WDM_CLC_Persistent_Implementation
        if config.scheduler == "clc"
        else SliceK_WDM_NonPersistent_Implementation
    )
    result = implementation(
        ab_dtype=ab_dtype,
        cd_dtype=cd_dtype,
        cta_tiler_mnk=(config.cta_m, config.cta_n, config.cta_k),
        mtiles_num=config.mtiles_num,
        acc_stage=config.acc_stage,
        use_percentage=config.use_percentage,
        operand_stage=config.operand_stage,
        smem_usage_percentage=config.smem_percentage,
        tmem_usage_percentage=config.tmem_percentage,
        use_scales=config.use_scales,
        c_major=config.c_major,
    )
    a_diagpack_bytes = (
        config.cta_m * config.cta_k * config.mtiles_num * ab_dtype.width // 8
    )
    stage_bytes = a_diagpack_bytes + config.cta_n * config.cta_k * ab_dtype.width // 8
    smem_bytes = 1024 + result.operand_stage * stage_bytes
    smem_budget = (
        result.auto_stage_management.smem_capacity * config.smem_percentage // 100
    )
    if smem_bytes > smem_budget:
        raise ValueError(
            "the requested A-from-SMEM stage count exceeds the SMEM budget: "
            f"{smem_bytes}B > {smem_budget}B"
        )
    accum_cols = (
        config.cta_n * config.fundamental_k_128b * config.mtiles_num * config.acc_stage
    )
    tmem_columns = max(32, 1 << (accum_cols - 1).bit_length())
    tmem_budget = (
        result.auto_stage_management.tmem_capacity * config.tmem_percentage // 100
    )
    if tmem_columns > tmem_budget:
        raise ValueError(
            "the requested accumulator allocation exceeds the TMEM budget: "
            f"{tmem_columns} columns > {tmem_budget}"
        )
    return result


def _make_tensor(
    shape: tuple[int, int], dtype: type[cutlass.Numeric], *, random_input: bool
) -> tuple[cute.Tensor, torch.Tensor]:
    source = (
        torch.empty(shape, dtype=torch.float32).random_(-1, 2)
        if random_input
        else torch.zeros(shape, dtype=torch.float32)
    )
    _, storage = cutlass_torch.cute_tensor_like(
        source, dtype, is_dynamic_layout=True, assumed_align=16
    )
    tensor = cute_tensor_from_torch(storage, element_type=dtype, leading_dim=1)
    return (tensor, storage.view(cutlass_torch.dtype(dtype)))


def compile_slicek(
    config: SliceKConfig,
    *,
    problem_k: int,
    ab_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    cd_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    encode_a_scale: float = 1.0,
    encode_b_scale: float = 1.0,
    decode_d_scale: float = 1.0,
) -> Callable:
    config.validate(problem_k=problem_k, ab_dtype=ab_dtype)
    implementation = make_implementation(config, ab_dtype=ab_dtype, cd_dtype=cd_dtype)
    return implementation.compile(
        encode_a_scale,
        encode_b_scale,
        decode_d_scale,
        config.use_pdl,
        k_alignment_bytes=_k_alignment_bytes(problem_k, ab_dtype),
    )


def run_slicek(
    mnk: tuple[int, int, int],
    config: SliceKConfig,
    *,
    ab_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    cd_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    encode_a_scale: float = 1.0,
    encode_b_scale: float = 1.0,
    decode_d_scale: float = 1.0,
    tolerance: float = 1.0,
    exact_fp8: bool = False,
) -> None:
    """Compile, run, and verify one Rubin Slice-K problem."""
    m, n, k = mnk
    if m <= 0 or n <= 0:
        raise ValueError("problem M and N must be positive")
    config.validate(problem_k=k, ab_dtype=ab_dtype)
    if exact_fp8 and cd_dtype != cutlass.Float8E4M3FN:
        raise ValueError("exact_fp8 verification requires FP8 E4M3 output")
    if not config.use_scales and (
        encode_a_scale != 1.0 or encode_b_scale != 1.0 or decode_d_scale != 1.0
    ):
        raise ValueError("non-unit scales require use_scales=True")
    implementation = make_implementation(config, ab_dtype=ab_dtype, cd_dtype=cd_dtype)
    compiled = implementation.compile(
        encode_a_scale,
        encode_b_scale,
        decode_d_scale,
        config.use_pdl,
        k_alignment_bytes=_k_alignment_bytes(k, ab_dtype),
    )
    a, a_torch = _make_tensor((m, k), ab_dtype, random_input=True)
    b, b_torch = _make_tensor((n, k), ab_dtype, random_input=True)
    c_shape = (m, n) if config.c_major == "n" else (n, m)
    c, c_torch = _make_tensor(c_shape, cd_dtype, random_input=False)
    stream = cuda_driver.CUstream(torch.cuda.Stream().cuda_stream)
    compiled(
        a,
        b,
        c,
        mnk,
        encode_a_scale,
        encode_b_scale,
        decode_d_scale,
        stream,
        config.use_pdl,
    )
    torch.cuda.synchronize()
    scale = encode_a_scale * encode_b_scale * decode_d_scale
    reference = torch.einsum("mk,nk->nm", a_torch.float(), b_torch.float()) * scale
    if config.c_major == "n":
        reference = reference.t().contiguous()
    reference_output = reference.to(cutlass_torch.dtype(cd_dtype))
    if exact_fp8:
        torch.testing.assert_close(
            c_torch.view(torch.uint8),
            reference_output.view(torch.uint8),
            rtol=0,
            atol=0,
        )
    else:
        torch.testing.assert_close(
            c_torch.float(), reference_output.float(), rtol=0.0, atol=tolerance
        )


def benchmark_slicek(
    mnk: tuple[int, int, int],
    config: SliceKConfig,
    *,
    ab_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    cd_dtype: type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    encode_a_scale: float = 1.0,
    encode_b_scale: float = 1.0,
    decode_d_scale: float = 1.0,
    warmup: int = 20,
    iterations: int = 100,
) -> tuple[float, float]:
    """Compile once and return CUDA-event time in microseconds and TFLOP/s."""
    if warmup < 0:
        raise ValueError("warmup must be nonnegative")
    if iterations <= 0:
        raise ValueError("iterations must be positive")

    m, n, k = mnk
    if m <= 0 or n <= 0:
        raise ValueError("problem M and N must be positive")
    config.validate(problem_k=k, ab_dtype=ab_dtype)
    if not config.use_scales and (
        encode_a_scale != 1.0 or encode_b_scale != 1.0 or decode_d_scale != 1.0
    ):
        raise ValueError("non-unit scales require use_scales=True")

    implementation = make_implementation(config, ab_dtype=ab_dtype, cd_dtype=cd_dtype)
    compiled = implementation.compile(
        encode_a_scale,
        encode_b_scale,
        decode_d_scale,
        config.use_pdl,
        k_alignment_bytes=_k_alignment_bytes(k, ab_dtype),
    )
    a, _ = _make_tensor((m, k), ab_dtype, random_input=True)
    b, _ = _make_tensor((n, k), ab_dtype, random_input=True)
    c_shape = (m, n) if config.c_major == "n" else (n, m)
    c, _ = _make_tensor(c_shape, cd_dtype, random_input=False)

    torch_stream = torch.cuda.Stream()
    stream = cuda_driver.CUstream(torch_stream.cuda_stream)
    torch.cuda.synchronize()
    with torch.cuda.stream(torch_stream):
        for _ in range(warmup):
            compiled(
                a,
                b,
                c,
                mnk,
                encode_a_scale,
                encode_b_scale,
                decode_d_scale,
                stream,
                config.use_pdl,
            )

        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record(torch_stream)
        for _ in range(iterations):
            compiled(
                a,
                b,
                c,
                mnk,
                encode_a_scale,
                encode_b_scale,
                decode_d_scale,
                stream,
                config.use_pdl,
            )
        end.record(torch_stream)

    end.synchronize()
    gpu_us = start.elapsed_time(end) * 1000.0 / iterations
    tflops = 2.0 * m * n * k / (gpu_us * 1.0e6)
    return (gpu_us, tflops)


def _parse_mnk(value: str) -> tuple[int, int, int]:
    values = tuple((int(item.strip()) for item in value.split(",")))
    if len(values) != 3:
        raise argparse.ArgumentTypeError("expected M,N,K")
    return values


def main() -> None:
    global ab_dtype, cd_dtype
    parser = argparse.ArgumentParser(description="Rubin Slice-K WDM GEMM")
    parser.add_argument("--mnk", type=_parse_mnk, default=(128, 8, 512))
    parser.add_argument(
        "--cta-m", type=int, choices=tuple(_FUNDAMENTAL_K_128B), default=16
    )
    parser.add_argument("--cta-n", type=int, default=8)
    parser.add_argument("--cta-k", type=int, default=512)
    parser.add_argument("--mtiles-num", type=int, default=1)
    parser.add_argument(
        "--scheduler", choices=("nonpersistent", "clc"), default="nonpersistent"
    )
    parser.add_argument("--ab-dtype", choices=("fp8",), default="fp8")
    parser.add_argument("--cd-dtype", choices=("fp8", "fp16", "fp32"), default="fp8")
    parser.add_argument("--acc-stage", type=int, default=1)
    parser.add_argument("--smem-percentage", type=int, default=100)
    parser.add_argument("--tmem-percentage", type=int, default=100)
    parser.add_argument("--operand-stage", type=int, default=2)
    parser.add_argument("--manual-stages", action="store_true")
    parser.add_argument("--use-pdl", action="store_true")
    parser.add_argument("--emulate-rubin", action="store_true")
    parser.add_argument("--use-scales", action="store_true")
    parser.add_argument("--c-major", choices=("m", "n"), default="m")
    parser.add_argument("--encode-a-scale", type=float, default=1.0)
    parser.add_argument("--encode-b-scale", type=float, default=1.0)
    parser.add_argument("--decode-d-scale", type=float, default=1.0)
    parser.add_argument("--tolerance", type=float, default=1.0)
    parser.add_argument("--exact-fp8", action="store_true")
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--warmup", type=int, default=20)
    parser.add_argument("--iterations", type=int, default=100)
    args = parser.parse_args()
    ab_dtype = cutlass.Float8E4M3FN
    cd_dtype = {
        "fp8": cutlass.Float8E4M3FN,
        "fp16": cutlass.Float16,
        "fp32": cutlass.Float32,
    }[args.cd_dtype]
    config = SliceKConfig(
        cta_m=args.cta_m,
        cta_n=args.cta_n,
        cta_k=args.cta_k,
        mtiles_num=args.mtiles_num,
        scheduler=args.scheduler,
        acc_stage=args.acc_stage,
        use_percentage=not args.manual_stages,
        smem_percentage=args.smem_percentage,
        tmem_percentage=args.tmem_percentage,
        operand_stage=args.operand_stage,
        use_pdl=args.use_pdl,
        emulate_rubin=args.emulate_rubin,
        use_scales=args.use_scales,
        c_major=args.c_major,
    )
    if args.benchmark:
        gpu_us, tflops = benchmark_slicek(
            args.mnk,
            config,
            ab_dtype=ab_dtype,
            cd_dtype=cd_dtype,
            encode_a_scale=args.encode_a_scale,
            encode_b_scale=args.encode_b_scale,
            decode_d_scale=args.decode_d_scale,
            warmup=args.warmup,
            iterations=args.iterations,
        )
        print(
            f"benchmark: gpu_us={gpu_us:.3f}, tflops={tflops:.3f}, warmup={args.warmup}, iterations={args.iterations}"
        )
    else:
        run_slicek(
            args.mnk,
            config,
            ab_dtype=ab_dtype,
            cd_dtype=cd_dtype,
            encode_a_scale=args.encode_a_scale,
            encode_b_scale=args.encode_b_scale,
            decode_d_scale=args.decode_d_scale,
            tolerance=args.tolerance,
            exact_fp8=args.exact_fp8,
        )
        print("PASS")


# ===== END: driver =====

if __name__ == "__main__":
    main()
