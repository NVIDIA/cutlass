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

"""Tutorial 07: **Merge** / **FusedMerge**(AsyncUmma + TmaUmma) GEMM with ReLU.

Heterogeneous ``PipelineGroup`` merge in a 1-CTA GEMM: LoadA uses
``AsyncUmma`` (global memory load to SMEM A) and LoadB uses ``TmaUmma`` (TMA to SMEM B).
Both producers join ``ab_sync``.

LoadA fills SmemA via async register-through copy (``AsyncUmma``).
LoadB fills SmemB via TMA (``TmaUmma``).

  **Merge** (N producers → 1 consumer):
    MMA waits each member, runs tcgen05 MMA, then ``group.release()``.

  **FusedMerge** (N producers → 1 consumer):
    MMA waits once on the group (``group.wait()``), runs tcgen05 MMA, then
    ``group.release()``. Each producer still ``commit()``s on the shared
    full barrier with its own op.

Resources::

    GmemAResource  ──→  SmemAResource (async)  ──┐
                                                  ├──  ab_sync (PipelineGroup)
    GmemBResource  ──→  SmemBResource (TMA)    ──┘
                                                  │
                                                  ▼
                                            TmemCResource
                                                  │
                                                  ▼
                                         GmemDReluResource

Tasks::

  - LoadA      (warp 4)    : Async copy A → smem_a (member barrier ops)
  - LoadB      (warp 5)    : TMA copy B → smem_b (member barrier ops)
  - MmaTask    (warp 6)    : tcgen05 MMA, then group.release() on ab_sync
  - StoreReLU  (warps 0-3) : Read tmem_c, apply ReLU, store D0
  - PaddingTask(warp 7)    : Warp-group alignment (no-op)
"""

import argparse
from typing import Tuple, Type
from functools import lru_cache
from dataclasses import dataclass, field

import cutlass
import cutlass.experimental.cuda as cuda
from cutlass import Numeric
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
num_load_a_warps = 1
num_load_b_warps = 1
num_mma_warps = 1
num_padding_warps = 1

total_warps = (
    num_store_warps
    + num_load_a_warps
    + num_load_b_warps
    + num_mma_warps
    + num_padding_warps
)
assert total_warps == 8, f"Expected 8 warps (2 warp-groups), got {total_warps}"

bytes_a = mma_tiler_mnk[0] * mma_tiler_mnk[2] * (io_dtype.width // 8)
bytes_b = mma_tiler_mnk[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)

t2r_inst_repx = min(32, mma_tiler_mnk[1])

debug_print = False

# ──────────────────────────────────────────────────────────────────────
# Resource definitions
# ──────────────────────────────────────────────────────────────────────


@dataclass
class GmemAResource(MemoryResource):
    """
    Coordinate computation for TMA load of matrix A.
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
    Coordinate computation for TMA load of matrix B.
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
class SmemAResource(MemoryResource):
    """Staged SMEM buffer for matrix A, filled by async register-through copy.

    Unlike SmemBResource (TMA-filled), this resource uses explicit
    vector loads from GMEM followed by stores to SMEM, demonstrating
    the heterogeneous PipelineGroup pattern where one member uses an
    async pipeline and the other uses TMA.
    """

    gA: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_a: cutlass.Constexpr = field(init=False, default=None)
    sA_copy_elems: cutlass.Constexpr = field(init=False, default=None)
    _alloc_a: cutlass.Constexpr = field(init=False, default=None)
    desc_a_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(self, gA: cutlass.Array, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.gA = gA
        self.sA_copy_elems = cutlass.Int32(mma_tiler_mnk[0] * mma_tiler_mnk[2])
        elem_size = io_dtype.width // 8
        self._alloc_a = SmemAllocation(
            "smem_a",
            mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages * elem_size,
        )
        self.desc_a_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SMEM A descriptor base for MMA.",
        )

    def get_smem_requirements(self):
        return [self._alloc_a]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        sA_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages
        self.shared_smem_a = cutlass.Array(
            smem_base.data_ptr() + self._alloc_a.offset,
            dtype=io_dtype,
            shape=(sA_elems,),
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
        sA_curr = self.shared_smem_a.subview(self.sA_copy_elems * stage_info.stage_idx)
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
        tx, _, _ = cute.arch.thread_idx()
        lane = tx % 32
        sA_curr = self.shared_smem_a.subview(self.sA_copy_elems * stage_info.stage_idx)
        total_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2]
        vec_size = 8
        elems_per_thread = total_elems // 32
        elem_bytes = io_dtype.width // 8

        for i in cutlass.range_constexpr(elems_per_thread // vec_size):
            base = lane * elems_per_thread + i * vec_size
            row = base // mma_tiler_mnk[2]
            col = base % mma_tiler_mnk[2]
            gmem_idx = (coord_m + row) * self.gA.shape[1] + (coord_k + col)
            vec = self.gA.load(gmem_idx, vec_size)
            # 128B XOR swizzle (Swizzle<3,4,3>) to match TMA's s128b layout.
            byte_off = base * elem_bytes
            swizzled = byte_off ^ (((byte_off >> 7) & 0x7) << 4)
            sA_curr.store(vec, idx=swizzled // elem_bytes, vector_size=vec_size)

        prims.fence_proxy("async_shared", space=prims.SharedSpace.shared_cta)


@dataclass
class SmemBResource(MemoryResource):
    """
    Staged SMEM buffer for matrix B, filled by TMA.
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
        smem_base = stage_info.context.smem_base
        sB_elems = mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages
        self.shared_smem_b = cutlass.Array(
            smem_base.data_ptr() + self._alloc_b.offset,
            dtype=io_dtype,
            shape=(sB_elems,),
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
        sB_curr = self.shared_smem_b.subview(self.sB_copy_elems * stage_info.stage_idx)
        desc_b_base = prims.Tcgen05SmemDesc.build(
            sB_curr,
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
            sB_curr = self.shared_smem_b.subview(
                self.sB_copy_elems * stage_info.stage_idx
            )
            tma_b_box_elems = mma_tiler_mnk[1] * tma_k_box
            for ki in cutlass.range_constexpr(tma_copy_iters):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sB_curr.subview(tma_b_box_elems * ki),
                    self.tma_desc_b,
                    (coord_k + tma_k_box * ki, coord_n),
                    stage_info.barrier,
                )


@dataclass
class TmemCResource(MemoryResource):
    """
    TMEM accumulator written by 1-CTA MMA, read by the epilogue task.
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
            docs="Register tile loaded from TMEM for the epilogue.",
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

        base_col_id = (self.tmem_raw_addr & 0xFFFF) + (
            stage_info.stage_idx * mma_tiler_mnk[1]
        )
        base_row_id = self.tmem_raw_addr >> 16
        row_id = base_row_id + warp_idx * 32
        tmem_addr = (row_id << 16) | base_col_id

        tmem_ptr = prims.make_tmem_ptr(tmem_addr, cutlass.Float32)
        t2r_rmem = prims.tcgen05_ld(
            self.t2r_inst_shape, tmem_ptr, num=self.t2r_inst_repx
        )
        cute.arch.fence_view_async_tmem_load()
        return t2r_rmem

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
        tmem_ptr_for_mma = (
            tmem_ptr.data_ptr() + stage_info.stage_idx * mma_tiler_mnk[1] // 4
        )
        tmem_ptr_curr = cutlass.Array(
            tmem_ptr_for_mma, dtype=cutlass.Int32, addrspace=6
        )

        num_k_halves = mma_tiler_mnk[2] // tma_k_box
        k_blocks_per_half = tma_k_box // mma_inst_shape_mnk[2]
        half_offset_a = mma_tiler_mnk[0] * tma_k_box * (io_dtype.width // 8) >> 4
        half_offset_b = mma_tiler_mnk[1] * tma_k_box * (io_dtype.width // 8) >> 4

        for k_half in cutlass.range_constexpr(num_k_halves):
            desc_a_half = desc_a_base + half_offset_a * k_half
            desc_b_half = desc_b_base + half_offset_b * k_half
            for local_k in cutlass.range_constexpr(k_blocks_per_half):
                inc_bytes_per_iter = mma_inst_shape_mnk[2] * io_dtype.width // 8
                increment = (inc_bytes_per_iter * local_k) >> 4
                desc_a = desc_a_half + increment
                desc_b = desc_b_half + increment
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr_curr,
                        desc_a,
                        desc_b,
                        self.idesc,
                        self.scale_d,
                    )
                self.scale_d = cutlass.Boolean(True)


@dataclass
class GmemDReluResource(MemoryResource):
    """GMEM output sink that applies ReLU activation.

    Reads ``t2r_rmem`` forwarded from TmemCResource consumer, applies
    ``max(0, x)``, and stores the result to output D0.
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    gD0: cutlass.Constexpr = field(init=False, default=None)
    n_dim: cutlass.Constexpr = field(init=False, default=None)

    def __init__(self, mD0_mn: cutlass.Array, n_dim: int, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_repx = t2r_inst_repx
        self.gD0 = mD0_mn
        self.n_dim = n_dim

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, t2r_rmem: cutlass.Float32) -> None:
        tx, _, _ = cute.arch.thread_idx()

        bx, by, _ = cute.arch.block_idx()
        coord_m = bx * mma_tiler_mnk[0]
        coord_n = by * mma_tiler_mnk[1]
        row = coord_m + tx

        store_vec = min(8, self.t2r_inst_repx)
        buf = cutlass.Array(
            cutlass.Float16,
            self.t2r_inst_repx,
            alignment=min(16, self.t2r_inst_repx * 2),
        )
        for j in cutlass.range_constexpr(self.t2r_inst_repx):
            val = t2r_rmem[j]
            relu_val = cutlass.max(val, cutlass.Float32(0.0))
            buf[j] = relu_val.to(cutlass.Float16)

        for j in cutlass.range_constexpr(self.t2r_inst_repx // store_vec):
            vec = buf.load(j * store_vec, store_vec)
            linear_idx = row * self.n_dim + coord_n + j * store_vec
            self.gD0.store(
                vec,
                idx=linear_idx,
                vector_size=store_vec,
                alignment=min(16, store_vec * 2),
            )


# ──────────────────────────────────────────────────────────────────────
# Resource construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_gmem_a_resource() -> GmemAResource:
    """
    Instantiate GmemAResource for per-CTA A tile coordinates.
    """
    return GmemAResource(name="gmem_a")


@cute.jit
def create_gmem_b_resource() -> GmemBResource:
    """
    Instantiate GmemBResource for per-CTA B tile coordinates.
    """
    return GmemBResource(name="gmem_b")


@cute.jit
def create_smem_a_resource(gA: cutlass.Array) -> SmemAResource:
    """
    Build staged SmemAResource with AsyncUmma pipeline for global memory load to SMEM A.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    smem_a_pipeline_config = PipelineConfig.create_async_umma_pipeline_cfg(
        num_stages=ab_stages,
        producer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, size=num_load_a_warps * 32
        ),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return SmemAResource(
        gA=gA,
        pipeline_config=smem_a_pipeline_config,
        name="smem_a",
    )


@cute.jit
def create_smem_b_resource(tma_b_desc: cutlass.Pointer) -> SmemBResource:
    """
    Build staged SmemBResource with TmaUmma pipeline for TMA B loads.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    smem_b_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=bytes_b,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return SmemBResource(
        tma_desc_b=tma_b_desc,
        pipeline_config=smem_b_pipeline_config,
        name="smem_b",
    )


@cute.jit
def create_ab_sync_group(
    smem_a: SmemAResource,
    smem_b: SmemBResource,
    mode: cutlass.Constexpr[PipelineGroupMode],
) -> PipelineGroup:
    """PipelineGroup for smem_a + smem_b feeding the MMA consumer.

    ``mode`` selects ``Merge`` (per-member full barriers) or ``FusedMerge``
    (one shared full barrier; the MMA waits once on the group).
    """
    return PipelineGroup(
        name="ab_sync",
        members=[smem_a, smem_b],
        mode=mode,
    )


@cute.jit
def create_tmem_c_resource(num_epilogue_warps: int) -> TmemCResource:
    """
    Build TmemCResource accumulator pipeline between MMA and epilogue.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    tmem_c_pipeline_config = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, size=num_epilogue_warps * 32
        ),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return TmemCResource(
        pipeline_config=tmem_c_pipeline_config,
        name="tmem_c",
    )


@cute.jit
def create_gmem_d_relu_resource(mD0_mn: cutlass.Array, n_dim: int) -> GmemDReluResource:
    """
    Build GmemDReluResource for ReLU epilogue stores to output D0.
    """
    return GmemDReluResource(mD0_mn=mD0_mn, n_dim=n_dim, name="gmem_d_relu")


# ──────────────────────────────────────────────────────────────────────
# Task schedule construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_load_a_task(
    gmem_a: GmemAResource,
    smem_a: SmemAResource,
    ab_sync: PipelineGroup,
    num_k_tiles: int,
) -> Task:
    """
    Warp 4 LoadA: global memory load A into smem_a (ab_sync member producer).
    """

    @schedule
    def load_a_schedule(gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        gmem.init_tile_coords()
        with domain_loop(0, num_k_tiles, 1):
            coord_m, coord_k = gmem.compute_coords()
            smem.try_acquire()
            smem.acquire()
            smem.load(coord_m=coord_m, coord_k=coord_k)
            smem.commit()

    # Pass grouped resource ab_sync.smem_a to the schedule
    result = load_a_schedule(gmem_a, ab_sync.smem_a)
    return Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_a],
        dst_resources=[smem_a],
        warp_idx=4,
        num_warps=num_load_a_warps,
        schedule=result,
        num_registers=40,
        name="LoadA",
        debug_print=debug_print,
    )


@cute.jit
def create_load_b_task(
    gmem_b: GmemBResource,
    smem_b: SmemBResource,
    ab_sync: PipelineGroup,
    num_k_tiles: int,
) -> Task:
    """
    Warp 5 LoadB: TMA copy B into smem_b (ab_sync member producer).
    """

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

    # Pass grouped resource ab_sync.smem_b to the schedule
    result = load_b_schedule(gmem_b, ab_sync.smem_b)
    return Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_b],
        dst_resources=[smem_b],
        warp_idx=5,
        num_warps=num_load_b_warps,
        schedule=result,
        num_registers=40,
        name="LoadB",
        debug_print=debug_print,
    )


@cute.jit
def create_mma_task(
    smem_a: SmemAResource,
    smem_b: SmemBResource,
    ab_sync: PipelineGroup,
    tmem_c: TmemCResource,
    num_k_tiles: int,
    ab_sync_mode: cutlass.Constexpr[PipelineGroupMode],
) -> Task:
    """
    Warp 6 MMA: wait both SMEM members, MMA, then group.release().
    """

    @schedule
    def mma_schedule(
        smem_a_ref: MemoryResource,
        smem_b_ref: MemoryResource,
        tmem: MemoryResource,
        group: MemoryResource,
    ) -> None:
        smem_a_ref.init_descriptor_state()
        smem_b_ref.init_descriptor_state()
        tmem.init_mma_state()
        tmem.try_acquire()
        tmem.acquire()
        with domain_loop(0, num_k_tiles, 1):
            if cutlass.const_expr(ab_sync_mode == PipelineGroupMode.FusedMerge):
                # FusedMerge: one shared full barrier — wait once on the group.
                group.try_wait()
                group.wait()
            else:
                # Merge: per-member full barriers — wait on each member.
                smem_a_ref.try_wait()
                smem_b_ref.try_wait()
                smem_a_ref.wait()
                smem_b_ref.wait()
            desc_a_base = smem_a_ref.build_descriptor()
            desc_b_base = smem_b_ref.build_descriptor()
            tmem.mma(desc_a_base=desc_a_base, desc_b_base=desc_b_base)
            # Release the pipeline group, not the individual members
            group.release()
        tmem.commit()

    # Pass grouped resources ab_sync.smem_a and ab_sync.smem_b to the schedule
    result = mma_schedule(ab_sync.smem_a, ab_sync.smem_b, tmem_c, ab_sync)
    return Task(
        # Task gets original resources, not the grouped resource
        src_resources=[smem_a, smem_b],
        dst_resources=[tmem_c],
        warp_idx=6,
        num_warps=num_mma_warps,
        schedule=result,
        num_registers=40,
        name="MmaTask",
        debug_print=debug_print,
    )


@cute.jit
def create_store_relu_task(
    tmem_c: TmemCResource,
    gmem_d_relu: GmemDReluResource,
    num_k_tiles: int,
) -> Task:
    """
    Warps 0-3 epilogue: read tmem_c, apply ReLU, store D0.
    """

    @schedule
    def store_relu_schedule(tmem: MemoryResource, gmem: MemoryResource) -> None:
        tmem.init_store_state()
        with domain_loop(0, num_k_tiles, 1):
            pass
        tmem.try_wait()
        tmem.wait()
        t2r_rmem = tmem.load_acc()
        gmem.store(t2r_rmem=t2r_rmem)
        tmem.release()

    result = store_relu_schedule(tmem_c, gmem_d_relu)
    return Task(
        src_resources=[tmem_c],
        dst_resources=[gmem_d_relu],
        warp_idx=0,
        num_warps=num_store_warps,
        schedule=result,
        num_registers=160,
        name="StoreReLU",
        debug_print=debug_print,
    )


@cute.jit
def create_padding_task(num_k_tiles: int) -> Task:
    """
    Warp 7 no-op padding task for warp-group alignment.
    """

    @schedule
    def padding_schedule() -> None:
        with domain_loop(0, num_k_tiles, 1):
            pass

    result = padding_schedule()
    return Task(
        src_resources=[],
        dst_resources=[],
        warp_idx=7,
        num_warps=num_padding_warps,
        schedule=result,
        num_registers=40,
        name="PaddingTask",
        debug_print=debug_print,
    )


# ──────────────────────────────────────────────────────────────────────
# Kernel
# ──────────────────────────────────────────────────────────────────────


@cute.kernel
def merge_gemm_kernel(
    gA: cutlass.Array,
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mD0_mn: cutlass.Array,
    mnk: Tuple[int, int, int],
    ab_sync_mode: cutlass.Constexpr[PipelineGroupMode],
) -> None:
    """
    1-CTA TS kernel: Merge/FusedMerge PipelineGroup, resources, and TaskManager.

    ``ab_sync_mode`` selects ``Merge`` or ``FusedMerge`` for the A/B group.
    """
    m, n, k = mnk
    num_epilogue_warps = num_store_warps
    num_k_tiles = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 5:
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    # Resource construction
    allocator = SmemAllocator()
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )

    gmem_a = create_gmem_a_resource()
    gmem_b = create_gmem_b_resource()
    smem_a = create_smem_a_resource(gA)
    smem_b = create_smem_b_resource(tma_b_desc.get_ptr())
    # Merge two SMEM resources into a single PipelineGroup
    ab_sync = create_ab_sync_group(smem_a, smem_b, ab_sync_mode)
    tmem_c = create_tmem_c_resource(num_epilogue_warps)
    gmem_d_relu = create_gmem_d_relu_resource(mD0_mn, n)

    allocator.add_resource(smem_a)
    allocator.add_resource(smem_b)
    # Do not forget to add the pipeline group to the allocator
    allocator.add_pipeline_group(ab_sync)

    # Task schedule construction
    load_a_task = create_load_a_task(gmem_a, smem_a, ab_sync, num_k_tiles)
    load_b_task = create_load_b_task(gmem_b, smem_b, ab_sync, num_k_tiles)
    mma_task = create_mma_task(
        smem_a, smem_b, ab_sync, tmem_c, num_k_tiles, ab_sync_mode
    )
    store_relu_task = create_store_relu_task(tmem_c, gmem_d_relu, num_k_tiles)
    padding_task = create_padding_task(num_k_tiles)

    task_list = [
        load_a_task,
        load_b_task,
        mma_task,
        store_relu_task,
        padding_task,
    ]

    # TaskManager construction and execution
    # PipelineGroup is not a resource, it does not participate in the dependency graph
    resource_dependency_graph = {
        smem_a: [gmem_a],
        smem_b: [gmem_b],
        tmem_c: [smem_a, smem_b],
        gmem_d_relu: [tmem_c],
    }

    allocator.compute_layout()

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c)
    tmem_allocator.compute_layout()

    task_manager = TaskManager(
        tasks=task_list,
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
    tmem_allocator_warp_id = 0
    tmem_bar_id = 2
    tmem_bar_threads = (num_epilogue_warps + num_mma_warps) * 32

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols)
        prims.tcgen05_relinquish_alloc_permit()

    if store_relu_task.is_selected() or mma_task.is_selected():
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    tmem_raw_addr = cutlass.Int32(0)
    if store_relu_task.is_selected() or mma_task.is_selected():
        tmem_raw_addr = tmem_ptr_i32.load()

    tmem_ptr = prims.make_tmem_ptr(tmem_raw_addr, acc_dtype)

    task_manager.run()

    dealloc_bar_id = 3
    dealloc_bar_threads = num_epilogue_warps * 32
    if store_relu_task.is_selected():
        prims.barrier_cta_sync(dealloc_bar_id, thread_count=dealloc_bar_threads)

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols)


# ──────────────────────────────────────────────────────────────────────
# Host runners and CLI
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    d0: cute.Tensor,
    mnk: Tuple[int, int, int],
    ab_sync_mode: cutlass.Constexpr[PipelineGroupMode],
) -> None:
    """
    Host JIT: build B TMA tensor map and launch merge_gemm_kernel.
    """
    m, n, k = mnk

    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk[1], tma_k_box),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )

    m_tiles = m // mma_tiler_mnk[0]
    n_tiles = n // mma_tiler_mnk[1]
    grid_shape = (m_tiles, n_tiles, 1)
    block_size = total_warps * cute.arch.WARP_SIZE

    merge_gemm_kernel(a, tma_b_desc, d0, mnk, ab_sync_mode).launch(
        grid=grid_shape,
        block=[block_size, 1, 1],
    )


# ──────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────


_GROUP_MODE_MAP = {
    "merge": PipelineGroupMode.Merge,
    "fused": PipelineGroupMode.FusedMerge,
}


@lru_cache(maxsize=2)
def _prepare(m: int, n: int, k: int, ab_sync_mode: PipelineGroupMode):
    """
    Allocate random CUDA tensors and compile host_function (cached).
    """
    import torch
    import cutlass.torch as cutlass_torch

    def make_tensor(rows: int, cols: int, dtype: Type[Numeric]) -> "torch.Tensor":
        return (
            torch.empty(rows, cols, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=cutlass_torch.dtype(dtype))
        )

    a = make_tensor(m, k, io_dtype)
    b = make_tensor(n, k, io_dtype)
    d0 = make_tensor(m, n, io_dtype)

    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    d0_ = from_dlpack(d0).mark_layout_dynamic()

    mnk = (m, n, k)
    compiled_fn = cute.compile[cute.FrontendNext, cute.GenerateLineInfo(True)](
        host_function,
        a_,
        b_,
        d0_,
        mnk,
        ab_sync_mode,
    )
    return compiled_fn, (a, b, d0, a_, b_, d0_, mnk)


def run(
    mnk: Tuple[int, int, int] = (256, 256, 256),
    ab_sync_mode: str = "merge",
    tolerance: float = 1e-01,
) -> None:
    """
    Run Merge GEMM+ReLU on GPU and validate against PyTorch reference.
    """
    import torch
    import cutlass.torch as cutlass_torch

    if ab_sync_mode not in _GROUP_MODE_MAP:
        raise ValueError(
            f"ab_sync_mode must be one of {sorted(_GROUP_MODE_MAP)}, "
            f"got {ab_sync_mode!r}."
        )
    ab_mode = _GROUP_MODE_MAP[ab_sync_mode]

    m, n, k = mnk
    torch.manual_seed(1111)

    compiled_fn, (a, b, d0, a_, b_, d0_, mnk_t) = _prepare(m, n, k, ab_mode)
    compiled_fn(a_, b_, d0_, mnk_t)
    torch.cuda.synchronize()

    ref = torch.einsum("mk,nk->mn", a.to(torch.float32), b.to(torch.float32))
    d0_ref = torch.relu(ref).to(cutlass_torch.dtype(io_dtype))

    torch.testing.assert_close(d0, d0_ref, atol=tolerance, rtol=1e-05)


if __name__ == "__main__":
    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)

    parser = argparse.ArgumentParser(
        description="Merge/FusedMerge(AsyncUmma + TmaUmma) GEMM + ReLU"
    )
    parser.add_argument(
        "--mnk",
        type=str,
        default="256,256,256",
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument(
        "--ab-sync-mode",
        choices=_GROUP_MODE_MAP.keys(),
        default="merge",
        help="Group mode for the A/B (AsyncUmma + TmaUmma) group feeding the MMA.",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    args = parser.parse_args()
    mnk = tuple(int(x) for x in args.mnk.split(","))

    run(mnk=mnk, ab_sync_mode=args.ab_sync_mode, tolerance=args.tolerance)
    print("PASS")
