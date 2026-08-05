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

"""Clustered CUTLASS Python DSL TS FP16/BF16 GEMM tutorial kernel.

Read ``01_fp16_bf16_gemm_3.py`` first. This file expands the minimal
GEMM into a production-shaped clustered TS kernel:

  - 2-CTA MMA pairs compute each 256x256 output tile.
  - TMA multicast distributes A tiles across pair columns and B tiles across
    pair rows.
  - ``SmemA`` and ``SmemB`` use cluster-scoped TMA/UMMA pipelines because one
    CTA's TMA operation can write into peer CTAs' SMEM.
  - ``TmemCResource`` remains scoped to each 2-CTA MMA group.
  - Optional fallback-cluster path builds both preferred and fallback
    pipelines before the runtime branch, keeping pipeline group sizes
    compile-time constants.

This is the CUTLASS Python DSL-level clustered counterpart to the CuteDSL
clustered kernel in ``02_fp16_bf16_gemm_3_cute_cluster.py``.

Resource/task flow:

                   +-------------------+
                   |   GmemAbResource  |
                   |  tile coordinates |
                   +----+----------+---+
                        |          |
        LoadATask:      |          |      LoadBTask:
        PDL wait,       |          |      compute B coords,
        compute A coords|          |      TMA B into SMEM
        TMA A into SMEM |          |
                        v          v
                   +----+----+ +---+-----+
                   |  SmemA  | |  SmemB  |
                   | TmaUmma | | TmaUmma |
                   +--+------+ +---+-----+
                      |            |
                      | MmaTask waits A/B full stages,
                      | builds descriptors, issues MMA
                      v
                +-----+-----+
                |   TmemC   |
                | UmmaAsync |
                +-----+-----+
                      |
                      | StoreTask waits accumulator,
                      | Tmem to Regs load, optional bias, GMEM store
                      v
                 +----+----+
                 |  GmemD  |
                 | output  |
                 +---------+

   WorkQueue: every task advances the same persistent tile stream.
   PdlWait -> LoadATask before the loop; LoadATask -> PdlLaunch after the loop.
"""

import argparse
from typing import Tuple, Optional, Type, Callable, Any
from functools import lru_cache
from dataclasses import dataclass, field
from pathlib import Path
import sys

import cuda.bindings.driver as cuda_driver
import cutlass
import cutlass.experimental.cuda as cuda
from cutlass import Numeric
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass.cute.runtime import from_dlpack, make_fake_stream

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
    PdlLaunchBarrier,
    PdlWaitBarrier,
    PipelineConfig,
    StageInfo,
    TaskLocalVariable,
    TileSchedulerConfig,
    WorkQueue,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    schedule,
    domain_loop,
    work_tile_loop,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

# Make the repository sitecustomize importable for direct script execution.
_REPO_ROOT = Path(__file__).resolve().parents[10]
_repo_root_str = str(_REPO_ROOT)
if _repo_root_str not in sys.path:
    sys.path.insert(0, _repo_root_str)
try:
    import sitecustomize  # noqa: F401
except Exception:
    pass

_DTYPE_MAP = {"fp16": cutlass.Float16, "bf16": cutlass.BFloat16}
_SUPPORTED_CLUSTER_DIMS = (1, 2, 4)


def _set_io_dtype(dtype_name: str) -> None:
    normalized = dtype_name.strip().lower()
    if normalized not in _DTYPE_MAP:
        choices = ", ".join(_DTYPE_MAP.keys())
        raise ValueError(
            f"Unsupported dtype '{dtype_name}'. Expected one of: {choices}"
        )
    globals()["io_dtype"] = _DTYPE_MAP[normalized]


def _get_io_dtype_name() -> str:
    if io_dtype is cutlass.BFloat16:
        return "bf16"
    return "fp16"


def _validate_cluster_shape(
    shape: tuple[int, int, int],
    *,
    option_name: str,
) -> None:
    if len(shape) != 3:
        raise ValueError(f"{option_name} must contain exactly 3 values")
    cm, cn, ck = shape
    if cm not in _SUPPORTED_CLUSTER_DIMS or cn not in _SUPPORTED_CLUSTER_DIMS:
        raise ValueError(
            f"{option_name} M and N dimensions must be one of "
            f"{_SUPPORTED_CLUSTER_DIMS}, got {shape}"
        )
    if ck != 1:
        raise ValueError(f"{option_name} K dimension must be 1, got {shape}")
    if cm % num_mma_ctas != 0:
        raise ValueError(f"{option_name} cluster_m must be divisible by {num_mma_ctas}")


def _validate_fallback_cluster_shape(
    fallback_shape: tuple[int, int, int],
    preferred_shape: tuple[int, int, int],
) -> None:
    _validate_cluster_shape(
        fallback_shape,
        option_name="--fallback-cluster",
    )
    for fb_dim, preferred_dim in zip(fallback_shape, preferred_shape):
        if preferred_dim % fb_dim != 0:
            raise ValueError(
                "--fallback-cluster must divide --cluster in every dimension; "
                f"got fallback={fallback_shape}, cluster={preferred_shape}"
            )


io_dtype = _DTYPE_MAP["fp16"]
acc_dtype = cutlass.Float32
cluster_shape_mnk = (2, 1, 1)

# Cluster decomposition for CTA_2 MMA pairs.
num_mma_ctas = 2
cluster_m = cluster_shape_mnk[0]
cluster_n = cluster_shape_mnk[1]
cluster_size = cluster_m * cluster_n
num_pairs = cluster_size // num_mma_ctas
num_pair_rows = cluster_m // num_mma_ctas
num_pair_cols = cluster_n

# Clustered CTA_2 MMA tile shapes: instruction shape, K-tile shape,
# and per-CTA tile.
mma_inst_shape_mnk = (256, 256, 16)
mma_tiler_mnk = (256, 256, 64)
mma_tiler_mnk_per_cta = (128, mma_tiler_mnk[1] // num_mma_ctas, 64)
super_tile_m = num_pair_rows * mma_tiler_mnk[0]
super_tile_n = num_pair_cols * mma_tiler_mnk[1]

# Precomputed multicast mask templates (compile-time constants).
# A: bits for all pair-columns at stride num_mma_ctas
# B: bits for all pair-rows at stride num_pair_cols * num_mma_ctas
_a_mcast_template = sum(1 << (num_mma_ctas * c) for c in range(num_pair_cols))
_b_mcast_template = sum(
    1 << (num_pair_cols * num_mma_ctas * r) for r in range(num_pair_rows)
)

threads_in_epilogue = 128  # epilogue threads per cta

# Pipeline stage configuration
ab_stages = 3
epi_stages = 2
acc_stages = 2
num_scheduler_stages = 2
debug_print = False

# Scheduling mode option: set to True for CLC dynamic persistent,
# False for static persistent.
# Can also be overridden via --clc-dynamic-scheduler CLI flag.
use_clc_dynamic_scheduler = False

# Fallback cluster: when set, the kernel supports a smaller fallback cluster.
# The hardware launches preferred-sized clusters when possible, falling back
# to this shape on GPCs that cannot accommodate the preferred size.
# Must divide cluster_shape_mnk in each dimension (e.g. (2,1,1) for (4,2,1)).
fallback_cluster_shape_mnk = None


########################################################
# Resource definitions
########################################################


@dataclass
class GmemAbResource(MemoryResource):
    """Global-memory A/B input resource (read-only source).

    This resource has no producer side — it simply exposes the global A/B
    tensors so that downstream consumers can compute TMA load coordinates.

    ``compute_coords`` computes the TMA load coordinates for the current work
    tile and publishes them to the downstream SMEM resource.
    """

    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    cta_rank_in_cluster: Any = field(init=False, default=None)
    bx: Any = field(init=False, default=None)
    by: Any = field(init=False, default=None)
    bz: Any = field(init=False, default=None)

    def __init__(
        self,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.coord_k = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="K coordinate for the current TMA load tile.",
        )
        self.coord_m = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="M coordinate for the current TMA load tile.",
        )
        self.coord_n = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="N coordinate for the current TMA load tile.",
        )
        self.bx, self.by, self.bz = cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)
        self.cta_rank_in_cluster = cutlass.Int32(0)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        self.bx, self.by, self.bz = stage_info.work_tile.tile_idx
        self.cta_rank_in_cluster = (self.by % cluster_shape_mnk[1]) * (
            cluster_shape_mnk[0]
        ) + (self.bx % cluster_shape_mnk[0])

    @consumer_work(returns=(coord_k, coord_m, coord_n))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        mma_tile_coord_mnl = (
            self.bx // cluster_shape_mnk[0],
            self.by // cluster_shape_mnk[1],
            self.bz,
        )

        pair_id = self.cta_rank_in_cluster // num_mma_ctas
        rank_in_pair = self.cta_rank_in_cluster % num_mma_ctas
        pair_row = pair_id // num_pair_cols
        pair_col = pair_id % num_pair_cols

        coord_k = stage_info.loop_offset * mma_tiler_mnk[2]
        coord_m = (
            mma_tile_coord_mnl[0] * super_tile_m
            + pair_row * mma_tiler_mnk[0]
            + rank_in_pair * mma_tiler_mnk_per_cta[0]
        )
        coord_n = (
            mma_tile_coord_mnl[1] * super_tile_n
            + pair_col * mma_tiler_mnk[1]
            + rank_in_pair * mma_tiler_mnk_per_cta[1]
        )
        return coord_k, coord_m, coord_n


@dataclass
class SmemAbResource(MemoryResource):
    """Shared-memory A or B buffer filled by an asynchronous TMA load.

    The producer side issues a TMA bulk-copy instruction to move one operand
    from global memory into staged shared-memory buffers, using the
    coordinates provided by GmemAbResource's consumer_work().

    The consumer side builds SMEM descriptors that the Tensor Cores (MMA)
    read during the MMA phase.

    Producer auxiliary work initializes SMEM state before TMA loads. Consumer
    auxiliary work initializes the same state before descriptor construction.
    """

    tma_desc_a: cutlass.Pointer = field(init=False, default=None)
    tma_desc_b: cutlass.Pointer = field(init=False, default=None)
    operand: cutlass.Constexpr[str] = field(init=False, default=None)
    shared_smem: Any = field(init=False, default=None)
    copy_elems: Any = field(init=False, default=None)
    cta_rank_in_cluster: Any = field(init=False, default=None)
    rank_in_pair: Any = field(init=False, default=None)
    tma_mcast_mask: Any = field(init=False, default=None)
    is_leader: Any = field(init=False, default=None)
    desc_a_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    desc_b_base: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    # Actual-cluster multicast parameters (may differ from module globals
    # when running on a fallback cluster).
    act_num_pair_cols: Any = field(init=False, default=None)
    act_a_mcast_template: Any = field(init=False, default=None)
    act_b_mcast_template: Any = field(init=False, default=None)

    # SMEM allocation declarations (offsets set by SmemAllocator)
    _alloc: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        tma_desc_a: cutlass.Pointer,
        tma_desc_b: cutlass.Pointer,
        operand: str,
        act_num_pair_cols: int = None,
        act_a_mcast_template: int = None,
        act_b_mcast_template: int = None,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
        self.tma_desc_b = tma_desc_b
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
        if operand not in {"a", "b"}:
            raise ValueError(
                f"SmemAbResource operand must be 'a' or 'b', got {operand}"
            )
        self.operand = operand
        if operand == "a":
            copy_elems = mma_tiler_mnk_per_cta[0] * mma_tiler_mnk[2]
        else:
            copy_elems = mma_tiler_mnk_per_cta[1] * mma_tiler_mnk[2]
        self.copy_elems = cutlass.Int32(copy_elems)
        self.act_num_pair_cols = cutlass.Int32(
            act_num_pair_cols if act_num_pair_cols is not None else num_pair_cols
        )
        self.act_a_mcast_template = cutlass.Int32(
            act_a_mcast_template
            if act_a_mcast_template is not None
            else _a_mcast_template
        )
        self.act_b_mcast_template = cutlass.Int32(
            act_b_mcast_template
            if act_b_mcast_template is not None
            else _b_mcast_template
        )
        elem_bytes = io_dtype.width // 8
        smem_bytes = copy_elems * ab_stages * elem_bytes
        self._alloc = SmemAllocation(f"smem_{operand}", smem_bytes, alignment=128)
        nullptr = cutlass.inttoptr(0, mem_space=3, dtype=io_dtype)
        self.shared_smem = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(self.copy_elems * ab_stages,),
            addrspace=3,
        )
        self.cta_rank_in_cluster = cutlass.Int32(0)
        self.rank_in_pair = cutlass.Int32(0)
        self.tma_mcast_mask = cutlass.Int32(0)
        self.is_leader = cutlass.Boolean(False)

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        # Derive SMEM pointers from the unified allocator base.
        smem_base = stage_info.context.smem_base
        smem_elems = self.copy_elems * ab_stages
        self.shared_smem = cutlass.Array(
            smem_base.data_ptr() + self._alloc.offset,
            dtype=io_dtype,
            shape=(smem_elems,),
            addrspace=3,
        )

        # WORKAROUND: materialize multicast parameters as
        # staged values before using them in dynamic control flow. Keep the
        # object fields constexpr so the preferred/fallback branch that owns
        # this resource cannot overwrite the other branch's constants.
        act_num_pair_cols = cutlass.Int32(self.act_num_pair_cols)
        act_a_mcast_template = cutlass.Int32(self.act_a_mcast_template)
        act_b_mcast_template = cutlass.Int32(self.act_b_mcast_template)

        # Use actual-cluster rank for multicast masks and leader determination,
        # since TMA multicast only reaches CTAs within the actual cluster.
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()

        pair_id = self.cta_rank_in_cluster // num_mma_ctas
        self.rank_in_pair = self.cta_rank_in_cluster % num_mma_ctas
        pair_row = pair_id // act_num_pair_cols
        pair_col = pair_id % act_num_pair_cols

        if cutlass.const_expr(self.operand == "a"):
            base = pair_row * act_num_pair_cols * num_mma_ctas + self.rank_in_pair
            self.tma_mcast_mask = act_a_mcast_template << base
            self.is_leader = pair_col == 0
        else:
            base = pair_col * num_mma_ctas + self.rank_in_pair
            self.tma_mcast_mask = act_b_mcast_template << base
            self.is_leader = pair_row == 0

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptors(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    def get_smem_requirements(self):
        return [self._alloc]

    def create_pipeline(self, pipeline_config: PipelineConfig) -> object:
        """Override to set a cluster-wide consumer_mask on the empty barrier.

        PipelineTmaUmma.create() sets consumer_mask = producer_mask (the
        TMA multicast pattern), which only covers CTAs sharing A or B data.
        For the empty barrier, tcgen05_commit must reach ALL CTAs in the
        cluster so that every pair leader's arrival is counted.  Without
        this, diagonal pairs (e.g. CTA 0 and CTA 6 in a 4x2 cluster)
        would miss each other's commits and deadlock.
        """
        pipe = super().create_pipeline(pipeline_config)
        layout = pipeline_config.cta_layout_vmnk
        if layout is not None:
            cluster_total = 1
            for d in layout:
                cluster_total *= d
            if cluster_total > 2:
                object.__setattr__(pipe, "consumer_mask", (1 << cluster_total) - 1)
        return pipe

    @consumer_work(returns=desc_a_base)
    @cute.jit
    def build_desc_a(
        self,
        stage_info: StageInfo,
    ) -> cutlass.Int64:
        desc_a_base = cutlass.Int64(0)
        if self.rank_in_pair == 0:
            sA_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
            desc_a_base = prims.Tcgen05SmemDesc.build(
                sA_curr,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )
        return desc_a_base

    @consumer_work(returns=desc_b_base)
    @cute.jit
    def build_desc_b(
        self,
        stage_info: StageInfo,
    ) -> cutlass.Int64:
        desc_b_base = cutlass.Int64(0)
        if self.rank_in_pair == 0:
            sB_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
            desc_b_base = prims.Tcgen05SmemDesc.build(
                sB_curr,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )
        return desc_b_base

    @producer_work
    @cute.jit
    def tma_load_a(
        self,
        stage_info: StageInfo,
        *,
        coord_k: cutlass.Int32,
        coord_m: cutlass.Int32,
    ) -> None:
        if prims.elect_sync():
            sA_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
            if self.is_leader:
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    sA_curr,
                    self.tma_desc_a,
                    (coord_k, coord_m),
                    stage_info.barrier,
                    [],
                    multicast_mask=self.tma_mcast_mask,
                    group=prims.CTAGroup.CTA_2,
                )

    @producer_work
    @cute.jit
    def tma_load_b(
        self,
        stage_info: StageInfo,
        *,
        coord_k: cutlass.Int32,
        coord_n: cutlass.Int32,
    ) -> None:
        if prims.elect_sync():
            sB_curr = self.shared_smem.subview(self.copy_elems * stage_info.stage_idx)
            if self.is_leader:
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    sB_curr,
                    self.tma_desc_b,
                    (coord_k, coord_n),
                    stage_info.barrier,
                    [],
                    multicast_mask=self.tma_mcast_mask,
                    group=prims.CTAGroup.CTA_2,
                )


@dataclass
class TmemCResource(MemoryResource):
    """Tensor-memory (TMEM) accumulator written by MMA and read by the epilogue.

    The producer side executes tcgen05 MMA instructions that accumulate
    results into TMEM.  The consumer side loads TMEM sub-tiles into
    register memory (RMEM) so the epilogue warps can convert and store
    the final output.

    Producer auxiliary work initializes TMEM state for MMA. Consumer auxiliary
    work initializes the same state for epilogue loads. Per-work-tile producer
    auxiliary work resets the MMA accumulate flag.
    """

    # this must be a constant, but I think putting it here is making it into a variable
    t2r_inst_shape: cutlass.Constexpr[int] = field(init=False, default=None)

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    scale_d: Any = field(init=False, default=None)
    idesc: Any = field(init=False, default=None)
    tmem_raw_addr: Any = field(init=False, default=None)
    cta_rank_in_cluster: Any = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(
        self,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        # Pick the right T2R instruction configuration
        self.t2r_inst_shape = "32x32b"
        # This requires cta_n size to be a multiple of 32
        self.t2r_inst_repx = 32
        self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * acc_stages)
        self.t2r_rmem = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.full([self.t2r_inst_repx], 0.0, cutlass.Float32),
            docs="Register-memory subtile loaded from TMEM for the epilogue.",
        )
        self.scale_d = cutlass.Boolean(False)
        self.idesc = cutlass.Int32(0)
        self.tmem_raw_addr = cutlass.Int32(0)
        self.cta_rank_in_cluster = cutlass.Int32(0)

    @cute.jit
    def _init_tmem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        # PTX: https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instruction-descriptor
        self.idesc = prims.Tcgen05InstrDesc.build(
            a_dtype=io_dtype,
            b_dtype=io_dtype,
            c_dtype=cutlass.Float32,
            n_dim=mma_inst_shape_mnk[1],
            m_dim=mma_inst_shape_mnk[0],
        )
        self.tmem_raw_addr = context.tmem_ptr_i32.load()
        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        # Initialize scale_d before dynamic while loops so the MLIR
        # structure stays consistent when the work-tile reset reassigns it.
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

    def get_tmem_requirements(self):
        return [self._alloc_acc]

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_subtile(
        self, stage_info: StageInfo, *, subtile_idx: cutlass.Constexpr[int]
    ) -> cutlass.Float32:
        warp_idx = cute.arch.warp_idx()
        # Compute the tensor memory address
        base_col_id = (self.tmem_raw_addr & 0xFFFF) + (
            stage_info.stage_idx * mma_tiler_mnk[1]
        )
        base_row_id = self.tmem_raw_addr >> 16
        # Each warp accesses different TMEM rows
        # (warp 0 -> row 0-31, warp 1 -> row 32-63, etc.)
        row_id_with_warp_offset = base_row_id + warp_idx * 32
        current_tmem_raw_addr = (row_id_with_warp_offset << 16) | base_col_id

        # TMEM -> RMEM
        # step1: compute tensor memory address for subtile
        curr_tmem_raw_subtile_addr = (
            current_tmem_raw_addr + subtile_idx * self.t2r_inst_repx
        )

        # step2: get TMEM pointer and load data as Float32
        tmem_ptr = prims.make_tmem_ptr(curr_tmem_raw_subtile_addr, cutlass.Float32)

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
        if self.cta_rank_in_cluster % num_mma_ctas == 0:
            tmem_ptr = prims.make_tmem_ptr(self.tmem_raw_addr, acc_dtype)
            tmem_ptr_for_mma = (
                tmem_ptr.data_ptr() + stage_info.stage_idx * mma_tiler_mnk[1]
            )
            tmem_ptr_curr = cutlass.Array(
                tmem_ptr_for_mma,
                dtype=cutlass.Int32,
                addrspace=6,
            )

            # Execute one K-block worth of MMA instructions
            num_k_blocks = mma_tiler_mnk[2] // mma_inst_shape_mnk[2]
            for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                # move 16 * 2 bytes per iteration, address excludes 4 LSBs
                inc_bytes_per_iter = mma_inst_shape_mnk[2] * io_dtype.width // 8
                increment = (inc_bytes_per_iter * k_block_idx) >> 4
                desc_a = desc_a_base + increment
                desc_b = desc_b_base + increment

                if prims.elect_sync():
                    # submit MMA from one elected thread from leader CTA only
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_2,
                        tmem_ptr_curr,
                        desc_a,
                        desc_b,
                        self.idesc,
                        self.scale_d,
                    )
                # switch to accumulate after first iteration
                self.scale_d = True


@dataclass
class GmemDResource(MemoryResource):
    """Global-memory D output resource (write-only sink).

    This resource has no consumer side — it is the final destination of
    the dataflow pipeline.  The producer side takes RMEM data from
    TmemCResource, optionally applies a column bias of shape [N], converts
    FP32 -> FP16/BF16, and issues vectorized global stores.

    Methods
    -------
    producer_work()
        Applies optional bias, converts FP32 accumulators to FP16/BF16, and
        writes the result to global memory D with 128-bit vectorized stores.

    The producer-side t2r_rmem slot is auto-allocated from the upstream
    TmemCResource TaskLocalVariable flow.
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    bias: Any = field(init=False, default=None)
    mC_mn: Any = field(init=False, default=None)
    gC: Any = field(init=False, default=None)
    vsize: cutlass.Constexpr[int] = field(init=False, default=None)

    def __init__(
        self,
        mC_mn: cute.Tensor,
        bias: Optional[cute.Tensor] = None,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.t2r_inst_repx = 32
        self.bias = bias
        # Global C view for direct STG stores
        self.mC_mn = mC_mn
        self.gC = cutlass.make_array_view(mC_mn)
        self.vsize = 256 // self.gC.dtype.width

    # Pure sink — producer-side t2r_rmem slot is auto-allocated by
    # Task.init_variables from upstream TmemCResource.

    @producer_work
    @cute.jit
    def store(
        self,
        stage_info: StageInfo,
        *,
        t2r_rmem: cutlass.Float32,
        subtile_idx: cutlass.Constexpr[int],
    ) -> None:
        bx, by, bz = stage_info.work_tile.tile_idx
        cta_rank_for_coords = (by % cluster_shape_mnk[1]) * cluster_shape_mnk[0] + (
            bx % cluster_shape_mnk[0]
        )
        mma_tile_coord_mnl = (
            bx // cluster_shape_mnk[0],
            by // cluster_shape_mnk[1],
            bz,
        )

        pair_id = cta_rank_for_coords // num_mma_ctas
        rank_in_pair = cta_rank_for_coords % num_mma_ctas
        pair_row = pair_id // num_pair_cols
        pair_col = pair_id % num_pair_cols

        coordc_m = (
            mma_tile_coord_mnl[0] * super_tile_m
            + pair_row * mma_tiler_mnk[0]
            + rank_in_pair * mma_tiler_mnk_per_cta[0]
        )
        coordc_n = mma_tile_coord_mnl[1] * super_tile_n + pair_col * mma_tiler_mnk[1]
        tx, _, _ = cute.arch.thread_idx()
        row = coordc_m + tx
        col = coordc_n + subtile_idx * 32
        num_rows = self.mC_mn.shape[0]
        num_cols = self.mC_mn.shape[1]
        gC_ptr = self.mC_mn.iterator.raw_ptr()
        bias_ptr = self.bias.iterator.raw_ptr() if self.bias is not None else None

        if row < num_rows:
            row_offset = cutlass.Int64(row) * cutlass.Int64(num_cols)
            for j in cutlass.range_constexpr(self.t2r_inst_repx // self.vsize):
                chunk_col = col + j * self.vsize
                vec_f32 = t2r_rmem[j * self.vsize : j * self.vsize + self.vsize]

                if chunk_col + self.vsize <= num_cols:
                    # Keep the common fully in-bounds path vectorized.
                    if cutlass.const_expr(self.bias is not None):
                        bias_vec = (
                            (bias_ptr + cutlass.Int64(chunk_col))
                            .load(count=self.vsize, alignment=16)
                            .to(cutlass.Float32)
                        )
                        vec_f32 = vec_f32 + bias_vec
                    (gC_ptr + row_offset + cutlass.Int64(chunk_col)).store(
                        vec_f32.to(io_dtype), alignment=16
                    )
                else:
                    # Tail tiles fall back to scalar predication so N need not be padded.
                    for i in cutlass.range_constexpr(self.vsize):
                        col_idx = chunk_col + i
                        if col_idx < num_cols:
                            value = vec_f32[i]
                            if cutlass.const_expr(self.bias is not None):
                                value = value + (
                                    bias_ptr + cutlass.Int64(col_idx)
                                ).load().to(cutlass.Float32)
                            (gC_ptr + row_offset + cutlass.Int64(col_idx)).store(
                                value.to(io_dtype)
                            )


# ──────────────────────────────────────────────────────────────────────
# Resource construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_gmem_ab_resource() -> GmemAbResource:
    """
    Create the global memory A/B input resource.
    """
    return GmemAbResource(name="GmemAb")


def create_smem_ab_resource(
    tma_a_desc: cutlass.Pointer,
    tma_b_desc: cutlass.Pointer,
    operand: str,
    cluster_shape_vmnk: cute.Layout,
    act_num_pairs: int = None,
    act_num_pair_cols: int = None,
    act_a_mcast_template: int = None,
    act_b_mcast_template: int = None,
) -> SmemAbResource:
    """
    Create a shared memory A or B resource with TMA+UMMA async pipeline.
    """
    if act_num_pairs is None:
        act_num_pairs = num_pairs
    sA_copy_bytes = mma_tiler_mnk_per_cta[0] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    sB_copy_bytes = mma_tiler_mnk_per_cta[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    if operand == "a":
        tma_copy_bytes_per_cta = sA_copy_bytes
    elif operand == "b":
        tma_copy_bytes_per_cta = sB_copy_bytes
    else:
        raise ValueError(f"operand must be 'a' or 'b', got {operand}")

    # TmaUmma full barriers are armed per UMMA CTA group. Even when the
    # cluster has several independent pairs, each pair leader only receives
    # the V-group's TMA transaction bytes for its own full barrier.
    num_tma_copy_bytes = tma_copy_bytes_per_cta * num_mma_ctas

    num_umma_consumers = act_num_pairs
    smem_ab_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=num_tma_copy_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_umma_consumers
        ),
        cta_layout_vmnk=cluster_shape_vmnk,
        consumer_signaling_threads=SignalingThreads.CtaLeader,
        num_bytes_per_warp_per_cta=tma_copy_bytes_per_cta,
    )
    return SmemAbResource(
        tma_desc_a=tma_a_desc,
        tma_desc_b=tma_b_desc,
        operand=operand,
        act_num_pair_cols=act_num_pair_cols,
        act_a_mcast_template=act_a_mcast_template,
        act_b_mcast_template=act_b_mcast_template,
        pipeline_config=smem_ab_pipeline_config,
        name=f"Smem{operand.upper()}",
    )


@cute.jit
def create_tmem_c_resource(
    num_epilogue_warps: int, cluster_shape_vmnk: cute.Layout
) -> TmemCResource:
    """
    Create the TMEM accumulator resource with UMMA async pipeline.
    """
    # Accumulator is pair-scoped (2-CTA): only the 2 CTAs in the MMA group
    # participate, not the full cluster.
    tmem_c_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread, size=num_epilogue_warps * 32 * num_mma_ctas
    )
    tmem_c_pipeline_config = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=tmem_c_pipeline_consumer_group,
        cta_layout_vmnk=cluster_shape_vmnk,
        producer_signaling_threads=SignalingThreads.CtaLeader,
    )
    return TmemCResource(
        pipeline_config=tmem_c_pipeline_config,
        name="TmemC",
    )


@cute.jit
def create_gmem_d_resource(
    mC_mn: cute.Tensor,
    bias: Optional[cute.Tensor] = None,
) -> GmemDResource:
    """
    Create the global memory D (output) resource.
    """
    return GmemDResource(
        mC_mn=mC_mn,
        bias=bias,
        name="GmemD",
    )


@cute.jit
def create_work_queue(
    tile_sched_params: object,
    cluster_shape_vmnk: cute.Layout,
    num_load_warps: int,
    num_epilogue_warps: int,
    num_mma_warps: int,
    num_padding_warps: int,
    num_scheduler_warps: int = 0,
    clc_response_ptr: Optional[cute.Pointer] = None,
) -> WorkQueue:
    """
    Create the work queue for static or CLC-dynamic scheduling.
    """
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        cluster_size = (
            cluster_shape_vmnk[0]
            * cluster_shape_vmnk[1]
            * cluster_shape_vmnk[2]
            * cluster_shape_vmnk[3]
        )
        # All consumer tasks (load, mma, store, scheduler) run on every CTA
        # in the cluster and call consumer_release, so every warp across all
        # CTAs must be counted in the arrive count.
        num_clc_consumer_threads = (
            32
            * cluster_size
            * (
                num_load_warps
                + num_epilogue_warps
                + num_mma_warps
                + num_padding_warps
                + num_scheduler_warps
            )
        )
        num_clc_response_bytes = 16
        scheduler_pipeline_config = PipelineConfig.create_clc_fetch_async_pipeline_cfg(
            num_stages=num_scheduler_stages,
            num_bytes=num_clc_response_bytes,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_clc_consumer_threads
            ),
            cta_layout_vmnk=cluster_shape_vmnk,
            # Only CTA 0 runs the producer side (CLC is cluster-wide)
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
    else:
        # Static persistent tile scheduler - no pipeline, no scheduler warp
        tile_scheduler_config = (
            TileSchedulerConfig.create_static_persistent_tile_scheduler_params(
                tile_scheduler_params=tile_sched_params,
            )
        )
        return WorkQueue(
            tile_scheduler_config=tile_scheduler_config,
            name="WorkQueue",
        )


########################################################
# Task schedule construction helpers
########################################################


@cute.jit
def create_load_a_task(
    gmem_ab_resource: GmemAbResource,
    smem_a_resource: SmemAbResource,
    pdl_wait: PdlWaitBarrier,
    pdl_launch: PdlLaunchBarrier,
    work_queue: WorkQueue,
    num_k_tiles: int,
) -> Task:
    """
    Create the A TMA load task.
    """

    @schedule
    def load_a_schedule(
        gmem_ab: GmemAbResource,
        smem_a: SmemAbResource,
        pdl_wait_resource: PdlWaitBarrier,
        pdl_launch_resource: PdlLaunchBarrier,
        wq: WorkQueue,
    ) -> None:
        # PDL wait gates the A-load stream before any persistent work is issued.
        pdl_wait_resource.wait_griddep()
        smem_a.init_load_state()
        with work_tile_loop(wq):
            gmem_ab.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_k, coord_m, coord_n = gmem_ab.compute_coords()
                # Producer side of SmemA: reserve empty stage, TMA-fill it,
                # then commit full.
                smem_a.try_acquire()
                smem_a.acquire()
                smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
                smem_a.commit()
            # TAIL: advance to next work tile
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()
        # PDL launch is emitted only after all persistent A-load work completes.
        pdl_launch_resource.launch_griddep()

    result = load_a_schedule(
        gmem_ab_resource, smem_a_resource, pdl_wait, pdl_launch, work_queue
    )
    return Task(
        src_resources=[gmem_ab_resource, pdl_wait, work_queue],
        dst_resources=[smem_a_resource, pdl_launch],
        warp_idx=4,
        num_warps=1,
        schedule=result,
        num_registers=40,
        name="LoadATask",
        debug_print=debug_print,
    )


@cute.jit
def create_load_b_task(
    gmem_ab_resource: GmemAbResource,
    smem_b_resource: SmemAbResource,
    work_queue: WorkQueue,
    num_k_tiles: int,
) -> Task:
    """
    Create the B TMA load task.
    """

    @schedule
    def load_b_schedule(
        gmem_ab: GmemAbResource,
        smem_b: SmemAbResource,
        wq: WorkQueue,
    ) -> None:
        # B-load schedule has the same coordinate flow as A but no PDL dependency.
        smem_b.init_load_state()
        with work_tile_loop(wq):
            gmem_ab.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coord_k, coord_m, coord_n = gmem_ab.compute_coords()
                # Producer side of SmemB: reserve empty stage, TMA-fill it,
                # then commit full.
                smem_b.try_acquire()
                smem_b.acquire()
                smem_b.tma_load_b(coord_k=coord_k, coord_n=coord_n)
                smem_b.commit()
            # TAIL: advance to next work tile
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = load_b_schedule(gmem_ab_resource, smem_b_resource, work_queue)
    return Task(
        src_resources=[gmem_ab_resource, work_queue],
        dst_resources=[smem_b_resource],
        warp_idx=5,
        num_warps=1,
        schedule=result,
        num_registers=40,
        name="LoadBTask",
        debug_print=debug_print,
    )


@cute.jit
def create_padding_task(
    work_queue: WorkQueue,
    num_padding_warps: int,
    total_num_warps_so_far: int,
    num_k_tiles: int,
) -> Task:
    """
    Create the padding task that does nothing.
    """

    @schedule
    def padding_schedule(wq: WorkQueue) -> None:
        # Padding warps only participate in WorkQueue synchronization.
        with work_tile_loop(wq):
            with domain_loop(0, num_k_tiles, 1):
                pass  # padding warps do no loop work
            # TAIL: advance to next work tile
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = padding_schedule(work_queue)
    return Task(
        src_resources=[work_queue],
        dst_resources=[],
        warp_idx=total_num_warps_so_far,
        num_warps=num_padding_warps,
        schedule=result,
        num_registers=40,
        name="PaddingTask",
        debug_print=debug_print,
    )


@cute.jit
def create_mma_task(
    smem_a_resource: SmemAbResource,
    smem_b_resource: SmemAbResource,
    tmem_c_resource: TmemCResource,
    work_queue: WorkQueue,
    num_k_tiles: int,
    num_mma_warps: int,
) -> Task:
    """
    Create the MMA compute task.
    """

    @schedule
    def mma_schedule(
        smem_a: SmemAbResource,
        smem_b: SmemAbResource,
        tmem_c: TmemCResource,
        wq: WorkQueue,
    ) -> None:
        smem_a.init_descriptors()
        smem_b.init_descriptors()
        tmem_c.init_accumulator_state()
        with work_tile_loop(wq):
            tmem_c.init_work_tile_state()
            # HEAD: acquire TMEM accumulator stage
            tmem_c.try_acquire()
            tmem_c.acquire()
            with domain_loop(0, num_k_tiles, 1):
                # Consumer side of SmemA/B: wait for TMA-full stages before MMA.
                smem_a.try_wait()
                smem_b.try_wait()
                smem_a.wait()
                smem_b.wait()
                desc_a_base = smem_a.build_desc_a()
                desc_b_base = smem_b.build_desc_b()
                tmem_c.mma(desc_a_base=desc_a_base, desc_b_base=desc_b_base)
                # Release both SMEM stages after descriptors have been consumed.
                smem_a.release()
                smem_b.release()
            # TAIL: commit TMEM, advance to next work tile
            tmem_c.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = mma_schedule(smem_a_resource, smem_b_resource, tmem_c_resource, work_queue)
    return Task(
        src_resources=[smem_a_resource, smem_b_resource, work_queue],
        dst_resources=[tmem_c_resource],
        warp_idx=6,
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
    work_queue: WorkQueue,
    num_k_tiles: int,
    num_epilogue_warps: int,
) -> Task:
    """
    Create the epilogue store task.
    """
    subtile_cnt = mma_tiler_mnk[1] // 32

    @schedule
    def store_schedule(
        tmem_c: TmemCResource,
        gmem_d: GmemDResource,
        wq: WorkQueue,
    ) -> None:
        # t2r_rmem flows from TmemCResource.load_subtile() into GmemDResource.store().
        tmem_c.init_store_state()
        with work_tile_loop(wq):
            with domain_loop(0, num_k_tiles, 1):
                pass  # no loop-body work for the store task
            # TAIL: drain TMEM subtiles and store to global memory
            tmem_c.try_wait()
            tmem_c.wait()
            for subtile_idx in cutlass.range_constexpr(subtile_cnt):
                t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
                gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
            # Release TMEM only after all output subtiles have been stored.
            tmem_c.release()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = store_schedule(tmem_c_resource, gmem_d_resource, work_queue)
    return Task(
        src_resources=[tmem_c_resource, work_queue],
        dst_resources=[gmem_d_resource],
        warp_idx=0,
        num_warps=num_epilogue_warps,
        schedule=result,
        num_registers=160,
        name="StoreTask",
        debug_print=debug_print,
    )


@cute.jit
def create_work_schedule_task(
    work_queue: WorkQueue,
    num_scheduler_warps: int,
    scheduler_warp_idx: int,
) -> Task:
    """
    Create the CLC dynamic persistent scheduler task. Dynamic mode only.
    """

    @schedule
    def scheduler_schedule(wq: WorkQueue) -> None:
        # Dedicated CLC task fetches new work tiles; data tasks only consume them.
        with work_tile_loop(wq) as work_tile:
            with domain_loop(0, 0, 1):
                pass  # no K-loop work for the scheduler
            # TAIL: fetch and distribute next work tile
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
        num_warps=num_scheduler_warps,
        schedule=result,
        num_registers=40,
        name="WorkScheduleTask",
        debug_print=debug_print,
    )


########################################################
# Resource and task construction
########################################################


def _create_gemm_pipeline(
    tma_a_desc: object,
    tma_b_desc: object,
    mC_mn: object,
    bias: object,
    tile_sched_params: object,
    num_k_tiles: int,
    act_num_pairs: int,
    act_num_pair_cols: int,
    act_a_mcast_template: int,
    act_b_mcast_template: int,
    act_cluster_shape_vmnk: object,
    clc_response_ptr: object = None,
) -> Tuple[TaskManager, Task, Task, SmemAllocation, SmemAllocation]:
    """Create resources, tasks, TaskManager, and SmemAllocator (compile-time).

    Must be called outside any dynamic branch so that pipeline
    configurations keep their compile-time sizes.

    Returns ``(task_manager, mma_task, store_task,
    tmem_ptr_alloc, dealloc_mbar_alloc)`` — the last two are
    ``SmemAllocation`` descriptors for infrastructure slots that the
    caller resolves via ``SmemAllocator.get()`` after
    ``setup_resources_and_tasks()`` triggers ``allocate()``.
    """
    num_epilogue_warps = 4
    num_mma_warps = 1
    num_load_warps = 2
    num_scheduler_warps = 1 if use_clc_dynamic_scheduler else 0

    ########################################################
    # Resource construction
    ########################################################

    # Resource skeleton: GMEM coords -> SMEM A/B -> TMEM accumulator -> GMEM D.
    gmem_ab_resource = create_gmem_ab_resource()

    smem_a_resource = create_smem_ab_resource(
        tma_a_desc,
        tma_b_desc,
        "a",
        act_cluster_shape_vmnk,
        act_num_pairs=act_num_pairs,
        act_num_pair_cols=act_num_pair_cols,
        act_a_mcast_template=act_a_mcast_template,
        act_b_mcast_template=act_b_mcast_template,
    )
    smem_b_resource = create_smem_ab_resource(
        tma_a_desc,
        tma_b_desc,
        "b",
        act_cluster_shape_vmnk,
        act_num_pairs=act_num_pairs,
        act_num_pair_cols=act_num_pair_cols,
        act_a_mcast_template=act_a_mcast_template,
        act_b_mcast_template=act_b_mcast_template,
    )
    pdl_wait = PdlWaitBarrier(name="PdlWait")
    pdl_launch = PdlLaunchBarrier(name="PdlLaunch")

    tmem_c_resource = create_tmem_c_resource(
        num_epilogue_warps,
        act_cluster_shape_vmnk,
    )
    gmem_d_resource = create_gmem_d_resource(mC_mn, bias)

    # Unified SMEM allocator: data buffers + infrastructure slots.
    allocator = SmemAllocator()
    allocator.add_resource(smem_a_resource)
    allocator.add_resource(smem_b_resource)
    # TMEM allocation returns the raw address through this SMEM mailbox.
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )
    # TMEM deallocation uses a shared-memory barrier allocated with the same block.
    dealloc_mbar_alloc = allocator.add(
        SmemAllocation("tmem_dealloc_mbar", dtype=cutlass.Int64, alignment=8)
    )
    allocator.compute_layout()

    # TMEM allocator tracks accumulator ownership for TaskManager validation.
    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c_resource)
    tmem_allocator.compute_layout()

    total_num_warps_so_far = num_mma_warps + num_load_warps + num_epilogue_warps
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        total_num_warps_so_far += num_scheduler_warps
    num_padding_warps = (total_num_warps_so_far + 3) // 4 * 4 - total_num_warps_so_far

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        work_queue = create_work_queue(
            tile_sched_params,
            act_cluster_shape_vmnk,
            num_load_warps,
            num_epilogue_warps,
            num_mma_warps,
            num_padding_warps,
            num_scheduler_warps=num_scheduler_warps,
            clc_response_ptr=clc_response_ptr,
        )
    else:
        work_queue = create_work_queue(
            tile_sched_params,
            act_cluster_shape_vmnk,
            num_load_warps,
            num_epilogue_warps,
            num_mma_warps,
            num_padding_warps,
        )

    ########################################################
    # Task schedule construction
    ########################################################

    # Bind the captured schedules to concrete warp ranges.
    load_a_task = create_load_a_task(
        gmem_ab_resource,
        smem_a_resource,
        pdl_wait,
        pdl_launch,
        work_queue,
        num_k_tiles,
    )
    load_b_task = create_load_b_task(
        gmem_ab_resource,
        smem_b_resource,
        work_queue,
        num_k_tiles,
    )
    mma_task = create_mma_task(
        smem_a_resource,
        smem_b_resource,
        tmem_c_resource,
        work_queue,
        num_k_tiles,
        num_mma_warps,
    )
    store_task = create_store_task(
        tmem_c_resource,
        gmem_d_resource,
        work_queue,
        num_k_tiles,
        num_epilogue_warps,
    )
    task_list = [load_a_task, load_b_task, mma_task, store_task]

    if cutlass.const_expr(num_padding_warps > 0):
        padding_task = create_padding_task(
            work_queue,
            num_padding_warps,
            total_num_warps_so_far,
            num_k_tiles,
        )
        task_list.append(padding_task)

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        scheduler_warp_idx = total_num_warps_so_far - num_scheduler_warps
        work_schedule_task = create_work_schedule_task(
            work_queue, num_scheduler_warps, scheduler_warp_idx
        )
        task_list.append(work_schedule_task)

    # Dependency graph records value/pipeline flow between resources.
    resource_dependency_graph = {
        pdl_launch: [],
        smem_a_resource: [gmem_ab_resource, pdl_wait, work_queue],
        smem_b_resource: [gmem_ab_resource, work_queue],
        tmem_c_resource: [smem_a_resource, smem_b_resource, work_queue],
        gmem_d_resource: [tmem_c_resource, work_queue],
    }
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        resource_dependency_graph[work_queue] = [work_queue]

    ########################################################
    # TaskManager construction
    ########################################################

    # TaskManager validates the skeleton and wires resource contexts/allocators.
    task_manager = TaskManager(
        tasks=task_list,
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )
    return task_manager, mma_task, store_task, tmem_ptr_alloc, dealloc_mbar_alloc


@cute.jit
def _run_gemm_execution(
    task_manager: TaskManager,
    mma_task: Task,
    store_task: Task,
    warp_idx: object,
    tmem_ptr_alloc: SmemAllocation,
    dealloc_mbar_alloc: SmemAllocation,
) -> None:
    """Setup barriers, sync cluster, allocate TMEM, run, deallocate TMEM.

    Safe to call inside a dynamic branch — no pipeline / resource creation.
    Infrastructure pointers (``tmem_ptr_i32``, ``tmem_dealloc_mbar_ptr``)
    are derived from the unified SMEM block after ``allocate()``.
    """
    num_epilogue_warps = 4
    num_mma_warps = 1
    tmem_allocator_warp_id = 0

    task_manager.setup_resources_and_tasks()

    # Derive infrastructure pointers from the unified SMEM block.
    # tmem_ptr_i32 for ResourceContext is auto-populated by TaskManager
    # in setup_resources_and_tasks() via SmemAllocator.tmem_ptr_alloc.
    allocator = task_manager.smem_allocator
    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)
    tmem_dealloc_mbar_ptr = allocator.get(dealloc_mbar_alloc)

    if warp_idx == tmem_allocator_warp_id:
        if prims.elect_sync():
            prims.mbarrier_init(tmem_dealloc_mbar_ptr, cute.arch.WARP_SIZE)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    num_tmem_cols = 512
    tmem_bar_id = 2
    tmem_bar_threads = (num_epilogue_warps + num_mma_warps) * 32

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols, group="cta_2")
        prims.tcgen05_relinquish_alloc_permit(group="cta_2")

    if store_task.is_selected() or mma_task.is_selected():
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

    tmem_raw_addr = cutlass.Int32(0)
    if store_task.is_selected() or mma_task.is_selected():
        tmem_raw_addr = tmem_ptr_i32.load()

    tmem_ptr = prims.make_tmem_ptr(tmem_raw_addr, acc_dtype)

    task_manager.run()

    dealloc_bar_id = 3
    dealloc_bar_threads = num_epilogue_warps * 32
    if store_task.is_selected():
        prims.barrier_cta_sync(dealloc_bar_id, thread_count=dealloc_bar_threads)

    if warp_idx == tmem_allocator_warp_id:
        cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        peer_cta_rank = cta_rank_in_cluster ^ 1

        peer_mbar = prims.mapa(tmem_dealloc_mbar_ptr, peer_cta_rank)
        prims.mbarrier_arrive(peer_mbar, count=1, scope=prims.MemScope.CTA)

        while not prims.mbarrier_try_wait_parity(
            tmem_dealloc_mbar_ptr, 0, time_limit=10000000
        ):
            pass

        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols, group="cta_2")


########################################################
# Kernel
########################################################


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mC_mn: cute.Tensor,
    mnk: Tuple[int, int, int],
    tile_sched_params: object,
    fallback_tile_sched_params: object = None,
    bias: Optional[cute.Tensor] = None,
) -> None:
    """Warp-specialised persistent GEMM kernel with optional fallback cluster support.

    Execution flow
    ==============

    1. Configuration & prefetch
       Extract problem size, compute K-tile count, prefetch TMA descriptors.

    2. Pipeline creation via _create_gemm_pipeline (compile-time)
       Build resources (GmemAb, SmemAb, TmemC, GmemD, WorkQueue),
       tasks (Load, Mma, Store, Padding, WorkSchedule), and TaskManager.
       Data SMEM buffers, the TMEM pointer slot, and the TMEM-dealloc
       mbarrier are unified via ``SmemAllocator``; the CLC response
       buffer (when enabled) is allocated separately because the work
       queue consumes it before ``allocate()`` runs.
       When a fallback cluster is enabled, TWO pipelines are created before
       any dynamic branch — one for the preferred cluster shape and one
       for the fallback — so that pipeline.CooperativeGroup sizes remain
       compile-time constants.

    3. Fallback-cluster detection (when fallback_cluster_shape_mnk is set)
       Query runtime cluster dimensions via block_in_cluster_dim() and
       branch to select which pre-built pipeline to execute.

    4. Execution via _run_gemm_execution (runtime)

       a. setup_resources_and_tasks()
          Unified SMEM allocation (data + infra) and pipeline barrier
          init.

       b. Derive infrastructure pointers
          ``tmem_ptr_i32`` and ``tmem_dealloc_mbar_ptr`` from the
          unified SMEM block via ``SmemAllocator.get()``.

       c. Barrier init & cluster sync
          Init TMEM-dealloc mbarrier, fence, cluster_arrive / cluster_wait.

       d. TMEM allocation (2-CTA)
          tcgen05_alloc, relinquish alloc permit, per-CTA barrier,
          read TMEM pointer.

       e. task_manager.run()
          For each task: select warps, set register budget, create
          function/work/loop variables, execute head/loop/tail schedules
          inside the persistent work loop.

       f. TMEM deallocation
          Peer-CTA mbarrier handshake, tcgen05_dealloc.
    """
    m, n, k = mnk

    num_k_tiles = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]

    warp_idx = cute.arch.warp_idx()

    if warp_idx == 4:
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    # clc_response_ptr must remain a separate allocation: the work queue
    # needs it at resource-creation time to build TileSchedulerConfig,
    # which runs before SmemAllocator.allocate().
    clc_response_ptr = None
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        # Allocate per-stage CLC response buffers (16 bytes per stage).
        clc_response_ptr = cute.arch.alloc_smem(cutlass.Int128, num_scheduler_stages)

    pref_vmnk = (
        num_mma_ctas,
        cluster_shape_mnk[0] // num_mma_ctas,
        cluster_shape_mnk[1],
        cluster_shape_mnk[2],
    )

    if cutlass.const_expr(fallback_cluster_shape_mnk is not None):
        # Compute fallback constants at Python level (compile-time)
        fb = fallback_cluster_shape_mnk
        fb_num_pairs = (fb[0] * fb[1]) // num_mma_ctas
        fb_num_pair_rows = fb[0] // num_mma_ctas
        fb_num_pair_cols = fb[1]
        fb_a_mcast = sum(1 << (num_mma_ctas * c) for c in range(fb_num_pair_cols))
        fb_b_mcast = sum(
            1 << (fb_num_pair_cols * num_mma_ctas * r) for r in range(fb_num_pair_rows)
        )
        fb_vmnk = (num_mma_ctas, fb[0] // num_mma_ctas, fb[1], fb[2])

        # Create BOTH pipelines outside any dynamic branch so that
        # pipeline.CooperativeGroup sizes remain compile-time constants.
        pref_tm, pref_mma, pref_store, pref_tp, pref_dm = _create_gemm_pipeline(
            tma_a_desc.get_ptr(),
            tma_b_desc.get_ptr(),
            mC_mn,
            bias,
            tile_sched_params,
            num_k_tiles,
            act_num_pairs=num_pairs,
            act_num_pair_cols=num_pair_cols,
            act_a_mcast_template=_a_mcast_template,
            act_b_mcast_template=_b_mcast_template,
            act_cluster_shape_vmnk=pref_vmnk,
            clc_response_ptr=clc_response_ptr,
        )
        fb_tm, fb_mma, fb_store, fb_tp, fb_dm = _create_gemm_pipeline(
            tma_a_desc.get_ptr(),
            tma_b_desc.get_ptr(),
            mC_mn,
            bias,
            (
                fallback_tile_sched_params
                if fallback_tile_sched_params is not None
                else tile_sched_params
            ),
            num_k_tiles,
            act_num_pairs=fb_num_pairs,
            act_num_pair_cols=fb_num_pair_cols,
            act_a_mcast_template=fb_a_mcast,
            act_b_mcast_template=fb_b_mcast,
            act_cluster_shape_vmnk=fb_vmnk,
            clc_response_ptr=clc_response_ptr,
        )

        # Runtime: detect actual cluster size and branch for execution only
        cbdim_x, cbdim_y, _ = cute.arch.block_in_cluster_dim()
        is_preferred = (cbdim_x == cluster_shape_mnk[0]) & (
            cbdim_y == cluster_shape_mnk[1]
        )

        if is_preferred:
            _run_gemm_execution(
                pref_tm,
                pref_mma,
                pref_store,
                warp_idx,
                pref_tp,
                pref_dm,
            )
        else:
            _run_gemm_execution(
                fb_tm,
                fb_mma,
                fb_store,
                warp_idx,
                fb_tp,
                fb_dm,
            )
    else:
        tm, mma, store, tp_alloc, dm_alloc = _create_gemm_pipeline(
            tma_a_desc.get_ptr(),
            tma_b_desc.get_ptr(),
            mC_mn,
            bias,
            tile_sched_params,
            num_k_tiles,
            act_num_pairs=num_pairs,
            act_num_pair_cols=num_pair_cols,
            act_a_mcast_template=_a_mcast_template,
            act_b_mcast_template=_b_mcast_template,
            act_cluster_shape_vmnk=pref_vmnk,
            clc_response_ptr=clc_response_ptr,
        )
        _run_gemm_execution(
            tm,
            mma,
            store,
            warp_idx,
            tp_alloc,
            dm_alloc,
        )


def compute_grid(
    c: cute.Tensor,
    mma_tiler_mnk: Tuple[int, int, int],
    cluster_shape_mnk: Tuple[int, int, int],
    max_active_clusters: cutlass.Constexpr,
) -> Tuple[object, Tuple[int, int, int]]:
    c_shape = cute.slice_(mma_tiler_mnk, (None, None, 0))
    gc = cute.zipped_divide(c, tiler=c_shape)
    num_ctas_mn = gc[(0, (None, None))].shape
    cluster_shape_mnl = (*cluster_shape_mnk[:2], 1)

    if use_clc_dynamic_scheduler:
        # CLC dynamic persistent: swizzle_size=1, raster_along_m=True
        tile_sched_params = utils.ClcDynamicPersistentTileSchedulerParams(
            (*num_ctas_mn, 1), cluster_shape_mnl, 1, True
        )
        grid = utils.ClcDynamicPersistentTileScheduler.get_grid_shape(tile_sched_params)
    else:
        tile_sched_params = utils.PersistentTileSchedulerParams(
            (*num_ctas_mn, 1), cluster_shape_mnk
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
    return tile_sched_params, grid


########################################################
# Host runners and CLI
########################################################


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    mnk: Tuple[int, int, int],
    max_active_clusters: cutlass.Constexpr,
    stream,
    bias: Optional[cute.Tensor] = None,
) -> None:
    # Construct TMA Descriptors
    # A/B use cutlass to create tensormap descriptors, like the base GEMM example.
    # box_dims in tensor's original mode order: A is (M, K), B is (N, K).
    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(mma_tiler_mnk_per_cta[0], mma_tiler_mnk[2]),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk_per_cta[1], mma_tiler_mnk[2]),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    cta_tile_shape_mnk = (
        mma_tiler_mnk_per_cta[0],
        mma_tiler_mnk[1],
        mma_tiler_mnk[2],
    )

    # Launch the kernel
    tile_sched_params, grid_shape = compute_grid(
        c,
        cta_tile_shape_mnk,
        cluster_shape_mnk,
        max_active_clusters,
    )
    fallback_tile_sched_params = None
    if cutlass.const_expr(
        use_clc_dynamic_scheduler and fallback_cluster_shape_mnk is not None
    ):
        fallback_tile_sched_params, _ = compute_grid(
            c,
            cta_tile_shape_mnk,
            fallback_cluster_shape_mnk,
            max_active_clusters,
        )

    # 4 epilogue warps + 1 mma warp + 2 tma load warps (A/B split)
    block_size = cute.arch.WARP_SIZE * (4 + 1 + 2)
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        # 4 epilogue warps + 1 mma warp + 2 tma load warps + 1 scheduler warp
        block_size = cute.arch.WARP_SIZE * (4 + 1 + 2 + 1)
    # Pad block size to warp-group granularity
    block_size = (block_size + 127) // 128 * 128
    if cutlass.const_expr(fallback_cluster_shape_mnk is not None):
        kernel(
            tma_a_desc,
            tma_b_desc,
            c,
            mnk,
            tile_sched_params,
            fallback_tile_sched_params,
            bias,
        ).launch(
            grid=grid_shape,
            block=[block_size, 1, 1],
            cluster=cluster_shape_mnk,
            fallback_cluster=fallback_cluster_shape_mnk,
            stream=stream,
            use_pdl=True,
        )
    else:
        kernel(
            tma_a_desc,
            tma_b_desc,
            c,
            mnk,
            tile_sched_params,
            fallback_tile_sched_params,
            bias,
        ).launch(
            grid=grid_shape,
            block=[block_size, 1, 1],
            cluster=cluster_shape_mnk,
            stream=stream,
            use_pdl=True,
        )


@lru_cache(maxsize=1)
def prepare_run(
    callable: Callable,
    m: int,
    n: int,
    k: int,
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    has_bias: bool = False,
) -> tuple[Callable, tuple]:
    import torch
    import cutlass.torch as cutlass_torch

    # Make K-major tensors (torch tensors are row-major)
    def make_tensors(mn: int, k_dim: int, dtype: Type[Numeric]) -> torch.Tensor:
        shape = (mn, k_dim)
        return (torch.randn(*shape, dtype=torch.float32) * 0.01).to(
            device="cuda", dtype=cutlass_torch.dtype(dtype)
        )

    a = make_tensors(m, k, a_dtype)
    b = make_tensors(n, k, b_dtype)
    c = make_tensors(m, n, c_dtype)
    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    c_ = from_dlpack(c).mark_layout_dynamic()

    # Bias follows the Linear/MatMul epilogue contract: C[m, n] += bias[n].
    bias = None
    bias_ = None
    if has_bias:
        bias = torch.randn(n, device="cuda", dtype=cutlass_torch.dtype(c_dtype))
        bias_ = from_dlpack(bias, assumed_align=16).mark_layout_dynamic()

    hw = utils.HardwareInfo()
    if fallback_cluster_shape_mnk is not None:
        sm_count = hw.get_device_multiprocessor_count()
        preferred_ctas = cluster_shape_mnk[0] * cluster_shape_mnk[1]
        max_active_clusters = sm_count // preferred_ctas
    else:
        max_active_clusters = hw.get_max_active_clusters(
            cluster_shape_mnk[0] * cluster_shape_mnk[1]
        )
    mnk = (m, n, k)

    compiled_fn = cute.compile[cute.GenerateLineInfo(True)](
        callable,
        a_,
        b_,
        c_,
        mnk,
        max_active_clusters,
        make_fake_stream(),
        bias_,
    )

    def run_fn() -> object:
        stream = cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)
        return compiled_fn(a_, b_, c_, mnk, stream, bias_)

    return run_fn, (a, b, c, bias)


def prepare_cuda_graph_chain_run(
    callable: Callable,
    m: int,
    n: int,
    k: int,
    chain_length: int,
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    has_bias: bool = False,
) -> tuple[list[Callable], tuple]:
    import torch
    import cutlass.torch as cutlass_torch

    if chain_length > 1 and n != k:
        raise ValueError(
            "Back-to-back CUDA graph validation requires n == k so each "
            "kernel output (M,N) can be fed as the next kernel input (M,K). "
            f"Got n={n}, k={k}."
        )
    if chain_length < 1:
        raise ValueError(f"chain_length must be at least 1, got {chain_length}")

    def make_tensors(mn: int, k_dim: int, dtype: Type[Numeric]) -> torch.Tensor:
        shape = (mn, k_dim)
        if chain_length > 1:
            return (torch.randn(*shape, dtype=torch.float32) * 0.02).to(
                device="cuda", dtype=cutlass_torch.dtype(dtype)
            )
        return (
            torch.empty(*shape, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=cutlass_torch.dtype(dtype))
        )

    a0 = make_tensors(m, k, a_dtype)
    b = make_tensors(n, k, b_dtype)
    output_shape = (m, n)
    chain_tensors = [a0] + [
        torch.empty(
            *output_shape,
            dtype=cutlass_torch.dtype(c_dtype),
            device="cuda",
        )
        for _ in range(chain_length)
    ]
    chain_tensors_ = [from_dlpack(t).mark_layout_dynamic() for t in chain_tensors]
    b_ = from_dlpack(b).mark_layout_dynamic()

    bias = None
    bias_ = None
    if has_bias:
        bias = torch.randn(n, device="cuda", dtype=cutlass_torch.dtype(c_dtype))
        bias_ = from_dlpack(bias, assumed_align=16).mark_layout_dynamic()

    hw = utils.HardwareInfo()
    if fallback_cluster_shape_mnk is not None:
        sm_count = hw.get_device_multiprocessor_count()
        preferred_ctas = cluster_shape_mnk[0] * cluster_shape_mnk[1]
        max_active_clusters = sm_count // preferred_ctas
    else:
        max_active_clusters = hw.get_max_active_clusters(
            cluster_shape_mnk[0] * cluster_shape_mnk[1]
        )
    mnk = (m, n, k)

    compiled_fn = cute.compile[cute.GenerateLineInfo(True)](
        callable,
        chain_tensors_[0],
        b_,
        chain_tensors_[1],
        mnk,
        max_active_clusters,
        make_fake_stream(),
        bias_,
    )

    def make_run_fn(index: int) -> Callable[[], object]:
        def run_fn() -> object:
            stream = cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)
            return compiled_fn(
                chain_tensors_[index],
                b_,
                chain_tensors_[index + 1],
                mnk,
                stream,
                bias_,
            )

        return run_fn

    run_fns = [make_run_fn(i) for i in range(chain_length)]
    return run_fns, (chain_tensors, b, bias)


def run_dense_gemm_ws(
    mnk: Tuple[int, int, int],
    tolerance: float,
    has_bias: bool = False,
    dtype: Optional[str] = None,
    cuda_graph_chain_length: int = 1,
) -> None:
    global torch, cutlass_torch
    import torch
    import torch.nn.functional as F
    import cutlass.torch as cutlass_torch

    if dtype is not None:
        _set_io_dtype(dtype)

    scheduler_mode = (
        "CLC dynamic persistent" if use_clc_dynamic_scheduler else "static persistent"
    )
    fallback_str = (
        f" (fallback: {fallback_cluster_shape_mnk})"
        if fallback_cluster_shape_mnk is not None
        else ""
    )
    print("===================================================================")
    print("Running Blackwell 16-bit GEMM example 3 task-scheduling (clustered) with:")
    print(f"  mnk:       {mnk}")
    print(f"  dtype:     {_get_io_dtype_name()}")
    print(f"  cluster:   {cluster_shape_mnk}{fallback_str}")
    print(f"  scheduler: {scheduler_mode}")
    print(f"  has_bias:  {has_bias}")
    print(f"  tolerance: {tolerance}")
    print(f"  cuda graph chain length: {cuda_graph_chain_length}")
    print("===================================================================")
    print()

    m, n, k = mnk
    torch.manual_seed(1111)

    run_fns, (chain_tensors, b, bias) = prepare_cuda_graph_chain_run(
        host_function,
        m,
        n,
        k,
        cuda_graph_chain_length,
        io_dtype,
        io_dtype,
        io_dtype,
        has_bias,
    )

    expected = chain_tensors[0]
    for _ in range(cuda_graph_chain_length):
        expected = F.linear(
            expected.to(torch.float32),
            b.to(torch.float32),
            bias.to(torch.float32) if bias is not None else None,
        ).to(cutlass_torch.dtype(io_dtype))

    warmup_stream = torch.cuda.Stream()
    torch.cuda.synchronize()
    with torch.cuda.stream(warmup_stream):
        for _ in range(2):
            for run_fn in run_fns:
                run_fn()
    warmup_stream.synchronize()

    for tensor in chain_tensors[1:]:
        tensor.zero_()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        for run_fn in run_fns:
            run_fn()

    for tensor in chain_tensors[1:]:
        tensor.zero_()
    graph.replay()
    torch.cuda.synchronize()

    torch.testing.assert_close(chain_tensors[-1], expected, atol=tolerance, rtol=1e-05)


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
        description="Blackwell 16-bit GEMM example 3 task-scheduling (clustered)"
    )
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=(512, 512, 512),
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument("--has_bias", action="store_true", help="Whether to use bias")
    parser.add_argument(
        "--clc-dynamic-scheduler",
        action="store_true",
        help="Use CLC dynamic persistent tile scheduler instead of static persistent",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--cluster",
        type=parse_comma_separated_ints,
        default=None,
        help="Cluster shape M,N,K (e.g. 4,2,1). Default: module-level value",
    )
    parser.add_argument(
        "--fallback-cluster",
        type=parse_comma_separated_ints,
        default=None,
        help="Fallback cluster shape M,N,K",
    )
    parser.add_argument(
        "--dtype",
        choices=tuple(_DTYPE_MAP.keys()),
        default="fp16",
        help="Input/output dtype for A/B/C tensors",
    )
    parser.add_argument(
        "--cuda-graph-chain-length",
        type=int,
        default=1,
        help=(
            "Number of GEMM kernels to capture back-to-back in one CUDA graph. "
            "Values >1 feed each output as the next kernel's A input and require n == k."
        ),
    )
    args = parser.parse_args()
    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")

    _set_io_dtype(args.dtype)

    # Override scheduling mode from CLI before compilation
    globals()["use_clc_dynamic_scheduler"] = args.clc_dynamic_scheduler

    # Override cluster shape from CLI if provided
    if args.cluster is not None:
        if len(args.cluster) != 3:
            parser.error("--cluster must contain exactly 3 values")
        cm, cn, ck = args.cluster
        globals()["cluster_shape_mnk"] = (cm, cn, ck)
        globals()["cluster_m"] = cm
        globals()["cluster_n"] = cn
        globals()["cluster_size"] = cm * cn
        globals()["num_pairs"] = (cm * cn) // num_mma_ctas
        globals()["num_pair_rows"] = cm // num_mma_ctas
        globals()["num_pair_cols"] = cn
        globals()["super_tile_m"] = (cm // num_mma_ctas) * mma_tiler_mnk[0]
        globals()["super_tile_n"] = cn * mma_tiler_mnk[1]
        globals()["_a_mcast_template"] = sum(1 << (num_mma_ctas * c) for c in range(cn))
        globals()["_b_mcast_template"] = sum(
            1 << (cn * num_mma_ctas * r) for r in range(cm // num_mma_ctas)
        )
        try:
            _validate_cluster_shape((cm, cn, ck), option_name="--cluster")
        except ValueError as exc:
            parser.error(str(exc))

    if args.fallback_cluster is not None:
        fb = tuple(args.fallback_cluster)
        if len(fb) != 3:
            parser.error("--fallback-cluster must contain exactly 3 values")
        try:
            _validate_fallback_cluster_shape(fb, cluster_shape_mnk)
        except ValueError as exc:
            parser.error(str(exc))
        globals()["fallback_cluster_shape_mnk"] = fb

    m, n, k = args.mnk
    _validate_cluster_shape(cluster_shape_mnk, option_name="cluster_shape_mnk")
    if fallback_cluster_shape_mnk is not None:
        _validate_fallback_cluster_shape(
            fallback_cluster_shape_mnk,
            cluster_shape_mnk,
        )
    if m % super_tile_m != 0:
        raise ValueError(f"m must be divisible by super_tile_m={super_tile_m}")
    if n % super_tile_n != 0:
        raise ValueError(f"n must be divisible by super_tile_n={super_tile_n}")
    if n % 32 != 0:
        raise ValueError("n must be divisible by 32")

    run_dense_gemm_ws(
        args.mnk,
        args.tolerance,
        args.has_bias,
        args.dtype,
        cuda_graph_chain_length=args.cuda_graph_chain_length,
    )
    print("PASS")
