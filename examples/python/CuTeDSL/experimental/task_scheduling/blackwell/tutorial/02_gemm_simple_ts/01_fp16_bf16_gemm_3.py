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

"""Single-CTA TS FP16/BF16 GEMM tutorial kernel.

Each CTA computes one 128 x 256 output tile. A single load task TMA-loads both
A and B into one combined SMEM resource, one MMA task accumulates the tile in
TMEM, and one store task drains the accumulator to GMEM. The task graph is
linear:

    GmemAbResource -> SmemAbResource -> TmemCResource -> GmemDResource

Resource/task flow:

                   +-------------------+
                   |   GmemAbResource  |
                   |  tile coordinates |
                   +---------+---------+
                             |
                LoadTask: compute A/B coords,
                TMA A and B into one SMEM resource
                             v
                   +---------+---------+
                   |  SmemAbResource   |
                   |  TmaUmma pipeline |
                   +---------+---------+
                             |
                MmaTask: wait SMEM, build descriptors,
                issue CTA_1 MMA into TMEM
                             v
                   +---------+---------+
                   |   TmemCResource   |
                   |  UmmaAsync pipe   |
                   +---------+---------+
                             |
                StoreTask: wait accumulator,
                T2R subtiles, store GMEM output
                             v
                   +---------+---------+
                   |   GmemDResource   |
                   |      output       |
                   +-------------------+
"""

import argparse
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
import sys
from typing import Callable, Optional, Tuple, Type

import cuda.bindings.driver as cuda_driver

import cutlass
import cutlass.experimental.cuda as cuda
from cutlass import Numeric
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack, make_fake_stream
import cutlass.pipeline as pipeline

from cutlass.experimental.task_scheduling.enums import WorkAttr
from cutlass.experimental.task_scheduling.memory import (
    SmemAllocation,
    SmemAllocator,
    TmemAllocation,
    TmemAllocator,
)
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    PipelineConfig,
    StageInfo,
    TaskLocalVariable,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import domain_loop, schedule
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

# Supported input/output element types selectable from the command line.
_DTYPE_MAP = {"fp16": cutlass.Float16, "bf16": cutlass.BFloat16}


def _set_io_dtype(dtype_name: str) -> None:
    """
    Select the global input/output dtype for A/B/C from a name string.

    The kernel reads the module-level ``io_dtype`` global when building TMA
    descriptors and MMA instruction descriptors, so this helper validates the
    requested name and rebinds that global in place.

    Args:
        dtype_name: One of the keys in ``_DTYPE_MAP`` (``"fp16"`` or ``"bf16"``).

    Raises:
        ValueError: If ``dtype_name`` is not a supported dtype.
    """
    normalized = dtype_name.strip().lower()
    if normalized not in _DTYPE_MAP:
        choices = ", ".join(_DTYPE_MAP.keys())
        raise ValueError(
            f"Unsupported dtype '{dtype_name}'. Expected one of: {choices}"
        )
    globals()["io_dtype"] = _DTYPE_MAP[normalized]


def _get_io_dtype_name() -> str:
    """
    Return the short name (``"fp16"``/``"bf16"``) of the current ``io_dtype``.

    Used only for human-readable logging of the active configuration.
    """
    if io_dtype is cutlass.BFloat16:
        return "bf16"
    return "fp16"


# Active 16-bit input/output dtype (mutated by `_set_io_dtype`).
io_dtype = _DTYPE_MAP["fp16"]
# Accumulation always happens in FP32 in TMEM, regardless of the I/O dtype.
acc_dtype = cutlass.Float32

# CTA_1 MMA shapes. One CTA computes a 128 x 256 output tile and walks K in
# 64-element TMA stages.
# mma_inst_shape_mnk: the per-instruction tcgen05 MMA shape (M, N, K).
mma_inst_shape_mnk = (128, 256, 16)
# mma_tiler_mnk: the full CTA output tile and the K step taken per TMA stage.
mma_tiler_mnk = (128, 256, 64)

# Number of buffered SMEM A/B pipeline stages (producer/consumer depth).
ab_stages = 3
# Number of buffered TMEM accumulator pipeline stages.
acc_stages = 2
# Thread count of the epilogue (store) warp group: 4 warps x 32 threads.
threads_in_epilogue = 128
# When True, tasks emit per-stage runtime debug prints during execution.
debug_print = False


########################################################
# Resource definitions
########################################################


@dataclass
class GmemAbResource(MemoryResource):
    """Coordinate source for A/B TMA loads.

    This resource has no storage and no pipeline. It maps the current CTA tile
    plus K-loop index into the coordinates consumed by `SmemAbResource.tma_load`.
    """

    coord_k: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_m: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    coord_n: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        """
        Declare the three captured coordinate values owned by this resource.

        ``coord_k``, ``coord_m`` and ``coord_n`` are ``TaskLocalVariable``s: they
        are the dataflow edges produced by ``compute_coords`` and consumed by
        ``SmemAbResource.tma_load``.
        """
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

    @consumer_work(returns=(coord_k, coord_m, coord_n))
    @cute.jit
    def compute_coords(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        """
        Compute the (K, M, N) tile coordinates for the current K stage.

        This is consumer work because it reads the CTA id and the K-loop offset
        out of this coordinate resource. ``stage_info.loop_offset`` is the K-tile
        index from the surrounding ``domain_loop``.

        Returns:
            The K, M, and N element offsets of the tile to TMA-load next.
        """
        bx, by, _ = cute.arch.block_idx()
        coord_k = stage_info.loop_offset * mma_tiler_mnk[2]
        coord_m = bx * mma_tiler_mnk[0]
        coord_n = by * mma_tiler_mnk[1]
        return coord_k, coord_m, coord_n


@dataclass
class SmemAbResource(MemoryResource):
    """
    Combined staged SMEM resource for GEMM operands A and B.

    This resource owns the staged shared-memory tiles for both operands behind a
    single ``TmaUmma`` pipeline: the load task (producer) TMA-fills the stage and
    the MMA task (consumer) reads it through SMEM descriptors. Holding A and B in
    one resource lets a single pipeline guard both transfers with one barrier.

    The SMEM storage is declared through ``get_smem_requirements`` and placed by
    the unified ``SmemAllocator``; the typed ``cutlass.Array`` views are materialized
    lazily from the allocator base in the auxiliary init work methods.
    """

    tma_desc_a: cutlass.Pointer = field(init=False, default=None)
    tma_desc_b: cutlass.Pointer = field(init=False, default=None)
    shared_smem_a: cutlass.Array = field(init=False, default=None)
    shared_smem_b: cutlass.Array = field(init=False, default=None)
    sA_copy_elems: cutlass.Constexpr[int] = field(init=False, default=None)
    sB_copy_elems: cutlass.Constexpr[int] = field(init=False, default=None)
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
        """
        Store the A/B TMA descriptors and declare SMEM/captured values.

        Args:
            tma_desc_a: Device pointer to the TMA tensor map for operand A.
            tma_desc_b: Device pointer to the TMA tensor map for operand B.
            **kwargs: Forwarded to ``MemoryResource`` (``name``,
                ``pipeline_config``, ...).

        It also declares the per-stage element counts, the ``desc_a_base`` /
        ``desc_b_base`` captured SMEM-descriptor values, and the two
        ``SmemAllocation``s that reserve the A and B staging buffers.
        """
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
        self.tma_desc_b = tma_desc_b
        self.sA_copy_elems = mma_tiler_mnk[0] * mma_tiler_mnk[2]
        self.sB_copy_elems = mma_tiler_mnk[1] * mma_tiler_mnk[2]
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

        elem_bytes = io_dtype.width // 8
        self._alloc_a = SmemAllocation(
            "smem_a",
            self.sA_copy_elems * ab_stages * elem_bytes,
            alignment=128,
        )
        self._alloc_b = SmemAllocation(
            "smem_b",
            self.sB_copy_elems * ab_stages * elem_bytes,
            alignment=128,
        )
        nullptr = cutlass.inttoptr(0, mem_space=3, dtype=io_dtype)
        self.shared_smem_a = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(self.sA_copy_elems * ab_stages,),
            addrspace=3,
        )
        self.shared_smem_b = cutlass.Array(
            nullptr,
            dtype=io_dtype,
            shape=(self.sB_copy_elems * ab_stages,),
            addrspace=3,
        )

    def get_smem_requirements(self):
        """
        Report the SMEM allocations (A and B buffers) to the allocator.

        Returns:
            The list of ``SmemAllocation`` objects the ``SmemAllocator`` must
            place in the unified shared-memory block.
        """
        return [self._alloc_a, self._alloc_b]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        """
        Materialize typed A/B ``cutlass.Array`` views over the allocator base.

        The allocator owns the raw SMEM block; this derives the per-operand views
        at the offsets reserved in ``__init__``. Shared by the producer and
        consumer auxiliary init methods.
        """
        smem_base = stage_info.context.smem_base
        self.shared_smem_a = cutlass.Array(
            smem_base.data_ptr() + self._alloc_a.offset,
            dtype=io_dtype,
            shape=(self.sA_copy_elems * ab_stages,),
            addrspace=3,
        )
        self.shared_smem_b = cutlass.Array(
            smem_base.data_ptr() + self._alloc_b.offset,
            dtype=io_dtype,
            shape=(self.sB_copy_elems * ab_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        """
        Producer-side setup: build SMEM views for the load (TMA) task.

        Auxiliary work, so it runs in the head phase and is not subject to the
        producer pipeline bracket.
        """
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_descriptors(self, stage_info: StageInfo) -> None:
        """
        Consumer-side setup: build SMEM views for the MMA task.

        Auxiliary work, so it runs in the head phase before the K loop.
        """
        self._init_smem_state(stage_info)

    @consumer_work(returns=(desc_a_base, desc_b_base))
    @cute.jit
    def build_descriptors(
        self, stage_info: StageInfo
    ) -> tuple[cutlass.Int64, cutlass.Int64]:
        """
        Build the tcgen05 SMEM descriptors for the current pipeline stage.

        Consumer work: it reads the staged A/B SMEM tiles (selected by
        ``stage_info.stage_idx``) and returns descriptor base addresses that the
        MMA producer work consumes.

        Returns:
            The A and B SMEM-descriptor base values for ``tcgen05_mma``.
        """
        sA_curr = self.shared_smem_a.subview(self.sA_copy_elems * stage_info.stage_idx)
        sB_curr = self.shared_smem_b.subview(self.sB_copy_elems * stage_info.stage_idx)

        desc_a_base = prims.Tcgen05SmemDesc.build(
            sA_curr,
            leading_byte_offset=16,
            stride_byte_offset=1024,
            layout=2,
        )
        desc_b_base = prims.Tcgen05SmemDesc.build(
            sB_curr,
            leading_byte_offset=16,
            stride_byte_offset=1024,
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
        """
        Issue the TMA bulk copies that fill the current SMEM stage.

        This is the producer work that writes into the resource: one elected
        thread launches the A and B ``cp.async.bulk.tensor`` transfers into the
        stage selected by ``stage_info.stage_idx`` and arms ``stage_info.barrier``
        so the consumer ``wait`` can detect completion.

        Args:
            coord_k: K element offset of the tile (shared by A and B).
            coord_m: M element offset for operand A.
            coord_n: N element offset for operand B.
        """
        if prims.elect_sync():
            sA_curr = self.shared_smem_a.subview(
                self.sA_copy_elems * stage_info.stage_idx
            )
            sB_curr = self.shared_smem_b.subview(
                self.sB_copy_elems * stage_info.stage_idx
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                sA_curr,
                self.tma_desc_a,
                (coord_k, coord_m),
                stage_info.barrier,
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                sB_curr,
                self.tma_desc_b,
                (coord_k, coord_n),
                stage_info.barrier,
            )


@dataclass
class TmemCResource(MemoryResource):
    """
    TMEM accumulator resource between MMA and epilogue tasks.

    This resource owns the FP32 accumulator tile in tensor memory behind a
    ``UmmaAsync`` pipeline: the MMA task (producer) accumulates into TMEM with
    ``tcgen05_mma`` and the store task (consumer) loads register subtiles out of
    TMEM (T2R) for the epilogue.

    The TMEM columns are declared through ``get_tmem_requirements`` and placed by
    ``TmemAllocator``, but the actual hardware ``tcgen05_alloc`` / ``dealloc``
    still happens explicitly in ``_run_gemm_execution``.
    """

    t2r_inst_shape: cutlass.Constexpr[str] = field(init=False, default=None)
    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    scale_d: cutlass.Boolean = field(init=False, default=None)
    idesc: prims.Tcgen05InstrDesc = field(init=False, default=None)
    tmem_raw_addr: cutlass.Int32 = field(init=False, default=None)
    _alloc_acc: cutlass.Constexpr = field(init=False, default=None)
    t2r_rmem: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(self, **kwargs: object) -> None:
        """
        Declare the TMEM accumulator allocation and the T2R captured value.

        Sets the tcgen05 T2R load shape/repeat count, reserves the accumulator
        TMEM columns (``mma_tiler_mnk[1] * acc_stages``), and declares
        ``t2r_rmem`` as the register fragment produced by ``load_subtile`` and
        consumed by ``GmemDResource.store``.
        """
        super().__init__(**kwargs)
        self.t2r_inst_shape = "32x32b"
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

    def get_tmem_requirements(self):
        """
        Report the TMEM accumulator allocation to the ``TmemAllocator``.

        Returns:
            The single ``TmemAllocation`` reserving the accumulator columns.
        """
        return [self._alloc_acc]

    @cute.jit
    def _init_tmem_state(self, stage_info: StageInfo) -> None:
        """
        Build the MMA instruction descriptor and read the TMEM base address.

        Shared by the producer and consumer auxiliary init methods. Also resets
        ``scale_d`` to False so the first MMA of a tile overwrites rather than
        accumulates.
        """
        self.idesc = prims.Tcgen05InstrDesc.build(
            a_dtype=io_dtype,
            b_dtype=io_dtype,
            c_dtype=cutlass.Float32,
            n_dim=mma_inst_shape_mnk[1],
            m_dim=mma_inst_shape_mnk[0],
        )
        self.tmem_raw_addr = stage_info.context.tmem_ptr_i32.load()
        self.scale_d = cutlass.Boolean(False)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_accumulator_state(self, stage_info: StageInfo) -> None:
        """
        Producer-side setup for the MMA task (head-phase auxiliary work).
        """
        self._init_tmem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        """
        Consumer-side setup for the store task (head-phase auxiliary work).
        """
        self._init_tmem_state(stage_info)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_work_tile_state(self, stage_info: StageInfo) -> None:
        """
        Reset the accumulate flag at the start of each output tile.

        ``scale_d=False`` makes the first ``tcgen05_mma`` of the K loop overwrite
        the accumulator; ``mma`` flips it to True afterwards.
        """
        del stage_info
        self.scale_d = cutlass.Boolean(False)

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_subtile(
        self, stage_info: StageInfo, *, subtile_idx: cutlass.Constexpr[int]
    ) -> cutlass.Float32:
        """
        Load one 32-column accumulator subtile from TMEM into registers (T2R).

        Consumer work: it reads the accumulator out of TMEM. ``subtile_idx``
        selects which subtile (the store tail calls this once per N subtile).

        Args:
            subtile_idx: 0-based subtile ordinal supplied by the schedule (the
                per-section consumer-work counter for this resource).

        Returns:
            The register fragment for this subtile, consumed by the GMEM store.
        """
        warp_idx = cute.arch.warp_idx()
        base_col_id = (
            (self.tmem_raw_addr & 0xFFFF)
            + stage_info.stage_idx * mma_tiler_mnk[1]
            + subtile_idx * self.t2r_inst_repx
        )
        tmem_ptr = prims.make_tmem_ptr_from_warp_row_col(
            self.tmem_raw_addr,
            warp_idx,
            base_col_id,
            cutlass.Float32,
        )
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
        """
        Issue the tcgen05 MMAs that accumulate one K stage into TMEM.

        This is the producer work that writes into the accumulator: it loops over
        the 16-wide K blocks inside the current 64-wide TMA stage, advancing the
        A/B SMEM descriptors and issuing one ``tcgen05_mma`` per block.
        ``scale_d`` starts False (overwrite) and becomes True so subsequent blocks
        accumulate.

        Args:
            desc_a_base: SMEM descriptor base for operand A (from
                ``build_descriptors``).
            desc_b_base: SMEM descriptor base for operand B.
        """
        tmem_ptr = prims.make_tmem_ptr(self.tmem_raw_addr, acc_dtype)
        tmem_ptr_for_mma = (
            tmem_ptr.data_ptr() + stage_info.stage_idx * mma_tiler_mnk[1] // 4
        )
        tmem_ptr_curr = cutlass.Array(
            tmem_ptr_for_mma,
            dtype=cutlass.Int32,
            addrspace=6,
        )

        num_k_blocks = mma_tiler_mnk[2] // mma_inst_shape_mnk[2]
        for k_block_idx in cutlass.range_constexpr(num_k_blocks):
            inc_bytes_per_iter = mma_inst_shape_mnk[2] * io_dtype.width // 8
            increment = (inc_bytes_per_iter * k_block_idx) >> 4
            desc_a = desc_a_base + increment
            desc_b = desc_b_base + increment

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
    """
    Write-only GMEM output sink for the epilogue.

    A pure sink with no pipeline of its own: it just writes register subtiles
    produced by ``TmemCResource.load_subtile`` into the output matrix ``D``. The
    upstream ``t2r_rmem`` captured value is auto-mirrored on the producer side.
    """

    t2r_inst_repx: cutlass.Constexpr[int] = field(init=False, default=None)
    mC_mn: cute.Tensor = field(init=False, default=None)
    gC: cutlass.Array = field(init=False, default=None)
    vsize: cutlass.Constexpr[int] = field(init=False, default=None)

    def __init__(self, mC_mn: cute.Tensor, **kwargs: object) -> None:
        """
        Bind the output tensor and derive the vectorized store width.

        Args:
            mC_mn: The output matrix ``D`` with shape ``(M, N)``.
            **kwargs: Forwarded to ``MemoryResource`` (e.g. ``name``).
        """
        super().__init__(**kwargs)
        self.t2r_inst_repx = 32
        self.mC_mn = mC_mn
        self.gC = cutlass.make_array_view(mC_mn)
        self.vsize = 256 // self.gC.dtype.width

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
        Write one register subtile into the output GMEM matrix.

        Producer work that writes into the output resource. It maps the CTA tile
        plus ``subtile_idx`` to the output row/column, then stores the register
        fragment with a vectorized fast path and a scalar tail for the ragged
        edge near the column boundary.

        Args:
            t2r_rmem: The register subtile from ``TmemCResource.load_subtile``.
            subtile_idx: 0-based subtile ordinal supplied by the schedule (the
                per-section producer-work counter for this resource).
        """
        bx, by, _ = cute.arch.block_idx()
        coordc_m = bx * mma_tiler_mnk[0]
        coordc_n = by * mma_tiler_mnk[1]
        tx, _, _ = cute.arch.thread_idx()
        row = coordc_m + tx
        col = coordc_n + subtile_idx * self.t2r_inst_repx
        num_rows = self.mC_mn.shape[0]
        num_cols = self.mC_mn.shape[1]
        gC_ptr = self.mC_mn.iterator.raw_ptr()

        if row < num_rows:
            row_offset = cutlass.Int64(row) * cutlass.Int64(num_cols)
            for j in cutlass.range_constexpr(self.t2r_inst_repx // self.vsize):
                chunk_col = col + j * self.vsize
                vec_f32 = t2r_rmem[j * self.vsize : j * self.vsize + self.vsize]

                if chunk_col + self.vsize <= num_cols:
                    (gC_ptr + row_offset + cutlass.Int64(chunk_col)).store(
                        vec_f32.to(io_dtype),
                        alignment=16,
                    )
                else:
                    for i in cutlass.range_constexpr(self.vsize):
                        col_idx = chunk_col + i
                        if col_idx < num_cols:
                            (gC_ptr + row_offset + cutlass.Int64(col_idx)).store(
                                vec_f32[i].to(io_dtype)
                            )


########################################################
# Resource construction helpers
########################################################


@cute.jit
def create_gmem_ab_resource() -> GmemAbResource:
    """
    Create the coordinate-source resource (no storage, no pipeline).
    """
    return GmemAbResource(name="GmemAb")


def create_smem_ab_resource(
    tma_a_desc: cutlass.Pointer,
    tma_b_desc: cutlass.Pointer,
) -> SmemAbResource:
    """
    Create the staged SMEM A/B resource with its TMA-to-UMMA pipeline.

    Sizes the ``TmaUmma`` pipeline so the producer transaction-byte count covers
    one A tile plus one B tile, with a single-thread MMA consumer group.

    Args:
        tma_a_desc: Device pointer to the TMA tensor map for operand A.
        tma_b_desc: Device pointer to the TMA tensor map for operand B.

    Returns:
        A configured ``SmemAbResource``.
    """
    sA_copy_bytes = mma_tiler_mnk[0] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    sB_copy_bytes = mma_tiler_mnk[1] * mma_tiler_mnk[2] * (io_dtype.width // 8)
    smem_ab_pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=ab_stages,
        num_bytes=sA_copy_bytes + sB_copy_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        cta_layout_vmnk=(1, 1, 1, 1),
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
    Create the TMEM accumulator resource with its UMMA-to-thread pipeline.

    The ``UmmaAsync`` pipeline has a single-thread MMA producer and a consumer
    group sized to the whole epilogue warp group.

    Args:
        num_epilogue_warps: Number of warps in the store task; sets the consumer
            cooperative-group size (``num_epilogue_warps * 32`` threads).

    Returns:
        A configured ``TmemCResource``.
    """
    tmem_c_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread,
        size=num_epilogue_warps * 32,
    )
    tmem_c_pipeline_config = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=tmem_c_pipeline_consumer_group,
        cta_layout_vmnk=(1, 1, 1, 1),
    )
    return TmemCResource(
        pipeline_config=tmem_c_pipeline_config,
        name="TmemC",
    )


@cute.jit
def create_gmem_d_resource(mC_mn: cute.Tensor) -> GmemDResource:
    """
    Create the output GMEM sink resource for matrix ``D``.

    Args:
        mC_mn: The output matrix ``D`` with shape ``(M, N)``.

    Returns:
        A configured ``GmemDResource``.
    """
    return GmemDResource(mC_mn=mC_mn, name="GmemD")


########################################################
# Task schedule construction helpers
########################################################


@cute.jit
def create_load_task(
    gmem_ab_resource: GmemAbResource,
    smem_ab_resource: SmemAbResource,
    num_k_tiles: int,
    num_load_warps: int,
) -> Task:
    """
    Build the load task: warp 4 TMA-loads A and B into combined SMEM.

    Captures the producer schedule (compute coords, acquire/commit bracket around
    ``tma_load``) and binds it to the load warp.

    Args:
        gmem_ab_resource: Coordinate source consumed by the task.
        smem_ab_resource: SMEM A/B resource produced by the task.
        num_k_tiles: Number of K stages, i.e. the producer ``domain_loop`` length.
        num_load_warps: Warp count for this task.

    Returns:
        The configured ``LoadTask``.
    """

    @schedule
    def load_schedule(gmem_ab: MemoryResource, smem_ab: MemoryResource) -> None:
        """
        Producer schedule: per K tile, compute coords then TMA into a stage.
        """
        smem_ab.init_load_state()
        with domain_loop(0, num_k_tiles, 1):
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
    num_k_tiles: int,
    num_mma_warps: int,
) -> Task:
    """
    Build the MMA task: warp 5 consumes SMEM and accumulates into TMEM.

    This task is a consumer of ``SmemAbResource`` and a producer of
    ``TmemCResource``. The accumulator is acquired before the K loop and
    committed after it, so all K stages land in one tile before the store task
    may read it.

    Args:
        smem_ab_resource: SMEM A/B resource consumed by the task.
        tmem_c_resource: TMEM accumulator resource produced by the task.
        num_k_tiles: Number of K stages (the consumer ``domain_loop`` length).
        num_mma_warps: Warp count for this task.

    Returns:
        The configured ``MmaTask``.
    """

    @schedule
    def mma_schedule(smem_ab: MemoryResource, tmem_c: MemoryResource) -> None:
        """
        Consumer/producer schedule: drain SMEM stages, accumulate one tile.
        """
        smem_ab.init_descriptors()
        tmem_c.init_accumulator_state()
        tmem_c.init_work_tile_state()
        tmem_c.try_acquire()
        tmem_c.acquire()
        with domain_loop(0, num_k_tiles, 1):
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
    num_k_tiles: int,
    num_epilogue_warps: int,
) -> Task:
    """
    Build the store task: warps 0-3 drain TMEM subtiles and store GMEM.

    The K ``domain_loop`` body is empty on purpose so the TMEM consume/store work
    runs in the tail phase, after the MMA task commits the complete accumulator.

    Args:
        tmem_c_resource: TMEM accumulator resource consumed by the task.
        gmem_d_resource: Output GMEM resource produced by the task.
        num_k_tiles: Number of K stages (length of the empty pacing loop).
        num_epilogue_warps: Warp count for this task.

    Returns:
        The configured ``StoreTask``.
    """

    subtile_cnt = mma_tiler_mnk[1] // 32

    @schedule
    def store_schedule(tmem_c: MemoryResource, gmem_d: MemoryResource) -> None:
        """
        Consumer schedule: wait the accumulator, then T2R + store each subtile.
        """
        tmem_c.init_store_state()
        with domain_loop(0, num_k_tiles, 1):
            pass
        tmem_c.try_wait()
        tmem_c.wait()
        for subtile_idx in cutlass.range_constexpr(subtile_cnt):
            t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
            gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
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
    num_k_tiles: int,
) -> Task:
    """
    Build a padding task to fill out the last 4-warp group.

    CUDA register reallocation works per 4-warp group, so TS requires every warp
    in a group to declare a register budget. This task owns the leftover warps
    with a matching budget and an empty schedule.

    Args:
        num_padding_warps: Number of warps to cover.
        total_num_warps_so_far: First warp index for this task.
        num_k_tiles: Length of the empty pacing loop, to match other tasks.

    Returns:
        The configured ``PaddingTask``.
    """

    @schedule
    def padding_schedule() -> None:
        """
        Empty schedule: iterate the K domain doing no work.
        """
        with domain_loop(0, num_k_tiles, 1):
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


########################################################
# Resource and task construction
########################################################


def _create_gemm_pipeline(
    tma_a_desc: object,
    tma_b_desc: object,
    mC_mn: object,
    num_k_tiles: int,
) -> tuple[TaskManager, Task, Task, SmemAllocation]:
    """
    Create the full TS resource/task skeleton for the GEMM.

    Builds the four resources, runs the SMEM and TMEM allocators, creates the
    load/MMA/store tasks plus a padding task, declares the linear dependency
    graph, and wires everything into a ``TaskManager``.

    Args:
        tma_a_desc: Device pointer to operand A's TMA tensor map.
        tma_b_desc: Device pointer to operand B's TMA tensor map.
        mC_mn: Output matrix ``D`` tensor.
        num_k_tiles: Number of K stages the schedules loop over.

    Returns:
        ``(task_manager, mma_task, store_task, tmem_ptr_alloc)``. The MMA and
        store tasks and the TMEM-pointer allocation are returned so the execution
        helper can coordinate explicit TMEM allocation.
    """

    num_epilogue_warps = 4
    num_load_warps = 1
    num_mma_warps = 1

    ########################################################
    # Resource construction
    ########################################################

    allocator = SmemAllocator()
    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr_i32", dtype=cutlass.Int32, alignment=4)
    )

    gmem_ab_resource = create_gmem_ab_resource()
    smem_ab_resource = create_smem_ab_resource(
        tma_a_desc,
        tma_b_desc,
    )
    tmem_c_resource = create_tmem_c_resource(num_epilogue_warps)
    gmem_d_resource = create_gmem_d_resource(mC_mn)

    allocator.add_resource(smem_ab_resource)
    allocator.compute_layout()

    tmem_allocator = TmemAllocator()
    tmem_allocator.add_resource(tmem_c_resource)
    tmem_allocator.compute_layout()

    total_num_warps = num_epilogue_warps + num_load_warps + num_mma_warps
    num_padding_warps = (total_num_warps + 3) // 4 * 4 - total_num_warps

    ########################################################
    # Task schedule construction
    ########################################################

    load_task = create_load_task(
        gmem_ab_resource,
        smem_ab_resource,
        num_k_tiles,
        num_load_warps,
    )
    mma_task = create_mma_task(
        smem_ab_resource,
        tmem_c_resource,
        num_k_tiles,
        num_mma_warps,
    )
    store_task = create_store_task(
        tmem_c_resource,
        gmem_d_resource,
        num_k_tiles,
        num_epilogue_warps,
    )
    task_list = [load_task, mma_task, store_task]

    if cutlass.const_expr(num_padding_warps > 0):
        padding_task = create_padding_task(
            num_padding_warps,
            total_num_warps,
            num_k_tiles,
        )
        task_list.append(padding_task)

    resource_dependency_graph = {
        smem_ab_resource: [gmem_ab_resource],
        tmem_c_resource: [smem_ab_resource],
        gmem_d_resource: [tmem_c_resource],
    }

    ########################################################
    # TaskManager construction
    ########################################################

    task_manager = TaskManager(
        tasks=task_list,
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
        tmem_allocator=tmem_allocator,
    )
    return task_manager, mma_task, store_task, tmem_ptr_alloc


########################################################
# Kernel execution
########################################################


@cute.jit
def _run_gemm_execution(
    task_manager: TaskManager,
    mma_task: Task,
    store_task: Task,
    warp_idx: object,
    tmem_ptr_alloc: SmemAllocation,
) -> None:
    num_epilogue_warps = 4
    num_mma_warps = 1
    tmem_allocator_warp_id = 0

    task_manager.setup_resources_and_tasks()

    allocator = task_manager.smem_allocator
    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)

    prims.fence_mbarrier_init()

    num_tmem_cols = 512
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

    task_manager.run()

    dealloc_bar_id = 3
    dealloc_bar_threads = num_epilogue_warps * 32
    if store_task.is_selected():
        prims.barrier_cta_sync(dealloc_bar_id, thread_count=dealloc_bar_threads)

    if warp_idx == tmem_allocator_warp_id:
        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols)


########################################################
# Kernel
########################################################


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mC_mn: cute.Tensor,
    mnk: Tuple[int, int, int],
) -> None:
    """
    Warp-specialized single-CTA GEMM device entry point.

    Computes the K-tile count, prefetches the TMA tensor maps on the load warp,
    builds the TS skeleton, and runs it. One CTA computes one 128 x 256 tile.

    Args:
        tma_a_desc: Grid-constant TMA tensor map for operand A.
        tma_b_desc: Grid-constant TMA tensor map for operand B.
        mC_mn: Output matrix ``D`` tensor.
        mnk: Problem size ``(M, N, K)``.
    """

    _m, _n, k = mnk
    num_k_tiles = k // mma_tiler_mnk[2]

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 4:
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())

    tm, mma, store, tp_alloc = _create_gemm_pipeline(
        tma_a_desc.get_ptr(),
        tma_b_desc.get_ptr(),
        mC_mn,
        num_k_tiles,
    )
    _run_gemm_execution(
        tm,
        mma,
        store,
        warp_idx,
        tp_alloc,
    )


########################################################
# Host runners and CLI
########################################################


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    mnk: Tuple[int, int, int],
    stream,
) -> None:
    """
    Host side: build TMA descriptors, size the grid, and launch the kernel.

    Args:
        a: Operand A tensor with shape ``(M, K)``.
        b: Operand B tensor with shape ``(N, K)``.
        c: Output tensor ``D`` with shape ``(M, N)``.
        mnk: Problem size ``(M, N, K)``.
        stream: CUDA stream to launch on.
    """
    m, n, _k = mnk

    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(mma_tiler_mnk[0], mma_tiler_mnk[2]),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(mma_tiler_mnk[1], mma_tiler_mnk[2]),
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    grid_shape = (
        cute.ceil_div(m, mma_tiler_mnk[0]),
        cute.ceil_div(n, mma_tiler_mnk[1]),
        1,
    )
    block_size = cute.arch.WARP_SIZE * 8
    kernel(
        tma_a_desc,
        tma_b_desc,
        c,
        mnk,
    ).launch(
        grid=grid_shape,
        block=[block_size, 1, 1],
        stream=stream,
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
) -> tuple[Callable, tuple]:
    """
    Allocate inputs and JIT-compile the host function (cached per shape/dtype).

    The result is memoized by ``lru_cache`` so repeated calls with the same
    arguments reuse the compiled kernel and the device tensors.

    Args:
        callable: The host function to compile (``host_function``).
        m, n, k: GEMM problem dimensions.
        a_dtype, b_dtype, c_dtype: Element types for A, B, and C.

    Returns:
        ``(run_fn, (a, b, c))``: a zero-argument launcher and the device tensors.
    """
    import torch
    import cutlass.torch as cutlass_torch

    def make_tensors(mn: int, k_dim: int, dtype: Type[Numeric]) -> torch.Tensor:
        """
        Allocate one small-integer device tensor of the requested shape/dtype.
        """
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
        make_fake_stream(),
    )

    def run_fn() -> object:
        """
        Launch the compiled kernel on the current torch CUDA stream.
        """
        stream = cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)
        return compiled_fn(a_, b_, c_, mnk, stream)

    return run_fn, (a, b, c)


def _validate_mnk(mnk: Tuple[int, int, int]) -> None:
    """
    Validate that the problem size is divisible by the CTA tile shape.

    Args:
        mnk: Problem size ``(M, N, K)``.

    Raises:
        ValueError: If M, N, or K is not a multiple of the corresponding tile
            dimension.
    """
    m, n, k = mnk
    if m % mma_tiler_mnk[0] != 0:
        raise ValueError(f"m must be divisible by tile_m={mma_tiler_mnk[0]}")
    if n % mma_tiler_mnk[1] != 0:
        raise ValueError(f"n must be divisible by tile_n={mma_tiler_mnk[1]}")
    if k % mma_tiler_mnk[2] != 0:
        raise ValueError(f"k must be divisible by tile_k={mma_tiler_mnk[2]}")


def run_dense_gemm_ws(
    mnk: Tuple[int, int, int],
    tolerance: float,
    dtype: Optional[str] = None,
) -> None:
    """
    Run and validate the GEMM against a PyTorch reference.

    Sets the dtype, validates the shape, compiles and warms up the kernel, runs
    it, and compares the result to ``F.linear`` within ``tolerance``.

    Args:
        mnk: Problem size ``(M, N, K)``.
        tolerance: Absolute tolerance for ``torch.testing.assert_close``.
        dtype: Optional dtype name (``"fp16"``/``"bf16"``); keeps the current
            ``io_dtype`` if None.
    """
    global torch, cutlass_torch
    import torch
    import torch.nn.functional as F
    import cutlass.torch as cutlass_torch

    if dtype is not None:
        _set_io_dtype(dtype)
    _validate_mnk(mnk)

    print("===================================================================")
    print("Running Blackwell 16-bit GEMM TS tutorial kernel with:")
    print(f"  mnk:       {mnk}")
    print(f"  dtype:     {_get_io_dtype_name()}")
    print("  scheduler: direct CTA tile mapping")
    print(f"  tolerance: {tolerance}")
    print("===================================================================")
    print()

    m, n, k = mnk
    torch.manual_seed(1111)

    run_fn, (a, b, c) = prepare_run(
        host_function,
        m,
        n,
        k,
        io_dtype,
        io_dtype,
        io_dtype,
    )

    expected = F.linear(
        a.to(torch.float32),
        b.to(torch.float32),
        None,
    ).to(cutlass_torch.dtype(io_dtype))

    warmup_stream = torch.cuda.Stream()
    torch.cuda.synchronize()
    with torch.cuda.stream(warmup_stream):
        for _ in range(2):
            run_fn()
    warmup_stream.synchronize()

    c.zero_()
    run_fn()
    torch.cuda.synchronize()

    torch.testing.assert_close(c, expected, atol=tolerance, rtol=1e-05)
    print("PASS")


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> list[int]:
        """
        Parse a comma-separated integer string into a list (for argparse).
        """
        try:
            return [int(x.strip()) for x in s.split(",")]
        except ValueError as exc:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            ) from exc

    parser = argparse.ArgumentParser(
        description="Blackwell 16-bit GEMM TS tutorial kernel"
    )
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=(512, 512, 512),
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-01,
        help="Tolerance for validation",
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

    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)
    err, device_count = cu_driver.cuDeviceGetCount()
    if err != cu_driver.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A GPU is required to run this example")

    _set_io_dtype(args.dtype)
    run_dense_gemm_ws(
        tuple(args.mnk),
        args.tolerance,
        dtype=args.dtype,
    )
