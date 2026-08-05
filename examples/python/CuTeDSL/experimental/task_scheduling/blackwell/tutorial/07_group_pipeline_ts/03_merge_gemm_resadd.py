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

"""Tutorial 07: **Merge** PipelineGroup — two merge groups in GEMM + residual-add.

Demonstrates two independent ``PipelineGroup(Merge)`` barriers in one 1-CTA
kernel:

- **ab_sync** — LoadA + LoadB (both ``TmaUmma``) share one empty barrier for MMA.
- **resadd_sync** — epilogue Merge of TMEM accumulator (``UmmaAsync``) and SMEM
  residual (``AsyncAsync`` or ``TmaAsync``).

Configurable residual load via ``residual_load_mode``:

- ``"gmem"`` -> global memory load (``AsyncAsync``) - Merge(UmmaAsync + AsyncAsync)
- ``"tma"`` → TMA load (``TmaAsync``) — Merge(UmmaAsync + TmaAsync)

The MMA engine produces the accumulator (UmmaAsync) and the residual is loaded
into SMEM by a separate warp.  The epilogue task consumes both via
``resadd_sync``: it reads the accumulator from TMEM, reads the residual from
SMEM, adds them, and stores to GMEM.

Resources::

    GmemA ──→ SmemA (TmaUmma) ──┐
                                ├── ab_sync (Merge) → MMA → TmemAcc (UmmaAsync) ──┐
    GmemB ──→ SmemB (TmaUmma) ──┘                                                  │
                                                                                   ├── resadd_sync (Merge)
    GmemRes ──→ SmemRes (AsyncAsync or TmaAsync) ──────────────────────────────────┘
                                                                                   │
                                                                                   ▼
                                                                       Epilogue: D = Acc + Res

Validation: D == matmul(A, B) + Residual
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
num_load_a_warps = 1
num_load_b_warps = 1
num_load_res_warps = 1
num_mma_warps = 1

total_warps = (
    num_store_warps
    + num_load_a_warps
    + num_load_b_warps
    + num_load_res_warps
    + num_mma_warps
)

bytes_a = mma_tiler_mnk[0] * mma_tiler_mnk[2] * (io_dtype.width // 8)
bytes_b = mma_tiler_mnk[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)
res_elems = mma_tiler_mnk[0] * mma_tiler_mnk[1]
bytes_res = res_elems * (io_dtype.width // 8)

t2r_inst_repx = min(32, mma_tiler_mnk[1])

debug_print = False


# ──────────────────────────────────────────────────────────────────────
# Resource definitions
# ──────────────────────────────────────────────────────────────────────


@dataclass
class GmemAResource(MemoryResource):
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
class GmemResResource(MemoryResource):
    """
    Coordinate computation for residual tile.
    """

    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.coord_m = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="M coordinate for residual tile loads.",
        )
        self.coord_n = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="N coordinate for residual tile loads.",
        )

    @consumer_work(returns=(coord_m, coord_n))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32]:
        del stage_info
        bx, by, _ = cute.arch.block_idx()
        return bx * mma_tiler_mnk[0], by * mma_tiler_mnk[1]


@dataclass
class SmemAResource(MemoryResource):
    """
    SMEM buffer for matrix A, filled by TMA.
    """

    tma_desc_a: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_a: cutlass.Constexpr = field(init=False, default=None)
    sA_copy_elems: cutlass.Constexpr = field(init=False, default=None)
    _alloc_a: cutlass.Constexpr = field(init=False, default=None)
    desc_a_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(self, tma_desc_a: cutlass.Pointer, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
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
        if prims.elect_sync():
            sA_curr = self.shared_smem_a.subview(
                self.sA_copy_elems * stage_info.stage_idx
            )
            tma_a_box_elems = mma_tiler_mnk[0] * tma_k_box
            for ki in cutlass.range_constexpr(tma_copy_iters):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sA_curr.subview(tma_a_box_elems * ki),
                    self.tma_desc_a,
                    (coord_k + tma_k_box * ki, coord_m),
                    stage_info.barrier,
                )


@dataclass
class SmemBResource(MemoryResource):
    """
    SMEM buffer for matrix B, filled by TMA.
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
class TmemAccResource(MemoryResource):
    """TMEM accumulator, produced by MMA (UmmaAsync pipeline).

    This resource is one member of a PipelineGroup(Merge) with SmemRes.
    The epilogue task consumes both to compute D = Acc + Residual.
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
            docs="Register tile loaded from TMEM for residual-add epilogue.",
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
            self.t2r_inst_shape,
            tmem_ptr,
            num=self.t2r_inst_repx,
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
class SmemResResource(MemoryResource):
    """
    SMEM buffer for residual data, filled by global memory load or TMA.
    """

    shared_smem_res: cutlass.Constexpr = field(init=False, default=None)
    _alloc_res: cutlass.Constexpr = field(init=False, default=None)
    _is_tma: cutlass.Constexpr = field(init=False, default=False)
    _gRes: cutlass.Constexpr = field(init=False, default=None)
    _tma_desc_res: cutlass.Constexpr = field(init=False, default=None)
    res_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(
        self,
        gRes: cute.Tensor = None,
        tma_desc_res: cutlass.Pointer = None,
        is_tma: bool = False,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self._is_tma = is_tma
        self._gRes = gRes
        self._tma_desc_res = tma_desc_res
        elem_size = io_dtype.width // 8
        self._alloc_res = SmemAllocation(
            "smem_res",
            res_elems * acc_stages * elem_size,
        )
        self.res_rmem = TaskLocalVariable(
            dtype=io_dtype,
            default=cutlass.full([t2r_inst_repx], 0.0, io_dtype),
            docs="Residual register tile loaded from SMEM.",
        )

    def get_smem_requirements(self):
        return [self._alloc_res]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        self.shared_smem_res = cutlass.Array(
            smem_base.data_ptr() + self._alloc_res.offset,
            dtype=io_dtype,
            shape=(res_elems * acc_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=res_rmem)
    @cute.jit
    def read_residual(self, stage_info: StageInfo) -> io_dtype:
        tx, _, _ = cute.arch.thread_idx()
        warp_idx_local = tx // 32
        lane = tx % 32
        sR = self.shared_smem_res.subview(res_elems * stage_info.stage_idx)
        base = (warp_idx_local * 32 + lane) * mma_tiler_mnk[1]
        res_rmem = sR.load(base, t2r_inst_repx)
        return res_rmem

    @producer_work
    @cute.jit
    def load(
        self, stage_info: StageInfo, *, coord_m: cutlass.Int32, coord_n: cutlass.Int32
    ) -> None:
        if cutlass.const_expr(self._is_tma):
            if prims.elect_sync():
                sR_curr = self.shared_smem_res.subview(res_elems * stage_info.stage_idx)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sR_curr,
                    self._tma_desc_res,
                    (coord_n, coord_m),
                    stage_info.barrier,
                )
        else:
            tx, _, _ = cute.arch.thread_idx()
            lane = tx % 32
            sR_curr = self.shared_smem_res.subview(res_elems * stage_info.stage_idx)
            vec_size = 8
            elems_per_thread = res_elems // 32

            for i in cutlass.range_constexpr(elems_per_thread // vec_size):
                base = lane * elems_per_thread + i * vec_size
                row = base // mma_tiler_mnk[1]
                col = base % mma_tiler_mnk[1]
                gmem_idx = (coord_m + row) * self._gRes.shape[1] + (coord_n + col)
                vec = self._gRes.load(gmem_idx, vec_size)
                sR_curr.store(vec, idx=base, vector_size=vec_size)


@dataclass
class GmemDResource(MemoryResource):
    """
    GMEM output: D = Acc + Residual.
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    gD: cutlass.Constexpr = field(init=False, default=None)
    n_dim: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        mD_mn: cute.Tensor,
        n_dim: int,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_repx = t2r_inst_repx
        self.gD = cutlass.make_array_view(mD_mn)
        self.n_dim = n_dim

    @producer_work
    @cute.jit
    def store(
        self, stage_info: StageInfo, *, t2r_rmem: cutlass.Float32, res_rmem: io_dtype
    ) -> None:
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
            val = t2r_rmem[j] + res_rmem[j].to(cutlass.Float32)
            buf[j] = val.to(cutlass.Float16)

        for j in cutlass.range_constexpr(self.t2r_inst_repx // store_vec):
            vec = buf.load(j * store_vec, store_vec)
            linear_idx = row * self.n_dim + coord_n + j * store_vec
            self.gD.store(
                vec,
                idx=linear_idx,
                vector_size=store_vec,
                alignment=min(16, store_vec * 2),
            )


# ──────────────────────────────────────────────────────────────────────
# Resource construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_smem_a(tma_desc_a: cutlass.Pointer) -> SmemAResource:
    """
    Build SmemA with a TmaUmma pipeline for TMA A-tile loads.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    cfg = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=bytes_a,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return SmemAResource(tma_desc_a=tma_desc_a, pipeline_config=cfg, name="smem_a")


@cute.jit
def create_smem_b(tma_desc_b: cutlass.Pointer) -> SmemBResource:
    """
    Build SmemB with a TmaUmma pipeline for TMA B-tile loads.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    cfg = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=bytes_b,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return SmemBResource(tma_desc_b=tma_desc_b, pipeline_config=cfg, name="smem_b")


@cute.jit
def create_ab_sync(smem_a: SmemAResource, smem_b: SmemBResource) -> PipelineGroup:
    """
    Merge group synchronizing SmemA and SmemB for the MMA consumer.
    """
    return PipelineGroup(
        name="ab_sync",
        members=[smem_a, smem_b],
        mode=PipelineGroupMode.Merge,
    )


@cute.jit
def create_tmem_acc(num_epilogue_warps: int) -> TmemAccResource:
    """
    Build TMEM accumulator resource with UmmaAsync epilogue pipeline.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    cfg = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_epilogue_warps * 32,
        ),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return TmemAccResource(pipeline_config=cfg, name="tmem_acc")


@cute.jit
def create_smem_res_gmem(gRes: cute.Tensor) -> SmemResResource:
    """
    Build SmemRes with AsyncAsync pipeline for residual global memory loads.
    """
    cfg = PipelineConfig.create_async_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_load_res_warps * 32,
        ),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_store_warps * 32,
        ),
        cta_layout_vmnk=(1, 1, 1, 1),
    )
    return SmemResResource(
        gRes=gRes,
        is_tma=False,
        pipeline_config=cfg,
        name="smem_res",
    )


@cute.jit
def create_smem_res_tma(tma_desc_res: cutlass.Pointer) -> SmemResResource:
    """
    Build SmemRes with TmaAsync pipeline for TMA residual loads.
    """
    cfg = PipelineConfig.create_tma_async_pipeline_cfg(
        num_stages=acc_stages,
        num_bytes=bytes_res,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_store_warps,
        ),
        cta_layout_vmnk=(1, 1, 1, 1),
    )
    return SmemResResource(
        tma_desc_res=tma_desc_res,
        is_tma=True,
        pipeline_config=cfg,
        name="smem_res",
    )


@cute.jit
def create_resadd_sync(
    tmem_acc: TmemAccResource,
    smem_res: SmemResResource,
) -> PipelineGroup:
    """
    Merge group for epilogue: TMEM accumulator plus SMEM residual.
    """
    return PipelineGroup(
        name="resadd_sync",
        members=[tmem_acc, smem_res],
        mode=PipelineGroupMode.Merge,
    )


# ──────────────────────────────────────────────────────────────────────
# Kernel
# ──────────────────────────────────────────────────────────────────────


@cute.kernel
def kernel(
    mA_mk: cute.Tensor,
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mD_mn: cute.Tensor,
    mRes_mn: cute.Tensor,
    mnk: Tuple[int, int, int],
    use_tma_res: cutlass.Constexpr[bool],
    tma_res_desc: cutlass.GridConstant[cuda.TensorMap],
) -> None:
    """
    Device kernel: TMA GEMM with dual Merge groups and residual-add epilogue.
    """
    m, n, k = mnk
    num_epilogue_warps = num_store_warps
    num_k_tiles = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 5:
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    # Resource construction
    allocator = SmemAllocator()
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )

    gA = cutlass.make_array_view(mA_mk)
    gRes = cutlass.make_array_view(mRes_mn)

    gmem_a = GmemAResource(name="gmem_a")
    gmem_b = GmemBResource(name="gmem_b")
    gmem_res = GmemResResource(name="gmem_res")
    smem_a = create_smem_a(tma_a_desc.get_ptr())
    smem_b = create_smem_b(tma_b_desc.get_ptr())
    # Merge SmemA and SmemB for the MMA mainloop consumer
    ab_sync = create_ab_sync(smem_a, smem_b)

    tmem_acc = create_tmem_acc(num_epilogue_warps)

    if cutlass.const_expr(use_tma_res):
        smem_res = create_smem_res_tma(tma_res_desc.get_ptr())
    else:
        smem_res = create_smem_res_gmem(gRes)

    # Merge TmemAcc and SmemRes for the epilogue consumer
    resadd_sync = create_resadd_sync(tmem_acc, smem_res)

    gmem_d = GmemDResource(mD_mn=mD_mn, n_dim=n, name="gmem_d")

    allocator.add_resource(smem_a)
    allocator.add_resource(smem_b)
    allocator.add_resource(smem_res)
    # Do not forget to add each pipeline group to the allocator
    allocator.add_pipeline_group(ab_sync)
    allocator.add_pipeline_group(resadd_sync)

    # Task schedule construction
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
    load_a_result = load_a_schedule(gmem_a, ab_sync.smem_a)

    load_a_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_a],
        dst_resources=[smem_a],
        warp_idx=4,
        num_warps=num_load_a_warps,
        schedule=load_a_result,
        num_registers=40,
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

    # Pass grouped resource ab_sync.smem_b to the schedule
    load_b_result = load_b_schedule(gmem_b, ab_sync.smem_b)

    load_b_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_b],
        dst_resources=[smem_b],
        warp_idx=5,
        num_warps=num_load_b_warps,
        schedule=load_b_result,
        num_registers=40,
        name="LoadB",
        debug_print=debug_print,
    )

    @schedule
    def load_res_schedule(gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        with domain_loop(0, num_k_tiles, 1):
            pass
        coord_m, coord_n = gmem.compute_coords()
        smem.try_acquire()
        smem.acquire()
        smem.load(coord_m=coord_m, coord_n=coord_n)
        smem.commit()

    # Pass grouped resource resadd_sync.smem_res to the schedule
    load_res_result = load_res_schedule(gmem_res, resadd_sync.smem_res)

    load_res_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[gmem_res],
        dst_resources=[smem_res],
        warp_idx=7,
        num_warps=num_load_res_warps,
        schedule=load_res_result,
        num_registers=40,
        name="LoadRes",
        debug_print=debug_print,
    )

    @schedule
    def mma_schedule(
        smem_a_ref: MemoryResource,
        smem_b_ref: MemoryResource,
        tmem_ref: MemoryResource,
        ab_group: MemoryResource,
    ) -> None:
        smem_a_ref.init_descriptor_state()
        smem_b_ref.init_descriptor_state()
        tmem_ref.init_mma_state()
        tmem_ref.try_acquire()
        tmem_ref.acquire()
        with domain_loop(0, num_k_tiles, 1):
            # Call waits on both shared SMEM resources and then works on both members.
            smem_a_ref.try_wait()
            smem_a_ref.wait()
            smem_b_ref.try_wait()
            smem_b_ref.wait()
            desc_a_base = smem_a_ref.build_descriptor()
            desc_b_base = smem_b_ref.build_descriptor()
            tmem_ref.mma(desc_a_base=desc_a_base, desc_b_base=desc_b_base)
            # Release the ab_sync pipeline group, not the individual members
            ab_group.release()
        tmem_ref.commit()

    # Pass grouped resources for ab_sync (MMA also writes resadd_sync.tmem_acc)
    mma_result = mma_schedule(
        ab_sync.smem_a,
        ab_sync.smem_b,
        resadd_sync.tmem_acc,
        ab_sync,
    )

    mma_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[smem_a, smem_b],
        dst_resources=[tmem_acc],
        warp_idx=6,
        num_warps=num_mma_warps,
        schedule=mma_result,
        num_registers=40,
        name="MmaTask",
        debug_print=debug_print,
    )

    @schedule
    def store_schedule(
        tmem_ref: MemoryResource,
        smem_res_ref: MemoryResource,
        gmem: MemoryResource,
        resadd_group: MemoryResource,
    ) -> None:
        tmem_ref.init_store_state()
        smem_res_ref.init_store_state()
        with domain_loop(0, num_k_tiles, 1):
            pass
        tmem_ref.try_wait()
        tmem_ref.wait()
        smem_res_ref.try_wait()
        smem_res_ref.wait()
        t2r_rmem = tmem_ref.load_acc()
        res_rmem = smem_res_ref.read_residual()
        gmem.store(t2r_rmem=t2r_rmem, res_rmem=res_rmem)
        # Release the resadd_sync pipeline group, not the individual members
        resadd_group.release()

    # Pass grouped resources for resadd_sync to the schedule
    store_result = store_schedule(
        resadd_sync.tmem_acc,
        resadd_sync.smem_res,
        gmem_d,
        resadd_sync,
    )

    store_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[tmem_acc, smem_res],
        dst_resources=[gmem_d],
        warp_idx=0,
        num_warps=num_store_warps,
        schedule=store_result,
        num_registers=160,
        name="StoreTask",
        debug_print=debug_print,
    )

    # TaskManager construction and execution
    # PipelineGroup is not a resource, it does not participate in the dependency graph
    resource_dependency_graph = {
        smem_a: [gmem_a],
        smem_b: [gmem_b],
        smem_res: [gmem_res],
        tmem_acc: [smem_a, smem_b],
        gmem_d: [tmem_acc, smem_res],
    }

    allocator.compute_layout()

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_acc)
    tmem_allocator.compute_layout()

    task_manager = TaskManager(
        tasks=[load_a_task, load_b_task, load_res_task, mma_task, store_task],
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
    tmem_bar_threads = (num_store_warps + num_mma_warps) * 32

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols)
        prims.tcgen05_relinquish_alloc_permit()

    if store_task.is_selected() or mma_task.is_selected():
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    tmem_raw_addr = cutlass.Int32(0)
    if store_task.is_selected() or mma_task.is_selected():
        tmem_raw_addr = tmem_ptr_i32.load()

    tmem_ptr = prims.make_tmem_ptr(tmem_raw_addr, acc_dtype)

    task_manager.run()

    # Sync epilogue warps to ensure all T2R loads complete before TMEM dealloc
    dealloc_bar_id = 3
    dealloc_bar_threads = num_store_warps * 32
    if store_task.is_selected():
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
    d: cute.Tensor,
    res: cute.Tensor,
    mnk: Tuple[int, int, int],
    use_tma_res: cutlass.Constexpr[bool],
) -> None:
    """
    Build TMA descriptors and launch the GEMM + residual-add kernel.
    """
    m, n, k = mnk

    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(mma_tiler_mnk[0], tma_k_box),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk[1], tma_k_box),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )

    if cutlass.const_expr(use_tma_res):
        tma_res_desc = cuda.create_tensor_map_tiled_from_view(
            res,
            box_dims=(mma_tiler_mnk[0], mma_tiler_mnk[1]),
            swizzle=cuda.TensorMapSwizzle.none,
            stride_order=(1, 0),
        )
    else:
        tma_res_desc = tma_a_desc

    m_tiles = m // mma_tiler_mnk[0]
    n_tiles = n // mma_tiler_mnk[1]
    grid = (m_tiles, n_tiles, 1)
    block = (total_warps * cute.arch.WARP_SIZE, 1, 1)

    kernel(a, tma_a_desc, tma_b_desc, d, res, mnk, use_tma_res, tma_res_desc).launch(
        grid=grid,
        block=block,
    )


# ──────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────


@lru_cache(maxsize=4)
def _prepare(m: int, n: int, k: int, use_tma_res: bool):
    """
    Allocate tensors and compile host_function for the given problem size.
    """
    import torch
    import cutlass.torch as cutlass_torch

    def make_tensor(rows, cols, dtype):
        return (
            torch.empty(rows, cols, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=cutlass_torch.dtype(dtype))
        )

    a = make_tensor(m, k, io_dtype)
    b = make_tensor(n, k, io_dtype)
    res = make_tensor(m, n, io_dtype)
    d = make_tensor(m, n, io_dtype)

    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    d_ = from_dlpack(d).mark_layout_dynamic()
    res_ = from_dlpack(res).mark_layout_dynamic()

    mnk = (m, n, k)
    compiled_fn = cute.compile[cute.GenerateLineInfo(True)](
        host_function,
        a_,
        b_,
        d_,
        res_,
        mnk,
        use_tma_res,
    )
    return compiled_fn, (a, b, d, res, a_, b_, d_, res_, mnk)


def run(
    mnk: Tuple[int, int, int] = (256, 256, 256),
    residual_load_mode: str = "gmem",
    tolerance: float = 1e-01,
) -> None:
    """Run the GEMM + residual-add kernel.

    Args:
        mnk: M, N, K dimensions.
        residual_load_mode: "gmem" for global memory load with AsyncAsync pipeline,
            "tma" for TmaAsync.
        tolerance: Tolerance for validation.
    """
    import torch
    import cutlass.torch as cutlass_torch

    m, n, k = mnk
    use_tma_res = residual_load_mode == "tma"

    torch.manual_seed(1111)

    compiled_fn, (a, b, d, res, a_, b_, d_, res_, mnk_t) = _prepare(
        m,
        n,
        k,
        use_tma_res,
    )
    compiled_fn(a_, b_, d_, res_, mnk_t)
    torch.cuda.synchronize()

    ref = torch.einsum("mk,nk->mn", a.to(torch.float32), b.to(torch.float32))
    d_ref = (ref + res.to(torch.float32)).to(cutlass_torch.dtype(io_dtype))

    torch.testing.assert_close(d, d_ref, atol=tolerance, rtol=1e-05)


if __name__ == "__main__":
    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)

    parser = argparse.ArgumentParser(description="GEMM + residual-add kernel")
    parser.add_argument("--mnk", type=str, default="256,256,256")
    parser.add_argument("--mode", choices=["gmem", "tma"], default="gmem")
    parser.add_argument("--tolerance", type=float, default=1e-01)
    args = parser.parse_args()

    mnk = tuple(int(x) for x in args.mnk.split(","))
    run(mnk=mnk, residual_load_mode=args.mode, tolerance=args.tolerance)
    print("PASS")
