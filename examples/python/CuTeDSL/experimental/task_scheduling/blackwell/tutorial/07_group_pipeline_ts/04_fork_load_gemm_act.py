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

"""Tutorial 07: **Fork** PipelineGroup — one LoadA producer, two SMEM consumers.

One LoadA producer fills SmemA; ``group.commit()`` on the Fork
``PipelineGroup`` wakes two consumers that share the **same physical SMEM
buffer** through different pipeline views:

- **SmemAGemm** — UMMA descriptor path for MMA
- **SmemAAct** — linear global memory load for activation / ReLU store

Configurable kernel for two test cases:

- ``load_mode="tma"``: Fork(TmaUmma + TmaAsync)
- ``load_mode="gmem"``: Fork(AsyncUmma + AsyncAsync)

One producer (LoadA) fills SmemA.  Two consumers read from SmemA:

- MMA reads SmemAGemm (UMMA descriptor path) + SmemB → TmemC → GmemD
- StoreReLU reads SmemAAct (linear read), applies ReLU → GmemReluD

SmemAGemm and SmemAAct are two pipeline "views" of the **same physical
SMEM buffer**, grouped in a ``PipelineGroup(Fork)``.

Resources:

    GmemA ──→ SmemAGemm ─┐ (TmaUmma or AsyncUmma)
                          ├── fork_sync (PipelineGroup, Fork)
              SmemAAct   ─┘ (TmaAsync or AsyncAsync) — shares SMEM

    GmemB ──→ SmemB (TmaUmma)

    SmemAGemm + SmemB ──→ MMA → TmemC → StoreD → GmemD
    SmemAAct ──→ StoreReLU → GmemReluD

Tasks:

  - LoadA      (warp 4)    : Fill SmemAGemm (fork propagates to SmemAAct)
  - LoadB      (warp 5)    : TMA fill SmemB
  - MmaTask    (warp 6)    : Consume SmemAGemm + SmemB → TmemC
  - StoreD     (warps 0-2) : Consume TmemC, store to GmemD
  - StoreReLU  (warp 3)    : Consume SmemAAct, relu, store to GmemReluD
  - Padding    (warp 7)    : Warp-group alignment (no-op)

Validation:
  - GmemD == matmul(A, B) + ReLU
  - GmemReluD contains relu(A_tiles) (element-wise, in SMEM order)
"""

import argparse
from typing import Tuple
from functools import lru_cache
from dataclasses import dataclass, field

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

from cutlass.experimental.task_scheduling.enums import (
    WorkAttr,
    PipelineGroupMode,
)
from cutlass.experimental.task_scheduling.memory import (
    SmemAllocation,
    TmemAllocation,
    SmemAllocator,
    TmemAllocator,
)
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    StageInfo,
    PipelineConfig,
    PipelineGroup,
    TaskLocalVariable,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    domain_loop,
    schedule,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

# ──────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────

io_dtype = cutlass.Float16
acc_dtype = cutlass.Float32

mma_inst_shape_mnk = (128, 16, 16)
mma_tiler_mnk = (128, 16, 64)

tma_k_box = min(mma_tiler_mnk[2], 128 // (io_dtype.width // 8))
tma_copy_iters = mma_tiler_mnk[2] // tma_k_box

ab_stages = 4
acc_stages = 1

num_store_warps = 4
num_relu_warps = 1
num_load_a_warps = 1
num_load_b_warps = 1
num_mma_warps = 1
num_padding_warps = 0

total_warps = (
    num_store_warps
    + num_relu_warps
    + num_load_a_warps
    + num_load_b_warps
    + num_mma_warps
    + num_padding_warps
)
assert total_warps == 8

a_tile_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2]
bytes_a = a_tile_elems * (io_dtype.width // 8)
bytes_b = mma_tiler_mnk[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)

t2r_inst_repx = min(32, mma_tiler_mnk[1])

debug_print = False

# ──────────────────────────────────────────────────────────────────────
# Resource definitions
# ──────────────────────────────────────────────────────────────────────


@dataclass
class GmemAResource(MemoryResource):
    """
    Coordinate computation for A tile load.
    """

    tile_m_idx: cutlass.Constexpr = field(init=False, default=None)
    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.coord_m = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="M coordinate for A tile loads.",
        )
        self.coord_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="K coordinate for A tile loads.",
        )

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        del stage_info
        bx, _, _ = cute.arch.block_idx()
        self.tile_m_idx = bx

    @consumer_work(returns=(coord_m, coord_k))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32]:
        return (
            self.tile_m_idx * mma_tiler_mnk[0],
            stage_info.loop_offset * mma_tiler_mnk[2],
        )


@dataclass
class GmemBResource(MemoryResource):
    """
    Coordinate computation for B tile load.
    """

    tile_n_idx: cutlass.Constexpr = field(init=False, default=None)
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.coord_n = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="N coordinate for B tile loads.",
        )
        self.coord_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="K coordinate for B tile loads.",
        )

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        del stage_info
        _, by, _ = cute.arch.block_idx()
        self.tile_n_idx = by

    @consumer_work(returns=(coord_n, coord_k))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32]:
        return (
            self.tile_n_idx * mma_tiler_mnk[1],
            stage_info.loop_offset * mma_tiler_mnk[2],
        )


@dataclass
class SmemAGemmResource(MemoryResource):
    """SMEM A for the GEMM path — owns the physical SMEM allocation.

    The producer loads A data from GMEM (TMA or global memory load with 128B XOR
    swizzle).  The consumer builds a Tcgen05SmemDesc for MMA.
    SmemAAct shares this buffer through the fork PipelineGroup.
    """

    gA: cutlass.Constexpr = field(init=False, default=None)
    shared_smem: cutlass.Constexpr = field(init=False, default=None)
    copy_elems: cutlass.Constexpr = field(init=False, default=None)
    _alloc: cutlass.Constexpr = field(init=False, default=None)
    _is_tma: cutlass.Constexpr = field(init=False, default=False)
    _tma_desc: cutlass.Constexpr = field(init=False, default=None)
    desc_a_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(
        self,
        gA: cute.Tensor = None,
        tma_desc=None,
        is_tma: bool = False,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.gA = gA
        self._is_tma = is_tma
        self._tma_desc = tma_desc
        self.copy_elems = cutlass.Int32(a_tile_elems)
        elem_size = io_dtype.width // 8
        self._alloc = SmemAllocation(
            "smem_a",
            a_tile_elems * ab_stages * elem_size,
        )
        self.desc_a_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SMEM A descriptor base for MMA.",
        )

    def get_smem_requirements(self):
        return [self._alloc]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.shared_smem = cutlass.Array(
            context.smem_base.data_ptr() + self._alloc.offset,
            dtype=io_dtype,
            shape=(a_tile_elems * ab_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptor_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=desc_a_base)
    @cute.jit
    def build_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        sA_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
        desc_a_base = prims.Tcgen05SmemDesc.build(
            sA_curr,
            leading_byte_offset=16,
            stride_byte_offset=8 * tma_k_box * (io_dtype.width // 8),
            layout=2,
        )
        return desc_a_base

    @producer_work
    @cute.jit
    def load(
        self, stage_info: StageInfo, *, coord_m: cutlass.Int32, coord_k: cutlass.Int32
    ) -> None:
        if cutlass.const_expr(self._is_tma):
            if prims.elect_sync():
                sA_curr = self.shared_smem.subview(
                    self.copy_elems * stage_info.stage_idx
                )
                box_elems = mma_tiler_mnk[0] * tma_k_box
                for ki in cutlass.range_constexpr(tma_copy_iters):
                    prims.cp_async_bulk_tensor_shared_cta_global(
                        sA_curr.subview(box_elems * ki),
                        self._tma_desc,
                        (coord_k + tma_k_box * ki, coord_m),
                        stage_info.barrier,
                    )
        else:
            tx, _, _ = cute.arch.thread_idx()
            lane = tx % 32
            sA_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
            vec_size = 8
            elems_per_thread = a_tile_elems // 32
            elem_bytes = io_dtype.width // 8

            for i in cutlass.range_constexpr(elems_per_thread // vec_size):
                base = lane * elems_per_thread + i * vec_size
                row = base // mma_tiler_mnk[2]
                col = base % mma_tiler_mnk[2]
                gmem_idx = (coord_m + row) * self.gA.shape[1] + (coord_k + col)
                vec = self.gA.load(gmem_idx, vec_size)
                # 128B XOR swizzle to match TMA s128b / Tcgen05SmemDesc layout.
                byte_off = base * elem_bytes
                swizzled = byte_off ^ (((byte_off >> 7) & 0x7) << 4)
                sA_curr.store(vec, idx=swizzled // elem_bytes, vector_size=vec_size)
            cute.arch.fence_view_async_shared()


@dataclass
class SmemAActResource(MemoryResource):
    """SMEM A for the activation path — shares SmemAGemm's physical buffer.

    No separate SMEM allocation.  The consumer loads all per-thread
    elements from SMEM into registers in a single ConsumerWork call
    (using ``cutlass.range_constexpr`` to iterate subtiles), then
    passes the full register array to ``GmemReluDResource``.
    """

    _gemm_alloc: cutlass.Constexpr = field(init=False, default=None)
    shared_smem: cutlass.Constexpr = field(init=False, default=None)
    relu_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, gemm_alloc: SmemAllocation, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self._gemm_alloc = gemm_alloc
        self.relu_rmem = TaskLocalVariable(
            dtype=io_dtype,
            default=cutlass.full([a_tile_elems // 32], 0.0, io_dtype),
            docs="Register tile loaded from SMEM A for the ReLU side output.",
        )

    def get_smem_requirements(self):
        return []

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_activation_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.shared_smem = cutlass.Array(
            context.smem_base.data_ptr() + self._gemm_alloc.offset,
            dtype=io_dtype,
            shape=(a_tile_elems * ab_stages,),
            addrspace=3,
        )

    @consumer_work(returns=relu_rmem)
    @cute.jit
    def load_activation(self, stage_info: StageInfo) -> io_dtype:
        tx, _, _ = cute.arch.thread_idx()
        lane = tx % 32
        sA = self.shared_smem.subview(a_tile_elems * stage_info.stage_idx)
        ept = a_tile_elems // 32
        rmem = sA.load(lane * ept, ept)
        return rmem


@dataclass
class SmemBResource(MemoryResource):
    """
    SMEM B filled by TMA.
    """

    tma_desc_b: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_b: cutlass.Constexpr = field(init=False, default=None)
    sB_copy_elems: cutlass.Constexpr = field(init=False, default=None)
    _alloc_b: cutlass.Constexpr = field(init=False, default=None)
    desc_b_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(self, tma_desc_b: cutlass.Pointer, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.tma_desc_b = tma_desc_b
        self.sB_copy_elems = cutlass.Int32(mma_tiler_mnk[1] * mma_tiler_mnk[2])
        elem_size = io_dtype.width // 8
        self._alloc_b = SmemAllocation(
            "smem_b",
            mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages * elem_size,
        )
        self.desc_b_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SMEM B descriptor base for MMA.",
        )

    def get_smem_requirements(self):
        return [self._alloc_b]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.shared_smem_b = cutlass.Array(
            context.smem_base.data_ptr() + self._alloc_b.offset,
            dtype=io_dtype,
            shape=(mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptor_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=desc_b_base)
    @cute.jit
    def build_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        sB = self.shared_smem_b.subview(self.sB_copy_elems * stage_info.stage_idx)
        desc_b_base = prims.Tcgen05SmemDesc.build(
            sB,
            leading_byte_offset=16,
            stride_byte_offset=8 * tma_k_box * (io_dtype.width // 8),
            layout=2,
        )
        return desc_b_base

    @producer_work
    @cute.jit
    def load(
        self, stage_info: StageInfo, *, coord_n: cutlass.Int32, coord_k: cutlass.Int32
    ) -> None:
        if prims.elect_sync():
            sB = self.shared_smem_b.subview(self.sB_copy_elems * stage_info.stage_idx)
            box_elems = mma_tiler_mnk[1] * tma_k_box
            for ki in cutlass.range_constexpr(tma_copy_iters):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sB.subview(box_elems * ki),
                    self.tma_desc_b,
                    (coord_k + tma_k_box * ki, coord_n),
                    stage_info.barrier,
                )


@dataclass
class TmemCResource(MemoryResource):
    """
    TMEM accumulator written by MMA, read by StoreD.
    """

    t2r_inst_shape: cutlass.Constexpr[int] = field(init=False, default=None)
    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    scale_d: cutlass.Constexpr = field(init=False, default=None)
    idesc: cutlass.Constexpr = field(init=False, default=None)
    tmem_raw_addr: cutlass.Constexpr = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_shape = "32x32b"
        self.t2r_inst_repx = t2r_inst_repx
        self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * acc_stages)
        self.t2r_rmem = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.full([t2r_inst_repx], 0.0, cutlass.Float32),
            docs="Register tile loaded from TMEM for the D epilogue.",
        )

    def get_tmem_requirements(self):
        return [self._alloc_acc]

    @cute.jit
    def _init_tmem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.idesc = prims.Tcgen05InstrDesc.build(
            a_dtype=cutlass.Float16,
            b_dtype=cutlass.Float16,
            c_dtype=cutlass.Float32,
            n_dim=mma_inst_shape_mnk[1],
            m_dim=mma_inst_shape_mnk[0],
        )
        self.tmem_raw_addr = context.tmem_ptr_i32.load()
        self.scale_d = cutlass.Boolean(False)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_mma_state(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_acc(self, stage_info: StageInfo) -> cutlass.Float32:
        warp_idx = cute.arch.warp_idx()
        base_col = (self.tmem_raw_addr & 0xFFFF) + (
            stage_info.stage_idx * mma_tiler_mnk[1]
        )
        row_id = (self.tmem_raw_addr >> 16) + warp_idx * 32
        tmem_addr = (row_id << 16) | base_col
        tmem_ptr = prims.make_tmem_ptr(tmem_addr, cutlass.Float32)
        t2r = prims.tcgen05_ld(
            self.t2r_inst_shape,
            tmem_ptr,
            num=self.t2r_inst_repx,
        )
        cute.arch.fence_view_async_tmem_load()
        return t2r

    @producer_work
    @cute.jit
    def mma(
        self,
        stage_info: StageInfo,
        *,
        desc_a_base: cutlass.Int64,
        desc_b_base: cutlass.Int64,
    ) -> None:
        tmem_ptr = prims.make_tmem_ptr(self.tmem_raw_addr, acc_dtype)
        tmem_curr = cutlass.Array(
            tmem_ptr.data_ptr() + stage_info.stage_idx * mma_tiler_mnk[1] // 4,
            dtype=cutlass.Int32,
            addrspace=6,
        )

        num_k_halves = mma_tiler_mnk[2] // tma_k_box
        k_blocks = tma_k_box // mma_inst_shape_mnk[2]
        h_off_a = mma_tiler_mnk[0] * tma_k_box * (io_dtype.width // 8) >> 4
        h_off_b = mma_tiler_mnk[1] * tma_k_box * (io_dtype.width // 8) >> 4

        for kh in cutlass.range_constexpr(num_k_halves):
            da = desc_a_base + h_off_a * kh
            db = desc_b_base + h_off_b * kh
            for lk in cutlass.range_constexpr(k_blocks):
                inc = (mma_inst_shape_mnk[2] * io_dtype.width // 8 * lk) >> 4
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_1,
                        tmem_curr,
                        da + inc,
                        db + inc,
                        self.idesc,
                        self.scale_d,
                    )
                self.scale_d = cutlass.Boolean(True)


@dataclass
class GmemDResource(MemoryResource):
    """
    GMEM output for GEMM result with ReLU: D = relu(A @ B^T).
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    gD: cutlass.Constexpr = field(init=False, default=None)
    n_dim: cutlass.Constexpr = field(init=False, default=None)

    def __init__(self, mD_mn: cutlass.Array, n_dim: int, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_repx = t2r_inst_repx
        self.gD = mD_mn
        self.n_dim = n_dim

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, t2r_rmem: cutlass.Float32) -> None:
        tx, _, _ = cute.arch.thread_idx()
        bx, by, _ = cute.arch.block_idx()
        row = bx * mma_tiler_mnk[0] + tx
        col = by * mma_tiler_mnk[1]

        sv = min(8, self.t2r_inst_repx)
        buf = cutlass.Array(
            cutlass.Float16,
            self.t2r_inst_repx,
            alignment=min(16, self.t2r_inst_repx * 2),
        )
        for j in cutlass.range_constexpr(self.t2r_inst_repx):
            relu_val = cutlass.max(t2r_rmem[j], cutlass.Float32(0.0))
            buf[j] = relu_val.to(cutlass.Float16)
        for j in cutlass.range_constexpr(self.t2r_inst_repx // sv):
            vec = buf.load(j * sv, sv)
            self.gD.store(
                vec,
                idx=row * self.n_dim + col + j * sv,
                vector_size=sv,
                alignment=min(16, sv * 2),
            )


@dataclass
class GmemReluDResource(MemoryResource):
    """GMEM output for element-wise relu(A_tile).

    Receives the full per-thread register array from
    ``SmemAActResource``, applies ReLU, and stores to GMEM in a
    single ProducerWork call (iterating subtiles with
    ``cutlass.range_constexpr``).
    """

    gReluD: cutlass.Constexpr = field(init=False, default=None)
    _num_k_tiles: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        mReluD: cutlass.Array,
        num_k_tiles: int,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.gReluD = mReluD
        self._num_k_tiles = num_k_tiles

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, relu_rmem: io_dtype) -> None:
        tx, _, _ = cute.arch.thread_idx()
        lane = tx % 32
        bx, _, _ = cute.arch.block_idx()

        ept = a_tile_elems // 32
        gmem_row = bx * self._num_k_tiles + stage_info.loop_offset
        gmem_base = gmem_row * a_tile_elems + lane * ept

        vec_size = 8
        buf = cutlass.Array(cutlass.Float16, vec_size, alignment=16)
        for i in cutlass.range_constexpr(ept // vec_size):
            for j in cutlass.range_constexpr(vec_size):
                v = relu_rmem[i * vec_size + j].to(cutlass.Float32)
                buf[j] = cutlass.max(v, cutlass.Float32(0.0)).to(cutlass.Float16)
            self.gReluD.store(
                buf.load(0, vec_size),
                idx=gmem_base + i * vec_size,
                vector_size=vec_size,
            )


# ──────────────────────────────────────────────────────────────────────
# Kernel
# ──────────────────────────────────────────────────────────────────────


@cute.kernel
def fork_kernel(
    gA: cutlass.Array,
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mD_mn: cutlass.Array,
    mReluD: cutlass.Array,
    mnk: Tuple[int, int, int],
    use_tma: cutlass.Constexpr[bool],
) -> None:
    """
    1-CTA GEMM + ReLU kernel with a Fork PipelineGroup on shared SmemA.
    """
    m, n, k = mnk
    num_k_tiles = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]
    num_epilogue_warps = num_store_warps
    cta = (1, 1, 1, 1)

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 5:
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    allocator = SmemAllocator()
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4),
    )

    # Resource construction
    gmem_a = GmemAResource(name="gmem_a")
    gmem_b = GmemBResource(name="gmem_b")

    if cutlass.const_expr(use_tma):
        cfg_gemm = PipelineConfig.create_tma_umma_pipeline_cfg(
            num_stages=ab_stages,
            num_bytes=bytes_a,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            cta_layout_vmnk=cta,
        )
        cfg_act = PipelineConfig.create_tma_async_pipeline_cfg(
            num_stages=ab_stages,
            num_bytes=bytes_a,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_relu_warps,
            ),
            cta_layout_vmnk=cta,
        )
        smem_a_gemm = SmemAGemmResource(
            tma_desc=tma_a_desc.get_ptr(),
            is_tma=True,
            pipeline_config=cfg_gemm,
            name="smem_a_gemm",
        )
    else:
        cfg_gemm = PipelineConfig.create_async_umma_pipeline_cfg(
            num_stages=ab_stages,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_load_a_warps * 32,
            ),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            cta_layout_vmnk=cta,
        )
        cfg_act = PipelineConfig.create_async_async_pipeline_cfg(
            num_stages=ab_stages,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_load_a_warps * 32,
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_relu_warps * 32,
            ),
            cta_layout_vmnk=cta,
        )
        smem_a_gemm = SmemAGemmResource(
            gA=gA,
            is_tma=False,
            pipeline_config=cfg_gemm,
            name="smem_a_gemm",
        )

    smem_a_act = SmemAActResource(
        gemm_alloc=smem_a_gemm._alloc,
        pipeline_config=cfg_act,
        name="smem_a_act",
    )

    # Fork two pipeline views of the same SMEM A buffer into a single PipelineGroup
    fork_sync = PipelineGroup(
        name="fork_sync",
        members=[smem_a_gemm, smem_a_act],
        mode=PipelineGroupMode.Fork,
    )

    cfg_b = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=bytes_b,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta,
    )
    smem_b = SmemBResource(
        tma_desc_b=tma_b_desc.get_ptr(),
        pipeline_config=cfg_b,
        name="smem_b",
    )

    cfg_c = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_epilogue_warps * 32,
        ),
        cta_layout_vmnk=cta,
    )
    tmem_c = TmemCResource(pipeline_config=cfg_c, name="tmem_c")

    gmem_d = GmemDResource(mD_mn=mD_mn, n_dim=n, name="gmem_d")
    gmem_relu_d = GmemReluDResource(
        mReluD=mReluD,
        num_k_tiles=num_k_tiles,
        name="gmem_relu_d",
    )

    allocator.add_resource(smem_a_gemm)
    allocator.add_resource(smem_b)
    # Do not forget to add the pipeline group to the allocator
    allocator.add_pipeline_group(fork_sync)

    # Task schedule construction
    @schedule
    def load_a_schedule(
        gmem: MemoryResource,
        smem_gemm: MemoryResource,
        smem_act: MemoryResource,
        group: MemoryResource,
    ) -> None:
        smem_gemm.init_load_state()
        gmem.init_tile_coords()
        with domain_loop(0, num_k_tiles, 1):
            coord_m, coord_k = gmem.compute_coords()
            # Acquire each fork member's empty barrier (per-member)
            smem_gemm.try_acquire()
            smem_gemm.acquire()
            smem_act.try_acquire()
            smem_act.acquire()
            smem_gemm.load(coord_m=coord_m, coord_k=coord_k)
            # Commit the pipeline group, not the individual members
            group.commit()

    # Pass grouped resources fork_sync.smem_a_gemm, fork_sync.smem_a_act, and fork_sync
    load_a_result = load_a_schedule(
        gmem_a,
        fork_sync.smem_a_gemm,
        fork_sync.smem_a_act,
        fork_sync,
    )

    load_a = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_a],
        dst_resources=[smem_a_gemm, smem_a_act],
        warp_idx=4,
        num_warps=num_load_a_warps,
        schedule=load_a_result,
        num_registers=160,
        name="LoadA",
        debug_print=debug_print,
    )

    @schedule
    def load_b_schedule(gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        gmem.init_tile_coords()
        with domain_loop(0, num_k_tiles, 1):
            coord_n, coord_k = gmem.compute_coords()
            smem.try_acquire()
            smem.acquire()
            smem.load(coord_n=coord_n, coord_k=coord_k)
            smem.commit()

    load_b_result = load_b_schedule(gmem_b, smem_b)

    load_b = Task(
        src_resources=[gmem_b],
        dst_resources=[smem_b],
        warp_idx=5,
        num_warps=num_load_b_warps,
        schedule=load_b_result,
        num_registers=160,
        name="LoadB",
        debug_print=debug_print,
    )

    @schedule
    def mma_schedule(
        smem_a_ref: MemoryResource, smem_b_ref: MemoryResource, tmem: MemoryResource
    ) -> None:
        smem_a_ref.init_descriptor_state()
        smem_b_ref.init_descriptor_state()
        tmem.init_mma_state()
        tmem.try_acquire()
        tmem.acquire()
        with domain_loop(0, num_k_tiles, 1):
            # Wait on the GEMM view of shared SMEM A (fork member).
            smem_a_ref.try_wait()
            smem_a_ref.wait()
            smem_b_ref.try_wait()
            smem_b_ref.wait()
            desc_a_base = smem_a_ref.build_descriptor()
            desc_b_base = smem_b_ref.build_descriptor()
            tmem.mma(desc_a_base=desc_a_base, desc_b_base=desc_b_base)
            # Release per-member empty barriers (Fork consumer side, not group.release())
            smem_a_ref.release()
            smem_b_ref.release()
        tmem.commit()

    # Pass grouped resource fork_sync.smem_a_gemm to the schedule
    mma_result = mma_schedule(fork_sync.smem_a_gemm, smem_b, tmem_c)

    mma = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[smem_a_gemm, smem_b],
        dst_resources=[tmem_c],
        warp_idx=6,
        num_warps=num_mma_warps,
        schedule=mma_result,
        num_registers=160,
        name="MmaTask",
        debug_print=debug_print,
    )

    @schedule
    def store_d_schedule(tmem: MemoryResource, gmem: MemoryResource) -> None:
        tmem.init_store_state()
        with domain_loop(0, num_k_tiles, 1):
            pass
        tmem.try_wait()
        tmem.wait()
        t2r_rmem = tmem.load_acc()
        gmem.store(t2r_rmem=t2r_rmem)
        tmem.release()

    store_d_result = store_d_schedule(tmem_c, gmem_d)

    store_d = Task(
        src_resources=[tmem_c],
        dst_resources=[gmem_d],
        warp_idx=0,
        num_warps=num_store_warps,
        schedule=store_d_result,
        num_registers=160,
        name="StoreD",
        debug_print=debug_print,
    )

    @schedule
    def store_relu_schedule(smem: MemoryResource, gmem: MemoryResource) -> None:
        smem.init_activation_state()
        with domain_loop(0, num_k_tiles, 1):
            smem.try_wait()
            smem.wait()
            relu_rmem = smem.load_activation()
            gmem.store(relu_rmem=relu_rmem)
            # Release per-member empty barrier on the activation view (not group.release())
            smem.release()

    # Pass grouped resource fork_sync.smem_a_act to the schedule
    store_relu_result = store_relu_schedule(fork_sync.smem_a_act, gmem_relu_d)

    store_relu = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[smem_a_act],
        dst_resources=[gmem_relu_d],
        warp_idx=7,
        num_warps=num_relu_warps,
        schedule=store_relu_result,
        num_registers=160,
        name="StoreReLU",
        debug_print=debug_print,
    )

    # TaskManager construction and execution
    # PipelineGroup is not a resource, it does not participate in the dependency graph
    resource_dependency_graph = {
        smem_a_gemm: [gmem_a],
        smem_b: [gmem_b],
        tmem_c: [smem_a_gemm, smem_b],
        gmem_d: [tmem_c],
        gmem_relu_d: [smem_a_act],
    }

    allocator.compute_layout()

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c)
    tmem_allocator.compute_layout()

    task_manager = TaskManager(
        tasks=[load_a, load_b, mma, store_d, store_relu],
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )

    task_manager.setup_resources_and_tasks()

    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    num_tmem_cols = max(32, mma_tiler_mnk[1] * acc_stages)
    tmem_alloc_warp = 0
    tmem_bar_id = 2
    tmem_bar_threads = (num_epilogue_warps + num_mma_warps) * 32

    if warp_idx == tmem_alloc_warp:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols)
        prims.tcgen05_relinquish_alloc_permit()

    if store_d.is_selected() or mma.is_selected():
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    tmem_raw = cutlass.Int32(0)
    if store_d.is_selected() or mma.is_selected():
        tmem_raw = tmem_ptr_i32.load()

    prims.make_tmem_ptr(tmem_raw, acc_dtype)

    task_manager.run()

    dealloc_bar_id = 3
    dealloc_bar_threads = num_store_warps * 32
    if store_d.is_selected():
        prims.barrier_cta_sync(dealloc_bar_id, thread_count=dealloc_bar_threads)

    if warp_idx == tmem_alloc_warp:
        prims.tcgen05_dealloc(
            prims.make_tmem_ptr(tmem_raw, acc_dtype),
            num_tmem_cols,
        )


# ──────────────────────────────────────────────────────────────────────
# Host runners and CLI
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def host_fn(
    a: cute.Tensor,
    b: cute.Tensor,
    d: cute.Tensor,
    relu_d: cute.Tensor,
    mnk: Tuple[int, int, int],
    use_tma: cutlass.Constexpr[bool],
) -> None:
    """
    Build TMA tensor maps and launch ``fork_kernel`` on a 2-D tile grid.
    """
    m, n, k = mnk

    tma_a = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(mma_tiler_mnk[0], tma_k_box),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )
    tma_b = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk[1], tma_k_box),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )

    mt = m // mma_tiler_mnk[0]
    nt = n // mma_tiler_mnk[1]
    fork_kernel(a, tma_a, tma_b, d, relu_d, mnk, use_tma).launch(
        grid=(mt, nt, 1),
        block=(total_warps * cute.arch.WARP_SIZE, 1, 1),
    )


# ──────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────


@lru_cache(maxsize=4)
def _prepare(m: int, n: int, k: int, use_tma: bool):
    """
    Allocate CUDA tensors, compile ``host_fn``, return callable and buffers.
    """
    import torch
    import cutlass.torch as ct

    def make_tensor(rows, cols, dtype):
        return (
            torch.empty(rows, cols, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=ct.dtype(dtype))
        )

    a = make_tensor(m, k, io_dtype)
    b = make_tensor(n, k, io_dtype)
    d = make_tensor(m, n, io_dtype)

    num_k_tiles = k // mma_tiler_mnk[2]
    m_tiles = m // mma_tiler_mnk[0]
    relu_d = torch.zeros(
        m_tiles * num_k_tiles,
        a_tile_elems,
        dtype=torch.float16,
        device="cuda",
    )

    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    d_ = from_dlpack(d).mark_layout_dynamic()
    r_ = from_dlpack(relu_d).mark_layout_dynamic()

    fn = cute.compile[cute.GenerateLineInfo(True)](
        host_fn,
        a_,
        b_,
        d_,
        r_,
        (m, n, k),
        use_tma,
    )
    return fn, (a, b, d, relu_d, a_, b_, d_, r_, (m, n, k))


def run(
    mnk: Tuple[int, int, int] = (256, 256, 256),
    load_mode: str = "tma",
    tolerance: float = 1e-01,
) -> None:
    """Run the fork kernel.

    Args:
        mnk: M, N, K dimensions.
        load_mode: "tma" or "gmem".
        tolerance: Tolerance for GEMM result validation.
    """
    import torch
    import cutlass.torch as ct

    m, n, k = mnk
    use_tma = load_mode == "tma"
    torch.manual_seed(1111)

    fn, (a, b, d, relu_d, a_, b_, d_, r_, mnk_t) = _prepare(m, n, k, use_tma)
    fn(a_, b_, d_, r_, mnk_t)
    torch.cuda.synchronize()

    # Validate GEMM result: D == relu(A @ B^T)
    ref = torch.einsum("mk,nk->mn", a.to(torch.float32), b.to(torch.float32))
    d_ref = torch.relu(ref).to(ct.dtype(io_dtype))
    torch.testing.assert_close(d, d_ref, atol=tolerance, rtol=1e-05)

    # Validate ReLU output: each tile's elements should match relu(A_tile),
    # compared by sorted values to account for SMEM swizzle reordering.
    num_k_tiles = k // mma_tiler_mnk[2]
    m_tiles = m // mma_tiler_mnk[0]
    for bx in range(m_tiles):
        for kt in range(num_k_tiles):
            row = bx * num_k_tiles + kt
            a_tile = a[
                bx * mma_tiler_mnk[0] : (bx + 1) * mma_tiler_mnk[0],
                kt * mma_tiler_mnk[2] : (kt + 1) * mma_tiler_mnk[2],
            ].flatten()
            ref_relu = torch.relu(a_tile)
            ref_sorted, _ = torch.sort(ref_relu)
            out_sorted, _ = torch.sort(relu_d[row])
            torch.testing.assert_close(out_sorted, ref_sorted, atol=0.0, rtol=0.0)


if __name__ == "__main__":
    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)

    parser = argparse.ArgumentParser(description="Fork: GEMM + activation")
    parser.add_argument("--mnk", type=str, default="256,256,256")
    parser.add_argument("--mode", choices=["tma", "gmem"], default="tma")
    parser.add_argument("--tolerance", type=float, default=1e-01)
    args = parser.parse_args()

    run(
        mnk=tuple(int(x) for x in args.mnk.split(",")),
        load_mode=args.mode,
        tolerance=args.tolerance,
    )
    print("PASS")
