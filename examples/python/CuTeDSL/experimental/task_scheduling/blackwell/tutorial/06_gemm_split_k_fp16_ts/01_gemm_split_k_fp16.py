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
Split-K FP16 GEMM with DSMEM reduce-scatter using TS.

Each CTA in a cluster of `split_k_factor` CTAs computes a partial GEMM
over its K-slice using 1-CTA MMA.  After the MMA loop, CTAs exchange
partial results via stores to mapped DSMEM addresses (st.shared::cluster).
Each CTA scatters N/split_k_factor columns of its partial result to each
peer.  After a cluster-wide sync, each CTA holds `split_k_factor` partial
tiles of size [M_tile, N_slice], reduces them, and writes the final result
to GMEM.

Resources
---------
    GmemAbResource --> SmemAbResource --> TmemCResource --> GmemDResource
                                                  |
                                           (staging SMEM)
                                                  |
                                        [post-TS DSMEM scatter]
                                                  |
                                        [cluster sync + reduce]
                                                  |
                                             GMEM store

  - GmemAbResource : Coordinate computation with split-K offset.
  - SmemAbResource : TMA loads into staged SMEM buffers (1-CTA pipeline).
  - TmemCResource  : 1-CTA MMA accumulator.
  - GmemDResource  : TMEM->SMEM staging, DSMEM scatter, reduce, GMEM store.

Tasks
-----
  - LoadTask  (warp 4)  : TMA copy from global to shared memory.
  - MmaTask   (warp 5)  : 1-CTA tcgen05 MMA computation.
  - StoreTask (warps 0-3): TMEM->SMEM staging + DSMEM scatter + reduce + GMEM store.
  - PaddingTask (warps 6-7): Warp-group register alignment.

TS verification note
-----------------------
TS can verify cross-CTA handoff only through TS-managed pipelines (e.g. cluster
TMA multicast in tutorial 04). The DSMEM scatter, remote mbarrier arrives, and
reduce in GmemDResource.store are user code inside producer work — not an TS
pipeline — so a missing arrive/wait can deadlock or race without an TS error.
"""

import argparse
from typing import Tuple, Type, Callable, Any
from functools import partial, lru_cache
from dataclasses import dataclass, field

import cutlass
import cutlass.experimental.cuda as cuda
from cutlass import Numeric
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

from cutlass.experimental.task_scheduling.memory import (
    SmemAllocation,
    TmemAllocation,
    SmemAllocator,
    TmemAllocator,
)
from cutlass.experimental.task_scheduling.resources import (
    WorkAttr,
    MemoryResource,
    StageInfo,
    TaskLocalVariable,
    PipelineConfig,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import domain_loop, schedule
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

# ──────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────

io_dtype = cutlass.Float16
acc_dtype = cutlass.Float32

split_k_factor = 2
cluster_shape = (1, 1, split_k_factor)

# 1-CTA MMA tile
mma_inst_shape_mnk = (128, 16, 16)
mma_tiler_mnk = (128, 16, 64)

tma_k_box = min(mma_tiler_mnk[2], 128 // (io_dtype.width // 8))
tma_copy_iters = mma_tiler_mnk[2] // tma_k_box

n_slice = mma_tiler_mnk[1] // split_k_factor
t2r_inst_repx = min(32, mma_tiler_mnk[1])
subtile_cnt = mma_tiler_mnk[1] // t2r_inst_repx
peers_per_subtile = t2r_inst_repx // n_slice

ab_stages = 8
acc_stages = 1

threads_in_epilogue = 128

debug_print = False

dsmem_chunk_elems = mma_tiler_mnk[0] * n_slice

_epilogue_elems = split_k_factor * dsmem_chunk_elems
_smem_a_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages
_smem_b_elems = mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages
assert _smem_a_elems >= _epilogue_elems, (
    f"smem_a ({_smem_a_elems} elems) too small to reuse as epilogue staging "
    f"({_epilogue_elems} elems) — increase ab_stages or K tile"
)
assert _smem_b_elems >= _epilogue_elems, (
    f"smem_b ({_smem_b_elems} elems) too small to reuse as epilogue recv "
    f"({_epilogue_elems} elems) — increase ab_stages or K tile"
)

# ──────────────────────────────────────────────────────────────────────
# Resource definitions
# ──────────────────────────────────────────────────────────────────────


@dataclass
class GmemAbResource(MemoryResource):
    """Coordinate computation for TMA loads, incorporating split-K offset.

    Each CTA's K-range is determined by its cluster rank:
      k_start = cta_rank * num_k_tiles_per_cta * k_tile
    """

    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    cta_rank_in_cluster: Any = field(init=False, default=None)
    tile_m_idx: Any = field(init=False, default=None)
    tile_n_idx: Any = field(init=False, default=None)

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.coord_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="K coordinate for the current split-K TMA load tile.",
        )
        self.coord_m = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="M coordinate for the current split-K TMA load tile.",
        )
        self.coord_n = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="N coordinate for the current split-K TMA load tile.",
        )
        self.cta_rank_in_cluster = cutlass.Int32(0)
        self.tile_m_idx = cutlass.Int32(0)
        self.tile_n_idx = cutlass.Int32(0)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        """
        Bind block/cluster tile indices for split-K coordinate computation.
        """
        del stage_info
        bx, by, _ = cute.arch.block_idx()
        self.tile_m_idx = bx
        self.tile_n_idx = by
        self.cta_rank_in_cluster = prims.cluster_ctarank()

    @consumer_work(returns=(coord_k, coord_m, coord_n))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        """
        Compute TMA (K,M,N) coords with split-K offset from cluster rank.
        """
        num_k_tiles_per_cta = stage_info.loop_end - stage_info.loop_start
        k_offset = (
            self.cta_rank_in_cluster * num_k_tiles_per_cta + stage_info.loop_offset
        )
        coord_k = k_offset * mma_tiler_mnk[2]
        coord_m = self.tile_m_idx * mma_tiler_mnk[0]
        coord_n = self.tile_n_idx * mma_tiler_mnk[1]

        return coord_k, coord_m, coord_n


@dataclass
class SmemAbResource(MemoryResource):
    """
    Staged SMEM buffers for A and B, filled by TMA, consumed by 1-CTA MMA.
    """

    tma_desc_a: Any = field(init=False, default=None)
    tma_desc_b: Any = field(init=False, default=None)
    shared_smem_a: Any = field(init=False, default=None)
    shared_smem_b: Any = field(init=False, default=None)
    sA_copy_elems: Any = field(init=False, default=None)
    sB_copy_elems: Any = field(init=False, default=None)
    desc_a_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    desc_b_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    _alloc_a: cutlass.Constexpr = field(init=False, default=None)
    _alloc_b: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        tma_desc_a: cutlass.Pointer,
        tma_desc_b: cutlass.Pointer,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
        self.tma_desc_b = tma_desc_b
        self.sA_copy_elems = cutlass.Int32(mma_tiler_mnk[0] * mma_tiler_mnk[2])
        self.sB_copy_elems = cutlass.Int32(mma_tiler_mnk[1] * mma_tiler_mnk[2])
        self.desc_a_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SMEM descriptor base for operand A.",
        )
        self.desc_b_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SMEM descriptor base for operand B.",
        )
        elem_size = io_dtype.width // 8
        self._alloc_a = SmemAllocation(
            "smem_a",
            mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages * elem_size,
        )
        self._alloc_b = SmemAllocation(
            "smem_b",
            mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages * elem_size,
        )
        nullptr = cutlass.inttoptr(0, mem_space=3, dtype=io_dtype)
        self.shared_smem_a = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages,),
            addrspace=3,
        )
        self.shared_smem_b = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages,),
            addrspace=3,
        )

    def get_smem_requirements(self):
        return [self._alloc_a, self._alloc_b]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        sA_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2] * ab_stages
        sB_elems = mma_tiler_mnk[1] * mma_tiler_mnk[2] * ab_stages
        self.shared_smem_a = cutlass.Array(
            smem_base.data_ptr() + self._alloc_a.offset,
            dtype=io_dtype,
            shape=(sA_elems,),
            addrspace=3,
        )
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
    def init_descriptors(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=(desc_a_base, desc_b_base))
    @cute.jit
    def build_descriptors(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int64, cutlass.Int64]:
        sA_curr = self.shared_smem_a.subview(self.sA_copy_elems * stage_info.stage_idx)
        sB_curr = self.shared_smem_b.subview(self.sB_copy_elems * stage_info.stage_idx)

        desc_a_base = prims.Tcgen05SmemDesc.build(
            sA_curr,
            leading_byte_offset=16,
            stride_byte_offset=8 * tma_k_box * (io_dtype.width // 8),
            layout=2,
        )
        desc_b_base = prims.Tcgen05SmemDesc.build(
            sB_curr,
            leading_byte_offset=16,
            stride_byte_offset=8 * tma_k_box * (io_dtype.width // 8),
            layout=2,
        )
        return desc_a_base, desc_b_base

    @producer_work
    @cute.jit
    def tma_load(
        self,
        stage_info: StageInfo,
        *,
        coord_k: cutlass.Int32,
        coord_m: cutlass.Int32,
        coord_n: cutlass.Int32,
    ) -> None:
        if prims.elect_sync():
            sA_curr = self.shared_smem_a.subview(
                self.sA_copy_elems * stage_info.stage_idx
            )
            sB_curr = self.shared_smem_b.subview(
                self.sB_copy_elems * stage_info.stage_idx
            )

            tma_a_box_elems = mma_tiler_mnk[0] * tma_k_box
            tma_b_box_elems = mma_tiler_mnk[1] * tma_k_box

            for ki in cutlass.range_constexpr(tma_copy_iters):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sA_curr.subview(tma_a_box_elems * ki),
                    self.tma_desc_a,
                    (coord_k + tma_k_box * ki, coord_m),
                    stage_info.barrier,
                )
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sB_curr.subview(tma_b_box_elems * ki),
                    self.tma_desc_b,
                    (coord_k + tma_k_box * ki, coord_n),
                    stage_info.barrier,
                )


@dataclass
class TmemCResource(MemoryResource):
    """
    TMEM accumulator written by 1-CTA MMA, read by epilogue warps.
    """

    t2r_inst_shape: cutlass.Constexpr[int] = field(init=False, default=None)
    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    scale_d: Any = field(init=False, default=None)
    idesc: Any = field(init=False, default=None)
    tmem_raw_addr: Any = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_shape = "32x32b"
        self.t2r_inst_repx = t2r_inst_repx
        self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * acc_stages)
        self.t2r_rmem = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.full([self.t2r_inst_repx], 0.0, cutlass.Float32),
            docs="Register-memory subtile loaded from TMEM for the epilogue.",
        )
        self.idesc = cutlass.Int32(0)
        self.tmem_raw_addr = cutlass.Int32(0)
        self.scale_d = cutlass.Boolean(False)

    def get_tmem_requirements(self):
        return [self._alloc_acc]

    @cute.jit
    def _init_tmem_state(self, stage_info: StageInfo) -> None:
        self.idesc = prims.Tcgen05InstrDesc.build(
            a_dtype=cutlass.Float16,  # Float16
            b_dtype=cutlass.Float16,  # Float16
            c_dtype=cutlass.Float32,
            n_dim=mma_inst_shape_mnk[1],
            m_dim=mma_inst_shape_mnk[0],
        )
        self.tmem_raw_addr = stage_info.context.tmem_ptr_i32.load()
        self.scale_d = cutlass.Boolean(False)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_accumulator_state(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_work_tile_state(self, stage_info: StageInfo) -> None:
        del stage_info
        self.scale_d = cutlass.Boolean(False)

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_subtile(
        self, stage_info: StageInfo, *, subtile_idx: cutlass.Constexpr[int]
    ) -> cutlass.Float32:
        warp_idx = cute.arch.warp_idx()
        base_col_id = (
            (self.tmem_raw_addr & 0xFFFF)
            + stage_info.stage_idx * mma_tiler_mnk[1]
            + subtile_idx * self.t2r_inst_repx
        )
        tmem_ptr = prims.make_tmem_ptr_from_warp_row_col(
            self.tmem_raw_addr, warp_idx, base_col_id, cutlass.Float32
        )
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
class GmemDResource(MemoryResource):
    """DSMEM reduce-scatter epilogue resource.

    Cross-CTA sync here is not a TS-managed pipeline (contrast cluster TMA in
    tutorial 04); scatter/sync/reduce ordering and mbarrier counts are manual
    inside producer_work below.

    producer_work is called subtile_cnt + 1 times (subtile_idx 0 .. subtile_cnt):

      subtile_idx 0 .. subtile_cnt-1
          Stage one 32-column TMEM subtile from FP32 RMEM to FP16 SMEM.
          smem_staging[subtile_idx * chunk] receives the partial for peer subtile_idx.

      subtile_idx == subtile_cnt
          1. DSMEM scatter — each thread stores its rows of each peer's
             partial to the peer's smem_recv via prims.mapa.
          2. Sync — named barrier among epilogue warps, then mbarrier_arrive
             to remote CTAs + mbarrier_try_wait on own CTA.
          3. Reduce — sum split_k_factor partials (own from smem_staging,
             remote peers' from smem_recv).
          4. GMEM store — write the reduced [M_tile, n_slice] tile.
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    smem_staging: Any = field(init=False, default=None)
    smem_recv: Any = field(init=False, default=None)
    dsmem_sync_mbar: Any = field(init=False, default=None)
    _dsmem_sync_mbar_alloc: cutlass.Constexpr = field(init=False, default=None)
    mC_mn: Any = field(init=False, default=None)
    gC: Any = field(init=False, default=None)
    n_dim: Any = field(init=False, default=None)
    _alloc_staging: cutlass.Constexpr = field(init=False, default=None)
    _alloc_recv: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        dsmem_sync_mbar_alloc: SmemAllocation,
        mC_mn: cutlass.Array,
        n_dim: int,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_repx = t2r_inst_repx
        self._dsmem_sync_mbar_alloc = dsmem_sync_mbar_alloc
        self.mC_mn = mC_mn
        self.gC = mC_mn
        self.n_dim = n_dim
        elem_size = io_dtype.width // 8
        self._alloc_staging = SmemAllocation(
            "smem_staging",
            split_k_factor * dsmem_chunk_elems * elem_size,
        )
        self._alloc_recv = SmemAllocation(
            "smem_recv",
            split_k_factor * dsmem_chunk_elems * elem_size,
        )
        nullptr = cutlass.inttoptr(0, mem_space=3, dtype=io_dtype)
        self.smem_staging = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(split_k_factor * dsmem_chunk_elems,),
            addrspace=3,
        )
        self.smem_recv = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(split_k_factor * dsmem_chunk_elems,),
            addrspace=3,
        )
        self.dsmem_sync_mbar = cutlass.Array(
            nullptr,
            dtype=cutlass.Int64,
            shape=(1,),
            addrspace=3,
        )

    def get_smem_requirements(self):
        return [self._alloc_staging, self._alloc_recv]

    @cute.jit
    def _init_store_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        staging_elems = split_k_factor * dsmem_chunk_elems
        recv_elems = split_k_factor * dsmem_chunk_elems
        self.smem_staging = cutlass.Array(
            smem_base.data_ptr() + self._alloc_staging.offset,
            dtype=io_dtype,
            shape=(staging_elems,),
            addrspace=3,
        )
        self.smem_recv = cutlass.Array(
            smem_base.data_ptr() + self._alloc_recv.offset,
            dtype=io_dtype,
            shape=(recv_elems,),
            addrspace=3,
        )
        self.dsmem_sync_mbar = cutlass.Array(
            smem_base.data_ptr() + self._dsmem_sync_mbar_alloc.offset,
            dtype=cutlass.Int64,
            shape=(1,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_store_state(stage_info)

    @producer_work
    @cute.jit
    def store(
        self,
        stage_info: StageInfo,
        *,
        t2r_rmem: cutlass.Float32,
        subtile_idx: cutlass.Constexpr[int],
    ) -> None:
        tx, _, _ = cute.arch.thread_idx()

        if subtile_idx < subtile_cnt:
            # ── Stage + scatter: wide TMEM load → multi-peer SMEM + DSMEM copy ──
            # Scatter t2r_inst_repx columns across peers_per_subtile peers.
            # j // n_slice = peer offset within subtile (compile-time)
            # j % n_slice  = column within that peer's chunk (compile-time)
            for j in cutlass.range_constexpr(self.t2r_inst_repx):
                local_peer_offset = j // n_slice
                col_in_peer = j % n_slice
                peer = subtile_idx * peers_per_subtile + local_peer_offset
                base = self.smem_staging.subview(
                    (peer * dsmem_chunk_elems + tx * n_slice + col_in_peer)
                )
                fp16_val = t2r_rmem[j].to(cutlass.Float16)
                base.store(fp16_val)

            # Make the writes from the generic proxy (st.shared) visible to the
            # async proxy before the async copy (cp.async.bulk).
            cute.arch.fence_view_async_shared()

            dsmem_scatter_bar_id = 3
            prims.barrier_cta_sync(
                dsmem_scatter_bar_id, thread_count=threads_in_epilogue
            )

            # Issue bulk async copies + arrives for peers in this subtile.
            # peer // peers_per_subtile gives the subtile that owns each peer;
            # both it and subtile_idx are compile-time, so this comparison folds.
            cta_rank = prims.cluster_ctarank()
            if prims.elect_sync():
                for peer in cutlass.range_constexpr(split_k_factor):
                    if peer != cta_rank:
                        peer_subtile = peer // peers_per_subtile
                        if peer_subtile == subtile_idx:
                            src = self.smem_staging.subview(peer * dsmem_chunk_elems)
                            dst = prims.mapa(
                                self.smem_recv.subview(cta_rank * dsmem_chunk_elems),
                                peer,
                            )
                            mbar = prims.mapa(
                                self.dsmem_sync_mbar,
                                peer,
                            )
                            prims.cp_async_bulk_shared_cluster_shared_cta(
                                dst,
                                src,
                                mbar,
                                dsmem_chunk_elems * 2,
                            )

            if prims.elect_sync():
                for peer in cutlass.range_constexpr(split_k_factor):
                    if peer != cta_rank:
                        peer_subtile = peer // peers_per_subtile
                        if peer_subtile == subtile_idx:
                            remote_mbar = prims.mapa(
                                self.dsmem_sync_mbar,
                                peer,
                            )
                            prims.mbarrier_arrive(
                                remote_mbar,
                                scope=prims.MemScope.CLUSTER,
                            )
        else:
            # ── Final: wait for all DSMEM copies, reduce, store to GMEM ──
            cta_rank = prims.cluster_ctarank()
            while not prims.mbarrier_try_wait_parity(self.dsmem_sync_mbar, 0):
                pass

            bx, by, _ = cute.arch.block_idx()
            coordc_m = bx * mma_tiler_mnk[0]
            coordc_n = by * mma_tiler_mnk[1] + cta_rank * n_slice
            row = coordc_m + tx

            reduced = cutlass.Array(
                cutlass.Float16,
                n_slice,
                alignment=min(16, n_slice * 2),
            )
            for col in cutlass.range_constexpr(n_slice):
                acc = cutlass.Float32(0.0)
                for peer in cutlass.range_constexpr(split_k_factor):
                    val = cutlass.Float16(0.0)
                    if peer == cta_rank:
                        val = (
                            self.smem_staging.subview(
                                peer * dsmem_chunk_elems + tx * n_slice + col
                            )
                        ).load()
                    else:
                        val = (
                            self.smem_recv.subview(
                                peer * dsmem_chunk_elems + tx * n_slice + col
                            )
                        ).load()
                    acc = acc + val.to(cutlass.Float32)
                reduced[col] = acc.to(cutlass.Float16)

            store_vec = min(8, n_slice)
            for j in cutlass.range_constexpr(n_slice // store_vec):
                vec_f16 = reduced.load(j * store_vec, store_vec)
                linear_idx = row * self.n_dim + coordc_n + j * store_vec
                self.gC.store(
                    vec_f16,
                    idx=linear_idx,
                    vector_size=store_vec,
                    alignment=min(16, store_vec * 2),
                )


# ──────────────────────────────────────────────────────────────────────
# Resource construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_gmem_ab_resource() -> GmemAbResource:
    """
    Build the GMEM coordinate resource (split-K K offset from cluster rank).
    """
    return GmemAbResource(name="GmemAb")


@cute.jit
def create_smem_ab_resource(
    tma_a_desc: cutlass.Pointer,
    tma_b_desc: cutlass.Pointer,
) -> SmemAbResource:
    """
    Build staged SMEM A/B with a TMA->UMMA pipeline config.
    """
    sA_copy_bytes = mma_tiler_mnk[0] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    sB_copy_bytes = mma_tiler_mnk[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    num_tma_copy_bytes = sA_copy_bytes + sB_copy_bytes

    cta_layout_vmnk = (1, 1, 1, 1)
    smem_ab_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=num_tma_copy_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return SmemAbResource(
        tma_desc_a=tma_a_desc,
        tma_desc_b=tma_b_desc,
        pipeline_config=smem_ab_pipeline_config,
        name="SmemAb",
    )


@cute.jit
def create_tmem_c_resource(num_epilogue_warps: int) -> TmemCResource:
    """
    Build TMEM accumulator resource; consumer group spans all epilogue warps.
    """
    cta_layout_vmnk = (1, 1, 1, 1)
    tmem_c_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread, size=num_epilogue_warps * 32
    )
    tmem_c_pipeline_config = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=tmem_c_pipeline_consumer_group,
        cta_layout_vmnk=cta_layout_vmnk,
    )
    return TmemCResource(
        pipeline_config=tmem_c_pipeline_config,
        name="TmemC",
    )


@cute.jit
def create_gmem_d_resource(
    dsmem_sync_mbar_alloc: SmemAllocation,
    mC_mn: cutlass.Array,
    n_dim: int,
) -> GmemDResource:
    """
    Build epilogue resource: staging/recv SMEM plus output tensor view.
    """
    return GmemDResource(
        dsmem_sync_mbar_alloc=dsmem_sync_mbar_alloc,
        mC_mn=mC_mn,
        n_dim=n_dim,
        name="GmemD",
    )


# ──────────────────────────────────────────────────────────────────────
# Task schedule construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_load_task(
    gmem_ab_resource: GmemAbResource,
    smem_ab_resource: SmemAbResource,
    num_k_tiles_per_cta: int,
    num_load_warps: int,
) -> Task:
    """
    Warp 4: K-loop TMA loads A+B into pipelined SMEM stages.
    """

    @schedule
    def load_schedule(gmem_ab: MemoryResource, smem_ab: MemoryResource) -> None:
        smem_ab.init_load_state()
        gmem_ab.init_tile_coords()
        with domain_loop(0, num_k_tiles_per_cta, 1):
            coord_k, coord_m, coord_n = gmem_ab.compute_coords()
            smem_ab.try_acquire()
            smem_ab.acquire()
            smem_ab.tma_load(coord_k=coord_k, coord_m=coord_m, coord_n=coord_n)
            smem_ab.commit()

    result = load_schedule(gmem_ab_resource, smem_ab_resource)
    return Task(
        src_resources=[gmem_ab_resource],
        dst_resources=[smem_ab_resource],
        warp_idx=4,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadTask",
        debug_print=debug_print,
    )


@cute.jit
def create_mma_task(
    smem_ab_resource: SmemAbResource,
    tmem_c_resource: TmemCResource,
    num_k_tiles_per_cta: int,
    num_mma_warps: int,
) -> Task:
    """
    Warp 5: wait SMEM, build tcgen05 descriptors, accumulate into TMEM.
    """

    @schedule
    def mma_schedule(smem_ab: MemoryResource, tmem_c: MemoryResource) -> None:
        smem_ab.init_descriptors()
        tmem_c.init_accumulator_state()
        tmem_c.init_work_tile_state()
        tmem_c.try_acquire()
        tmem_c.acquire()
        with domain_loop(0, num_k_tiles_per_cta, 1):
            smem_ab.try_wait()
            smem_ab.wait()
            desc_a_base, desc_b_base = smem_ab.build_descriptors()
            tmem_c.mma(desc_a_base=desc_a_base, desc_b_base=desc_b_base)
            smem_ab.release()
        tmem_c.commit()

    result = mma_schedule(smem_ab_resource, tmem_c_resource)
    return Task(
        src_resources=[smem_ab_resource],
        dst_resources=[tmem_c_resource],
        warp_idx=5,
        num_warps=num_mma_warps,
        schedule=result,
        num_registers=40,
        name="MmaTask",
        debug_print=debug_print,
    )


@cute.jit
def create_store_task(
    tmem_c_resource: TmemCResource,
    gmem_d_resource: GmemDResource,
    num_k_tiles_per_cta: int,
    num_epilogue_warps: int,
) -> Task:
    """
    Warps 0-3: T2R subtiles then multi-call DSMEM reduce-scatter epilogue.
    """

    @schedule
    def store_schedule(tmem_c: MemoryResource, gmem_d: MemoryResource) -> None:
        tmem_c.init_store_state()
        gmem_d.init_store_state()
        with domain_loop(0, num_k_tiles_per_cta, 1):
            pass
        tmem_c.try_wait()
        tmem_c.wait()
        for subtile_idx in cutlass.range_constexpr(subtile_cnt):
            t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
            gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
        # Extra store call performs DSMEM scatter, reduce, and GMEM store.
        gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_cnt)
        tmem_c.release()

    result = store_schedule(tmem_c_resource, gmem_d_resource)
    return Task(
        src_resources=[tmem_c_resource],
        dst_resources=[gmem_d_resource],
        warp_idx=0,
        num_warps=num_epilogue_warps,
        schedule=result,
        num_registers=160,
        name="StoreTask",
        debug_print=debug_print,
    )


@cute.jit
def create_padding_task(
    num_padding_warps: int,
    total_num_warps_so_far: int,
    num_k_tiles_per_cta: int,
) -> Task:
    """
    Padding warps: empty K-loop body for warp-group register alignment.
    """

    @schedule
    def padding_schedule() -> None:
        with domain_loop(0, num_k_tiles_per_cta, 1):
            pass

    result = padding_schedule()
    return Task(
        src_resources=[],
        dst_resources=[],
        warp_idx=total_num_warps_so_far,
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
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mC_mn: cutlass.Array,
    mnk: Tuple[int, int, int],
) -> None:
    """
    Device entry: allocate resources, init DSMEM sync, run TaskManager, free TMEM.
    """
    m, n, k = mnk

    num_epilogue_warps = 4
    num_mma_warps = 1
    num_load_warps = 1

    num_k_tiles_total = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]
    num_k_tiles_per_cta = num_k_tiles_total // split_k_factor

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 4:
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    # ── SMEM layout (data buffers + infrastructure slots) ──
    allocator = SmemAllocator()
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )
    dsmem_sync_mbar_alloc = allocator.add(
        SmemAllocation("dsmem_sync_mbar", dtype=cutlass.Int64, alignment=8)
    )

    ########################################################
    # Resource construction
    ########################################################

    gmem_ab_resource = create_gmem_ab_resource()
    smem_ab_resource = create_smem_ab_resource(
        tma_a_desc.get_ptr(), tma_b_desc.get_ptr()
    )
    tmem_c_resource = create_tmem_c_resource(num_epilogue_warps)
    gmem_d_resource = create_gmem_d_resource(dsmem_sync_mbar_alloc, mC_mn, n)

    allocator.add_resource(smem_ab_resource)
    allocator.add_resource(gmem_d_resource)
    # AB buffers are free once the mainloop completes — reuse for
    # epilogue staging (GmemDResource depends on TmemCResource).
    # We can't reuse it for recv unless we add a cluster-wide barrier
    # to ensure that the mainloop had completed in other CTAs.
    allocator.add_alias_group(
        [
            [smem_ab_resource._alloc_a, smem_ab_resource._alloc_b],
            [gmem_d_resource._alloc_staging],
        ]
    )

    total_num_warps = num_epilogue_warps + num_load_warps + num_mma_warps
    num_padding_warps = (total_num_warps + 3) // 4 * 4 - total_num_warps

    ########################################################
    # Task schedule construction
    ########################################################

    load_task = create_load_task(
        gmem_ab_resource,
        smem_ab_resource,
        num_k_tiles_per_cta,
        num_load_warps,
    )
    mma_task = create_mma_task(
        smem_ab_resource,
        tmem_c_resource,
        num_k_tiles_per_cta,
        num_mma_warps,
    )
    store_task = create_store_task(
        tmem_c_resource,
        gmem_d_resource,
        num_k_tiles_per_cta,
        num_epilogue_warps,
    )
    task_list = [load_task, mma_task, store_task]

    if cutlass.const_expr(num_padding_warps > 0):
        padding_task = create_padding_task(
            num_padding_warps,
            total_num_warps,
            num_k_tiles_per_cta,
        )
        task_list.append(padding_task)

    resource_dependency_graph = {
        smem_ab_resource: [gmem_ab_resource],
        tmem_c_resource: [smem_ab_resource],
        gmem_d_resource: [tmem_c_resource],
    }

    allocator.compute_layout()

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c_resource)
    tmem_allocator.compute_layout()

    ########################################################
    # TaskManager construction and execution
    ########################################################

    task_manager = TaskManager(
        tasks=task_list,
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )

    # ── Setup & sync ──
    task_manager.setup_resources_and_tasks()

    # Derive infrastructure pointers from the unified SMEM block.
    # tmem_ptr_i32 for ResourceContext is auto-populated by TaskManager
    # in setup_resources_and_tasks() via SmemAllocator.tmem_ptr_alloc.
    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)
    dsmem_sync_mbar = allocator.get(dsmem_sync_mbar_alloc)

    # Init DSMEM sync mbarrier.
    # elect_sync fires once per warp; with num_epilogue_warps warps in the
    # store task, each peer CTA sends num_epilogue_warps bulk copies and
    # num_epilogue_warps arrives.
    num_arrive_per_peer = num_epilogue_warps
    if warp_idx == 0:
        if prims.elect_sync():
            total_arrivals = (split_k_factor - 1) * num_arrive_per_peer
            prims.mbarrier_init(dsmem_sync_mbar, total_arrivals)
            expected_bytes = (
                (split_k_factor - 1) * num_arrive_per_peer * dsmem_chunk_elems * 2
            )
            prims.mbarrier_expect_tx(dsmem_sync_mbar, expected_bytes)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # ── TMEM allocation (1-CTA, no 2-CTA) ──
    # tcgen05.alloc granularity is 32 columns minimum for 1-CTA mode
    num_tmem_cols = max(32, mma_tiler_mnk[1] * acc_stages)
    tmem_allocator_warp_id = 0
    tmem_bar_id = 2
    tmem_bar_threads = (num_epilogue_warps + num_mma_warps) * 32

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols)
        prims.tcgen05_relinquish_alloc_permit()

    if store_task.is_selected() or mma_task.is_selected():
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    tmem_raw_addr = cutlass.Int32(0)
    if store_task.is_selected() or mma_task.is_selected():
        tmem_raw_addr = tmem_ptr_i32.load()

    tmem_ptr = prims.make_tmem_ptr(tmem_raw_addr, acc_dtype)

    # ── Run TS (K-loop, TMEM staging, DSMEM scatter+reduce all in tail) ──
    task_manager.run()

    # ── TMEM deallocation (1-CTA) ──
    # Note: the dsmem_scatter barrier protects T2R loads from TMEM dealloc.
    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols)


########################################################
# Host runners and CLI
########################################################


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cutlass.Array,
    mnk: Tuple[int, int, int],
) -> None:
    """
    Host JIT wrapper: build TMA descriptors and launch clustered split-K grid.
    """
    m, n, k = mnk

    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(mma_tiler_mnk[0], tma_k_box),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk[1], tma_k_box),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    m_tiles = m // mma_tiler_mnk[0]
    n_tiles = n // mma_tiler_mnk[1]
    grid_shape = (m_tiles, n_tiles, split_k_factor)

    block_size = cute.arch.WARP_SIZE * 8  # 4 epi + 1 mma + 1 load + 2 pad = 8 warps
    kernel(
        tma_a_desc,
        tma_b_desc,
        c,
        mnk,
    ).launch(
        grid=grid_shape,
        block=[block_size, 1, 1],
        cluster=cluster_shape,
    )


# ──────────────────────────────────────────────────────────────────────
# Test driver
# ──────────────────────────────────────────────────────────────────────


@lru_cache(maxsize=1)
def prepare_run(
    callable: Callable,
    m: int,
    n: int,
    k: int,
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
) -> tuple[Callable, tuple]:
    """
    Allocate random CUDA tensors, compile ``host_function``, return launch closure.
    """
    import torch
    import cutlass.torch as cutlass_torch

    def make_tensors(mn: int, k_dim: int, dtype: Type[Numeric]) -> "torch.Tensor":
        shape = (mn, k_dim)
        return (
            torch.empty(*shape, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=cutlass_torch.dtype(dtype))
        )

    a = make_tensors(m, k, a_dtype)
    b = make_tensors(n, k, b_dtype)
    c = make_tensors(m, n, c_dtype)
    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    c_ = from_dlpack(c).mark_layout_dynamic()

    mnk = (m, n, k)

    compiled_fn = cute.compile[cute.GenerateLineInfo(True)](
        callable,
        a_,
        b_,
        c_,
        mnk,
    )
    return partial(compiled_fn, a_, b_, c_, mnk), (a, b, c)


def run_splitk_gemm(
    mnk: Tuple[int, int, int],
    tolerance: float,
) -> None:
    """
    Run compiled kernel and compare against FP32 ``torch.einsum`` reference.
    """
    global torch, cutlass_torch
    import torch
    import cutlass.torch as cutlass_torch

    print("===================================================================")
    print("Running Blackwell Split-K FP16 GEMM with DSMEM reduce-scatter:")
    print(f"  mnk:            {mnk}")
    print(f"  split_k_factor: {split_k_factor}")
    print(f"  mma_tile:       {mma_tiler_mnk}")
    print(f"  n_slice:        {n_slice}")
    print(f"  tolerance:      {tolerance}")
    print("===================================================================")
    print()

    m, n, k = mnk
    torch.manual_seed(1111)

    run_fn, (a, b, c) = prepare_run(
        host_function, m, n, k, io_dtype, io_dtype, io_dtype
    )
    run_fn()

    torch.cuda.synchronize()

    ref = torch.einsum("mk,nk->mn", a.to(torch.float32), b.to(torch.float32))

    torch.testing.assert_close(
        c, ref.to(cutlass_torch.dtype(io_dtype)), atol=tolerance, rtol=1e-05
    )


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> list[int]:
        try:
            return [int(x.strip()) for x in s.split(",")]
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)
    err, device_count = cu_driver.cuDeviceGetCount()
    if err != cu_driver.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A GPU is required to run this example")

    parser = argparse.ArgumentParser(
        description="Blackwell Split-K FP16 GEMM with DSMEM reduce-scatter"
    )
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=(256, 256, 256),
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    args = parser.parse_args()
    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")

    m, n, k = args.mnk
    if m % mma_tiler_mnk[0] != 0:
        raise ValueError(f"m must be divisible by {mma_tiler_mnk[0]}")
    if n % mma_tiler_mnk[1] != 0:
        raise ValueError(f"n must be divisible by {mma_tiler_mnk[1]}")
    if k % (split_k_factor * mma_tiler_mnk[2]) != 0:
        divisor = split_k_factor * mma_tiler_mnk[2]
        raise ValueError(f"k must be divisible by split_k_factor * k_tile = {divisor}")

    run_splitk_gemm(args.mnk, args.tolerance)
    print("PASS")
