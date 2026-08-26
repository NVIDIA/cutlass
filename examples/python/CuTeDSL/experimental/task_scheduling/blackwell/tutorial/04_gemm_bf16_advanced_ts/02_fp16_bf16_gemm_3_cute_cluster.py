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

# ruff: noqa: E402

"""Clustered CuteDSL TS FP16/BF16 GEMM tutorial kernel.

Read ``01_fp16_bf16_gemm_3.py`` first, then the clustered CUTLASS
Python DSL version. This file keeps the clustered TS resource/task structure
while replacing the CUTLASS Python DSL-level operations with CuteDSL
abstractions:

  - TMA loads:    ``cute.copy(tma_atom, ...)``
  - MMA:          ``cute.gemm(tiled_mma, ...)``
  - T2R epilogue: ``cute.copy(tiled_copy_t2r, ...)`` via CuteDSL tiled copy
  - Multicast:    ``cute.nvgpu.cpasync.create_tma_multicast_mask``
  - TMEM mgmt:    ``cute.arch.alloc_tmem / dealloc_tmem``
  - Indexing:     ``cute.arch.block_idx / warp_idx / thread_idx``

The epilogue uses CuteDSL tiled T2R copies (``TmemCResource``) to read from
TMEM into registers, then ``GmemDResource`` converts FP32 to ``io_dtype`` and
stores to GMEM via aligned direct ``Tensor.store``.

Resource/task flow:

                   +-------------------+
                   |   GmemAbResource  |
                   |  tile coordinates |
                   +---------+---------+
                             |
        LoadTask: compute A/B coords, CuteDSL multicast TMA
                             |
                             v
                        +----+----+
                        |  SmemAB |
                        | TmaUmma |
                        +----+----+
                             |
                             | MmaTask waits full stages,
                             | partitions fragments, issues cute.gemm
                             v
                       +-----+-----+
                       |   TmemC   |
                       | UmmaAsync |
                       +-----+-----+
                             |
                             | StoreTask waits accumulator,
                             | CuteDSL T2R, GMEM store
                             v
                        +----+----+
                        |  GmemD  |
                        | output  |
                        +---------+

   WorkQueue: every task advances the same persistent tile stream.

Tasks
-----
  - LoadTask  (1 warp)  : CuteDSL TMA copy with multicast.
  - MmaTask   (1 warp)  : CuteDSL cute.gemm (2-CTA).
  - StoreTask (4 warps) : CuteDSL T2R (TmemC) + aligned GMEM store (GmemD).
  - WorkScheduleTask (1 warp, CLC dynamic mode only).
"""

import argparse
from typing import Tuple, Optional, Type, Callable, Any
from functools import partial, lru_cache
from dataclasses import dataclass, field
from pathlib import Path
import sys

_REPO_ROOT = Path(__file__).resolve().parents[10]
_repo_root_str = str(_REPO_ROOT)
if _repo_root_str not in sys.path:
    sys.path.insert(0, _repo_root_str)
try:
    import sitecustomize  # noqa: F401
except Exception:
    pass

import cutlass
from cutlass import Numeric
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass.experimental import primitives as prims
from cutlass.cute.runtime import from_dlpack

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
    TileSchedulerConfig,
    StageInfo,
    TaskLocalVariable,
    PipelineConfig,
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


_DTYPE_MAP = {"fp16": cutlass.Float16, "bf16": cutlass.BFloat16}


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


# Input/output dtype is mutable from the CLI; accumulation always stays FP32.
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

# Pipeline stage counts for SMEM A/B, epilogue staging, TMEM, and scheduler responses.
ab_stages = 6
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


# ======================================================================
# Resource definitions
# ======================================================================


@dataclass
class GmemAbResource(MemoryResource):
    """Global-memory A/B input resource (read-only coordinate source).

    Computes per-tile TMA load coordinates consumed by SmemAbResource.
    """

    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    cta_rank_in_cluster: Any = field(init=False, default=None)
    bx: Any = field(init=False, default=None)
    by: Any = field(init=False, default=None)
    bz: Any = field(init=False, default=None)

    def __init__(self, **kwargs: object) -> None:
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

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        bidx, bidy, _ = cute.arch.block_idx()
        self.cta_rank_in_cluster = (bidy % cluster_shape_mnk[1]) * cluster_shape_mnk[
            0
        ] + (bidx % cluster_shape_mnk[0])
        self.bx, self.by, self.bz = stage_info.work_tile.tile_idx

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
    """Shared-memory A/B buffers filled by CuteDSL TMA copies.

    Producer side issues ``cute.copy(tma_atom, ...)`` with multicast.
    Consumer side forwards the pipeline stage index so that TmemCResource
    can index into the correct SMEM fragment for ``cute.gemm``.
    """

    tma_atom_a: Any = field(init=False, default=None)
    tma_atom_b: Any = field(init=False, default=None)
    mA_mkl: Any = field(init=False, default=None)
    mB_nkl: Any = field(init=False, default=None)
    tiled_mma: Any = field(init=False, default=None)
    # Precomputed cta_layout_vmnk mode sizes for producer_work TMA partitioning
    cta_layout_size_v: cutlass.Constexpr[int] = field(init=False, default=0)
    cta_layout_size_m: cutlass.Constexpr[int] = field(init=False, default=0)
    cta_layout_size_n: cutlass.Constexpr[int] = field(init=False, default=0)
    sA: Any = field(init=False, default=None)
    sB: Any = field(init=False, default=None)

    ab_stage_idx: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    cta_rank_in_cluster: Any = field(init=False, default=None)
    cta_in_cluster_coord_vmnk: Any = field(init=False, default=None)
    mma_v_coord: Any = field(init=False, default=None)
    tma_mcast_mask_a: Any = field(init=False, default=None)
    tma_mcast_mask_b: Any = field(init=False, default=None)

    act_num_pair_cols: Any = field(init=False, default=None)
    act_a_mcast_template: Any = field(init=False, default=None)
    act_b_mcast_template: Any = field(init=False, default=None)
    _alloc_a: cutlass.Constexpr = field(init=False, default=None)
    _alloc_b: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        tma_atom_a: cute.CopyAtom,
        tma_atom_b: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        mB_nkl: cute.Tensor,
        a_smem_layout: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
        tiled_mma: cute.TiledMma,
        cta_layout_vmnk: cute.Layout,
        act_num_pair_cols: int = None,
        act_a_mcast_template: int = None,
        act_b_mcast_template: int = None,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tma_atom_a = tma_atom_a
        self.tma_atom_b = tma_atom_b
        self.mA_mkl = mA_mkl
        self.mB_nkl = mB_nkl
        self.tiled_mma = tiled_mma
        self.a_smem_layout = a_smem_layout
        self.b_smem_layout = b_smem_layout
        self.cta_layout_vmnk = cta_layout_vmnk

        self.cta_layout_size_v = cute.size(cta_layout_vmnk, mode=[0])
        self.cta_layout_size_m = cute.size(cta_layout_vmnk, mode=[1])
        self.cta_layout_size_n = cute.size(cta_layout_vmnk, mode=[2])
        self.act_num_pair_cols = (
            act_num_pair_cols if act_num_pair_cols is not None else num_pair_cols
        )
        self.act_a_mcast_template = (
            act_a_mcast_template
            if act_a_mcast_template is not None
            else _a_mcast_template
        )
        self.act_b_mcast_template = (
            act_b_mcast_template
            if act_b_mcast_template is not None
            else _b_mcast_template
        )
        self.ab_stage_idx = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="SMEM AB pipeline stage index consumed by MMA.",
        )

        elem_bytes = io_dtype.width // 8
        sA_bytes = mma_tiler_mnk_per_cta[0] * mma_tiler_mnk[2] * ab_stages * elem_bytes
        sB_bytes = mma_tiler_mnk_per_cta[1] * mma_tiler_mnk[2] * ab_stages * elem_bytes
        self._alloc_a = SmemAllocation("smem_a", sA_bytes, alignment=128)
        self._alloc_b = SmemAllocation("smem_b", sB_bytes, alignment=128)

        smem_ptr_a = cute.make_ptr(
            io_dtype, 0, cute.AddressSpace.smem, assumed_align=128
        )
        self.sA = cute.make_tensor(
            cute.recast_ptr(smem_ptr_a, self.a_smem_layout.inner),
            self.a_smem_layout.outer,
        )
        smem_ptr_b = cute.make_ptr(
            io_dtype, 0, cute.AddressSpace.smem, assumed_align=128
        )
        self.sB = cute.make_tensor(
            cute.recast_ptr(smem_ptr_b, self.b_smem_layout.inner),
            self.b_smem_layout.outer,
        )

    def get_smem_requirements(self):
        return [self._alloc_a, self._alloc_b]

    def create_pipeline(self, pipeline_config: PipelineConfig) -> object:
        """
        Set cluster-wide consumer_mask for the empty barrier.
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

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context

        smem_ptr_a = cute.make_ptr(
            io_dtype,
            context.smem_base.data_ptr() + self._alloc_a.offset,
            cute.AddressSpace.smem,
            assumed_align=128,
        )
        sA = cute.make_tensor(
            cute.recast_ptr(smem_ptr_a, self.a_smem_layout.inner),
            self.a_smem_layout.outer,
        )
        self.sA = sA

        smem_ptr_b = cute.make_ptr(
            io_dtype,
            context.smem_base.data_ptr() + self._alloc_b.offset,
            cute.AddressSpace.smem,
            assumed_align=128,
        )
        sB = cute.make_tensor(
            cute.recast_ptr(smem_ptr_b, self.b_smem_layout.inner),
            self.b_smem_layout.outer,
        )
        self.sB = sB

        cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        self.cta_rank_in_cluster = cta_rank_in_cluster
        cta_in_cluster_coord_vmnk = self.cta_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Force all tuple elements to DSL Int32 so that extent-1 modes
        # (which get_flat_coord may constant-fold to Python int 0) are
        # ir.Values visible to gather_leaves before any dynamic loop.
        cta_in_cluster_coord_vmnk = tuple(
            x if not isinstance(x, int) else cutlass.Int32(x)
            for x in cta_in_cluster_coord_vmnk
        )
        self.cta_in_cluster_coord_vmnk = cta_in_cluster_coord_vmnk

        bidx, _, _ = cute.arch.block_idx()
        self.mma_v_coord = bidx % self.cta_layout_size_v

        # Multicast masks (depend only on cluster position)
        self.tma_mcast_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
            self.cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=2
        )
        self.tma_mcast_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
            self.cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=1
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_stage_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=ab_stage_idx)
    @cute.jit
    def get_stage_idx(self, stage_info: StageInfo) -> cutlass.Int32:
        return stage_info.stage_idx

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
        k_tile_idx = stage_info.loop_offset
        stage_idx = stage_info.stage_idx

        # Recompute GMEM partition for the current work tile.
        # In a persistent kernel the tile coordinates change each iteration;
        # layout operations are lightweight (no memory traffic).
        bx, by, bz = stage_info.work_tile.tile_idx
        mma_coord_mnk = (
            bx // cluster_shape_mnk[0],
            by // cluster_shape_mnk[1],
            None,
        )

        gA = cute.local_tile(
            self.mA_mkl, mma_tiler_mnk, mma_coord_mnk, proj=(1, None, 1)
        )
        gB = cute.local_tile(
            self.mB_nkl, mma_tiler_mnk, mma_coord_mnk, proj=(None, 1, 1)
        )
        thr_mma = self.tiled_mma.get_slice(self.mma_v_coord)
        tCgA = thr_mma.partition_A(gA)
        tCgB = thr_mma.partition_B(gB)

        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            self.tma_atom_a,
            self.cta_in_cluster_coord_vmnk[2],
            cute.make_layout(self.cta_layout_size_n),
            cute.group_modes(self.sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            self.tma_atom_b,
            self.cta_in_cluster_coord_vmnk[1],
            cute.make_layout(self.cta_layout_size_m),
            cute.group_modes(self.sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        bar_ptr = cute.make_ptr(
            cutlass.Int64,
            stage_info.barrier.data_ptr().toint(),
            cutlass.AddressSpace.smem,
        )
        cute.copy(
            self.tma_atom_a,
            tAgA[(None, k_tile_idx)],
            tAsA[(None, stage_idx)],
            tma_bar_ptr=bar_ptr,
            mcast_mask=self.tma_mcast_mask_a,
        )
        cute.copy(
            self.tma_atom_b,
            tBgB[(None, k_tile_idx)],
            tBsB[(None, stage_idx)],
            tma_bar_ptr=bar_ptr,
            mcast_mask=self.tma_mcast_mask_b,
        )


@dataclass
class TmemCResource(MemoryResource):
    """TMEM accumulator + T2R: CuteDSL MMA and T2R epilogue load.

    Producer side uses ``cute.gemm(tiled_mma, ...)`` to accumulate.
    Consumer side uses CuteDSL tiled T2R copy to read TMEM sub-tiles
    into registers and passes them to GmemDResource for the GMEM store.
    """

    scale_d: Any = field(init=False, default=None)
    cta_rank_in_cluster: Any = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)

    # CuteDSL objects for cute.gemm
    tiled_mma_obj: Any = field(init=False, default=None)
    num_k_blocks: cutlass.Constexpr[int] = field(init=False, default=None)

    # FP32 register tensor for T2R results — sized from GMEM partition.
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    # Local SMEM tensor views consumed by MMA.
    sA: Any = field(init=False, default=None)
    sB: Any = field(init=False, default=None)
    a_smem_layout: Any = field(init=False, default=None)
    b_smem_layout: Any = field(init=False, default=None)
    alloc_a_offset: cutlass.Constexpr[int] = field(init=False, default=0)
    alloc_b_offset: cutlass.Constexpr[int] = field(init=False, default=0)

    # Epilogue tile shape
    epi_tile_mn: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        tiled_mma: cute.TiledMma,
        a_smem_layout: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
        alloc_a_offset: int,
        alloc_b_offset: int,
        mC_mn: cute.Tensor = None,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tiled_mma_obj = tiled_mma
        self.mC_mn = mC_mn
        self.a_smem_layout = a_smem_layout
        self.b_smem_layout = b_smem_layout
        self.alloc_a_offset = alloc_a_offset
        self.alloc_b_offset = alloc_b_offset
        smem_ptr_a = cute.make_ptr(
            io_dtype, 0, cute.AddressSpace.smem, assumed_align=128
        )
        self.sA = cute.make_tensor(
            cute.recast_ptr(smem_ptr_a, self.a_smem_layout.inner),
            self.a_smem_layout.outer,
        )
        smem_ptr_b = cute.make_ptr(
            io_dtype, 0, cute.AddressSpace.smem, assumed_align=128
        )
        self.sB = cute.make_tensor(
            cute.recast_ptr(smem_ptr_b, self.b_smem_layout.inner),
            self.b_smem_layout.outer,
        )
        self.num_k_blocks = mma_tiler_mnk[2] // mma_inst_shape_mnk[2]
        self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * acc_stages)
        self.t2r_rmem = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.full([32], 0.0, cutlass.Float32),
            docs="Register-memory subtile loaded from TMEM for the epilogue.",
        )
        self.epi_tile_mn = utils.blackwell_helpers.compute_epilogue_tile_size(
            mma_tiler_mnk_per_cta[0],
            mma_tiler_mnk[1],
            True,
            io_dtype.width,
        )

    def get_tmem_requirements(self):
        return [self._alloc_acc]

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_accumulator_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        smem_ptr_a = cute.make_ptr(
            io_dtype,
            context.smem_base.data_ptr() + self.alloc_a_offset,
            cute.AddressSpace.smem,
            assumed_align=128,
        )
        sA = cute.make_tensor(
            cute.recast_ptr(smem_ptr_a, self.a_smem_layout.inner),
            self.a_smem_layout.outer,
        )
        self.sA = sA

        smem_ptr_b = cute.make_ptr(
            io_dtype,
            context.smem_base.data_ptr() + self.alloc_b_offset,
            cute.AddressSpace.smem,
            assumed_align=128,
        )
        sB = cute.make_tensor(
            cute.recast_ptr(smem_ptr_b, self.b_smem_layout.inner),
            self.b_smem_layout.outer,
        )
        self.sB = sB

        self.cta_rank_in_cluster = cute.arch.block_idx_in_cluster()

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
        # Create accumulator in TMEM with STAGE dimension for double-buffering.
        # Shape: (MMA, MMA_M, MMA_N, STAGE)
        acc_shape = self.tiled_mma_obj.partition_shape_C(mma_tiler_mnk[:2])
        acc_template = self.tiled_mma_obj.make_fragment_C(
            cute.append(acc_shape, acc_stages)
        )
        tmem_ptr_i32 = cute.make_ptr(
            cutlass.Int32,
            stage_info.context.tmem_ptr_i32.data_ptr(),
            cutlass.AddressSpace.smem,
        )
        tmem_ptr = cute.arch.retrieve_tmem_ptr(
            acc_dtype,
            alignment=16,
            ptr_to_buffer_holding_addr=tmem_ptr_i32,
        )
        tCtAcc = cute.make_tensor(tmem_ptr, acc_template.layout)

        # --- CuteDSL T2R epilogue setup ---
        tidx, _, _ = cute.arch.thread_idx()
        copy_atom_t2r = cute.make_copy_atom(
            cute.nvgpu.tcgen05.Ld32x32bOp(
                cute.nvgpu.tcgen05.Repetition.x32,
                cute.nvgpu.tcgen05.Pack.NONE,
            ),
            cutlass.Float32,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tCtAcc_epi = cute.flat_divide(
            tCtAcc[((None, None), 0, 0, None)], self.epi_tile_mn
        )
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(
            copy_atom_t2r, tCtAcc_epi[(None, None, 0, 0, 0)]
        )
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, STAGE)
        tDtC_partitioned = thr_copy_t2r.partition_S(tCtAcc_epi)
        # Group EPI_M × EPI_N into SUBTILE_CNT, keep STAGE.
        # → (T2R, T2R_M, T2R_N, SUBTILE_CNT, STAGE)
        tDtC_grouped = cute.group_modes(
            tDtC_partitioned, 3, cute.rank(tDtC_partitioned) - 1
        )

        # --- CuteDSL SIMT GMEM store setup ---
        # Partition GMEM first: the per-subtile shape from partition_D
        # determines the register tensor size for both T2R and SIMT store.
        per_cta_tile_mn = (mma_tiler_mnk_per_cta[0], mma_tiler_mnk[1])
        gC = cute.local_tile(self.mC_mn, per_cta_tile_mn, (None, None))
        gC_epi = cute.flat_divide(gC, self.epi_tile_mn)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN)
        tTR_gC_full = thr_copy_t2r.partition_D(gC_epi)
        per_subtile_shape = tTR_gC_full[(None, None, None, 0, 0, 0, 0)].shape
        # FP32 register tensor for T2R results — sized from GMEM partition
        # so that cute.copy handles TMEM→register layout conversion.
        tCrC = cute.make_rmem_tensor(per_subtile_shape, cutlass.Float32)

        # Select accumulator stage, then subtile within that stage
        # tDtC shape: (T2R, T2R_M, T2R_N, SUBTILE_CNT, STAGE)
        tDtC_stage = tDtC_grouped[(None, None, None, None, stage_info.stage_idx)]
        tDtC_slice = tDtC_stage[(None, None, None, subtile_idx)]
        cute.copy(tiled_copy_t2r, tDtC_slice, tCrC)
        cute.arch.fence_view_async_tmem_load()
        return tCrC.load()

    @producer_work
    @cute.jit
    def mma(self, stage_info: StageInfo, *, ab_stage_idx: cutlass.Int32) -> None:
        if self.cta_rank_in_cluster % num_mma_ctas == 0:
            tiled_mma = self.tiled_mma_obj.with_()
            tiled_mma.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, self.scale_d)

            acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
            acc_template = tiled_mma.make_fragment_C(cute.append(acc_shape, acc_stages))
            tmem_ptr_i32 = cute.make_ptr(
                cutlass.Int32,
                stage_info.context.tmem_ptr_i32.data_ptr(),
                cutlass.AddressSpace.smem,
            )
            tmem_ptr = cute.arch.retrieve_tmem_ptr(
                acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_ptr_i32,
            )
            # Create accumulator in TMEM with STAGE dimension for double-buffering.
            # Shape: (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_full = cute.make_tensor(tmem_ptr, acc_template.layout)

            # Create SMEM fragments for cute.gemm.
            # tCrA shape: (MMA, MMA_M, MMA_K, STAGE)
            tCrA = tiled_mma.make_fragment_A(self.sA)
            tCrB = tiled_mma.make_fragment_B(self.sB)

            # Select the current accumulator stage for double-buffering
            tCtAcc = tCtAcc_full[(None, None, None, stage_info.stage_idx)]

            k_block_coord_0 = (None, None, 0, ab_stage_idx)
            cute.gemm(
                tiled_mma,
                tCtAcc,
                tCrA[k_block_coord_0],
                tCrB[k_block_coord_0],
                tCtAcc,
            )

            tiled_mma_accumulate = self.tiled_mma_obj.with_()
            tiled_mma_accumulate.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
            for k_block_idx in cutlass.range_constexpr(1, self.num_k_blocks):
                k_block_coord = (None, None, k_block_idx, ab_stage_idx)
                cute.gemm(
                    tiled_mma_accumulate,
                    tCtAcc,
                    tCrA[k_block_coord],
                    tCrB[k_block_coord],
                    tCtAcc,
                )
            self.scale_d = True


@dataclass
class GmemDResource(MemoryResource):
    """cutlass aligned GMEM store for epilogue output.

    Receives T2R register data from TmemCResource, converts
    FP32 → io_dtype, and stores directly to GMEM with vectorized
    cutlass pointer stores. The TS dataflow slot remains a plain
    cutlass vector initialized by ``cutlass.vector.full``.
    """

    bx: Any = field(init=False, default=None)
    by: Any = field(init=False, default=None)
    bz: Any = field(init=False, default=None)
    rank_in_pair: Any = field(init=False, default=None)
    pair_row: Any = field(init=False, default=None)
    pair_col: Any = field(init=False, default=None)
    mC_mn: Any = field(init=False, default=None)

    def __init__(self, mC_mn: cute.Tensor, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.mC_mn = mC_mn

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_tile_coords(self, stage_info: StageInfo) -> None:
        cta_rank = cute.arch.block_idx_in_cluster()
        self.rank_in_pair = cta_rank % num_mma_ctas
        pair_id = cta_rank // num_mma_ctas
        self.pair_row = pair_id // num_pair_cols
        self.pair_col = pair_id % num_pair_cols
        self.bx, self.by, self.bz = stage_info.work_tile.tile_idx

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
        coordc_m = (
            (self.bx // cluster_shape_mnk[0]) * super_tile_m
            + self.pair_row * mma_tiler_mnk[0]
            + self.rank_in_pair * mma_tiler_mnk_per_cta[0]
        )
        coordc_n = self.by * mma_tiler_mnk[1]
        row = coordc_m + tx
        col = coordc_n + subtile_idx * 32
        num_rows = self.mC_mn.shape[0]
        num_cols = self.mC_mn.shape[1]
        gC_ptr = self.mC_mn.iterator.raw_ptr()
        vsize = 256 // io_dtype.width

        # Convert FP32 → output dtype, store to GMEM via aligned direct store.
        if row < num_rows:
            row_offset = cutlass.Int64(row) * cutlass.Int64(num_cols)
            for j in cutlass.range_constexpr(32 // vsize):
                chunk_col = col + j * vsize
                vec_f32 = t2r_rmem[j * vsize : j * vsize + vsize]
                if chunk_col + vsize <= num_cols:
                    # The common path uses 128-bit vector stores instead of
                    # scalar STG.E.U16.
                    (gC_ptr + row_offset + cutlass.Int64(chunk_col)).store(
                        vec_f32.to(io_dtype), alignment=16
                    )
                else:
                    for i in cutlass.range_constexpr(vsize):
                        col_idx = chunk_col + i
                        if col_idx < num_cols:
                            (gC_ptr + row_offset + cutlass.Int64(col_idx)).store(
                                vec_f32[i].to(io_dtype)
                            )


# ======================================================================
# Resource construction helpers
# ======================================================================


@cute.jit
def create_gmem_ab_resource() -> GmemAbResource:
    return GmemAbResource(name="GmemAb")


def create_smem_ab_resource(
    tma_atom_a: cute.CopyAtom,
    tma_atom_b: cute.CopyAtom,
    mA_mkl: cute.Tensor,
    mB_nkl: cute.Tensor,
    a_smem_layout: cute.ComposedLayout,
    b_smem_layout: cute.ComposedLayout,
    tiled_mma: cute.TiledMma,
    cta_layout_vmnk: cute.Layout,
    cluster_shape_vmnk: cute.Layout,
    act_num_pairs: int = None,
    act_num_pair_cols: int = None,
    act_a_mcast_template: int = None,
    act_b_mcast_template: int = None,
) -> SmemAbResource:
    if act_num_pairs is None:
        act_num_pairs = num_pairs
    a_smem_layout_slice = cute.slice_(a_smem_layout, (None, None, None, 0))
    b_smem_layout_slice = cute.slice_(b_smem_layout, (None, None, None, 0))
    tma_copy_bytes_per_cta = cute.size_in_bytes(
        io_dtype, a_smem_layout_slice
    ) + cute.size_in_bytes(io_dtype, b_smem_layout_slice)
    num_tma_copy_bytes = tma_copy_bytes_per_cta * act_num_pairs * num_mma_ctas

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
        tma_atom_a=tma_atom_a,
        tma_atom_b=tma_atom_b,
        mA_mkl=mA_mkl,
        mB_nkl=mB_nkl,
        a_smem_layout=a_smem_layout,
        b_smem_layout=b_smem_layout,
        tiled_mma=tiled_mma,
        cta_layout_vmnk=cta_layout_vmnk,
        act_num_pair_cols=act_num_pair_cols,
        act_a_mcast_template=act_a_mcast_template,
        act_b_mcast_template=act_b_mcast_template,
        pipeline_config=smem_ab_pipeline_config,
        name="SmemAb",
    )


@cute.jit
def create_tmem_c_resource(
    num_epilogue_warps: int,
    cluster_shape_vmnk: cute.Layout,
    tiled_mma: cute.TiledMma,
    a_smem_layout: cute.ComposedLayout,
    b_smem_layout: cute.ComposedLayout,
    alloc_a_offset: int,
    alloc_b_offset: int,
    mC_mn: cute.Tensor = None,
) -> TmemCResource:
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
        tiled_mma=tiled_mma,
        a_smem_layout=a_smem_layout,
        b_smem_layout=b_smem_layout,
        alloc_a_offset=alloc_a_offset,
        alloc_b_offset=alloc_b_offset,
        mC_mn=mC_mn,
        pipeline_config=tmem_c_pipeline_config,
        name="TmemC",
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
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        cluster_size = (
            cluster_shape_vmnk[0]
            * cluster_shape_vmnk[1]
            * cluster_shape_vmnk[2]
            * cluster_shape_vmnk[3]
        )
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
def create_load_task(
    gmem_ab_resource: GmemAbResource,
    smem_ab_resource: SmemAbResource,
    work_queue: WorkQueue,
    num_k_tiles: int,
    num_load_warps: int,
) -> Task:
    @schedule
    def load_schedule(
        gmem_ab: MemoryResource, smem_ab: MemoryResource, wq: WorkQueue
    ) -> None:
        smem_ab.init_load_state()
        with work_tile_loop(wq):
            gmem_ab.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                coords = gmem_ab.compute_coords()
                smem_ab.try_acquire()
                smem_ab.acquire()
                coord_k, coord_m, coord_n = coords
                smem_ab.tma_load(coord_k=coord_k, coord_m=coord_m, coord_n=coord_n)
                smem_ab.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = load_schedule(gmem_ab_resource, smem_ab_resource, work_queue)
    return Task(
        src_resources=[gmem_ab_resource, work_queue],
        dst_resources=[smem_ab_resource],
        warp_idx=4,
        num_warps=num_load_warps,
        schedule=result,
        num_registers=40,
        name="LoadTask",
        debug_print=debug_print,
    )


@cute.jit
def create_padding_task(
    work_queue: WorkQueue,
    num_padding_warps: int,
    total_num_warps_so_far: int,
    num_k_tiles: int,
) -> Task:
    @schedule
    def padding_schedule(wq: WorkQueue) -> None:
        with work_tile_loop(wq):
            with domain_loop(0, num_k_tiles, 1):
                pass
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
    smem_ab_resource: SmemAbResource,
    tmem_c_resource: TmemCResource,
    work_queue: WorkQueue,
    num_k_tiles: int,
    num_mma_warps: int,
) -> Task:
    @schedule
    def mma_schedule(
        smem_ab: MemoryResource, tmem_c: MemoryResource, wq: WorkQueue
    ) -> None:
        smem_ab.init_stage_state()
        tmem_c.init_accumulator_state()
        with work_tile_loop(wq):
            tmem_c.init_work_tile_state()
            tmem_c.try_acquire()
            tmem_c.acquire()
            with domain_loop(0, num_k_tiles, 1):
                smem_ab.try_wait()
                smem_ab.wait()
                ab_stage_idx = smem_ab.get_stage_idx()
                tmem_c.mma(ab_stage_idx=ab_stage_idx)
                smem_ab.release()
            tmem_c.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    result = mma_schedule(smem_ab_resource, tmem_c_resource, work_queue)
    return Task(
        src_resources=[smem_ab_resource, work_queue],
        dst_resources=[tmem_c_resource],
        warp_idx=5,
        num_warps=num_mma_warps,
        schedule=result,
        num_registers=40,
        name="MmaTask",
        debug_print=debug_print,
    )


@cute.jit
def create_gmem_d_resource(
    mC_mn: cute.Tensor,
) -> GmemDResource:
    return GmemDResource(mC_mn=mC_mn, name="GmemD")


@cute.jit
def create_store_task(
    tmem_c_resource: TmemCResource,
    gmem_d_resource: GmemDResource,
    work_queue: WorkQueue,
    num_k_tiles: int,
    num_epilogue_warps: int,
) -> Task:
    epi_tile_m, epi_tile_n = tmem_c_resource.epi_tile_mn
    subtile_cnt = (mma_tiler_mnk_per_cta[0] // epi_tile_m) * (
        mma_tiler_mnk[1] // epi_tile_n
    )

    @schedule
    def store_schedule(
        tmem_c: MemoryResource, gmem_d: MemoryResource, wq: WorkQueue
    ) -> None:
        with work_tile_loop(wq):
            gmem_d.init_tile_coords()
            with domain_loop(0, num_k_tiles, 1):
                pass
            tmem_c.try_wait()
            tmem_c.wait()
            for subtile_idx in cutlass.range_constexpr(subtile_cnt):
                t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
                gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
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
) -> Task:
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
        warp_idx=6,
        num_warps=num_scheduler_warps,
        schedule=result,
        num_registers=40,
        name="WorkScheduleTask",
        debug_print=debug_print,
    )


# ======================================================================
# Resource and task construction
# ======================================================================


def _create_gemm_pipeline(
    tma_atom_a: object,
    tma_atom_b: object,
    mA_mkl: object,
    mB_nkl: object,
    mC_mn: object,
    tile_sched_params: object,
    num_k_tiles: int,
    tiled_mma: object,
    a_smem_layout: object,
    b_smem_layout: object,
    cta_layout_vmnk: object,
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
    num_load_warps = 1
    num_scheduler_warps = 1 if use_clc_dynamic_scheduler else 0

    ########################################################
    # Resource construction
    ########################################################

    gmem_ab_resource = create_gmem_ab_resource()

    smem_ab_resource = create_smem_ab_resource(
        tma_atom_a,
        tma_atom_b,
        mA_mkl,
        mB_nkl,
        a_smem_layout,
        b_smem_layout,
        tiled_mma,
        cta_layout_vmnk,
        act_cluster_shape_vmnk,
        act_num_pairs=act_num_pairs,
        act_num_pair_cols=act_num_pair_cols,
        act_a_mcast_template=act_a_mcast_template,
        act_b_mcast_template=act_b_mcast_template,
    )

    # Unified SMEM allocator: data buffers + infrastructure slots.
    allocator = SmemAllocator()
    allocator.add_resource(smem_ab_resource)
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )
    dealloc_mbar_alloc = allocator.add(
        SmemAllocation("tmem_dealloc_mbar", dtype=cutlass.Int64, alignment=8)
    )
    allocator.compute_layout()

    tmem_c_resource = create_tmem_c_resource(
        num_epilogue_warps,
        act_cluster_shape_vmnk,
        tiled_mma,
        a_smem_layout,
        b_smem_layout,
        smem_ab_resource._alloc_a.offset,
        smem_ab_resource._alloc_b.offset,
        mC_mn=mC_mn,
    )

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

    load_task = create_load_task(
        gmem_ab_resource,
        smem_ab_resource,
        work_queue,
        num_k_tiles,
        num_load_warps,
    )
    mma_task = create_mma_task(
        smem_ab_resource,
        tmem_c_resource,
        work_queue,
        num_k_tiles,
        num_mma_warps,
    )
    gmem_d_resource = create_gmem_d_resource(mC_mn)
    store_task = create_store_task(
        tmem_c_resource,
        gmem_d_resource,
        work_queue,
        num_k_tiles,
        num_epilogue_warps,
    )
    task_list = [load_task, mma_task, store_task]

    if cutlass.const_expr(num_padding_warps > 0):
        padding_task = create_padding_task(
            work_queue,
            num_padding_warps,
            total_num_warps_so_far,
            num_k_tiles,
        )
        task_list.append(padding_task)

    if cutlass.const_expr(use_clc_dynamic_scheduler):
        work_schedule_task = create_work_schedule_task(work_queue, num_scheduler_warps)
        task_list.append(work_schedule_task)

    resource_dependency_graph = {
        smem_ab_resource: [gmem_ab_resource, work_queue],
        tmem_c_resource: [smem_ab_resource, work_queue],
        gmem_d_resource: [tmem_c_resource, work_queue],
    }
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        resource_dependency_graph[work_queue] = [work_queue]

    ########################################################
    # TaskManager construction
    ########################################################

    task_manager = TaskManager(
        tasks=task_list,
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )
    return task_manager, mma_task, store_task, tmem_ptr_alloc, dealloc_mbar_alloc


# ======================================================================
# Kernel execution
# ======================================================================


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
    smem_base = allocator.smem_base.data_ptr()
    tmem_ptr_i32 = cute.make_ptr(
        cutlass.Int32,
        smem_base + tmem_ptr_alloc.offset,
        cutlass.AddressSpace.smem,
    )
    tmem_dealloc_mbar_ptr = cute.make_ptr(
        cutlass.Int64,
        smem_base + dealloc_mbar_alloc.offset,
        cutlass.AddressSpace.smem,
    )

    if warp_idx == tmem_allocator_warp_id:
        with cute.arch.elect_one():
            cute.arch.mbarrier_init(tmem_dealloc_mbar_ptr, 32)

    cute.arch.mbarrier_init_fence()
    cute.arch.cluster_arrive_relaxed()
    cute.arch.cluster_wait()

    num_tmem_cols = 512
    tmem_bar_id = 2
    tmem_bar_threads = (num_epilogue_warps + num_mma_warps) * 32

    if warp_idx == tmem_allocator_warp_id:
        cute.arch.alloc_tmem(num_tmem_cols, tmem_ptr_i32, is_two_cta=True)
        cute.arch.relinquish_tmem_alloc_permit(is_two_cta=True)

    if store_task.is_selected() or mma_task.is_selected():
        prims.barrier(barrier_id=tmem_bar_id, number_of_threads=tmem_bar_threads)

    task_manager.run()

    dealloc_bar_id = 3
    dealloc_bar_threads = num_epilogue_warps * 32
    if store_task.is_selected():
        cute.arch.barrier(
            barrier_id=dealloc_bar_id, number_of_threads=dealloc_bar_threads
        )

    if warp_idx == tmem_allocator_warp_id:
        cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
        peer_cta_rank = cta_rank_in_cluster ^ 1

        cute.arch.mbarrier_arrive(tmem_dealloc_mbar_ptr, peer_cta_rank)
        cute.arch.mbarrier_wait(tmem_dealloc_mbar_ptr, 0)

        tmem_ptr = cute.arch.retrieve_tmem_ptr(
            acc_dtype,
            alignment=16,
            ptr_to_buffer_holding_addr=tmem_ptr_i32,
        )
        cute.arch.dealloc_tmem(tmem_ptr, num_tmem_cols, is_two_cta=True)


########################################################
# Kernel
########################################################


@cute.kernel
def kernel(
    tiled_mma: cute.TiledMma,
    tma_atom_a: cute.CopyAtom,
    mA_mkl: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    mB_nkl: cute.Tensor,
    mC_mn: cute.Tensor,
    a_smem_layout: cute.ComposedLayout,
    b_smem_layout: cute.ComposedLayout,
    cta_layout_vmnk: cute.Layout,
    mnk: Tuple[int, int, int],
    tile_sched_params: object,
) -> None:
    """
    CuteDSL warp-specialised persistent GEMM kernel.
    """
    m, n, k = mnk
    num_k_tiles = (k + mma_tiler_mnk[2] - 1) // mma_tiler_mnk[2]

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

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
        fb = fallback_cluster_shape_mnk
        fb_num_pairs = (fb[0] * fb[1]) // num_mma_ctas
        fb_num_pair_rows = fb[0] // num_mma_ctas
        fb_num_pair_cols = fb[1]
        fb_a_mcast = sum(1 << (num_mma_ctas * c) for c in range(fb_num_pair_cols))
        fb_b_mcast = sum(
            1 << (fb_num_pair_cols * num_mma_ctas * r) for r in range(fb_num_pair_rows)
        )
        fb_vmnk = (num_mma_ctas, fb[0] // num_mma_ctas, fb[1], fb[2])

        pref_tm, pref_mma, pref_store, pref_tp, pref_dm = _create_gemm_pipeline(
            tma_atom_a,
            tma_atom_b,
            mA_mkl,
            mB_nkl,
            mC_mn,
            tile_sched_params,
            num_k_tiles,
            tiled_mma,
            a_smem_layout,
            b_smem_layout,
            cta_layout_vmnk,
            act_num_pairs=num_pairs,
            act_num_pair_cols=num_pair_cols,
            act_a_mcast_template=_a_mcast_template,
            act_b_mcast_template=_b_mcast_template,
            act_cluster_shape_vmnk=pref_vmnk,
            clc_response_ptr=clc_response_ptr,
        )
        fb_tm, fb_mma, fb_store, fb_tp, fb_dm = _create_gemm_pipeline(
            tma_atom_a,
            tma_atom_b,
            mA_mkl,
            mB_nkl,
            mC_mn,
            tile_sched_params,
            num_k_tiles,
            tiled_mma,
            a_smem_layout,
            b_smem_layout,
            cta_layout_vmnk,
            act_num_pairs=fb_num_pairs,
            act_num_pair_cols=fb_num_pair_cols,
            act_a_mcast_template=fb_a_mcast,
            act_b_mcast_template=fb_b_mcast,
            act_cluster_shape_vmnk=fb_vmnk,
            clc_response_ptr=clc_response_ptr,
        )

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
        tm, mma, store, tp, dm = _create_gemm_pipeline(
            tma_atom_a,
            tma_atom_b,
            mA_mkl,
            mB_nkl,
            mC_mn,
            tile_sched_params,
            num_k_tiles,
            tiled_mma,
            a_smem_layout,
            b_smem_layout,
            cta_layout_vmnk,
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
            tp,
            dm,
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
) -> None:
    # CuteDSL TiledMma construction
    op = cute.nvgpu.tcgen05.MmaF16BF16Op(
        io_dtype,
        acc_dtype,
        mma_inst_shape_mnk,
        cute.nvgpu.tcgen05.CtaGroup.TWO,
        cute.nvgpu.tcgen05.OperandSource.SMEM,
        cute.nvgpu.tcgen05.OperandMajorMode.K,
        cute.nvgpu.tcgen05.OperandMajorMode.K,
    )
    tiled_mma = cute.make_tiled_mma(op)

    # CuteDSL SMEM layouts for A and B
    a_smem_shape = cute.append(
        tiled_mma.partition_shape_A(
            (
                cute.size(mma_tiler_mnk, mode=[0]),
                cute.size(mma_tiler_mnk, mode=[2]),
            )
        ),
        ab_stages,
    )
    a_smem_layout_atom = cute.nvgpu.tcgen05.make_smem_layout_atom(
        cute.nvgpu.tcgen05.SmemLayoutAtomKind.K_SW128,
        a.element_type,
    )
    a_smem_layout = cute.nvgpu.tcgen05.tile_to_mma_shape(
        a_smem_layout_atom,
        a_smem_shape,
        order=(0, 1, 2),
    )

    b_smem_shape = cute.append(
        tiled_mma.partition_shape_B(
            (
                cute.size(mma_tiler_mnk, mode=[1]),
                cute.size(mma_tiler_mnk, mode=[2]),
            )
        ),
        ab_stages,
    )
    b_smem_layout_atom = cute.nvgpu.tcgen05.make_smem_layout_atom(
        cute.nvgpu.tcgen05.SmemLayoutAtomKind.K_SW128,
        b.element_type,
    )
    b_smem_layout = cute.nvgpu.tcgen05.tile_to_mma_shape(
        b_smem_layout_atom,
        b_smem_shape,
        order=(0, 1, 2),
    )

    # CuteDSL VMNK cluster layout
    cta_layout_mnk = cute.make_layout(cluster_shape_mnk)
    cta_layout_vmnk = cute.tiled_divide(cta_layout_mnk, (tiled_mma.thr_id,))

    # CuteDSL TMA load atoms with multicast
    tma_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp(
        cute.nvgpu.tcgen05.CtaGroup.TWO
    )
    a_smem_layout_slice = cute.slice_(a_smem_layout, (None, None, None, 0))
    a_tma_atom, a_tma_tensor = cute.nvgpu.make_tiled_tma_atom_A(
        tma_op,
        a,
        a_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        cta_layout_vmnk.shape,
    )
    b_smem_layout_slice = cute.slice_(b_smem_layout, (None, None, None, 0))
    b_tma_atom, b_tma_tensor = cute.nvgpu.make_tiled_tma_atom_B(
        tma_op,
        b,
        b_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        cta_layout_vmnk.shape,
    )

    cta_tile_shape_mnk = (
        mma_tiler_mnk_per_cta[0],
        mma_tiler_mnk[1],
        mma_tiler_mnk[2],
    )

    tile_sched_params, grid_shape = compute_grid(
        c,
        cta_tile_shape_mnk,
        cluster_shape_mnk,
        max_active_clusters,
    )

    block_size = 32 * (4 + 1 + 1)
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        block_size = 32 * (4 + 1 + 1 + 1)
    block_size = (block_size + 127) // 128 * 128

    if cutlass.const_expr(fallback_cluster_shape_mnk is not None):
        kernel(
            tiled_mma,
            a_tma_atom,
            a_tma_tensor,
            b_tma_atom,
            b_tma_tensor,
            c,
            a_smem_layout,
            b_smem_layout,
            cta_layout_vmnk,
            mnk,
            tile_sched_params,
        ).launch(
            grid=grid_shape,
            block=[block_size, 1, 1],
            cluster=cluster_shape_mnk,
            fallback_cluster=fallback_cluster_shape_mnk,
        )
    else:
        kernel(
            tiled_mma,
            a_tma_atom,
            a_tma_tensor,
            b_tma_atom,
            b_tma_tensor,
            c,
            a_smem_layout,
            b_smem_layout,
            cta_layout_vmnk,
            mnk,
            tile_sched_params,
        ).launch(
            grid=grid_shape,
            block=[block_size, 1, 1],
            cluster=cluster_shape_mnk,
        )


# ======================================================================
# Run / validation
# ======================================================================


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

    compiled_fn = cute.compile[cute.FrontendNext, cute.GenerateLineInfo(True)](
        callable,
        a_,
        b_,
        c_,
        mnk,
        max_active_clusters,
    )
    return partial(compiled_fn, a_, b_, c_, mnk), (a, b, c)


def run_dense_gemm_ws(
    mnk: Tuple[int, int, int],
    tolerance: float,
    dtype: Optional[str] = None,
) -> None:
    global torch, cutlass_torch
    import torch
    import torch.nn.functional as F
    import cutlass.torch as cutlass_torch

    if dtype is not None:
        _set_io_dtype(dtype)

    # --- Guard unsupported configurations ---
    if cluster_shape_mnk != (2, 1, 1):
        raise NotImplementedError(
            f"Cluster shapes other than (2,1,1) are not yet "
            f"supported. Got cluster_shape_mnk={cluster_shape_mnk}."
        )
    if fallback_cluster_shape_mnk is not None:
        raise NotImplementedError("Fallback cluster_shape_mnk is not yet supported.")

    scheduler_mode = (
        "CLC dynamic persistent" if use_clc_dynamic_scheduler else "static persistent"
    )
    fallback_str = (
        f" (fallback: {fallback_cluster_shape_mnk})"
        if fallback_cluster_shape_mnk is not None
        else ""
    )
    print("===================================================================")
    print("Running Blackwell 16-bit GEMM example 3 CuteDSL+TS with:")
    print(f"  mnk:       {mnk}")
    print(f"  dtype:     {_get_io_dtype_name()}")
    print(f"  cluster:   {cluster_shape_mnk}{fallback_str}")
    print(f"  scheduler: {scheduler_mode}")
    print(f"  tolerance: {tolerance}")
    print("===================================================================")
    print()

    m, n, k = mnk
    torch.manual_seed(1111)

    run_fn, (a, b, c) = prepare_run(
        host_function, m, n, k, io_dtype, io_dtype, io_dtype
    )
    run_fn()

    ref = F.linear(a.to(torch.float32), b.to(torch.float32))

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
        description="Blackwell 16-bit GEMM example 3 CuteDSL+TS"
    )
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=(512, 512, 256),
        help="MNK dimensions (comma-separated)",
    )
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
    args = parser.parse_args()
    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")

    _set_io_dtype(args.dtype)

    globals()["use_clc_dynamic_scheduler"] = args.clc_dynamic_scheduler

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

    if args.fallback_cluster is not None:
        fb = tuple(args.fallback_cluster)
        if len(fb) != 3:
            parser.error("--fallback-cluster must contain exactly 3 values")
        if fb[0] % num_mma_ctas != 0:
            parser.error(f"fallback cluster_m must be divisible by {num_mma_ctas}")
        globals()["fallback_cluster_shape_mnk"] = fb

    m, n, k = args.mnk
    if cluster_shape_mnk[0] % num_mma_ctas != 0:
        raise ValueError(f"cluster_m must be divisible by {num_mma_ctas}")
    if m % super_tile_m != 0:
        raise ValueError(f"m must be divisible by super_tile_m={super_tile_m}")
    if n % super_tile_n != 0:
        raise ValueError(f"n must be divisible by super_tile_n={super_tile_n}")
    if n % 32 != 0:
        raise ValueError("n must be divisible by 32")

    run_dense_gemm_ws(args.mnk, args.tolerance, args.dtype)
    print("PASS")
