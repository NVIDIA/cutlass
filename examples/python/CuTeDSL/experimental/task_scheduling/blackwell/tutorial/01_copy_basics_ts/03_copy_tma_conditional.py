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

"""TMA copy with conditional schedule guards (Tutorial 03).

Builds on ``02_copy_tma.py`` with the same pipelined load/store path and adds
guarded schedule regions inside ``domain_loop``:

* ``d.first_iter()`` — one-time begin marker on the load task
* ``d.every(4)`` — periodic heartbeat marker every four row iterations
* ``when_true(smem.is_highlight_tile())`` — opaque runtime guard that tags one
  host-selected highlight row on the store task
* ``d.last_iter()`` — end marker on the last row iteration

The main matrix copy result is unchanged. A separate ``trace`` tensor records
marker values so the host can verify each guard fired.

Resource/task flow:

                   +-------------------+
                   | InputGmemResource |
                   +---------+---------+
                             |
             LoadTask         v
                  +---------+---------+
                  |   SmemResource    |
                  +---------+---------+
            StoreTask       |
                            v
                  +---------+---------+
                  | OutputGmemResource|
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | TraceGmemResource |
                  |      markers      |
                  +-------------------+
"""

import argparse
import torch
from dataclasses import dataclass, field

import cutlass.cute as cute
from typing import Any, Tuple
import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.pipeline as pipeline

from cutlass.cute.runtime import from_dlpack
from cutlass.experimental.task_scheduling.resources import (
    WorkAttr,
    MemoryResource,
    StageInfo,
    TaskLocalVariable,
    PipelineConfig,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.memory import SmemAllocation, SmemAllocator
from cutlass.experimental.task_scheduling.schedule_builder import (
    domain_loop,
    schedule,
    when_true,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

num_stages = 1
tile_size = 128
STORE_TASK_WARP_IDX = 0
LOAD_TASK_WARP_IDX = 4
PADDING_TASK_WARP_IDX = 5

BEGIN_MARKER = 1000.0
HEARTBEAT_MARKER = 2000.0
HIGHLIGHT_MARKER = 3000.0
END_MARKER = 4000.0


def _expect_trace_column(
    trace: torch.Tensor,
    *,
    column: int,
    marker: float,
    expected_rows: list[int],
    label: str,
) -> None:
    """Require a trace marker column to match exactly the expected rows."""
    actual = trace[:, column]
    expected = torch.zeros_like(actual)
    if expected_rows:
        expected[expected_rows] = marker

    if torch.equal(actual, expected):
        return

    mismatch_rows = torch.nonzero(actual != expected, as_tuple=False).flatten()
    row_details = []
    for row in mismatch_rows[:8].cpu().tolist():
        row_details.append(
            f"row {row}: expected {expected[row].item()}, got {actual[row].item()}"
        )
    extra_count = max(0, mismatch_rows.numel() - len(row_details))
    suffix = f"; plus {extra_count} more mismatch(es)" if extra_count else ""
    raise RuntimeError(
        f"{label} trace column {column} does not match expected rows "
        f"{expected_rows}: {', '.join(row_details)}{suffix}"
    )


########################################################
# Resource definitions
########################################################


@dataclass
class InputGmemResource(MemoryResource):
    """Coordinate-only GMEM source: emits the TMA load row coordinate."""

    gmem_idx: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __post_init__(self) -> None:
        self.gmem_idx = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="GMEM row coordinate consumed by the SMEM TMA load.",
        )

    @consumer_work(returns=gmem_idx)
    @cute.jit
    def compute_coords(self, stage_info: StageInfo) -> cutlass.Int32:
        bx, _, _ = cute.arch.block_idx()
        return bx * tile_size


@dataclass
class TraceGmemResource(MemoryResource):
    """Side-channel trace matrix written only inside guarded schedule blocks."""

    trace: Any = field(init=False, default=None)

    def __init__(self, trace: cute.Tensor, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.trace = trace

    @producer_work
    @cute.jit
    def mark_begin(self, stage_info: StageInfo) -> None:
        bx, _, _ = cute.arch.block_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        if bx == 0:
            if warp_idx == LOAD_TASK_WARP_IDX:
                if prims.elect_sync():
                    self.trace[stage_info.loop_offset, 0] = cutlass.Float16(
                        BEGIN_MARKER
                    )

    @producer_work
    @cute.jit
    def record_heartbeat(self, stage_info: StageInfo) -> None:
        bx, _, _ = cute.arch.block_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        if bx == 0:
            if warp_idx == LOAD_TASK_WARP_IDX:
                if prims.elect_sync():
                    self.trace[stage_info.loop_offset, 1] = cutlass.Float16(
                        HEARTBEAT_MARKER
                    )

    @producer_work
    @cute.jit
    def mark_highlight(self, stage_info: StageInfo) -> None:
        bx, _, _ = cute.arch.block_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        if bx == 0:
            if warp_idx == STORE_TASK_WARP_IDX:
                if prims.elect_sync():
                    self.trace[stage_info.loop_offset, 2] = cutlass.Float16(
                        HIGHLIGHT_MARKER
                    )

    @producer_work
    @cute.jit
    def mark_end(self, stage_info: StageInfo) -> None:
        bx, _, _ = cute.arch.block_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        if bx == 0:
            if warp_idx == STORE_TASK_WARP_IDX:
                if prims.elect_sync():
                    self.trace[stage_info.loop_offset, 3] = cutlass.Float16(END_MARKER)


@dataclass
class SmemResource(MemoryResource):
    """Pipelined SMEM tile filled by TMA, consumed by the epilogue warps."""

    tma_desc_a: Any = field(init=False, default=None)
    shared_memory_values: Any = field(init=False, default=None)
    smem_val: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    is_highlight: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )
    highlight_row: int = 0
    _alloc_smem: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        tma_desc_a: cutlass.Pointer,
        highlight_row: cutlass.Constexpr,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
        self.highlight_row = highlight_row
        self.smem_val = TaskLocalVariable(
            dtype=cutlass.Float16,
            default=cutlass.Float16(0),
            docs="SMEM-loaded value consumed by the GMEM store.",
        )
        self.is_highlight = TaskLocalVariable(
            dtype=cutlass.Boolean,
            default=cutlass.Boolean(False),
            docs="Guard value for the host-selected highlight row.",
        )
        self._alloc_smem = SmemAllocation(
            "smem_data",
            dtype=cutlass.Float16,
            count=num_stages * tile_size,
            alignment=128,
        )

    def get_smem_requirements(self):
        return [self._alloc_smem]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        context = stage_info.context
        self.shared_memory_values = cutlass.Array(
            context.smem_base.data_ptr() + self._alloc_smem.offset,
            dtype=cutlass.Float16,
            shape=(num_stages * tile_size,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_read_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(returns=smem_val)
    @cute.jit
    def read_smem(self, stage_info: StageInfo) -> cutlass.Float16:
        tx, _, _ = cute.arch.thread_idx()
        return self.shared_memory_values[stage_info.stage_idx * tile_size + tx]

    @consumer_work(work_attrs=WorkAttr.AUXILIARY, returns=is_highlight)
    @cute.jit
    def is_highlight_tile(self, stage_info: StageInfo) -> cutlass.Boolean:
        """Store the value used by the runtime ``when_true`` guard."""
        return stage_info.loop_offset == cutlass.Int32(self.highlight_row)

    @producer_work
    @cute.jit
    def tma_load(self, stage_info: StageInfo, *, gmem_idx: cutlass.Int32) -> None:
        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cta_global(
                self.shared_memory_values.subview(stage_info.stage_idx * tile_size),
                self.tma_desc_a,
                (gmem_idx, stage_info.loop_offset),
                stage_info.barrier,
            )


@dataclass
class OutputGmemResource(MemoryResource):
    """GMEM sink: stores the SMEM-loaded value into matrix B."""

    matrix_b: Any = field(init=False, default=None)

    def __init__(self, matrix_b: cute.Tensor, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.matrix_b = matrix_b

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, smem_val: cutlass.Float16) -> None:
        tx, _, _ = cute.arch.thread_idx()
        bx, _, _ = cute.arch.block_idx()
        m_idx = tx + bx * tile_size
        self.matrix_b[stage_info.loop_offset, m_idx] = smem_val


########################################################
# Kernel
########################################################


@cute.kernel
def tma_copy_conditional_kernel(
    rows_cols: Tuple[int, int],
    highlight_row: cutlass.Constexpr,
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    matrix_b: cute.Tensor,
    trace_matrix: cute.Tensor,
    box_dim: cutlass.Constexpr,
):
    num_rows, _num_cols = rows_cols

    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())

    num_warps_epilogue = 4
    pipeline_config = PipelineConfig.create_tma_async_pipeline_cfg(
        num_stages=num_stages,
        num_bytes=box_dim[0] * box_dim[1] * cutlass.Float16.width // 8,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            num_warps_epilogue * 32,
        ),
    )

    input_gmem_resource = InputGmemResource(name="inputGmemResource")
    trace_gmem_resource = TraceGmemResource(
        name="traceGmemResource",
        trace=trace_matrix,
    )
    smem_resource = SmemResource(
        name="smemResource",
        tma_desc_a=tma_desc_a.get_ptr(),
        highlight_row=highlight_row,
        pipeline_config=pipeline_config,
    )
    output_gmem_resource = OutputGmemResource(
        name="outputGmemResource",
        matrix_b=matrix_b,
    )

    allocator = SmemAllocator()
    allocator.add_resource(smem_resource)
    allocator.compute_layout()

    @schedule
    def load_schedule(
        input_gmem: MemoryResource,
        smem: MemoryResource,
        trace: MemoryResource,
    ) -> None:
        smem.init_load_state()
        with domain_loop(0, num_rows, box_dim[1]) as d:
            with d.first_iter():
                trace.mark_begin()
            with d.every(4, start=0):
                trace.record_heartbeat()
            gmem_idx = input_gmem.compute_coords()
            smem.try_acquire()
            smem.acquire()
            smem.tma_load(gmem_idx=gmem_idx)
            smem.commit()

    @schedule
    def store_schedule(
        smem: MemoryResource,
        output_gmem: MemoryResource,
        trace: MemoryResource,
    ) -> None:
        smem.init_read_state()
        with domain_loop(0, num_rows, box_dim[1]) as d:
            smem.try_wait()
            smem.wait()
            smem_val = smem.read_smem()
            smem.release()
            is_highlight = smem.is_highlight_tile()
            with when_true(is_highlight):
                trace.mark_highlight()
            output_gmem.store(smem_val=smem_val)
            with d.last_iter():
                trace.mark_end()

    load_result = load_schedule(
        input_gmem_resource,
        smem_resource,
        trace_gmem_resource,
    )
    store_result = store_schedule(
        smem_resource,
        output_gmem_resource,
        trace_gmem_resource,
    )

    @schedule
    def padding_schedule() -> None:
        with domain_loop(0, num_rows, box_dim[1]):
            pass

    padding_result = padding_schedule()

    load_task = Task(
        name="LoadTask",
        src_resources=[input_gmem_resource],
        dst_resources=[smem_resource, trace_gmem_resource],
        warp_idx=LOAD_TASK_WARP_IDX,
        num_warps=1,
        schedule=load_result,
        num_registers=40,
    )

    store_task = Task(
        name="StoreTask",
        src_resources=[smem_resource],
        dst_resources=[output_gmem_resource, trace_gmem_resource],
        warp_idx=STORE_TASK_WARP_IDX,
        num_warps=num_warps_epilogue,
        schedule=store_result,
        num_registers=160,
    )

    padding_task = Task(
        name="PaddingTask",
        src_resources=[],
        dst_resources=[],
        warp_idx=PADDING_TASK_WARP_IDX,
        num_warps=3,
        schedule=padding_result,
        num_registers=40,
    )

    resource_dependency_graph = {
        smem_resource: [input_gmem_resource],
        output_gmem_resource: [smem_resource],
        trace_gmem_resource: [input_gmem_resource, smem_resource],
    }

    task_manager = TaskManager(
        tasks=[load_task, store_task, padding_task],
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
    )
    task_manager.setup_resources_and_tasks()

    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)
    task_manager.run()


########################################################
# Host runners and CLI
########################################################


def _verify_trace_markers(
    trace: torch.Tensor,
    *,
    num_rows: int,
    highlight_row: int,
) -> None:
    """Check guarded schedule markers written by ``TraceGmemResource``."""
    if not (0 <= highlight_row < num_rows):
        raise ValueError(
            f"highlight_row={highlight_row} must satisfy 0 <= highlight_row < num_rows"
        )
    if trace.shape != (num_rows, 4):
        raise RuntimeError(
            f"expected trace shape {(num_rows, 4)}, got {tuple(trace.shape)}"
        )

    _expect_trace_column(
        trace,
        column=0,
        marker=BEGIN_MARKER,
        expected_rows=[0],
        label="begin",
    )
    _expect_trace_column(
        trace,
        column=1,
        marker=HEARTBEAT_MARKER,
        expected_rows=list(range(0, num_rows, 4)),
        label="heartbeat",
    )
    _expect_trace_column(
        trace,
        column=2,
        marker=HIGHLIGHT_MARKER,
        expected_rows=[highlight_row],
        label="highlight",
    )
    _expect_trace_column(
        trace,
        column=3,
        marker=END_MARKER,
        expected_rows=[num_rows - 1],
        label="end",
    )


@cute.jit
def tma_copy_conditional_kernel_host(
    rows_cols: Tuple[int, int],
    highlight_row: cutlass.Constexpr,
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    trace_matrix: cute.Tensor,
):
    box_dim = (tile_size, 1)
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a, box_dims=box_dim[::-1], swizzle=cuda.TensorMapSwizzle.none
    )

    grid = (cute.ceil_div(matrix_a.shape[1], box_dim[0]), 1, 1)
    block = (256, 1, 1)
    tma_copy_conditional_kernel(
        rows_cols,
        highlight_row,
        tma_desc_a,
        matrix_b,
        trace_matrix,
        box_dim,
    ).launch(grid=grid, block=block)


def run_tma_copy_conditional_kernel_prim(
    rows_cols: Tuple[int, int],
    highlight_row: int,
) -> None:
    print("===================================================================")
    print("Running conditional TMA copy kernel with:")
    print(f"  rows_cols: {rows_cols}")
    print(f"  highlight_row: {highlight_row}")
    print("===================================================================")
    print()

    rows, cols = rows_cols
    if rows <= 0:
        raise ValueError(f"rows={rows} must be positive")
    if cols <= 0:
        raise ValueError(f"cols={cols} must be positive")
    if cols % tile_size != 0:
        raise ValueError(f"cols must be a multiple of tile_size={tile_size}")
    if not (0 <= highlight_row < rows):
        raise ValueError(
            f"highlight_row={highlight_row} must satisfy 0 <= highlight_row < rows"
        )

    a = torch.randn(rows, cols).to(torch.float16).cuda()
    b = torch.zeros_like(a)
    trace = torch.zeros(rows, 4, dtype=torch.float16, device="cuda")

    matrix_a = from_dlpack(a)
    matrix_b = from_dlpack(b)
    trace_matrix = from_dlpack(trace)
    func = cute.compile[cute.FrontendNext](
        tma_copy_conditional_kernel_host,
        rows_cols,
        highlight_row,
        matrix_a,
        matrix_b,
        trace_matrix,
    )
    func(rows_cols, matrix_a, matrix_b, trace_matrix)

    torch.testing.assert_close(b, a)
    _verify_trace_markers(trace, num_rows=rows, highlight_row=highlight_row)
    print("PASS")


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str):
        try:
            return [int(x.strip()) for x in s.split(",")]
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example")

    parser = argparse.ArgumentParser(
        description="TMA copy kernel with conditional schedule guards"
    )
    parser.add_argument(
        "--rows_cols",
        type=parse_comma_separated_ints,
        default=[256, 512],
        help="Num rows and cols (comma-separated)",
    )
    parser.add_argument(
        "--highlight-row",
        type=int,
        default=128,
        help="Row index tagged by the opaque when_true guard on the store task",
    )
    args = parser.parse_args()
    print(args)
    if len(args.rows_cols) != 2:
        parser.error("--rows_cols must contain exactly 2 values")

    run_tma_copy_conditional_kernel_prim(
        rows_cols=args.rows_cols,
        highlight_row=args.highlight_row,
    )
