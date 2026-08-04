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

"""Variable-length packed-to-padded copy using TS dynamic domain.

Demonstrates **dynamic loop domains** via a ``Task`` subclass override and
**static persistent scheduling** via ``WorkQueue`` (same shape as example 03).

Operation
---------
Given:
  - A       : (M,) 1D tensor — variable-length segments packed contiguously
  - offsets : (N+1,) int32 vector with offsets[0]=0 and offsets[N]=M
  - max_len : maximum segment length ``max(offsets[i+1] - offsets[i])``

Compute:
  B[i, 0 : offsets[i+1]-offsets[i]] = A[offsets[i] : offsets[i+1]]

Each persistent work tile (one output row) has a **dynamic loop domain**
``offsets[i+1] - offsets[i]``.  Within that domain, threads use a
**block-local grid-stride loop** (same pattern as ``01_copy_grid_stride``):
``range(tx, seg_len, threads_per_block)``.  If a segment length is 1, only
thread 0 performs the copy; the load/store work methods guard on
``loop_offset < seg_len``.

Resource/task flow:

                   +---------+-----------+
                   | InputPackedResource |
                   | load packed elem    |
                   +---------+-----------+
                             |
                             | val
                             v
                   +---------+------------+
                   | OutputPaddedResource |
                   | store padded elem    |
                   +----------------------+
"""

import argparse
import random
import torch
from dataclasses import dataclass, field

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from typing import Any
from cutlass.cute.runtime import from_dlpack

from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    StageInfo,
    TaskLocalVariable,
    WorkQueue,
    TileSchedulerConfig,
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


########################################################
# Resource definitions and dynamic-domain task subclass
########################################################


class DynamicDomainTask(Task):
    """Task subclass with per-tile dynamic domain from an offsets tensor.

    The domain for tile *i* is ``offsets[i+1] - offsets[i]``.

    NEW vs examples 1-3: loop bounds are not a compile-time constant.
    TS calls get_domain(tile_coord) at runtime for each work tile.
    Pair this by passing it as the domain_loop end:
    domain_loop(DynamicDomainTask.get_domain).
    """

    def __init__(self, offsets, **kwargs):
        super().__init__(**kwargs)
        self._offsets = offsets

    @cute.jit
    def get_domain(self, tile_coord):
        return self._offsets[tile_coord[0] + 1] - self._offsets[tile_coord[0]]


@dataclass
class InputPackedResource(MemoryResource):
    """
    Global-memory packed 1D source (one element loaded per loop iteration).
    """

    A: Any = field(init=False, default=None)
    offsets: Any = field(init=False, default=None)
    val: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __init__(
        self,
        A: cute.Tensor,
        offsets: cute.Tensor,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.A = A
        self.offsets = offsets
        self.val = TaskLocalVariable(
            dtype=cutlass.Float32,
            default=cutlass.Float32(0),
            docs="Packed source value for the current dynamic-domain copy iteration.",
        )

    @consumer_work(returns=val)
    @cute.jit
    def load(self, stage_info: StageInfo) -> cutlass.Float32:
        # work_tile.tile_idx[0] selects the segment (output row i).
        # loop_offset is the in-segment index after block-local grid-stride.
        bx, _, _ = stage_info.work_tile.tile_idx
        local_idx = stage_info.loop_offset
        # Packed 1D source: base offset[i] + local index within segment.
        val = self.A[self.offsets[bx] + local_idx]
        return val


@dataclass
class OutputPaddedResource(MemoryResource):
    """
    Global-memory padded 2D destination (one element stored per iteration).
    """

    B: Any = field(init=False, default=None)
    offsets: Any = field(init=False, default=None)

    def __init__(
        self,
        B: cute.Tensor,
        offsets: cute.Tensor,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.B = B
        self.offsets = offsets

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, val: cutlass.Float32) -> None:
        bx, _, _ = stage_info.work_tile.tile_idx
        local_idx = stage_info.loop_offset
        # Padded 2D destination: row i, column local_idx within segment.
        self.B[bx, local_idx] = val


########################################################
# Kernel
########################################################


@cute.kernel
def varlen_copy_kernel(
    A: cute.Tensor,
    B: cute.Tensor,
    offsets: cute.Tensor,
    tile_sched_params: object,
) -> None:
    num_warps = 4

    ########################################################
    # Resource construction
    ########################################################

    # Block-local grid-stride (example 01 uses a *global* stride via gdimx).
    threads_per_block = num_warps * 32
    tx, _, _ = cute.arch.thread_idx()

    src_resource = InputPackedResource(A=A, offsets=offsets, name="InputPacked")
    dst_resource = OutputPaddedResource(B=B, offsets=offsets, name="OutputPadded")

    # Static persistent WorkQueue (example 03); no CLC pipeline or scheduler task.
    tile_scheduler_config = (
        TileSchedulerConfig.create_static_persistent_tile_scheduler_params(
            tile_scheduler_params=tile_sched_params,
        )
    )
    work_queue = WorkQueue(
        tile_scheduler_config=tile_scheduler_config,
        name="WorkQueue",
    )

    ########################################################
    # Task schedule construction
    ########################################################

    @schedule
    def main_schedule(
        src: MemoryResource,
        dst: MemoryResource,
        wq: WorkQueue,
    ) -> None:
        with work_tile_loop(wq):
            # The callable end (DynamicDomainTask.get_domain) supplies the
            # per-tile segment length; start=tx, step=threads_per_block give a
            # block-local grid-stride (example 01).  seg_len=1 -> only thread 0
            # runs; threads 1..127 get an empty range.
            with domain_loop(tx, DynamicDomainTask.get_domain, threads_per_block):
                val = src.load()
                dst.store(val=val)
            # WorkQueue advance stays outside the copy loop (example 03).
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

    main_result = main_schedule(src_resource, dst_resource, work_queue)

    main_task = DynamicDomainTask(
        offsets=offsets,
        name="VarlenCopyTask",
        # WorkQueue is a src resource so the task reads the current tile id.
        src_resources=[src_resource, work_queue],
        dst_resources=[dst_resource],
        warp_idx=0,
        num_warps=num_warps,
        schedule=main_result,
    )

    ########################################################
    # TaskManager construction and execution
    ########################################################

    task_manager = TaskManager(
        tasks=[main_task],
        resource_dependency_graph={
            dst_resource: [src_resource, work_queue],
        },
    )
    # TaskManager validates the dynamic-domain skeleton before executing it.
    task_manager.setup_resources_and_tasks()
    task_manager.run()


########################################################
# Host runners and CLI
########################################################


@cute.jit
def host_function(
    A: cute.Tensor,
    B: cute.Tensor,
    offsets: cute.Tensor,
    N: int,
    max_active_clusters: cutlass.Constexpr,
) -> None:
    num_warps = 4
    block = (num_warps * 32, 1, 1)

    tile_grid = (N, 1, 1)
    tile_sched_params = utils.PersistentTileSchedulerParams(tile_grid, (1, 1, 1))
    grid = utils.StaticPersistentTileScheduler.get_grid_shape(
        tile_sched_params, max_active_clusters
    )

    varlen_copy_kernel(A, B, offsets, tile_sched_params).launch(grid=grid, block=block)


# ──────────────────────────────────────────────────────────────────────
# Driver
# ──────────────────────────────────────────────────────────────────────


def run_varlen_copy(N: int, seed: int = 42) -> None:
    random.seed(seed)
    torch.manual_seed(seed)
    segment_lengths = [random.randint(1, 20) for _ in range(N)]
    max_len = max(segment_lengths)

    # offsets[i]:offsets[i+1] indexes packed A; B[i, :seg_len] is the padded row.
    offsets_list = [0]
    for length in segment_lengths:
        offsets_list.append(offsets_list[-1] + length)
    M = offsets_list[-1]

    print("===================================================================")
    print("Running varlen packed-to-padded copy (dynamic domain demo) with:")
    print("  scheduler:          static_persistent")
    print(f"  N (segments):       {N}")
    print(f"  max_len (pad):      {max_len}")
    print(f"  M (packed elems):   {M}")
    print(f"  segment_lengths:    {segment_lengths}")
    print(f"  offsets:            {offsets_list}")
    print("===================================================================")
    print()

    A = torch.randn(M, dtype=torch.float32).cuda()
    B = torch.zeros(N, max_len, dtype=torch.float32).cuda()
    offsets_t = torch.tensor(offsets_list, dtype=torch.int32).cuda()

    A_ = from_dlpack(A).mark_layout_dynamic()
    B_ = from_dlpack(B).mark_layout_dynamic()
    offsets_ = from_dlpack(offsets_t).mark_layout_dynamic()

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(1)

    func = cute.compile(host_function, A_, B_, offsets_, N, max_active_clusters)
    func(A_, B_, offsets_, N)

    # PyTorch reference: copy each 1D segment into its padded 2D output row.
    B_ref = torch.zeros_like(B)
    for i in range(N):
        start = offsets_list[i]
        end = offsets_list[i + 1]
        length = end - start
        B_ref[i, :length] = A[start:end]

    torch.testing.assert_close(B, B_ref)
    print("PASS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Variable-length packed-to-padded copy (TS dynamic domain demo)"
    )
    parser.add_argument("--N", type=int, default=8, help="Number of segments")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example")

    run_varlen_copy(N=args.N, seed=args.seed)
