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

"""Persistent TS copy with an overlaunched, skipping WorkQueue.

This example mirrors the tile shape of ``02_copy_tma.py``: each work
tile owns a 128-column slice and every thread copies one column for each
row in the runtime problem.  The copy itself is plain GMEM-to-GMEM (no
TMA); the focus here is persistent scheduling and the skipped-tile
protocol, not the DMA mechanism.

The host intentionally launches more work-queue tiles than the logical
matrix requires.  The WorkQueue subclass uses only the assigned work
tile id to mark surplus tiles as skipped, so those iterations execute
WorkQueue bookkeeping but no copy work.

The schedule demonstrates the skipped-tile shape::

    with work_tile_loop(skip_if=OversubscribedCopyWorkQueue.skip_work_tile_if) as wtwl:
        with wtwl.skippable(), domain_loop(...):
            copy_resource.copy_tile_row()
        # WorkQueue wait/advance/release stays outside skippable().

Resource/task flow:

                   +-------------------+
                   |      WorkQueue    |
                   | persistent tiles  |
                   +---------+---------+
                             |
                             | skip_if drops overlaunched tiles
                             v
                   +---------+---------+
                   | PersistentCopyRes |
                   |  GMEM -> GMEM     |
                   +-------------------+
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from typing import Any, Tuple

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import torch

from cutlass.cute.runtime import from_dlpack
from cutlass.utils.static_persistent_tile_scheduler import WorkTileInfo
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    StageInfo,
    TileSchedulerConfig,
    WorkQueue,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    domain_loop,
    schedule,
    work_tile_loop,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager

tile_size = 128


########################################################
# Resource definitions
########################################################


@dataclass(kw_only=True)
class OversubscribedCopyWorkQueue(WorkQueue):
    """WorkQueue that skips overlaunched copy tiles.

    ``logical_tiles`` is the runtime number of column tiles in the matrix.
    The launch grid is intentionally larger than this logical tile count.
    Work tiles whose ``tile_idx.x`` falls outside ``logical_tiles`` skip
    immediately.
    """

    logical_tiles: Any = field(init=False, default=None)

    def __init__(self, logical_tiles: object, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.logical_tiles = logical_tiles

    @cute.jit
    def skip_work_tile_if(self, work_tile: WorkTileInfo) -> cutlass.Boolean:
        # Skip work tiles that were launched only to demonstrate overlaunch.
        tile_x, _, _ = work_tile.tile_idx
        return tile_x >= self.logical_tiles


@dataclass
class PersistentCopyResource(MemoryResource):
    """
    GMEM-to-GMEM tile copy driven by the persistent work tile.
    """

    matrix_a: Any = field(init=False, default=None)
    matrix_b: Any = field(init=False, default=None)

    def __init__(
        self,
        matrix_a: cute.Tensor,
        matrix_b: cute.Tensor,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.matrix_a = matrix_a
        self.matrix_b = matrix_b

    @producer_work
    @cute.jit
    def copy_tile_row(self, stage_info: StageInfo) -> None:
        tx, _, _ = cute.arch.thread_idx()
        # The active persistent tile is carried into producer work via StageInfo.
        tile_x, _, _ = stage_info.work_tile.tile_idx
        col = tx + tile_x * tile_size
        # Loop offset is the row index inside the current tile column slice.
        self.matrix_b[stage_info.loop_offset, col] = self.matrix_a[
            stage_info.loop_offset, col
        ]


########################################################
# Kernel
########################################################


@cute.kernel
def tma_copy_persistent_skip_kernel(
    rows_cols: Tuple[int, int],
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    tile_sched_params: object,
    logical_tiles: cutlass.Constexpr,
) -> None:
    num_rows, _ = rows_cols

    ########################################################
    # Resource construction
    ########################################################

    # Static persistent scheduler maps launched CTAs to a stream of tile IDs.
    tile_scheduler_config = (
        TileSchedulerConfig.create_static_persistent_tile_scheduler_params(
            tile_scheduler_params=tile_sched_params,
        )
    )
    # Resource skeleton: WorkQueue drives which GMEM column tile is copied.
    copy_resource = PersistentCopyResource(
        matrix_a=matrix_a,
        matrix_b=matrix_b,
        name="CopyResource",
    )
    work_queue = OversubscribedCopyWorkQueue(
        logical_tiles=logical_tiles,
        tile_scheduler_config=tile_scheduler_config,
        name="WorkQueue",
    )

    ########################################################
    # Task schedule construction
    ########################################################

    @schedule
    def copy_schedule(copy_res: MemoryResource, wq: WorkQueue) -> None:
        # Only the data copy is skippable; WorkQueue bookkeeping must still run.
        with work_tile_loop(
            wq, skip_if=OversubscribedCopyWorkQueue.skip_work_tile_if
        ) as wtwl:
            # Skipped tiles bypass only this data-work region.
            with wtwl.skippable(), domain_loop(0, num_rows, 1):
                copy_res.copy_tile_row()
            # Every launched CTA still advances/releases the WorkQueue.
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    copy_result = copy_schedule(copy_resource, work_queue)

    # One task owns the persistent copy loop for four warps.
    copy_task = Task(
        name="PersistentCopyTask",
        src_resources=[work_queue],
        dst_resources=[copy_resource],
        warp_idx=0,
        num_warps=4,
        schedule=copy_result,
    )

    ########################################################
    # TaskManager construction and execution
    ########################################################

    task_manager = TaskManager(
        tasks=[copy_task],
        resource_dependency_graph={copy_resource: [work_queue]},
    )
    # Validates the persistent skeleton and wires WorkQueue runtime state.
    task_manager.setup_resources_and_tasks()
    # Execute the captured persistent schedule.
    task_manager.run()


########################################################
# Host runners and CLI
########################################################


@cute.jit
def tma_copy_persistent_skip_kernel_host(
    rows_cols: Tuple[int, int],
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    logical_tiles: cutlass.Constexpr,
    overlaunch_tiles: cutlass.Constexpr,
) -> None:
    # Overlaunch by adding extra scheduler tiles beyond the logical tile count.
    launch_tiles = logical_tiles + overlaunch_tiles
    tile_grid = (launch_tiles, 1, 1)
    grid = (1, 1, launch_tiles)
    block = (tile_size, 1, 1)
    # Static persistent parameters describe the logical tile space.
    tile_sched_params = utils.PersistentTileSchedulerParams(tile_grid, (1, 1, 1))
    tma_copy_persistent_skip_kernel(
        rows_cols,
        matrix_a,
        matrix_b,
        tile_sched_params,
        logical_tiles,
    ).launch(grid=grid, block=block)


def run_copy_persistent_skip(
    rows_cols: Tuple[int, int],
    overlaunch_tiles: int = 4,
) -> None:
    rows, cols = rows_cols
    if cols % tile_size != 0:
        raise ValueError(f"cols must be divisible by tile_size={tile_size}.")
    if overlaunch_tiles < 0:
        raise ValueError("overlaunch_tiles must be non-negative for this example.")

    logical_tiles = cols // tile_size
    launch_tiles = logical_tiles + overlaunch_tiles
    print("===================================================================")
    print("Running persistent copy with overlaunched skipped tiles:")
    print(f"  rows_cols:        {rows_cols}")
    print(f"  logical tiles:    {logical_tiles}")
    print(f"  launched tiles:   {launch_tiles}")
    print(f"  skipped CTAs:     {overlaunch_tiles}")
    print("===================================================================")
    print()

    a = torch.randn(rows, cols).to(torch.float16).cuda()
    b = torch.zeros_like(a)

    matrix_a = from_dlpack(a)
    matrix_b = from_dlpack(b)
    func = cute.compile[cute.FrontendNext](
        tma_copy_persistent_skip_kernel_host,
        rows_cols,
        matrix_a,
        matrix_b,
        logical_tiles,
        overlaunch_tiles,
    )
    func(rows_cols, matrix_a, matrix_b)

    torch.testing.assert_close(b, a)
    print("PASS")


def parse_comma_separated_ints(s: str) -> list[int]:
    try:
        return [int(x.strip()) for x in s.split(",")]
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        ) from exc


if __name__ == "__main__":
    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example")

    parser = argparse.ArgumentParser(
        description="Persistent copy with overlaunched skipped WorkQueue tiles"
    )
    parser.add_argument(
        "--rows_cols",
        type=parse_comma_separated_ints,
        default=[256, 512],
        help="Num rows and cols (comma-separated)",
    )
    parser.add_argument(
        "--overlaunch-tiles",
        type=int,
        default=4,
        help="Extra scheduler tiles/CTAs to launch and skip at runtime",
    )
    args = parser.parse_args()
    if len(args.rows_cols) != 2:
        parser.error("--rows_cols must contain exactly 2 values")

    run_copy_persistent_skip(
        rows_cols=tuple(args.rows_cols),
        overlaunch_tiles=args.overlaunch_tiles,
    )
