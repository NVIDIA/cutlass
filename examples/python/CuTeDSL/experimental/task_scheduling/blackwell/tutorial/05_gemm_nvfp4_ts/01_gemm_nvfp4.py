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
TS (Task Scheduling) version of nvfp4_gemm_1_ws.py.

This example converts the bare-metal NVF4 block-scaled GEMM kernel to the
TS framework by decomposing it into twelve resources and three-to-seven tasks:

Resources
---------
  GmemResource(isA=True)    : Global-memory A input coordinates.
  GmemResource(isA=False)   : Global-memory B input coordinates.
  GmemSfResource(isA=True)  : Global-memory SFA scale-factor coordinates.
  GmemSfResource(isA=False) : Global-memory SFB scale-factor coordinates.
  SmemResource(isA=True)    : Shared-memory A buffer filled by TMA load.
  SmemResource(isA=False)   : Shared-memory B buffer filled by TMA load.
  SmemSfResource(isA=True)  : Shared-memory SFA buffer filled by TMA load.
  SmemSfResource(isA=False) : Shared-memory SFB buffer filled by TMA load.
  TmemSfResource(isA=True)  : Tensor-memory SFA (S2T copy target).
  TmemSfResource(isA=False) : Tensor-memory SFB (S2T copy target).
  TmemCResource             : Tensor-memory accumulator (block-scaled MMA).
  GmemDResource             : Global-memory C output (epilogue store).

Tasks (use_two_tma_warps=False — default)
------------------------------------------
  LoadTask  (warp 5, 1 warp)      : TMA copy A+B+SfA+SfB from global to shared.
  MmaTask   (warp 4, 1 warp)      : S2T copies + block-scaled MMA computation.
  StoreTask (warps 0-3, 4 warps)  : Epilogue conversion and global store.

Tasks (use_two_tma_warps=True, use_two_sf_load_warps=False)
------------------------------------------------------------
  LoadATask (warp 5, 1 warp)      : TMA copy A + SfA from global to shared.
  LoadBTask (warp 6, 1 warp)      : TMA copy B + SfB from global to shared.
  MmaTask   (warp 4, 1 warp)      : S2T copies + block-scaled MMA computation.
  StoreTask (warps 0-3, 4 warps)  : Epilogue conversion and global store.

Tasks (use_two_sf_load_warps=True, fuse_sf_copy_to_mma=True)
--------------------------------------------------------------
  LoadATask   (warp 5, 1 warp)     : TMA copy A from global to shared.
  LoadBTask   (warp 6, 1 warp)     : TMA copy B from global to shared.
  LoadSfATask (warp 7, 1 warp)     : TMA copy SfA from global to shared.
  LoadSfBTask (warp 8, 1 warp)     : TMA copy SfB from global to shared.
  MmaTask     (warp 4, 1 warp)     : S2T copies + block-scaled MMA computation.
  StoreTask   (warps 0-3, 4 warps) : Epilogue conversion and global store.

Tasks (use_two_sf_load_warps=True, fuse_sf_copy_to_mma=False)
--------------------------------------------------------------
  LoadATask   (warp 5, 1 warp)      : TMA copy A from global to shared.
  LoadBTask   (warp 6, 1 warp)      : TMA copy B from global to shared.
  LoadSfATask (warp 7, 1 warp)      : TMA copy SfA from global to shared.
  LoadSfBTask (warp 8, 1 warp)      : TMA copy SfB from global to shared.
  CopySfATask (warp 9, 1 warp)      : S2T copy SfA from shared to tensor memory.
  CopySfBTask (warp 10, 1 warp)     : S2T copy SfB from shared to tensor memory.
  MmaTask     (warp 4, 1 warp)      : Block-scaled MMA (no S2T copies).
  StoreTask   (warps 0-3, 4 warps)  : Epilogue conversion and global store.

The kernel supports 256x256x256 tile with 2SM feature, warp specialization
optimization and multistage optimization.
"""

import argparse
from typing import Tuple, Any, Optional
from dataclasses import dataclass, field

import cuda.bindings.driver as cuda_driver
import torch

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_ptr

from cutlass.experimental.task_scheduling.enums import (
    WorkAttr,
    SignalingThreads,
)
from cutlass.experimental.task_scheduling.memory import (
    SmemAllocation,
    TmemAllocation,
    SmemAllocator,
    TmemAllocator,
)
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    WorkQueue,
    StageInfo,
    PipelineConfig,
    TileSchedulerConfig,
    TaskLocalVariable,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    domain_loop,
    schedule,
    work_tile_loop,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims


# ═══════════════════════════════════════════════════════════════════════
# Kernel configuration constants
# ═══════════════════════════════════════════════════════════════════════
smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_100")
num_tmem_alloc_cols = 512
mma_tiler_mnk = (256, 256, 256)
mma_tiler_mnk_per_cta = (128, 256, 256)
mma_inst_mnk = (256, 256, 64)
cluster_shape_mnk = (2, 1, 1)
ab_dtype = cutlass.Float4E2M1FN
sf_dtype = cutlass.Float8E4M3FN
c_dtype = cutlass.Float16
torch_c_dtype = torch.float16
torch_sf_dtype = torch.float8_e8m0fnu  # PyTorch SF dtype for host-side operations
sf_vec_size = 16

# Pipeline stage configuration
num_acc_stage = 1
num_ab_stage = 5
num_sf_stage = 2

# TMEM layout for scale factors:
#   - accumulator uses 256 columns
#   - SFA uses 16 columns per stage
#   - SFB uses 32 columns per stage
tmem_sfa_cols_per_stage = 16
tmem_sfb_cols_per_stage = 32
tmem_sf_cols_per_stage = tmem_sfa_cols_per_stage + tmem_sfb_cols_per_stage

# Set specialized warp ids
epilog_warp_id = (0, 1, 2, 3)
mma_warp_id = 4
tma_warp_id = 5

# When True, split the TMA load task into two separate tasks:
#   LoadATask (warp 5): loads SmemA + SmemSfA
#   LoadBTask (warp 6): loads SmemB + SmemSfB
# When False (default), a single LoadTask (warp 5) loads all four buffers.
use_two_tma_warps = False

# When True (requires use_two_tma_warps=True), extract SmemSfA/SmemSfB loads
# from LoadATask and LoadBTask into two separate SF load tasks:
#   LoadATask   (warp 5): loads SmemA only
#   LoadBTask   (warp 6): loads SmemB only
#   LoadSfATask (warp 7): loads SmemSfA
#   LoadSfBTask (warp 8): loads SmemSfB
use_two_sf_load_warps = False

# When False (requires use_two_sf_load_warps=True), extract the S2T scale-
# factor copies from TmemCResource.producer_work into dedicated TmemSfA /
# TmemSfB resources with an AsyncUmma pipeline, driven by separate
# CopySfA / CopySfB tasks.
# When True (default), S2T copies remain fused inside the MMA task's
# TmemCResource.producer_work (original behaviour).  TmemSfA / TmemSfB
# resources are still created for the dependency graph but carry no pipeline.
fuse_sf_copy_to_mma = True

epi_threads_per_cta = 32 * len(epilog_warp_id)

# Shared memory stage sizes in bytes
# FP4: 4 bits per element, so 2 elements per byte
a_stage_bytes = mma_tiler_mnk_per_cta[0] * mma_tiler_mnk[2] // 2  # 128*256/2 = 16384
b_stage_bytes = (
    (mma_tiler_mnk[1] // cluster_shape_mnk[0]) * mma_tiler_mnk[2] // 2
)  # 128*256/2 = 16384
# FP8: 1 byte per element
sfa_stage_bytes = 512 * 4  # = 2048
sfb_stage_bytes = 512 * 4 * 2  # = 4096

# Named barrier config for TMEM allocation sync (MMA + epilogue warps
# + CopySf warps when non-fused)
tmem_bar_id = 1
_num_copy_sf_warps = 0
tmem_bar_threads = 0


def refresh_derived_config() -> None:
    """
    Refresh globals derived from metaprogramming flags.
    """
    globals()["_num_copy_sf_warps"] = 0 if fuse_sf_copy_to_mma else 2
    globals()["tmem_bar_threads"] = 32 * (
        1 + len(epilog_warp_id) + globals()["_num_copy_sf_warps"]
    )


refresh_derived_config()

# Epilogue tile size for TMEM -> RMEM loads
epi_t2r_repx = 128
epi_subtile_cnt = mma_tiler_mnk[1] // epi_t2r_repx  # 256 / 128 = 2

debug_print = False

# Scheduling mode option: set to True for CLC dynamic persistent scheduling.
# Can also be overridden via --clc-dynamic-scheduler CLI flag.
use_clc_dynamic_scheduler = False
num_scheduler_stages = 2


def compute_active_task_warp_count() -> int:
    """
    Return the number of active (non-padding) warps for current feature flags.
    """
    num_warps = len(epilog_warp_id) + 1  # Store + MMA
    if use_two_tma_warps:
        num_warps += 2  # LoadA + LoadB
        if use_two_sf_load_warps:
            num_warps += 2  # LoadSfA + LoadSfB
            if not fuse_sf_copy_to_mma:
                num_warps += 2  # CopySfA + CopySfB
    else:
        num_warps += 1  # single Load
    if use_clc_dynamic_scheduler:
        num_warps += 1  # WorkScheduleTask
    return num_warps


def compute_padded_warp_count() -> int:
    """
    Pad active warps to warp-group granularity (4 warps).
    """
    active = compute_active_task_warp_count()
    return ((active + 3) // 4) * 4


########################################################
# WorkQueue resource construction and scheduler task
########################################################


@cute.jit
def create_work_queue(
    tile_sched_params: object,
    cluster_shape_vmnk: tuple,
    num_consumer_warps: int,
    clc_response_ptr: Optional[cute.Pointer],
) -> WorkQueue:
    """
    Create CLC dynamic persistent work queue resource.
    """
    cluster_size = cluster_shape_mnk[0] * cluster_shape_mnk[1]
    num_clc_consumer_threads = 32 * cluster_size * num_consumer_warps
    num_clc_response_bytes = 16
    scheduler_pipeline_config = PipelineConfig.create_clc_fetch_async_pipeline_cfg(
        num_stages=num_scheduler_stages,
        num_bytes=num_clc_response_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_clc_consumer_threads
        ),
        cta_layout_vmnk=cluster_shape_vmnk,
        producer_signaling_threads=SignalingThreads.CtaLeader,
        consumer_signaling_threads=SignalingThreads.All,
    )
    tile_scheduler_config = (
        TileSchedulerConfig.create_clc_dynamic_persistent_tile_scheduler_params(
            tile_scheduler_params=tile_sched_params,
            response_ptr=clc_response_ptr,
        )
    )
    return WorkQueue(
        tile_scheduler_config=tile_scheduler_config,
        pipeline_config=scheduler_pipeline_config,
        name="WorkQueue",
    )


@cute.jit
def create_work_schedule_task(
    work_queue: WorkQueue,
    scheduler_warp_idx: int,
) -> Task:
    """
    Create the CLC scheduler task (produces and then consumes one work item).
    """

    @schedule
    def scheduler_schedule(wq: WorkQueue) -> None:
        with work_tile_loop(wq) as work_tile:
            with domain_loop(0, 0, 1):
                pass
            wq.try_acquire()
            wq.acquire()
            wq.fetch_work_tile()
            wq.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = scheduler_schedule(work_queue)
    return Task(
        src_resources=[work_queue],
        dst_resources=[work_queue],
        warp_idx=scheduler_warp_idx,
        num_warps=1,
        schedule=result,
        num_registers=40,
        name="WorkScheduleTask",
        debug_print=debug_print,
    )


# ═══════════════════════════════════════════════════════════════════════
# Resource definitions
# ═══════════════════════════════════════════════════════════════════════


@dataclass
class GmemResource(MemoryResource):
    """Global-memory A or B input resource (read-only source).

    Parameterised by ``isA``:
      * isA=True  → computes A-side TMA load coordinates (coord_a_*).
      * isA=False → computes B-side TMA load coordinates (coord_b_*).

    Consumer variable names include an 'a' or 'b' prefix to prevent
    cross-contamination when multiple GmemResource instances share
    the same Load task (copy_consumer_vars_to copies to ALL dst_resources).

    Methods
    -------
    compute_*_coords()
        Computes TMA load coordinates for the current k-tile iteration.
    """

    isA: cutlass.Constexpr[bool] = True
    coord_a_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_a_mn: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_a_l: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_b_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_b_mn: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_b_l: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    cta_rank_in_cluster: Any = field(init=False, default=None)
    bidx: Any = field(init=False, default=None)
    bidy: Any = field(init=False, default=None)
    bidz: Any = field(init=False, default=None)

    def __init__(self, isA: bool, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.isA = isA
        self.coord_a_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="A operand K coordinate for the current TMA load tile.",
        )
        self.coord_a_mn = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="A operand M coordinate for the current TMA load tile.",
        )
        self.coord_a_l = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="A operand batch coordinate for the current TMA load tile.",
        )
        self.coord_b_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="B operand K coordinate for the current TMA load tile.",
        )
        self.coord_b_mn = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="B operand N coordinate for the current TMA load tile.",
        )
        self.coord_b_l = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="B operand batch coordinate for the current TMA load tile.",
        )

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        self.bidx, self.bidy, self.bidz = cute.arch.block_idx()
        if cutlass.const_expr(use_clc_dynamic_scheduler):
            self.bidx, self.bidy, self.bidz = stage_info.work_tile.tile_idx

    @cute.jit
    def _compute_coords(self, stage_info: StageInfo) -> tuple:
        cta_tile_m = self.bidx
        cta_tile_n = self.bidy
        coord_l = self.bidz
        coord_k = stage_info.loop_offset * mma_tiler_mnk[2]
        cluster_tile_m = cta_tile_m // cluster_shape_mnk[0]
        coord_m_base = (
            cluster_tile_m * mma_tiler_mnk[0]
            + self.cta_rank_in_cluster * mma_tiler_mnk_per_cta[0]
        )
        coord_n_base = (
            cta_tile_n * mma_tiler_mnk[1]
            + self.cta_rank_in_cluster * mma_tiler_mnk_per_cta[0]
        )
        return coord_k, coord_m_base, coord_n_base, coord_l

    @consumer_work(returns=(coord_a_k, coord_a_mn, coord_a_l))
    @cute.jit
    def compute_a_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        coord_k, coord_m_base, _, coord_l = self._compute_coords(stage_info)
        return coord_k, coord_m_base, coord_l

    @consumer_work(returns=(coord_b_k, coord_b_mn, coord_b_l))
    @cute.jit
    def compute_b_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        coord_k, _, coord_n_base, coord_l = self._compute_coords(stage_info)
        return coord_k, coord_n_base, coord_l


@dataclass
class GmemSfResource(MemoryResource):
    """Global-memory SFA or SFB scale-factor input resource (read-only source).

    Parameterised by ``isA``:
      * isA=True  → computes SFA-side coordinates (coord_sfa_*).
      * isA=False → computes SFB-side coordinates (coord_sfb_*).

    Methods
    -------
    compute_*_coords()
        Computes TMA load coordinates for the current k-tile iteration.
    """

    isA: cutlass.Constexpr[bool] = True
    coord_sfa_sfk: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    coord_sfa_batch: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    coord_sfa_l: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    coord_sfb_sfk: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    coord_sfb_batch: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    coord_sfb_l: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    cta_rank_in_cluster: Any = field(init=False, default=None)
    bidx: Any = field(init=False, default=None)
    bidy: Any = field(init=False, default=None)
    bidz: Any = field(init=False, default=None)

    def __init__(self, isA: bool, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.isA = isA
        self.coord_sfa_sfk = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFA scale-factor K-group coordinate.",
        )
        self.coord_sfa_batch = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFA scale-factor batch coordinate.",
        )
        self.coord_sfa_l = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFA scale-factor L coordinate.",
        )
        self.coord_sfb_sfk = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFB scale-factor K-group coordinate.",
        )
        self.coord_sfb_batch = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFB scale-factor batch coordinate.",
        )
        self.coord_sfb_l = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SFB scale-factor L coordinate.",
        )

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        self.bidx, self.bidy, self.bidz = cute.arch.block_idx()
        if cutlass.const_expr(use_clc_dynamic_scheduler):
            self.bidx, self.bidy, self.bidz = stage_info.work_tile.tile_idx

    @cute.jit
    def _compute_sf_coords(self, stage_info: StageInfo) -> tuple:
        cta_tile_m = self.bidx
        cta_tile_n = self.bidy
        coord_l = self.bidz
        coord_sfk = stage_info.loop_offset * 4
        cluster_tile_m = cta_tile_m // cluster_shape_mnk[0]
        cta_tile_m_linear = (
            cluster_tile_m * cluster_shape_mnk[0] + self.cta_rank_in_cluster
        )
        cta_tile_n_linear = cta_tile_n * cluster_shape_mnk[0] + self.cta_rank_in_cluster
        return coord_sfk, cta_tile_m_linear, cta_tile_n_linear, coord_l

    @consumer_work(returns=(coord_sfa_sfk, coord_sfa_batch, coord_sfa_l))
    @cute.jit
    def compute_sfa_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        coord_sfk, cta_tile_m_linear, _, coord_l = self._compute_sf_coords(stage_info)
        return coord_sfk, cta_tile_m_linear, coord_l

    @consumer_work(returns=(coord_sfb_sfk, coord_sfb_batch, coord_sfb_l))
    @cute.jit
    def compute_sfb_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        coord_sfk, _, cta_tile_n_linear, coord_l = self._compute_sf_coords(stage_info)
        return coord_sfk, cta_tile_n_linear, coord_l


@dataclass
class SmemResource(MemoryResource):
    """Shared-memory A or B buffer filled by asynchronous TMA loads.

    Parameterised by ``isA``:
      * isA=True  → TMA loads for A; builds A MMA descriptor.
      * isA=False → TMA loads for B; builds B MMA descriptor.

    Producer side (LoadTask): Issues TMA bulk-copy instructions to move
    A or B tiles from global memory into staged SMEM buffers.

    Consumer side (MmaTask): Builds SMEM descriptors for MMA instructions.

    Methods
    -------
    init_descriptors()
        Initializes SMEM views and publishes descriptor TaskLocalVariable slots.
    tma_load_*()
        Issues cp.async.bulk.tensor load into the current SMEM stage.
    build_*_mma_descriptor()
        Builds SMEM descriptor for the current stage.
    """

    isA: cutlass.Constexpr[bool] = True
    tma_desc: Any = field(init=False, default=None)
    smem_buf: Any = field(init=False, default=None)
    stage_bytes_val: cutlass.Constexpr[int] = 0
    cta_rank_in_cluster: Any = field(init=False, default=None)
    mcast_mask: Any = field(init=False, default=None)
    _alloc: cutlass.Constexpr = field(init=False, default=None)
    desc_a_mma_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    desc_b_mma_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(
        self,
        isA: bool,
        tma_desc: cutlass.Pointer,
        stage_bytes_val: int,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.isA = isA
        self.tma_desc = tma_desc
        self.stage_bytes_val = stage_bytes_val
        label = "smem_a" if isA else "smem_b"
        self._alloc = SmemAllocation(label, stage_bytes_val * num_ab_stage)
        self.desc_a_mma_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="A operand SMEM descriptor base consumed by MMA.",
        )
        self.desc_b_mma_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="B operand SMEM descriptor base consumed by MMA.",
        )

    def get_smem_requirements(self):
        return [self._alloc]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        smem_base = context.smem_base
        self.smem_buf = cutlass.Array(
            smem_base.data_ptr() + self._alloc.offset,
            dtype=cutlass.Uint8,
            shape=(self.stage_bytes_val * num_ab_stage,),
            addrspace=3,
        )
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        shift_amount = cutlass.Int16(self.cta_rank_in_cluster)
        self.mcast_mask = cutlass.Int16(1) << shift_amount

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptors(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @producer_work
    @cute.jit
    def tma_load_a(
        self,
        stage_info: StageInfo,
        *,
        coord_a_k: cutlass.Int32,
        coord_a_mn: cutlass.Int32,
        coord_a_l: cutlass.Int32,
    ) -> None:
        """Issue TMA load for A into the current SMEM stage."""
        smem_stage = self.smem_buf.subview(self.stage_bytes_val * stage_info.stage_idx)

        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cluster_global(
                smem_stage,
                self.tma_desc,
                (coord_a_k, coord_a_mn, coord_a_l),
                stage_info.barrier,
                [],
                multicast_mask=self.mcast_mask,
                group=prims.CTAGroup.CTA_2,
            )

    @producer_work
    @cute.jit
    def tma_load_b(
        self,
        stage_info: StageInfo,
        *,
        coord_b_k: cutlass.Int32,
        coord_b_mn: cutlass.Int32,
        coord_b_l: cutlass.Int32,
    ) -> None:
        """Issue TMA load for B into the current SMEM stage."""
        smem_stage = self.smem_buf.subview(self.stage_bytes_val * stage_info.stage_idx)

        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cluster_global(
                smem_stage,
                self.tma_desc,
                (coord_b_k, coord_b_mn, coord_b_l),
                stage_info.barrier,
                [],
                multicast_mask=self.mcast_mask,
                group=prims.CTAGroup.CTA_2,
            )

    @consumer_work(returns=desc_a_mma_base)
    @cute.jit
    def build_a_mma_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        """
        Build A SMEM descriptor for MMA (leader CTA only).
        """
        desc_mma_base = cutlass.Int64(0)
        if self.cta_rank_in_cluster == 0:
            smem_stage = self.smem_buf.subview(
                stage_info.stage_idx * self.stage_bytes_val
            )
            # MMA descriptors: leading=16B, stride=1024B, swizzle=128B (layout=2)
            desc_mma_base = prims.Tcgen05SmemDesc.build(
                smem_stage,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )
        return desc_mma_base

    @consumer_work(returns=desc_b_mma_base)
    @cute.jit
    def build_b_mma_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        """
        Build B SMEM descriptor for MMA (leader CTA only).
        """
        desc_mma_base = cutlass.Int64(0)
        if self.cta_rank_in_cluster == 0:
            smem_stage = self.smem_buf.subview(
                stage_info.stage_idx * self.stage_bytes_val
            )
            # MMA descriptors: leading=16B, stride=1024B, swizzle=128B (layout=2)
            desc_mma_base = prims.Tcgen05SmemDesc.build(
                smem_stage,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )
        return desc_mma_base


@dataclass
class SmemSfResource(MemoryResource):
    """Shared-memory SFA or SFB buffer filled by asynchronous TMA loads.

    Parameterised by ``isA``:
      * isA=True  → TMA loads for SFA; builds SFA S2T descriptor.
      * isA=False → TMA loads for SFB; builds SFB S2T descriptor.

    Producer side (LoadTask): Issues TMA bulk-copy instructions to move
    SFA or SFB tiles from global memory into staged SMEM buffers.

    Consumer side (MmaTask): Builds SMEM descriptors for S2T copy
    instructions.

    Methods
    -------
    init_descriptors()
        Initializes SMEM views and publishes descriptor TaskLocalVariable slots.
    tma_load_*()
        Issues cp.async.bulk.tensor load into the current SMEM stage.
    build_*_s2t_descriptor()
        Builds SMEM descriptor for the current stage.
    """

    isA: cutlass.Constexpr[bool] = True
    tma_desc: Any = field(init=False, default=None)
    smem_buf: Any = field(init=False, default=None)
    stage_bytes_val: cutlass.Constexpr[int] = 0
    cta_rank_in_cluster: Any = field(init=False, default=None)
    mcast_mask: Any = field(init=False, default=None)
    bidx_mod2: Any = field(init=False, default=None)
    _alloc: cutlass.Constexpr = field(init=False, default=None)
    desc_a_s2t_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    desc_b_s2t_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(
        self,
        isA: bool,
        tma_desc: cutlass.Pointer,
        stage_bytes_val: int,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.isA = isA
        self.tma_desc = tma_desc
        self.stage_bytes_val = stage_bytes_val
        label = "smem_sfa" if isA else "smem_sfb"
        self._alloc = SmemAllocation(label, stage_bytes_val * num_ab_stage)
        self.desc_a_s2t_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SFA SMEM descriptor base consumed by S2T copy.",
        )
        self.desc_b_s2t_base = TaskLocalVariable(
            dtype=cutlass.Int64,
            default=cutlass.Int64(0),
            docs="SFB SMEM descriptor base consumed by S2T copy.",
        )

    def get_smem_requirements(self):
        return [self._alloc]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        smem_base = context.smem_base
        self.smem_buf = cutlass.Array(
            smem_base.data_ptr() + self._alloc.offset,
            dtype=cutlass.Uint8,
            shape=(self.stage_bytes_val * num_ab_stage,),
            addrspace=3,
        )
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        shift_amount = cutlass.Int16(self.cta_rank_in_cluster)
        if cutlass.const_expr(self.isA):
            self.mcast_mask = cutlass.Int16(1) << shift_amount
        else:
            self.mcast_mask = cutlass.Int16(3)
        self.bidx_mod2 = self.cta_rank_in_cluster

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptors(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @producer_work
    @cute.jit
    def tma_load_sfa(
        self,
        stage_info: StageInfo,
        *,
        coord_sfa_sfk: cutlass.Int32,
        coord_sfa_batch: cutlass.Int32,
        coord_sfa_l: cutlass.Int32,
    ) -> None:
        """Issue TMA load for SFA into the current SMEM stage."""
        smem_stage = self.smem_buf.subview(self.stage_bytes_val * stage_info.stage_idx)

        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cluster_global(
                smem_stage,
                self.tma_desc,
                (0, coord_sfa_sfk, coord_sfa_batch, coord_sfa_l),
                stage_info.barrier,
                [],
                multicast_mask=self.mcast_mask,
                group=prims.CTAGroup.CTA_2,
            )

    @producer_work
    @cute.jit
    def tma_load_sfb(
        self,
        stage_info: StageInfo,
        *,
        coord_sfb_sfk: cutlass.Int32,
        coord_sfb_batch: cutlass.Int32,
        coord_sfb_l: cutlass.Int32,
    ) -> None:
        """Issue TMA load for SFB into the current SMEM stage."""
        smem_stage = self.smem_buf.subview(
            self.stage_bytes_val * stage_info.stage_idx + self.bidx_mod2 * 2048
        )

        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cluster_global(
                smem_stage,
                self.tma_desc,
                (0, coord_sfb_sfk, coord_sfb_batch, coord_sfb_l),
                stage_info.barrier,
                [],
                multicast_mask=self.mcast_mask,
                group=prims.CTAGroup.CTA_2,
            )

    @consumer_work(returns=desc_a_s2t_base)
    @cute.jit
    def build_sfa_s2t_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        """
        Build SFA SMEM descriptor for S2T copy (leader CTA only).
        """
        desc_s2t_base = cutlass.Int64(0)
        if self.cta_rank_in_cluster == 0:
            smem_stage = self.smem_buf.subview(
                stage_info.stage_idx * self.stage_bytes_val
            )
            # S2T descriptors: leading=16B, stride=128B, no swizzle (layout=0)
            desc_s2t_base = prims.Tcgen05SmemDesc.build(
                smem_stage,
                leading_byte_offset=16,
                stride_byte_offset=128,
                layout=0,
            )
        return desc_s2t_base

    @consumer_work(returns=desc_b_s2t_base)
    @cute.jit
    def build_sfb_s2t_descriptor(self, stage_info: StageInfo) -> cutlass.Int64:
        """
        Build SFB SMEM descriptor for S2T copy (leader CTA only).
        """
        desc_s2t_base = cutlass.Int64(0)
        if self.cta_rank_in_cluster == 0:
            smem_stage = self.smem_buf.subview(
                stage_info.stage_idx * self.stage_bytes_val
            )
            # S2T descriptors: leading=16B, stride=128B, no swizzle (layout=0)
            desc_s2t_base = prims.Tcgen05SmemDesc.build(
                smem_stage,
                leading_byte_offset=16,
                stride_byte_offset=128,
                layout=0,
            )
        return desc_s2t_base


@dataclass
class TmemSfResource(MemoryResource):
    """Tensor-memory scale-factor buffer for SFA or SFB (S2T copy target).

    This resource represents the TMEM region that holds scale factors
    after the S2T copy from SMEM.

    When ``fuse_sf_copy_to_mma`` is **False** this resource carries an
    ``AsyncUmma`` pipeline:

      * **Producer side** (``CopySfA`` / ``CopySfB`` task) — issues
        ``tcgen05_copy`` instructions to move scale factors from SMEM to
        TMEM.
      * **Consumer side** (``MmaTask``) — the UMMA consumer wait ensures
        S2T data is visible in TMEM before the block-scaled MMA begins.

    When ``fuse_sf_copy_to_mma`` is **True** (default) the resource has
    no pipeline (``pipeline_config=None``) and is present only to
    document the dataflow dependency ``SmemSfA → TmemSfA`` in the
    resource dependency graph.

    Parameterised by ``isA``:
      * isA=True  → SFA scale factors (4 S2T iterations, 32-byte stride).
      * isA=False → SFB scale factors (8 S2T iterations, split stride).

    Methods
    -------
    copy_sf*()
        Issues tcgen05_copy instructions (S2T) for SFA or SFB.
    """

    isA: cutlass.Constexpr[bool] = True
    sfa_tmem_addr_base: Any = field(init=False, default=None)
    sfb_tmem_addr_base: Any = field(init=False, default=None)
    cta_rank_in_cluster: Any = field(init=False, default=None)
    _alloc: cutlass.Constexpr = field(init=False, default=None)
    sfa_stage_col_offset: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    sfb_stage_col_offset: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __init__(
        self,
        isA: bool,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.isA = isA
        if isA:
            cols = tmem_sfa_cols_per_stage * num_sf_stage
            self._alloc = TmemAllocation("tmem_sfa", cols)
        else:
            cols = tmem_sfb_cols_per_stage * num_sf_stage
            self._alloc = TmemAllocation("tmem_sfb", cols)
        self.sfa_stage_col_offset = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="Current SFA TMEM stage column offset.",
        )
        self.sfb_stage_col_offset = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="Current SFB TMEM stage column offset.",
        )

    def get_tmem_requirements(self):
        return [self._alloc]

    @cute.jit
    def _init_tmem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        tmem_raw_addr = context.tmem_ptr_i32.load()
        base_col_id = tmem_raw_addr & 0xFFFF
        base_row_id = tmem_raw_addr >> 16
        sfa_col_id = base_col_id + mma_tiler_mnk[1]
        sfb_col_id = sfa_col_id + tmem_sfa_cols_per_stage
        self.sfa_tmem_addr_base = (base_row_id << 16) | sfa_col_id
        self.sfb_tmem_addr_base = (base_row_id << 16) | sfb_col_id

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_copy_state(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_sfa_stage_offset(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_sfb_stage_offset(self, stage_info: StageInfo) -> None:
        self._init_tmem_state(stage_info)

    @producer_work
    @cute.jit
    def copy_sfa(
        self, stage_info: StageInfo, *, desc_a_s2t_base: cutlass.Int64
    ) -> None:
        """
        Issue S2T copies for SFA from SMEM to TMEM.
        """
        if self.cta_rank_in_cluster == 0:
            s2t_shape, s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4
            stage_idx = cutlass.Int32(0)
            if cutlass.const_expr(not fuse_sf_copy_to_mma):
                stage_idx = stage_info.stage_idx
            sf_stage_col_offset = stage_idx * tmem_sf_cols_per_stage

            for s2t_idx in cutlass.range_constexpr(4):
                sfa_tmem_addr_s2t = (
                    self.sfa_tmem_addr_base + sf_stage_col_offset + s2t_idx * 4
                )
                sfa_tmem_ptr_s2t = prims.make_tmem_ptr(
                    sfa_tmem_addr_s2t, cutlass.Float32
                )
                increment_s2t = 32 * s2t_idx
                desc_s2t = desc_a_s2t_base + increment_s2t
                if prims.elect_sync():
                    prims.tcgen05_cp(
                        s2t_shape,
                        sfa_tmem_ptr_s2t,
                        desc_s2t,
                        group=prims.CTAGroup.CTA_2,
                        multicast=s2t_multicast,
                    )
            # Ensure S2T TMEM stores are globally visible before ProducerCommit
            # signals this stage to the MMA consumer in the non-fused path.
            prims.tcgen05_wait(kind=prims.Tcgen05Wait.STORE)

    @producer_work
    @cute.jit
    def copy_sfb(
        self, stage_info: StageInfo, *, desc_b_s2t_base: cutlass.Int64
    ) -> None:
        """
        Issue S2T copies for SFB from SMEM to TMEM.
        """
        if self.cta_rank_in_cluster == 0:
            s2t_shape, s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4
            stage_idx = cutlass.Int32(0)
            if cutlass.const_expr(not fuse_sf_copy_to_mma):
                stage_idx = stage_info.stage_idx
            sf_stage_col_offset = stage_idx * tmem_sf_cols_per_stage

            for s2t_idx in cutlass.range_constexpr(8):
                sfb_tmem_addr_s2t = (
                    self.sfb_tmem_addr_base + sf_stage_col_offset + s2t_idx * 4
                )
                sfb_tmem_ptr_s2t = prims.make_tmem_ptr(
                    sfb_tmem_addr_s2t, cutlass.Float32
                )
                increment_s2t = 32 * (s2t_idx // 2) + 128 * (s2t_idx % 2)
                desc_s2t = desc_b_s2t_base + increment_s2t
                if prims.elect_sync():
                    prims.tcgen05_cp(
                        s2t_shape,
                        sfb_tmem_ptr_s2t,
                        desc_s2t,
                        group=prims.CTAGroup.CTA_2,
                        multicast=s2t_multicast,
                    )
            # Ensure S2T TMEM stores are globally visible before ProducerCommit
            # signals this stage to the MMA consumer in the non-fused path.
            prims.tcgen05_wait(kind=prims.Tcgen05Wait.STORE)

    @consumer_work(returns=sfa_stage_col_offset)
    @cute.jit
    def stage_sfa_offset(self, stage_info: StageInfo) -> cutlass.Int32:
        """
        Publish current TMEM SFA stage offset for downstream MMA consumption.
        """
        sf_stage_col_offset = stage_info.stage_idx * tmem_sf_cols_per_stage
        return sf_stage_col_offset

    @consumer_work(returns=sfb_stage_col_offset)
    @cute.jit
    def stage_sfb_offset(self, stage_info: StageInfo) -> cutlass.Int32:
        """
        Publish current TMEM SFB stage offset for downstream MMA consumption.
        """
        sf_stage_col_offset = stage_info.stage_idx * tmem_sf_cols_per_stage
        return sf_stage_col_offset


@dataclass
class TmemCResource(MemoryResource):
    """Tensor-memory accumulator written by block-scaled MMA.

    Producer side (MmaTask): Copies scale factors from SMEM to TMEM via
    S2T instructions, then executes block-scaled MMA.

    Consumer side (StoreTask): Loads TMEM sub-tiles into RMEM for the
    epilogue.

    Methods
    -------
    init_accumulator()
        Initializes TMEM accumulator state and publishes the RMEM output slot.
    mma()
        Executes S2T copies for SFA/SFB, then block-scaled MMA.
    load_tmem()
        Reads a sub-tile from TMEM into RMEM via prims.tcgen05_ld.
    """

    acc_tmem_ptr: Any = field(init=False, default=None)
    sfa_tmem_addr_base: Any = field(init=False, default=None)
    sfb_tmem_addr_base: Any = field(init=False, default=None)
    idesc: Any = field(init=False, default=None)
    scale_d: Any = field(init=False, default=None)
    tmem_raw_addr: Any = field(init=False, default=None)
    cta_rank_in_cluster: Any = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(
        self,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * num_acc_stage)
        self.t2r_rmem = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.full([epi_t2r_repx], 0.0, cutlass.Float32),
            docs="Register-memory subtile loaded from TMEM for the epilogue.",
        )

    def get_tmem_requirements(self):
        return [self._alloc_acc]

    @cute.jit
    def _init_accumulator_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        # Build block-scaled MMA instruction descriptor
        self.idesc = prims.Tcgen05MxInstrDesc.build(
            a_dtype=cutlass.Float8E5M2,
            b_dtype=cutlass.Float8E5M2,
            scale_format=0,
            n_dim=256,
            m_dim=256,
        )
        self.tmem_raw_addr = context.tmem_ptr_i32.load()
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()

        # Compute TMEM base pointer
        self.acc_tmem_ptr = prims.make_tmem_ptr(self.tmem_raw_addr, cutlass.Float32)

        # Compute TMEM addresses for scale factors
        base_col_id = self.tmem_raw_addr & 0xFFFF
        base_row_id = self.tmem_raw_addr >> 16
        # Acc uses 256 columns of TMEM; scale factors start after
        sfa_col_id = base_col_id + mma_tiler_mnk[1]
        sfb_col_id = sfa_col_id + tmem_sfa_cols_per_stage
        self.sfa_tmem_addr_base = (base_row_id << 16) | sfa_col_id
        self.sfb_tmem_addr_base = (base_row_id << 16) | sfb_col_id

        # Initialize scale_d before dynamic control flow
        self.scale_d = cutlass.Boolean(False)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_accumulator(self, stage_info: StageInfo) -> None:
        self._init_accumulator_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY, returns=t2r_rmem)
    @cute.jit
    def init_t2r_buffer(self, stage_info: StageInfo) -> cutlass.Float32:
        self._init_accumulator_state(stage_info)
        return cutlass.full([epi_t2r_repx], 0.0, cutlass.Float32)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_work_tile_state(self, stage_info: StageInfo) -> None:
        self.scale_d = False

    @producer_work
    @cute.jit
    def mma_fused(
        self,
        stage_info: StageInfo,
        *,
        desc_a_mma_base: cutlass.Int64,
        desc_b_mma_base: cutlass.Int64,
    ) -> None:
        """
        Execute fused-path block-scaled MMA.
        """
        self._issue_mma(
            stage_info,
            desc_a_mma_base,
            desc_b_mma_base,
            cutlass.Int32(0),
            cutlass.Int32(0),
        )

    @producer_work
    @cute.jit
    def mma_nonfused(
        self,
        stage_info: StageInfo,
        *,
        desc_a_mma_base: cutlass.Int64,
        desc_b_mma_base: cutlass.Int64,
        sfa_stage_col_offset: cutlass.Int32,
        sfb_stage_col_offset: cutlass.Int32,
    ) -> None:
        """
        Execute non-fused-path block-scaled MMA.
        """
        self._issue_mma(
            stage_info,
            desc_a_mma_base,
            desc_b_mma_base,
            sfa_stage_col_offset,
            sfb_stage_col_offset,
        )

    @cute.jit
    def _issue_mma(
        self,
        stage_info: StageInfo,
        desc_a_mma_base,
        desc_b_mma_base,
        sfa_stage_col_offset,
        sfb_stage_col_offset,
    ) -> None:
        """
        Execute block-scaled MMA using the selected SF TMEM stage.
        """
        # Leader CTA only
        if self.cta_rank_in_cluster == 0:
            # Block-scaled MMA computation
            num_kblocks = cute.ceil_div(mma_tiler_mnk[2], mma_inst_mnk[2])
            for kblock_idx in cutlass.range_constexpr(num_kblocks):
                sfa_tmem_addr_mma = (
                    self.sfa_tmem_addr_base + sfa_stage_col_offset + kblock_idx * 4
                )
                sfb_tmem_addr_mma = (
                    self.sfb_tmem_addr_base + sfb_stage_col_offset + kblock_idx * 8
                )
                sfa_tmem_ptr_mma = prims.make_tmem_ptr(
                    sfa_tmem_addr_mma, cutlass.Float32
                )
                sfb_tmem_ptr_mma = prims.make_tmem_ptr(
                    sfb_tmem_addr_mma, cutlass.Float32
                )

                increment_mma = 2 * kblock_idx
                desc_a_mma = desc_a_mma_base + increment_mma
                desc_b_mma = desc_b_mma_base + increment_mma

                if prims.elect_sync():
                    prims.tcgen05_mma_block_scale(
                        prims.MMABlockScaleKind.MXF4NVF4,
                        prims.CTAGroup.CTA_2,
                        self.acc_tmem_ptr,
                        desc_a_mma,
                        desc_b_mma,
                        self.idesc,
                        enable_input_d=self.scale_d,
                        scale_a=sfa_tmem_ptr_mma,
                        scale_b=sfb_tmem_ptr_mma,
                        scale_vec_size=prims.Tcgen05MMABlockScale.BLOCK16,
                    )
                self.scale_d = True

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_subtile(
        self, stage_info: StageInfo, *, subtile_idx: cutlass.Constexpr[int]
    ) -> cutlass.Float32:
        """
        Load a TMEM sub-tile into register memory.
        """
        warp_idx = cute.arch.warp_idx()

        base_col_id = self.tmem_raw_addr & 0xFFFF
        base_row_id = self.tmem_raw_addr >> 16
        row_id_with_warp_offset = base_row_id + warp_idx * 32

        # Each subtile_idx corresponds to one epi_t2r_repx-column sub-tile
        col_offset = subtile_idx * epi_t2r_repx
        col_id = base_col_id + col_offset
        current_tmem_raw_addr = (row_id_with_warp_offset << 16) | col_id

        # Load from TMEM
        shape = "32x32b"
        tmem = prims.make_tmem_ptr(current_tmem_raw_addr, cutlass.Float32)
        c_rmem = prims.tcgen05_ld(shape, tmem, num=epi_t2r_repx)
        cute.arch.fence_view_async_tmem_load()
        return c_rmem


@dataclass
class GmemDResource(MemoryResource):
    """Global-memory C output resource (write-only sink).

    This resource is the final destination of the dataflow pipeline.
    The producer side takes RMEM data from TmemCResource, converts
    FP32 -> FP16, and issues vectorized global stores.

    Methods
    -------
    store()
        Converts FP32 accumulators to FP16 and writes to global memory C.
    """

    mC_mnl: Any = field(init=False, default=None)
    gC: Any = field(init=False, default=None)
    vsize: int = field(init=False, default=0)

    def __init__(
        self,
        mC_mnl: cutlass.Array,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.mC_mnl = mC_mnl
        self.gC = mC_mnl
        # 256-bit vectorized stores: 16 elements for Float16
        self.vsize = 256 // c_dtype.width

    @producer_work
    @cute.jit
    def store(
        self,
        stage_info: StageInfo,
        *,
        t2r_rmem: cutlass.Float32,
        subtile_idx: cutlass.Constexpr[int],
    ) -> None:
        """
        Convert and store results to global memory.
        """
        tidx, _, _ = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        if cutlass.const_expr(use_clc_dynamic_scheduler):
            bidx, bidy, bidz = stage_info.work_tile.tile_idx
        m = self.mC_mnl.shape[0]
        n = self.mC_mnl.shape[1]

        row = bidx * mma_tiler_mnk_per_cta[0] + tidx
        col_base = bidy * mma_tiler_mnk[1] + subtile_idx * epi_t2r_repx
        batch_offset = bidz * m * n

        for j in cutlass.range_constexpr(epi_t2r_repx // self.vsize):
            vec_f32 = t2r_rmem[j * self.vsize : j * self.vsize + self.vsize]
            vec_f16 = vec_f32.to(cutlass.Float16)
            linear_idx = row * n + col_base + j * self.vsize + batch_offset
            self.gC.store(vec_f16, idx=linear_idx, vector_size=self.vsize, alignment=32)


# ═══════════════════════════════════════════════════════════════════════
# Resource construction helpers
# ═══════════════════════════════════════════════════════════════════════


@cute.jit
def create_gmem_resource(isA: bool) -> GmemResource:
    """
    Create a global memory A or B input resource.
    """
    if cutlass.const_expr(isA):
        return GmemResource(isA=True, name="GmemA")
    else:
        return GmemResource(isA=False, name="GmemB")


@cute.jit
def create_gmem_sf_resource(isA: bool) -> GmemSfResource:
    """
    Create a global memory SFA or SFB input resource.
    """
    if cutlass.const_expr(isA):
        return GmemSfResource(isA=True, name="GmemSfA")
    else:
        return GmemSfResource(isA=False, name="GmemSfB")


@cute.jit
def create_smem_resource(
    isA: bool,
    tma_desc: cutlass.Pointer,
    stage_bytes_val: int,
    cluster_shape_vmnk: tuple,
) -> SmemResource:
    """
    Create a shared memory A or B resource with TMA+UMMA pipeline.
    """
    cluster_size = cluster_shape_mnk[0] * cluster_shape_mnk[1] * cluster_shape_mnk[2]
    num_tma_load_bytes = stage_bytes_val * cluster_size
    num_tma_producer = 1
    smem_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=num_ab_stage,
        num_bytes=num_tma_load_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        ),
        cta_layout_vmnk=cluster_shape_vmnk,
        consumer_signaling_threads=SignalingThreads.CtaLeader,
        num_bytes_per_warp_per_cta=stage_bytes_val,
    )
    if cutlass.const_expr(isA):
        return SmemResource(
            isA=True,
            tma_desc=tma_desc,
            stage_bytes_val=stage_bytes_val,
            pipeline_config=smem_pipeline_config,
            name="SmemA",
        )
    else:
        return SmemResource(
            isA=False,
            tma_desc=tma_desc,
            stage_bytes_val=stage_bytes_val,
            pipeline_config=smem_pipeline_config,
            name="SmemB",
        )


@cute.jit
def create_smem_sf_resource(
    isA: bool,
    tma_desc: cutlass.Pointer,
    stage_bytes_val: int,
    cluster_shape_vmnk: tuple,
) -> SmemSfResource:
    """Create a shared memory SFA or SFB resource.

    When ``fuse_sf_copy_to_mma`` is True the consumer is the MMA warp
    (UMMA), so TmaUmma is used.  When False the consumer is the
    CopySf warp (AsyncThread), so TmaAsync is used instead.
    """
    cluster_size = cluster_shape_mnk[0] * cluster_shape_mnk[1] * cluster_shape_mnk[2]
    num_tma_load_bytes = stage_bytes_val * cluster_size
    num_tma_producer = 1
    if cutlass.const_expr(fuse_sf_copy_to_mma):
        # MMA (UMMA) is the consumer
        smem_sf_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
            num_stages=num_ab_stage,
            num_bytes=num_tma_load_bytes,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_tma_producer
            ),
            cta_layout_vmnk=cluster_shape_vmnk,
            # MMA consumer: only CTA 0 runs MMA, so only CTA 0 waits/releases
            consumer_signaling_threads=SignalingThreads.CtaLeader,
            num_bytes_per_warp_per_cta=stage_bytes_val,
        )
    else:
        # CopySf warp is the consumer.  Must use TmaUmma (not
        # TmaAsync) so that producer_acquire guards arrive_and_expect_tx
        # with is_leader_cta, preventing double TX counts in 2-CTA mode.
        smem_sf_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
            num_stages=num_ab_stage,
            num_bytes=num_tma_load_bytes,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_tma_producer
            ),
            cta_layout_vmnk=cluster_shape_vmnk,
            # CopySf consumer: only CTA 0 runs S2T copies
            consumer_signaling_threads=SignalingThreads.CtaLeader,
            num_bytes_per_warp_per_cta=stage_bytes_val,
        )
    if cutlass.const_expr(isA):
        return SmemSfResource(
            isA=True,
            tma_desc=tma_desc,
            stage_bytes_val=stage_bytes_val,
            pipeline_config=smem_sf_pipeline_config,
            name="SmemSfA",
        )
    else:
        return SmemSfResource(
            isA=False,
            tma_desc=tma_desc,
            stage_bytes_val=stage_bytes_val,
            pipeline_config=smem_sf_pipeline_config,
            name="SmemSfB",
        )


@cute.jit
def create_tmem_c_resource(
    cluster_shape_vmnk: tuple,
    num_epilogue_warps: int,
) -> TmemCResource:
    """
    Create the TMEM accumulator resource with UMMA async pipeline.
    """
    # Both CTAs consume TMEM, so arrive count covers all epilogue threads
    tmem_c_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread,
        size=num_epilogue_warps * 32 * cluster_shape_mnk[0],
    )
    tmem_c_pipeline_config = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=num_acc_stage,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=tmem_c_pipeline_consumer_group,
        cta_layout_vmnk=cluster_shape_vmnk,
        # Producer (MMA): only CTA 0 runs MMA
        producer_signaling_threads=SignalingThreads.CtaLeader,
    )
    return TmemCResource(
        pipeline_config=tmem_c_pipeline_config,
        name="TmemC",
    )


@cute.jit
def create_tmem_sf_resource(
    isA: bool,
    cluster_shape_vmnk: tuple,
) -> TmemSfResource:
    """Create a TMEM scale-factor resource for SFA or SFB.

    When ``fuse_sf_copy_to_mma`` is False the resource gets an
    ``AsyncUmma`` pipeline (CopySf warp produces, MMA warp consumes).
    When True the resource has no pipeline (dependency-graph-only).
    """
    if cutlass.const_expr(not fuse_sf_copy_to_mma):
        tmem_sf_pipeline_config = PipelineConfig.create_async_umma_pipeline_cfg(
            # Multistage TMEM SF handoff: each stage uses a disjoint TMEM SF slice.
            num_stages=num_sf_stage,
            # CopySf task uses one full warp per SF resource (warp 9 or 10).
            # Producer acquire/commit are called by that warp, so group size must be 32.
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 32),
            # One MMA warp consumes each SF resource.
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            # This kernel issues tcgen05 instructions in 2CTA mode, so all
            # UMMA-related pipelines must stay cluster-scoped (cta_group::2).
            cta_layout_vmnk=cluster_shape_vmnk,
            # Producer (CopySf): only CTA 0 runs S2T copies
            producer_signaling_threads=SignalingThreads.CtaLeader,
            # Consumer (MMA): only CTA 0 runs MMA
            consumer_signaling_threads=SignalingThreads.CtaLeader,
        )
    else:
        tmem_sf_pipeline_config = None

    if cutlass.const_expr(isA):
        return TmemSfResource(
            isA=True,
            pipeline_config=tmem_sf_pipeline_config,
            name="TmemSfA",
        )
    else:
        return TmemSfResource(
            isA=False,
            pipeline_config=tmem_sf_pipeline_config,
            name="TmemSfB",
        )


@cute.jit
def create_gmem_d_resource(mC_mnl: cutlass.Array) -> GmemDResource:
    """
    Create the global memory C (output) resource.
    """
    return GmemDResource(mC_mnl=mC_mnl, name="GmemD")


########################################################
# Task schedule construction helpers
########################################################


@cute.jit
def create_load_task(
    gmem_a_resource: GmemResource,
    gmem_b_resource: GmemResource,
    gmem_sfa_resource: GmemSfResource,
    gmem_sfb_resource: GmemSfResource,
    smem_a_resource: SmemResource,
    smem_b_resource: SmemResource,
    smem_sfa_resource: SmemSfResource,
    smem_sfb_resource: SmemSfResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task (warp 5) — loads all four SMEM buffers.
    """
    src_resources = [
        gmem_a_resource,
        gmem_b_resource,
        gmem_sfa_resource,
        gmem_sfb_resource,
    ]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_schedule(
        gmem_a: MemoryResource,
        gmem_b: MemoryResource,
        gmem_sfa: MemoryResource,
        gmem_sfb: MemoryResource,
        smem_a: MemoryResource,
        smem_b: MemoryResource,
        smem_sfa: MemoryResource,
        smem_sfb: MemoryResource,
        wq: WorkQueue = None,
    ) -> None:
        smem_a.init_load_state()
        smem_b.init_load_state()
        smem_sfa.init_load_state()
        smem_sfb.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_a.init_tile_coords()
                gmem_b.init_tile_coords()
                gmem_sfa.init_tile_coords()
                gmem_sfb.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                    coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                    coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                        gmem_sfa.compute_sfa_coords()
                    )
                    coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                        gmem_sfb.compute_sfb_coords()
                    )
                    smem_a.try_acquire()
                    smem_b.try_acquire()
                    smem_sfa.try_acquire()
                    smem_sfb.try_acquire()
                    smem_a.acquire()
                    smem_b.acquire()
                    smem_sfa.acquire()
                    smem_sfb.acquire()
                    smem_a.tma_load_a(
                        coord_a_k=coord_a_k,
                        coord_a_mn=coord_a_mn,
                        coord_a_l=coord_a_l,
                    )
                    smem_b.tma_load_b(
                        coord_b_k=coord_b_k,
                        coord_b_mn=coord_b_mn,
                        coord_b_l=coord_b_l,
                    )
                    smem_sfa.tma_load_sfa(
                        coord_sfa_sfk=coord_sfa_sfk,
                        coord_sfa_batch=coord_sfa_batch,
                        coord_sfa_l=coord_sfa_l,
                    )
                    smem_sfb.tma_load_sfb(
                        coord_sfb_sfk=coord_sfb_sfk,
                        coord_sfb_batch=coord_sfb_batch,
                        coord_sfb_l=coord_sfb_l,
                    )
                    smem_a.commit()
                    smem_b.commit()
                    smem_sfa.commit()
                    smem_sfb.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_a.init_tile_coords()
            gmem_b.init_tile_coords()
            gmem_sfa.init_tile_coords()
            gmem_sfb.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                    gmem_sfa.compute_sfa_coords()
                )
                coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                    gmem_sfb.compute_sfb_coords()
                )
                smem_a.try_acquire()
                smem_b.try_acquire()
                smem_sfa.try_acquire()
                smem_sfb.try_acquire()
                smem_a.acquire()
                smem_b.acquire()
                smem_sfa.acquire()
                smem_sfb.acquire()
                smem_a.tma_load_a(
                    coord_a_k=coord_a_k,
                    coord_a_mn=coord_a_mn,
                    coord_a_l=coord_a_l,
                )
                smem_b.tma_load_b(
                    coord_b_k=coord_b_k,
                    coord_b_mn=coord_b_mn,
                    coord_b_l=coord_b_l,
                )
                smem_sfa.tma_load_sfa(
                    coord_sfa_sfk=coord_sfa_sfk,
                    coord_sfa_batch=coord_sfa_batch,
                    coord_sfa_l=coord_sfa_l,
                )
                smem_sfb.tma_load_sfb(
                    coord_sfb_sfk=coord_sfb_sfk,
                    coord_sfb_batch=coord_sfb_batch,
                    coord_sfb_l=coord_sfb_l,
                )
                smem_a.commit()
                smem_b.commit()
                smem_sfa.commit()
                smem_sfb.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_schedule(
            gmem_a_resource,
            gmem_b_resource,
            gmem_sfa_resource,
            gmem_sfb_resource,
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
            work_queue,
        )
    else:
        result = load_schedule(
            gmem_a_resource,
            gmem_b_resource,
            gmem_sfa_resource,
            gmem_sfb_resource,
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
        )

    return Task(
        src_resources=src_resources,
        dst_resources=[
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
        ],
        warp_idx=tma_warp_id,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadTask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_a_task(
    gmem_a_resource: GmemResource,
    gmem_sfa_resource: GmemSfResource,
    smem_a_resource: SmemResource,
    smem_sfa_resource: SmemSfResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for A-side (warp 5) — loads SmemA + SmemSfA.
    """
    src_resources = [gmem_a_resource, gmem_sfa_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_a_schedule(
        gmem_a: MemoryResource,
        gmem_sfa: MemoryResource,
        smem_a: MemoryResource,
        smem_sfa: MemoryResource,
        wq: WorkQueue = None,
    ) -> None:
        smem_a.init_load_state()
        smem_sfa.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_a.init_tile_coords()
                gmem_sfa.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                    coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                        gmem_sfa.compute_sfa_coords()
                    )
                    smem_a.try_acquire()
                    smem_sfa.try_acquire()
                    smem_a.acquire()
                    smem_sfa.acquire()
                    smem_a.tma_load_a(
                        coord_a_k=coord_a_k,
                        coord_a_mn=coord_a_mn,
                        coord_a_l=coord_a_l,
                    )
                    smem_sfa.tma_load_sfa(
                        coord_sfa_sfk=coord_sfa_sfk,
                        coord_sfa_batch=coord_sfa_batch,
                        coord_sfa_l=coord_sfa_l,
                    )
                    smem_a.commit()
                    smem_sfa.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_a.init_tile_coords()
            gmem_sfa.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                    gmem_sfa.compute_sfa_coords()
                )
                smem_a.try_acquire()
                smem_sfa.try_acquire()
                smem_a.acquire()
                smem_sfa.acquire()
                smem_a.tma_load_a(
                    coord_a_k=coord_a_k,
                    coord_a_mn=coord_a_mn,
                    coord_a_l=coord_a_l,
                )
                smem_sfa.tma_load_sfa(
                    coord_sfa_sfk=coord_sfa_sfk,
                    coord_sfa_batch=coord_sfa_batch,
                    coord_sfa_l=coord_sfa_l,
                )
                smem_a.commit()
                smem_sfa.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_a_schedule(
            gmem_a_resource,
            gmem_sfa_resource,
            smem_a_resource,
            smem_sfa_resource,
            work_queue,
        )
    else:
        result = load_a_schedule(
            gmem_a_resource,
            gmem_sfa_resource,
            smem_a_resource,
            smem_sfa_resource,
        )

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_a_resource, smem_sfa_resource],
        warp_idx=tma_warp_id,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadATask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_b_task(
    gmem_b_resource: GmemResource,
    gmem_sfb_resource: GmemSfResource,
    smem_b_resource: SmemResource,
    smem_sfb_resource: SmemSfResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for B-side (warp 6) — loads SmemB + SmemSfB.
    """
    src_resources = [gmem_b_resource, gmem_sfb_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_b_schedule(
        gmem_b: MemoryResource,
        gmem_sfb: MemoryResource,
        smem_b: MemoryResource,
        smem_sfb: MemoryResource,
        wq: WorkQueue = None,
    ) -> None:
        smem_b.init_load_state()
        smem_sfb.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_b.init_tile_coords()
                gmem_sfb.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                    coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                        gmem_sfb.compute_sfb_coords()
                    )
                    smem_b.try_acquire()
                    smem_sfb.try_acquire()
                    smem_b.acquire()
                    smem_sfb.acquire()
                    smem_b.tma_load_b(
                        coord_b_k=coord_b_k,
                        coord_b_mn=coord_b_mn,
                        coord_b_l=coord_b_l,
                    )
                    smem_sfb.tma_load_sfb(
                        coord_sfb_sfk=coord_sfb_sfk,
                        coord_sfb_batch=coord_sfb_batch,
                        coord_sfb_l=coord_sfb_l,
                    )
                    smem_b.commit()
                    smem_sfb.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_b.init_tile_coords()
            gmem_sfb.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                    gmem_sfb.compute_sfb_coords()
                )
                smem_b.try_acquire()
                smem_sfb.try_acquire()
                smem_b.acquire()
                smem_sfb.acquire()
                smem_b.tma_load_b(
                    coord_b_k=coord_b_k,
                    coord_b_mn=coord_b_mn,
                    coord_b_l=coord_b_l,
                )
                smem_sfb.tma_load_sfb(
                    coord_sfb_sfk=coord_sfb_sfk,
                    coord_sfb_batch=coord_sfb_batch,
                    coord_sfb_l=coord_sfb_l,
                )
                smem_b.commit()
                smem_sfb.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_b_schedule(
            gmem_b_resource,
            gmem_sfb_resource,
            smem_b_resource,
            smem_sfb_resource,
            work_queue,
        )
    else:
        result = load_b_schedule(
            gmem_b_resource,
            gmem_sfb_resource,
            smem_b_resource,
            smem_sfb_resource,
        )

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_b_resource, smem_sfb_resource],
        warp_idx=tma_warp_id + 1,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadBTask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_a_no_sf_task(
    gmem_a_resource: GmemResource,
    smem_a_resource: SmemResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for A-side (warp 5) — loads SmemA only (no SF).
    """
    src_resources = [gmem_a_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_a_no_sf_schedule(
        gmem_a: MemoryResource, smem_a: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_a.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_a.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                    smem_a.try_acquire()
                    smem_a.acquire()
                    smem_a.tma_load_a(
                        coord_a_k=coord_a_k,
                        coord_a_mn=coord_a_mn,
                        coord_a_l=coord_a_l,
                    )
                    smem_a.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_a.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_a_k, coord_a_mn, coord_a_l = gmem_a.compute_a_coords()
                smem_a.try_acquire()
                smem_a.acquire()
                smem_a.tma_load_a(
                    coord_a_k=coord_a_k,
                    coord_a_mn=coord_a_mn,
                    coord_a_l=coord_a_l,
                )
                smem_a.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_a_no_sf_schedule(gmem_a_resource, smem_a_resource, work_queue)
    else:
        result = load_a_no_sf_schedule(gmem_a_resource, smem_a_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_a_resource],
        warp_idx=tma_warp_id,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadATask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_b_no_sf_task(
    gmem_b_resource: GmemResource,
    smem_b_resource: SmemResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for B-side (warp 6) — loads SmemB only (no SF).
    """
    src_resources = [gmem_b_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_b_no_sf_schedule(
        gmem_b: MemoryResource, smem_b: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_b.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_b.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                    smem_b.try_acquire()
                    smem_b.acquire()
                    smem_b.tma_load_b(
                        coord_b_k=coord_b_k,
                        coord_b_mn=coord_b_mn,
                        coord_b_l=coord_b_l,
                    )
                    smem_b.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_b.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_b_k, coord_b_mn, coord_b_l = gmem_b.compute_b_coords()
                smem_b.try_acquire()
                smem_b.acquire()
                smem_b.tma_load_b(
                    coord_b_k=coord_b_k,
                    coord_b_mn=coord_b_mn,
                    coord_b_l=coord_b_l,
                )
                smem_b.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_b_no_sf_schedule(gmem_b_resource, smem_b_resource, work_queue)
    else:
        result = load_b_no_sf_schedule(gmem_b_resource, smem_b_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_b_resource],
        warp_idx=tma_warp_id + 1,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadBTask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_sf_a_task(
    gmem_sfa_resource: GmemSfResource,
    smem_sfa_resource: SmemSfResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for SfA (warp 7) — loads SmemSfA only.
    """
    src_resources = [gmem_sfa_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_sfa_schedule(
        gmem_sfa: MemoryResource, smem_sfa: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_sfa.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_sfa.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                        gmem_sfa.compute_sfa_coords()
                    )
                    smem_sfa.try_acquire()
                    smem_sfa.acquire()
                    smem_sfa.tma_load_sfa(
                        coord_sfa_sfk=coord_sfa_sfk,
                        coord_sfa_batch=coord_sfa_batch,
                        coord_sfa_l=coord_sfa_l,
                    )
                    smem_sfa.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_sfa.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_sfa_sfk, coord_sfa_batch, coord_sfa_l = (
                    gmem_sfa.compute_sfa_coords()
                )
                smem_sfa.try_acquire()
                smem_sfa.acquire()
                smem_sfa.tma_load_sfa(
                    coord_sfa_sfk=coord_sfa_sfk,
                    coord_sfa_batch=coord_sfa_batch,
                    coord_sfa_l=coord_sfa_l,
                )
                smem_sfa.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_sfa_schedule(gmem_sfa_resource, smem_sfa_resource, work_queue)
    else:
        result = load_sfa_schedule(gmem_sfa_resource, smem_sfa_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_sfa_resource],
        warp_idx=tma_warp_id + 2,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadSfATask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_sf_b_task(
    gmem_sfb_resource: GmemSfResource,
    smem_sfb_resource: SmemSfResource,
    num_k_tiles: int,
    num_load_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the TMA load task for SfB (warp 8) — loads SmemSfB only.
    """
    src_resources = [gmem_sfb_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def load_sfb_schedule(
        gmem_sfb: MemoryResource, smem_sfb: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_sfb.init_load_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                gmem_sfb.init_tile_coords()
                with domain_loop(0, num_k_tiles, 1):
                    coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                        gmem_sfb.compute_sfb_coords()
                    )
                    smem_sfb.try_acquire()
                    smem_sfb.acquire()
                    smem_sfb.tma_load_sfb(
                        coord_sfb_sfk=coord_sfb_sfk,
                        coord_sfb_batch=coord_sfb_batch,
                        coord_sfb_l=coord_sfb_l,
                    )
                    smem_sfb.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            gmem_sfb.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_sfb_sfk, coord_sfb_batch, coord_sfb_l = (
                    gmem_sfb.compute_sfb_coords()
                )
                smem_sfb.try_acquire()
                smem_sfb.acquire()
                smem_sfb.tma_load_sfb(
                    coord_sfb_sfk=coord_sfb_sfk,
                    coord_sfb_batch=coord_sfb_batch,
                    coord_sfb_l=coord_sfb_l,
                )
                smem_sfb.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = load_sfb_schedule(gmem_sfb_resource, smem_sfb_resource, work_queue)
    else:
        result = load_sfb_schedule(gmem_sfb_resource, smem_sfb_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[smem_sfb_resource],
        warp_idx=tma_warp_id + 3,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadSfBTask",
        debug_print=debug_print,
    )


@cute.jit
def create_copy_sf_a_task(
    smem_sfa_resource: SmemSfResource,
    tmem_sfa_resource: TmemSfResource,
    num_k_tiles: int,
    num_copy_sf_warps: int,
    copy_sf_a_warp_id: int,
    work_queue: WorkQueue = None,
) -> Task:
    """Create the CopySfA task — S2T copy SFA from SMEM to TMEM.

    Only used when ``fuse_sf_copy_to_mma`` is False.
    """
    src_resources = [smem_sfa_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def copy_sfa_schedule(
        smem_sfa: MemoryResource, tmem_sfa: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_sfa.init_descriptors()
        tmem_sfa.init_copy_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                with domain_loop(0, num_k_tiles, 1):
                    smem_sfa.try_wait()
                    smem_sfa.wait()
                    desc_a_s2t_base = smem_sfa.build_sfa_s2t_descriptor()
                    tmem_sfa.try_acquire()
                    tmem_sfa.acquire()
                    tmem_sfa.copy_sfa(desc_a_s2t_base=desc_a_s2t_base)
                    smem_sfa.release()
                    tmem_sfa.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            with domain_loop(0, num_k_tiles, 1):
                smem_sfa.try_wait()
                smem_sfa.wait()
                desc_a_s2t_base = smem_sfa.build_sfa_s2t_descriptor()
                tmem_sfa.try_acquire()
                tmem_sfa.acquire()
                tmem_sfa.copy_sfa(desc_a_s2t_base=desc_a_s2t_base)
                smem_sfa.release()
                tmem_sfa.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = copy_sfa_schedule(smem_sfa_resource, tmem_sfa_resource, work_queue)
    else:
        result = copy_sfa_schedule(smem_sfa_resource, tmem_sfa_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[tmem_sfa_resource],
        warp_idx=copy_sf_a_warp_id,
        num_warps=num_copy_sf_warps,
        schedule=result,
        num_registers=40,
        name="CopySfATask",
        debug_print=debug_print,
    )


@cute.jit
def create_copy_sf_b_task(
    smem_sfb_resource: SmemSfResource,
    tmem_sfb_resource: TmemSfResource,
    num_k_tiles: int,
    num_copy_sf_warps: int,
    copy_sf_b_warp_id: int,
    work_queue: WorkQueue = None,
) -> Task:
    """Create the CopySfB task — S2T copy SFB from SMEM to TMEM.

    Only used when ``fuse_sf_copy_to_mma`` is False.
    """
    src_resources = [smem_sfb_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def copy_sfb_schedule(
        smem_sfb: MemoryResource, tmem_sfb: MemoryResource, wq: WorkQueue = None
    ) -> None:
        smem_sfb.init_descriptors()
        tmem_sfb.init_copy_state()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                with domain_loop(0, num_k_tiles, 1):
                    smem_sfb.try_wait()
                    smem_sfb.wait()
                    desc_b_s2t_base = smem_sfb.build_sfb_s2t_descriptor()
                    tmem_sfb.try_acquire()
                    tmem_sfb.acquire()
                    tmem_sfb.copy_sfb(desc_b_s2t_base=desc_b_s2t_base)
                    smem_sfb.release()
                    tmem_sfb.commit()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            with domain_loop(0, num_k_tiles, 1):
                smem_sfb.try_wait()
                smem_sfb.wait()
                desc_b_s2t_base = smem_sfb.build_sfb_s2t_descriptor()
                tmem_sfb.try_acquire()
                tmem_sfb.acquire()
                tmem_sfb.copy_sfb(desc_b_s2t_base=desc_b_s2t_base)
                smem_sfb.release()
                tmem_sfb.commit()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = copy_sfb_schedule(smem_sfb_resource, tmem_sfb_resource, work_queue)
    else:
        result = copy_sfb_schedule(smem_sfb_resource, tmem_sfb_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[tmem_sfb_resource],
        warp_idx=copy_sf_b_warp_id,
        num_warps=num_copy_sf_warps,
        schedule=result,
        num_registers=40,
        name="CopySfBTask",
        debug_print=debug_print,
    )


@cute.jit
def create_mma_task(
    smem_a_resource: SmemResource,
    smem_b_resource: SmemResource,
    smem_sfa_resource: SmemSfResource,
    smem_sfb_resource: SmemSfResource,
    tmem_c_resource: TmemCResource,
    num_k_tiles: int,
    num_mma_warps: int,
    tmem_sfa_resource: TmemSfResource = None,
    tmem_sfb_resource: TmemSfResource = None,
    work_queue: WorkQueue = None,
) -> Task:
    """Create the MMA compute task (warp 4).

    When ``fuse_sf_copy_to_mma`` is True (default) the MMA task consumes
    SmemSfA/SmemSfB directly (S2T copies fused inside producer_work) and
    TmemSfA/TmemSfB are passive dst_resources for the dependency graph.

    When False the MMA task no longer consumes SmemSf* directly; instead
    it consumes TmemSfA/TmemSfB (whose data has been produced by the
    separate CopySf* tasks via the AsyncUmma pipeline).
    """
    if cutlass.const_expr(fuse_sf_copy_to_mma):
        src_resources = [
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
        ]
        # TmemSfA/TmemSfB are dsts. We copy SFA/SFB from SMEM to TMEM in the producer_work() method.
        # Since it is done in the same warp as MMA, the ordering is provided in the schedule.
        # The pipeline between TmemSfA/TmemSfB and TmemC is not needed.
        dst_resources = [tmem_c_resource, tmem_sfa_resource, tmem_sfb_resource]

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            src_resources += [work_queue]

        @schedule
        def mma_schedule(
            smem_a: MemoryResource,
            smem_b: MemoryResource,
            smem_sfa: MemoryResource,
            smem_sfb: MemoryResource,
            tmem_c: MemoryResource,
            tmem_sfa: MemoryResource,
            tmem_sfb: MemoryResource,
            wq: WorkQueue = None,
        ) -> None:
            smem_a.init_descriptors()
            smem_b.init_descriptors()
            smem_sfa.init_descriptors()
            smem_sfb.init_descriptors()
            tmem_c.init_accumulator()
            tmem_sfa.init_copy_state()
            tmem_sfb.init_copy_state()

            if cutlass.const_expr(use_clc_dynamic_scheduler):
                with work_tile_loop(wq):
                    tmem_c.init_work_tile_state()
                    tmem_c.try_acquire()
                    tmem_c.acquire()
                    with domain_loop(0, num_k_tiles, 1):
                        smem_a.try_wait()
                        smem_b.try_wait()
                        smem_sfa.try_wait()
                        smem_sfb.try_wait()
                        smem_a.wait()
                        smem_b.wait()
                        smem_sfa.wait()
                        smem_sfb.wait()
                        desc_a_mma_base = smem_a.build_a_mma_descriptor()
                        desc_b_mma_base = smem_b.build_b_mma_descriptor()
                        desc_a_s2t_base = smem_sfa.build_sfa_s2t_descriptor()
                        desc_b_s2t_base = smem_sfb.build_sfb_s2t_descriptor()
                        tmem_sfa.copy_sfa(desc_a_s2t_base=desc_a_s2t_base)
                        tmem_sfb.copy_sfb(desc_b_s2t_base=desc_b_s2t_base)
                        tmem_c.mma_fused(
                            desc_a_mma_base=desc_a_mma_base,
                            desc_b_mma_base=desc_b_mma_base,
                        )
                        smem_a.release()
                        smem_b.release()
                        smem_sfa.release()
                        smem_sfb.release()
                    tmem_c.commit()
                    wq.try_wait()
                    wq.wait()
                    wq.get_and_advance_work_tile()
                    wq.release()
            else:
                tmem_c.try_acquire()
                tmem_c.acquire()
                with domain_loop(0, num_k_tiles, 1):
                    smem_a.try_wait()
                    smem_b.try_wait()
                    smem_sfa.try_wait()
                    smem_sfb.try_wait()
                    smem_a.wait()
                    smem_b.wait()
                    smem_sfa.wait()
                    smem_sfb.wait()
                    desc_a_mma_base = smem_a.build_a_mma_descriptor()
                    desc_b_mma_base = smem_b.build_b_mma_descriptor()
                    desc_a_s2t_base = smem_sfa.build_sfa_s2t_descriptor()
                    desc_b_s2t_base = smem_sfb.build_sfb_s2t_descriptor()
                    tmem_sfa.copy_sfa(desc_a_s2t_base=desc_a_s2t_base)
                    tmem_sfb.copy_sfb(desc_b_s2t_base=desc_b_s2t_base)
                    tmem_c.mma_fused(
                        desc_a_mma_base=desc_a_mma_base,
                        desc_b_mma_base=desc_b_mma_base,
                    )
                    smem_a.release()
                    smem_b.release()
                    smem_sfa.release()
                    smem_sfb.release()
                tmem_c.commit()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            result = mma_schedule(
                smem_a_resource,
                smem_b_resource,
                smem_sfa_resource,
                smem_sfb_resource,
                tmem_c_resource,
                tmem_sfa_resource,
                tmem_sfb_resource,
                work_queue,
            )
        else:
            result = mma_schedule(
                smem_a_resource,
                smem_b_resource,
                smem_sfa_resource,
                smem_sfb_resource,
                tmem_c_resource,
                tmem_sfa_resource,
                tmem_sfb_resource,
            )
    else:
        src_resources = [
            smem_a_resource,
            smem_b_resource,
            tmem_sfa_resource,
            tmem_sfb_resource,
        ]
        dst_resources = [tmem_c_resource]
        if cutlass.const_expr(use_clc_dynamic_scheduler):
            src_resources += [work_queue]

        @schedule
        def mma_schedule(
            smem_a: MemoryResource,
            smem_b: MemoryResource,
            tmem_sfa: MemoryResource,
            tmem_sfb: MemoryResource,
            tmem_c: MemoryResource,
            wq: WorkQueue = None,
        ) -> None:
            smem_a.init_descriptors()
            smem_b.init_descriptors()
            tmem_sfa.init_sfa_stage_offset()
            tmem_sfb.init_sfb_stage_offset()
            tmem_c.init_accumulator()

            if cutlass.const_expr(use_clc_dynamic_scheduler):
                with work_tile_loop(wq):
                    tmem_c.init_work_tile_state()
                    tmem_c.try_acquire()
                    tmem_c.acquire()
                    with domain_loop(0, num_k_tiles, 1):
                        smem_a.try_wait()
                        smem_b.try_wait()
                        tmem_sfa.try_wait()
                        tmem_sfb.try_wait()
                        smem_a.wait()
                        smem_b.wait()
                        tmem_sfa.wait()
                        tmem_sfb.wait()
                        desc_a_mma_base = smem_a.build_a_mma_descriptor()
                        desc_b_mma_base = smem_b.build_b_mma_descriptor()
                        sfa_stage_col_offset = tmem_sfa.stage_sfa_offset()
                        sfb_stage_col_offset = tmem_sfb.stage_sfb_offset()
                        tmem_c.mma_nonfused(
                            desc_a_mma_base=desc_a_mma_base,
                            desc_b_mma_base=desc_b_mma_base,
                            sfa_stage_col_offset=sfa_stage_col_offset,
                            sfb_stage_col_offset=sfb_stage_col_offset,
                        )
                        smem_a.release()
                        smem_b.release()
                        tmem_sfa.release()
                        tmem_sfb.release()
                    tmem_c.commit()
                    wq.try_wait()
                    wq.wait()
                    wq.get_and_advance_work_tile()
                    wq.release()
            else:
                tmem_c.try_acquire()
                tmem_c.acquire()
                with domain_loop(0, num_k_tiles, 1):
                    smem_a.try_wait()
                    smem_b.try_wait()
                    tmem_sfa.try_wait()
                    tmem_sfb.try_wait()
                    smem_a.wait()
                    smem_b.wait()
                    tmem_sfa.wait()
                    tmem_sfb.wait()
                    desc_a_mma_base = smem_a.build_a_mma_descriptor()
                    desc_b_mma_base = smem_b.build_b_mma_descriptor()
                    sfa_stage_col_offset = tmem_sfa.stage_sfa_offset()
                    sfb_stage_col_offset = tmem_sfb.stage_sfb_offset()
                    tmem_c.mma_nonfused(
                        desc_a_mma_base=desc_a_mma_base,
                        desc_b_mma_base=desc_b_mma_base,
                        sfa_stage_col_offset=sfa_stage_col_offset,
                        sfb_stage_col_offset=sfb_stage_col_offset,
                    )
                    smem_a.release()
                    smem_b.release()
                    tmem_sfa.release()
                    tmem_sfb.release()
                tmem_c.commit()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            result = mma_schedule(
                smem_a_resource,
                smem_b_resource,
                tmem_sfa_resource,
                tmem_sfb_resource,
                tmem_c_resource,
                work_queue,
            )
        else:
            result = mma_schedule(
                smem_a_resource,
                smem_b_resource,
                tmem_sfa_resource,
                tmem_sfb_resource,
                tmem_c_resource,
            )

    return Task(
        src_resources=src_resources,
        dst_resources=dst_resources,
        warp_idx=mma_warp_id,
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
    num_k_tiles: int,
    num_epilogue_warps: int,
    work_queue: WorkQueue = None,
) -> Task:
    """
    Create the epilogue store task (warps 0-3).
    """
    src_resources = [tmem_c_resource]
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        src_resources += [work_queue]

    @schedule
    def store_schedule(
        tmem_c: MemoryResource, gmem_d: MemoryResource, wq: WorkQueue = None
    ) -> None:
        t2r_rmem = tmem_c.init_t2r_buffer()

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            with work_tile_loop(wq):
                with domain_loop(0, num_k_tiles, 1):
                    pass
                tmem_c.try_wait()
                tmem_c.wait()
                for subtile_idx in cutlass.range_constexpr(epi_subtile_cnt):
                    t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
                    gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
                tmem_c.release()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()
        else:
            with domain_loop(0, num_k_tiles, 1):
                pass
            tmem_c.try_wait()
            tmem_c.wait()
            for subtile_idx in cutlass.range_constexpr(epi_subtile_cnt):
                t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
                gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
            tmem_c.release()

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        result = store_schedule(tmem_c_resource, gmem_d_resource, work_queue)
    else:
        result = store_schedule(tmem_c_resource, gmem_d_resource)

    return Task(
        src_resources=src_resources,
        dst_resources=[gmem_d_resource],
        warp_idx=0,
        num_warps=num_epilogue_warps,
        schedule=result,
        num_registers=160,
        name="StoreTask",
        debug_print=debug_print,
    )


# ═══════════════════════════════════════════════════════════════════════
# GPU device kernel
# ═══════════════════════════════════════════════════════════════════════


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfa_desc0: cutlass.GridConstant[cuda.TensorMap],
    tma_sfb_desc0: cutlass.GridConstant[cuda.TensorMap],
    mC_mnl: cutlass.Array,
    problem_size: tuple,
    tile_sched_params: object,
) -> None:
    """
    GPU device kernel performing the batched block-scaled GEMM using TS.

    Execution flow:
    1. Allocate SMEM buffers for A/B/SFA/SFB and TMEM pointer slot.
    2. Create resources (GmemA, GmemB, GmemSfA, GmemSfB,
       SmemA, SmemB, SmemSfA, SmemSfB, TmemSfA, TmemSfB, TmemC, GmemD).
    3. Create tasks (Load/LoadA+LoadB, [CopySfA+CopySfB], Mma, Store).
    4. TaskManager setup: initialise pipeline barriers.
    5. Cluster sync + TMEM allocation.
    6. TaskManager run: execute all tasks.
    7. TMEM deallocation with 2-CTA synchronisation.
    """
    m, n, k, l = problem_size  # noqa: E741

    # Warp and block setup
    num_epilogue_warps = len(epilog_warp_id)
    num_mma_warps = 1
    num_load_warps = 1
    num_scheduler_warps = 1 if use_clc_dynamic_scheduler else 0

    # Decompose cluster shape into (V, M, N, K) format
    num_mma_ctas = 2 if cluster_shape_mnk[0] >= 2 else 1
    cluster_shape_vmnk = (
        num_mma_ctas,
        cluster_shape_mnk[0] // num_mma_ctas,
        cluster_shape_mnk[1],
        cluster_shape_mnk[2],
    )

    k_tile_cnt = cute.ceil_div(k, mma_tiler_mnk[2])

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)
    cta_rank_in_cluster = cute.arch.block_idx_in_cluster()

    ########################################################
    # Resource construction
    ########################################################
    gmem_a_resource = create_gmem_resource(isA=True)
    gmem_b_resource = create_gmem_resource(isA=False)
    gmem_sfa_resource = create_gmem_sf_resource(isA=True)
    gmem_sfb_resource = create_gmem_sf_resource(isA=False)

    tma_a_ptr = tma_a_desc.get_ptr()
    tma_b_ptr = tma_b_desc.get_ptr()
    tma_sfa_ptr = tma_sfa_desc0.get_ptr()
    tma_sfb_ptr = tma_sfb_desc0.get_ptr()

    smem_a_resource = create_smem_resource(
        isA=True,
        tma_desc=tma_a_ptr,
        stage_bytes_val=a_stage_bytes,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )
    smem_b_resource = create_smem_resource(
        isA=False,
        tma_desc=tma_b_ptr,
        stage_bytes_val=b_stage_bytes,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )
    smem_sfa_resource = create_smem_sf_resource(
        isA=True,
        tma_desc=tma_sfa_ptr,
        stage_bytes_val=sfa_stage_bytes,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )
    smem_sfb_resource = create_smem_sf_resource(
        isA=False,
        tma_desc=tma_sfb_ptr,
        stage_bytes_val=sfb_stage_bytes,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )

    # ─────────────────────────────────────────────────────────────────
    # Unified SMEM layout (data buffers + infrastructure slots)
    # ─────────────────────────────────────────────────────────────────
    allocator = SmemAllocator()
    allocator.add_resource(smem_a_resource)
    allocator.add_resource(smem_b_resource)
    allocator.add_resource(smem_sfa_resource)
    allocator.add_resource(smem_sfb_resource)
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )
    dealloc_mbar_alloc = allocator.add(
        SmemAllocation("tmem_dealloc_mbar", dtype=cutlass.Int64, alignment=8)
    )
    allocator.compute_layout()

    tmem_c_resource = create_tmem_c_resource(
        cluster_shape_vmnk,
        num_epilogue_warps,
    )

    tmem_sfa_resource = create_tmem_sf_resource(
        isA=True,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )
    tmem_sfb_resource = create_tmem_sf_resource(
        isA=False,
        cluster_shape_vmnk=cluster_shape_vmnk,
    )

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c_resource)
    tmem_allocator.add_resource(tmem_sfa_resource)
    tmem_allocator.add_resource(tmem_sfb_resource)
    tmem_allocator.compute_layout()

    gmem_d_resource = create_gmem_d_resource(mC_mnl)
    work_queue = None
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        # CLC response payload lives in shared memory and is consumed by WorkQueue.
        # Allocate per-stage CLC response buffers (16 bytes per stage).
        clc_response_ptr = cute.arch.alloc_smem(cutlass.Int128, num_scheduler_stages)
        work_queue = create_work_queue(
            tile_sched_params=tile_sched_params,
            cluster_shape_vmnk=cluster_shape_vmnk,
            num_consumer_warps=compute_padded_warp_count(),
            clc_response_ptr=clc_response_ptr,
        )

    ########################################################
    # Task schedule construction
    ########################################################
    load_task = None
    load_a_task = None
    load_b_task = None
    load_sf_a_task = None
    load_sf_b_task = None
    if cutlass.const_expr(use_two_tma_warps):
        if cutlass.const_expr(use_two_sf_load_warps):
            # A-only on warp 5, B-only on warp 6, SfA on warp 7, SfB on warp 8
            load_a_task = create_load_a_no_sf_task(
                gmem_a_resource,
                smem_a_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
            load_b_task = create_load_b_no_sf_task(
                gmem_b_resource,
                smem_b_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
            load_sf_a_task = create_load_sf_a_task(
                gmem_sfa_resource,
                smem_sfa_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
            load_sf_b_task = create_load_sf_b_task(
                gmem_sfb_resource,
                smem_sfb_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
        else:
            # A+SfA on warp 5, B+SfB on warp 6
            load_a_task = create_load_a_task(
                gmem_a_resource,
                gmem_sfa_resource,
                smem_a_resource,
                smem_sfa_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
            load_b_task = create_load_b_task(
                gmem_b_resource,
                gmem_sfb_resource,
                smem_b_resource,
                smem_sfb_resource,
                k_tile_cnt,
                num_load_warps,
                work_queue=work_queue,
            )
    else:
        # Single load task (warp 5): loads all four SMEM buffers
        load_task = create_load_task(
            gmem_a_resource,
            gmem_b_resource,
            gmem_sfa_resource,
            gmem_sfb_resource,
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
            k_tile_cnt,
            num_load_warps,
            work_queue=work_queue,
        )

    mma_task = create_mma_task(
        smem_a_resource,
        smem_b_resource,
        smem_sfa_resource,
        smem_sfb_resource,
        tmem_c_resource,
        k_tile_cnt,
        num_mma_warps,
        tmem_sfa_resource=tmem_sfa_resource,
        tmem_sfb_resource=tmem_sfb_resource,
        work_queue=work_queue,
    )
    store_task = create_store_task(
        tmem_c_resource,
        gmem_d_resource,
        k_tile_cnt,
        num_epilogue_warps,
        work_queue=work_queue,
    )

    copy_sf_a_task = None
    copy_sf_b_task = None
    if cutlass.const_expr(not fuse_sf_copy_to_mma):
        # Separate warp for each S2T SF copy direction
        copy_sf_a_task = create_copy_sf_a_task(
            smem_sfa_resource,
            tmem_sfa_resource,
            k_tile_cnt,
            num_copy_sf_warps=1,
            copy_sf_a_warp_id=9,
            work_queue=work_queue,
        )
        copy_sf_b_task = create_copy_sf_b_task(
            smem_sfb_resource,
            tmem_sfb_resource,
            k_tile_cnt,
            num_copy_sf_warps=1,
            copy_sf_b_warp_id=10,
            work_queue=work_queue,
        )

    task_list = [mma_task, store_task]
    if cutlass.const_expr(use_two_tma_warps):
        task_list += [load_a_task, load_b_task]
        if cutlass.const_expr(use_two_sf_load_warps):
            task_list += [load_sf_a_task, load_sf_b_task]
            if cutlass.const_expr(not fuse_sf_copy_to_mma):
                task_list += [copy_sf_a_task, copy_sf_b_task]
    else:
        task_list += [load_task]

    max_warp_end = 0
    for task in task_list:
        max_warp_end = max(max_warp_end, task.warp_idx + task.num_warps)

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        work_schedule_task = create_work_schedule_task(
            work_queue=work_queue,
            scheduler_warp_idx=max_warp_end,
        )
        task_list.append(work_schedule_task)
        max_warp_end += 1

    num_padding_warps = ((max_warp_end + 3) // 4) * 4 - max_warp_end
    if cutlass.const_expr(num_padding_warps > 0):
        padding_src_resources = []
        if cutlass.const_expr(use_clc_dynamic_scheduler):
            padding_src_resources = [work_queue]

        @schedule
        def padding_schedule(wq: WorkQueue = None) -> None:
            if cutlass.const_expr(use_clc_dynamic_scheduler):
                with work_tile_loop(wq):
                    with domain_loop(0, k_tile_cnt, 1):
                        pass
                    wq.try_wait()
                    wq.wait()
                    wq.get_and_advance_work_tile()
                    wq.release()
            else:
                with domain_loop(0, k_tile_cnt, 1):
                    pass

        if cutlass.const_expr(use_clc_dynamic_scheduler):
            padding_sched = padding_schedule(work_queue)
        else:
            padding_sched = padding_schedule()

        padding_task = Task(
            src_resources=padding_src_resources,
            dst_resources=[],
            warp_idx=max_warp_end,
            num_warps=num_padding_warps,
            schedule=padding_sched,
            num_registers=40,
            name="PaddingTask",
            debug_print=debug_print,
        )

        task_list.append(padding_task)

    ########################################################
    # TaskManager construction and execution
    ########################################################

    # Create task manager with resource dependency graph
    if cutlass.const_expr(fuse_sf_copy_to_mma):
        # Fused: SmemSf* consumed directly by MMA task, TmemSf* are passive
        # dst_resources of MMA for the dependency graph only.
        resource_dependency_graph = {
            smem_a_resource: [gmem_a_resource],
            smem_b_resource: [gmem_b_resource],
            smem_sfa_resource: [gmem_sfa_resource],
            smem_sfb_resource: [gmem_sfb_resource],
            tmem_sfa_resource: [smem_sfa_resource],
            tmem_sfb_resource: [smem_sfb_resource],
            tmem_c_resource: [
                smem_a_resource,
                smem_b_resource,
                smem_sfa_resource,
                smem_sfb_resource,
            ],
            gmem_d_resource: [tmem_c_resource],
        }
    else:
        # Non-fused: CopySf tasks move SmemSf* → TmemSf*.
        # MMA task consumes TmemSf* (not SmemSf*).
        resource_dependency_graph = {
            smem_a_resource: [gmem_a_resource],
            smem_b_resource: [gmem_b_resource],
            smem_sfa_resource: [gmem_sfa_resource],
            smem_sfb_resource: [gmem_sfb_resource],
            tmem_sfa_resource: [smem_sfa_resource],
            tmem_sfb_resource: [smem_sfb_resource],
            tmem_c_resource: [
                smem_a_resource,
                smem_b_resource,
                tmem_sfa_resource,
                tmem_sfb_resource,
            ],
            gmem_d_resource: [tmem_c_resource],
        }

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        dynamic_consumers = [
            smem_a_resource,
            smem_b_resource,
            smem_sfa_resource,
            smem_sfb_resource,
            tmem_sfa_resource,
            tmem_sfb_resource,
            tmem_c_resource,
            gmem_d_resource,
        ]
        for resource in dynamic_consumers:
            resource_dependency_graph[resource] = resource_dependency_graph[
                resource
            ] + [work_queue]
        resource_dependency_graph[work_queue] = [work_queue]

    task_manager = TaskManager(
        tasks=task_list,
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )

    # ─────────────────────────────────────────────────────────────────
    # Setup resources and tasks, initialise barriers
    # ─────────────────────────────────────────────────────────────────
    task_manager.setup_resources_and_tasks()

    # Derive infrastructure pointers from the unified SMEM block.
    # tmem_ptr_i32 for ResourceContext is auto-populated by TaskManager
    # in setup_resources_and_tasks() via SmemAllocator.tmem_ptr_alloc.
    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)
    tmem_dealloc_mbar = allocator.get(dealloc_mbar_alloc)

    # Initialise TMEM deallocation mbarrier (not managed by any resource)
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(tmem_dealloc_mbar, 32)

    # Fence mbarrier init before cluster sync
    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # ─────────────────────────────────────────────────────────────────
    # TMEM allocation and intra-CTA sync
    # ─────────────────────────────────────────────────────────────────
    num_tmem_cols = 512
    tmem_allocator_warp_id = 0

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols, group="cta_2")
        prims.tcgen05_relinquish_alloc_permit(group="cta_2")

    # Sync MMA + epilogue warps (+ CopySf warps when non-fused) after TMEM allocation
    needs_tmem_sync = store_task.is_selected() or mma_task.is_selected()
    if cutlass.const_expr(not fuse_sf_copy_to_mma):
        needs_tmem_sync = (
            needs_tmem_sync
            or copy_sf_a_task.is_selected()
            or copy_sf_b_task.is_selected()
        )
    if needs_tmem_sync:
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    # ─────────────────────────────────────────────────────────────────
    # Main execution
    # ─────────────────────────────────────────────────────────────────
    task_manager.run()

    # ─────────────────────────────────────────────────────────────────
    # TMEM deallocation with 2-CTA sync
    # ─────────────────────────────────────────────────────────────────
    prims.barrier_cta_sync(0)
    if warp_idx == tmem_allocator_warp_id:
        # 2CTA TMEM deallocation synchronisation
        peer_cta_rank = cta_rank_in_cluster ^ 1
        peer_mbar = prims.mapa(tmem_dealloc_mbar, peer_cta_rank)
        prims.mbarrier_arrive(peer_mbar, count=1, scope=prims.MemScope.CTA)
        while not prims.mbarrier_try_wait_parity(
            tmem_dealloc_mbar, 0, time_limit=10000000
        ):
            pass

        tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), cutlass.Float32)
        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols, group="cta_2")

    return


# ═══════════════════════════════════════════════════════════════════════
# Host-side helpers
# ═══════════════════════════════════════════════════════════════════════


def compute_grid_and_tile_scheduler(c_tensor: cute.Tensor) -> tuple[object, tuple]:
    """
    Compute launch grid and scheduler params for static or CLC dynamic mode.
    """
    num_ctas_m = cute.ceil_div(c_tensor.shape[0], mma_tiler_mnk_per_cta[0])
    num_ctas_n = cute.ceil_div(c_tensor.shape[1], mma_tiler_mnk[1])
    num_ctas_l = c_tensor.shape[2]

    if use_clc_dynamic_scheduler:
        tile_sched_params = utils.ClcDynamicPersistentTileSchedulerParams(
            (num_ctas_m, num_ctas_n, num_ctas_l),
            cluster_shape_mnk,
            1,
            True,
        )
        grid = utils.ClcDynamicPersistentTileScheduler.get_grid_shape(tile_sched_params)
    else:
        # Keep the non-CLC path identical to the original static launch.
        # This placeholder is ignored because WorkQueue is not used.
        tile_sched_params = (0, 0, 0)
        grid = (num_ctas_m, num_ctas_n, num_ctas_l)

    return tile_sched_params, grid


@cute.jit
def gemm(
    a_ptr: cute.Pointer,
    b_ptr: cute.Pointer,
    sfa_ptr: cute.Pointer,
    sfb_ptr: cute.Pointer,
    c_ptr: cute.Pointer,
    problem_size: tuple,
    stream: cuda_driver.CUstream,
) -> None:
    """
    Host function: creates tensors, TMA descriptors, and launches kernel.
    """
    c_layout_enum = cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
    m, n, k, l = problem_size  # noqa: E741

    # Keep stride-1 dimension first to match current host-op descriptor logic.
    a_layout = cute.make_layout(
        (cute.assume(k, 32), m, l),
        stride=(1, cute.assume(k, 32), cute.assume(m * k, 32)),
    )
    a_tensor = cute.make_tensor(a_ptr, a_layout)
    b_layout = cute.make_layout(
        (cute.assume(k, 32), n, l),
        stride=(1, cute.assume(k, 32), cute.assume(n * k, 32)),
    )
    b_tensor = cute.make_tensor(b_ptr, b_layout)
    c_layout = cute.make_layout(
        (cute.assume(m, 32), cute.assume(n, 16), l),
        stride=(cute.assume(n, 16), 1, cute.assume(m * n, 512)),
    )
    c_tensor = cute.make_tensor(c_ptr, c_layout)

    # Create TMA descriptors using native FP4 TMA format
    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        tensor=a_tensor,
        box_dims=(mma_tiler_mnk[2], mma_tiler_mnk_per_cta[0], 1),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        dtype=cutlass.Float4E2M1FNx2,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        tensor=b_tensor,
        box_dims=(mma_tiler_mnk[2], mma_tiler_mnk[1] // cluster_shape_mnk[0], 1),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        dtype=cutlass.Float4E2M1FNx2,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )

    # Scaling factor TMA descriptors
    rest_k = k // sf_vec_size // 4
    rest_m = m // mma_tiler_mnk_per_cta[0]
    rest_n = n // (mma_tiler_mnk[1] // 2)
    sfa_flat_layout_fp16 = cute.make_layout(
        (256, rest_k, rest_m, l),
        stride=(1, 256, 256 * rest_k, 256 * rest_k * rest_m),
    )
    sfa_tensor_fp16 = cute.make_tensor(
        cute.recast_ptr(sfa_ptr, dtype=cutlass.Float16), sfa_flat_layout_fp16
    )

    sfb_flat_layout_fp16 = cute.make_layout(
        (256, rest_k, rest_n, l),
        stride=(1, 256, 256 * rest_k, 256 * rest_k * rest_n),
    )
    sfb_tensor_fp16 = cute.make_tensor(
        cute.recast_ptr(sfb_ptr, dtype=cutlass.Float16), sfb_flat_layout_fp16
    )

    tma_sfa_desc0 = cuda.create_tensor_map_tiled_from_view(
        tensor=sfa_tensor_fp16,
        box_dims=(256, 4, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        dtype=cutlass.Uint16,
    )
    tma_sfb_desc0 = cuda.create_tensor_map_tiled_from_view(
        tensor=sfb_tensor_fp16,
        box_dims=(256, 4, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        dtype=cutlass.Uint16,
    )

    tile_sched_params, grid = compute_grid_and_tile_scheduler(c_tensor)
    block_size = cute.arch.WARP_SIZE * compute_padded_warp_count()

    # Launch the kernel
    kernel(
        tma_a_desc,
        tma_b_desc,
        tma_sfa_desc0,
        tma_sfb_desc0,
        c_tensor,
        problem_size,
        tile_sched_params,
    ).launch(
        grid=grid,
        block=[block_size, 1, 1],
        cluster=cluster_shape_mnk,
        stream=stream,
    )
    return


# ═══════════════════════════════════════════════════════════════════════
# Scale factor layout conversion helper (unchanged)
# ═══════════════════════════════════════════════════════════════════════


def ceil_div(a: int, b: int) -> int:
    """
    Integer ceiling division: ``(a + b - 1) // b``.
    """
    return (a + b - 1) // b


@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_ptr: cute.Pointer,
    sf_mma_ptr: cute.Pointer,
    mn: int,
    sf_k: int,
    l: int,  # noqa: E741
    mma_shape: tuple,
) -> None:
    """
    Device layout transform: scale factors from MKL row-major to MMA tile layout.
    """
    mma_permute_order = (3, 4, 1, 5, 2, 0)
    permuted_shape = tuple(mma_shape[i] for i in mma_permute_order)
    cute_layout = cute.make_ordered_layout(permuted_shape, order=(2, 1, 4, 0, 3, 5))

    sf_ref_tensor = cute.make_tensor(
        sf_ref_ptr, cute.make_layout((mn, sf_k, l), stride=(sf_k, 1, mn * sf_k))
    )
    sf_mma_tensor = cute.make_tensor(sf_mma_ptr, cute_layout)

    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]
    pass


def to_blocked(input_matrix: torch.Tensor) -> torch.Tensor:
    """
    Host helper: rearrange a dense matrix into NVFP4 blocked scale-factor layout.
    """
    rows, cols = input_matrix.shape
    n_row_blocks = ceil_div(rows, 128)
    n_col_blocks = ceil_div(cols, 4)
    padded = input_matrix
    blocks = padded.view(n_row_blocks, 128, n_col_blocks, 4).permute(0, 2, 1, 3)
    rearranged = blocks.reshape(-1, 4, 32, 4).transpose(1, 2).reshape(-1, 32, 16)
    return rearranged.flatten()


# ═══════════════════════════════════════════════════════════════════════
# Host runners and CLI
# ═══════════════════════════════════════════════════════════════════════


def run_nvfp4_gemm(
    mnkl: Tuple[int, int, int, int],
    tolerance: float,
) -> None:
    """
    Prepare A/B/SFA/SFB/C tensors, launch GPU kernel, and verify.
    """
    # Keep compile-time derived globals in sync with feature flags.
    refresh_derived_config()

    print("=" * 60)
    print("Launching Blackwell Dense BlockScaled GEMM Test (TS)")
    print("-" * 60)
    print(f"Input dimensions (m, n, k, l): {mnkl}")
    print(f"    m (rows): {mnkl[0]}")
    print(f"    n (cols): {mnkl[1]}")
    print(f"    k (inner): {mnkl[2]}")
    print(f"    l (batch): {mnkl[3]}")
    print("Data Types & Precision:")
    print(f"    Input matrices (A, B): {ab_dtype}")
    print(f"    Scale factors (SFA, SFB): {sf_dtype}")
    print(f"    Output matrix (C): {c_dtype}")
    print(f"    Scale factor vector size: {sf_vec_size}")
    print("Tile and cluster configuration:")
    print(f"    MMA tiler (M, N, K): {mma_tiler_mnk}")
    print(f"    Cluster shape (M, N, K): {cluster_shape_mnk}")
    print(f"    Two TMA warps: {use_two_tma_warps}")
    print(f"    Two SF load warps: {use_two_sf_load_warps}")
    print(f"    CLC dynamic scheduler: {use_clc_dynamic_scheduler}")
    print(f"Validation tolerance: {tolerance}")
    print("=" * 60)

    m, n, k, l = mnkl  # noqa: E741

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    # Create tensor A/B/C
    a_ref = torch.randint(
        0, 2, (l, m, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)
    b_ref = torch.randint(
        0, 2, (l, n, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)

    a_ref_f4 = a_ref.view(torch.float4_e2m1fn_x2)
    b_ref_f4 = b_ref.view(torch.float4_e2m1fn_x2)

    c_torch = torch.randn((l, m, n), dtype=torch.float16, device="cuda").permute(
        1, 2, 0
    )

    def create_ref_scale_factor_tensor(
        l: int,  # noqa: E741
        mn: int,
        sf_k: int,
    ) -> torch.Tensor:
        ref_shape = (l, mn, sf_k)
        ref_permute_order = (1, 2, 0)
        ref_f8_random_int = torch.randint(1, 3, ref_shape, dtype=torch.int8)
        ref_f8_torch_tensor_cpu = ref_f8_random_int.to(dtype=torch.float8_e4m3fn)
        ref_f8_torch_tensor_cpu_permuted = ref_f8_torch_tensor_cpu.permute(
            *ref_permute_order
        )
        return ref_f8_torch_tensor_cpu_permuted

    def create_cute_scale_factor_tensor(
        l: int,  # noqa: E741
        mn: int,
        sf_k: int,
        ref_f8_torch_tensor_cpu_permuted: torch.Tensor,
    ) -> torch.Tensor:
        atom_m = (32, 4)
        atom_k = 4
        mma_shape = (
            l,
            ceil_div(mn, atom_m[0] * atom_m[1]),
            ceil_div(sf_k, atom_k),
            atom_m[0],
            atom_m[1],
            atom_k,
        )
        mma_permute_order = (3, 4, 1, 5, 2, 0)

        rand_int_tensor = torch.randint(0, 2, mma_shape, dtype=torch.int8)
        cute_f8_torch_tensor_cpu = rand_int_tensor.to(dtype=torch.float8_e4m3fn)
        cute_f8_torch_tensor_cpu = cute_f8_torch_tensor_cpu.permute(*mma_permute_order)

        cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
            make_ptr(
                cutlass.Float8E4M3FN,
                ref_f8_torch_tensor_cpu_permuted.data_ptr(),
                cutlass.AddressSpace.gmem,
                assumed_align=32,
            ),
            make_ptr(
                cutlass.Float8E4M3FN,
                cute_f8_torch_tensor_cpu.data_ptr(),
                cutlass.AddressSpace.gmem,
                assumed_align=32,
            ),
            mn,
            sf_k,
            l,
            mma_shape,
        )
        return cute_f8_torch_tensor_cpu.cuda()

    sf_k = ceil_div(k, sf_vec_size)
    sfa_ref = create_ref_scale_factor_tensor(l, m, sf_k)
    sfb_ref = create_ref_scale_factor_tensor(l, n, sf_k)
    sfa_torch = create_cute_scale_factor_tensor(l, m, sf_k, sfa_ref)
    sfb_torch = create_cute_scale_factor_tensor(l, n, sf_k, sfb_ref)

    # Initialise Stream
    current_stream = cutlass_torch.default_stream()
    a_ptr = make_ptr(
        ab_dtype, a_ref_f4.data_ptr(), cutlass.AddressSpace.gmem, assumed_align=16
    )
    b_ptr = make_ptr(
        ab_dtype, b_ref_f4.data_ptr(), cutlass.AddressSpace.gmem, assumed_align=16
    )
    c_ptr = make_ptr(
        c_dtype, c_torch.data_ptr(), cutlass.AddressSpace.gmem, assumed_align=32
    )
    sfa_ptr = make_ptr(
        sf_dtype, sfa_torch.data_ptr(), cutlass.AddressSpace.gmem, assumed_align=32
    )
    sfb_ptr = make_ptr(
        sf_dtype, sfb_torch.data_ptr(), cutlass.AddressSpace.gmem, assumed_align=32
    )

    # Compile and launch
    compiled_gemm = cute.compile[cute.FrontendNext](
        gemm,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        (m, n, k, l),
        current_stream,
    )
    compiled_gemm(a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, (m, n, k, l), current_stream)

    # Reference computation
    ref = torch.empty(
        (l, m, n),
        dtype=torch.float16,
        device="cuda",
    ).permute(1, 2, 0)
    for l_idx in range(l):
        scale_a = to_blocked(sfa_ref[:, :, l_idx])
        scale_b = to_blocked(sfb_ref[:, :, l_idx])
        res = torch._scaled_mm(
            a_ref_f4[:, :, l_idx],
            b_ref_f4[:, :, l_idx].transpose(0, 1),
            scale_a.cuda(),
            scale_b.cuda(),
            bias=None,
            out_dtype=torch.float16,
        )
        ref[:, :, l_idx] = res
    torch.testing.assert_close(c_torch, ref, atol=tolerance, rtol=1e-02)


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of Sm100 Dense BlockScaled GEMM (TS version)."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(8192, 8192, 1024, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--use-two-tma-warps", action="store_true", help="Use two TMA warps"
    )
    parser.add_argument(
        "--use-two-sf-load-warps",
        action="store_true",
        help="Use two separate SF load warps (requires --use-two-tma-warps)",
    )
    parser.add_argument(
        "--no-fuse-sf-copy-to-mma",
        action="store_true",
        help="Extract S2T SF copies into separate CopySfA/CopySfB tasks "
        "(requires --use-two-sf-load-warps)",
    )
    parser.add_argument(
        "--clc-dynamic-scheduler",
        action="store_true",
        help="Use CLC dynamic persistent scheduler instead of static launch grid",
    )
    args = parser.parse_args()
    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    m, n, k, _ = args.mnkl
    if m % 256 != 0:
        parser.error("M must be multiples of 256 (got m={})".format(m))
    if n % 256 != 0:
        parser.error("N must be multiples of 256 (got n={})".format(n))
    if k % 256 != 0:
        parser.error("k must be a multiple of 256 (got k={})".format(k))

    globals()["use_two_tma_warps"] = args.use_two_tma_warps
    globals()["use_two_sf_load_warps"] = args.use_two_sf_load_warps
    globals()["fuse_sf_copy_to_mma"] = not args.no_fuse_sf_copy_to_mma
    globals()["use_clc_dynamic_scheduler"] = args.clc_dynamic_scheduler
    refresh_derived_config()

    if args.use_two_sf_load_warps and not args.use_two_tma_warps:
        parser.error("--use-two-sf-load-warps requires --use-two-tma-warps")
    if args.no_fuse_sf_copy_to_mma and not args.use_two_sf_load_warps:
        parser.error("--no-fuse-sf-copy-to-mma requires --use-two-sf-load-warps")

    run_nvfp4_gemm(
        args.mnkl,
        args.tolerance,
    )
    print("PASS")
