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

"""Simplest TS copy example: grid-stride GMEM-to-GMEM copy.

Read this file first in ``01_copy_basics_ts``. It has one task, two
non-pipelined resources, no SMEM/TMEM allocators, and no persistent WorkQueue.
If ``num_entries == 0``, or if a thread's grid-stride ``gid`` is outside the
logical tensor length, ``get_item()`` leaves the captured ``item`` value at its
zero initializer and ``set_item()`` skips the store. No resources allocate
SMEM/TMEM state, so there is no allocation/finalization failure path in this
example.

Resource/task flow:

                   +-------------------+
                   | InputGmemResource |
                   |   load item       |
                   +---------+---------+
                             |
                             | CopyTask: grid-stride loop
                             | item variable flows by name
                             v
                   +---------+---------+
                   | OutputGmemResource|
                   |   store item      |
                   +-------------------+
"""

from dataclasses import dataclass

import torch

import cutlass
import cutlass.cute as cute

from cutlass.cute.runtime import from_dlpack
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    StageInfo,
    TaskLocalVariable,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    schedule,
    domain_loop,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager


########################################################
# Resource definitions
########################################################


@dataclass(kw_only=True)
class InputGmemResource(MemoryResource):
    """
    Source resource that emits one ``item`` per grid-stride loop iteration.
    """

    source_tensor: cute.Tensor
    num_entries: cutlass.Int32
    num_warps: cutlass.Constexpr[int]
    item: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

    def __post_init__(self) -> None:
        # Create a variable for the item.
        # It is passed from the consumer work of InputGmemResource
        # to the producer work of OutputGmemResource.
        self.item = TaskLocalVariable(
            dtype=cutlass.Int16,
            default=cutlass.Int16(0),
            docs="Input element loaded for the current grid-stride iteration.",
        )

    @consumer_work(returns=item)
    @cute.jit
    def get_item(self, stage_info: StageInfo) -> cutlass.Int16:
        # Loop offest is the current loop iteration index.
        # It is the same as the global thread index for grid-stride loops.
        gid = stage_info.loop_offset
        val = cutlass.Int16(0)
        if gid < self.num_entries:
            # Load the item from the source tensor.
            val = self.source_tensor[gid]
        # Return the item to the consumer work.
        # It is passed to the producer work of OutputGmemResource.
        # Check schedule definition for the order of operations.
        return val


@dataclass(kw_only=True)
class OutputGmemResource(MemoryResource):
    """
    Destination resource that consumes ``item`` and stores it to GMEM.
    """

    destination_tensor: cute.Tensor
    num_entries: cutlass.Int32
    num_warps: cutlass.Constexpr[int]

    @producer_work
    @cute.jit
    def set_item(self, stage_info: StageInfo, data: cutlass.Int16) -> None:
        # Loop offest is the current loop iteration index.
        # It is the same as the global thread index for grid-stride loops.
        gid = stage_info.loop_offset
        if gid < self.num_entries:
            # Store the item to the destination tensor.
            self.destination_tensor[gid] = data


########################################################
# Kernel
########################################################


@cute.kernel
def gmem_copy_kernel(
    num_entries: cutlass.Int32,
    source_tensor: cute.Tensor,
    destination_tensor: cute.Tensor,
    num_warps: cutlass.Constexpr,
    unroll: cutlass.Constexpr = 1,
):
    ########################################################
    # Resource construction
    ########################################################

    # Resource skeleton: source GMEM value flows directly to destination GMEM.
    # No pipelines are used in this example as only 1 task is used and no
    # resources are shared.
    input_gmem_resource = InputGmemResource(
        name="inputGmemResource",
        source_tensor=source_tensor,
        num_entries=num_entries,
        num_warps=num_warps,
    )
    output_gmem_resource = OutputGmemResource(
        name="outputGmemResource",
        destination_tensor=destination_tensor,
        num_entries=num_entries,
        num_warps=num_warps,
    )

    gdimx, _, _ = cute.arch.grid_dim()
    bx, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()

    ########################################################
    # Task schedule construction
    ########################################################

    @schedule
    def schedule_fn(
        input_gmem: InputGmemResource,
        output_gmem: OutputGmemResource,
    ) -> None:
        threads_per_block = num_warps * 32
        start = bx * threads_per_block + tx
        step = gdimx * threads_per_block
        # Grid-stride domain gives each thread a strided slice of the 1D tensor.
        with domain_loop(start, num_entries, step, unroll=unroll):
            res = input_gmem.get_item()
            output_gmem.set_item(data=res)

    task = Task(
        name="CopyTask",
        src_resources=[input_gmem_resource],
        dst_resources=[output_gmem_resource],
        warp_idx=0,
        num_warps=num_warps,
        schedule=schedule_fn(input_gmem_resource, output_gmem_resource),
    )

    ########################################################
    # TaskManager construction and execution
    ########################################################

    # OutputGmemResource depends on InputGmemResource.
    resource_dependency_graph = {
        output_gmem_resource: [input_gmem_resource],
    }
    # TaskManager validates the resource graph and executes the captured schedule.
    task_manager = TaskManager(
        tasks=[task],
        resource_dependency_graph=resource_dependency_graph,
    )
    task_manager.setup_resources_and_tasks()
    task_manager.run()


########################################################
# Host runners and raw baseline
########################################################


@cute.jit
def gmem_copy_kernel_host(
    num_entries: cutlass.Int32,
    source_tensor: cute.Tensor,
    destination_tensor: cute.Tensor,
    num_blocks: cutlass.Int32,
    num_warps: cutlass.Constexpr,
    unroll: cutlass.Constexpr = 1,
):
    gmem_copy_kernel(
        num_entries, source_tensor, destination_tensor, num_warps, unroll
    ).launch(
        grid=(num_blocks, 1, 1),
        block=(num_warps * 32, 1, 1),
    )


@cute.kernel
def gmem_copy_naive_kernel(
    num_entries: cutlass.Int32,
    source_tensor: cute.Tensor,
    destination_tensor: cute.Tensor,
    num_warps: cutlass.Constexpr,
):
    gdimx, _, _ = cute.arch.grid_dim()
    bx, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()
    gid = bx * num_warps * 32 + tx
    for i in cutlass.range(gid, num_entries, gdimx * num_warps * 32):
        destination_tensor[i] = source_tensor[i]


@cute.jit
def gmem_copy_naive_kernel_host(
    num_entries: cutlass.Int32,
    source_tensor: cute.Tensor,
    destination_tensor: cute.Tensor,
    num_blocks: cutlass.Int32,
    num_warps: cutlass.Constexpr,
):
    gmem_copy_naive_kernel(
        num_entries, source_tensor, destination_tensor, num_warps
    ).launch(
        grid=(num_blocks, 1, 1),
        block=(num_warps * 32, 1, 1),
    )


def run_gmem_copy_kernel_prim(num_blocks: int = 256, num_warps: int = 8):
    num_entries = 1 << 24
    source = torch.randint(-32768, 32768, (num_entries,), dtype=torch.int16).cuda()
    destination = torch.zeros_like(source).cuda()

    source_tensor = from_dlpack(source)
    destination_tensor = from_dlpack(destination)
    naive_func = cute.compile(
        gmem_copy_naive_kernel_host,
        num_entries,
        source_tensor,
        destination_tensor,
        num_blocks,
        num_warps,
    )
    ts_func = cute.compile(
        gmem_copy_kernel_host,
        num_entries,
        source_tensor,
        destination_tensor,
        num_blocks,
        num_warps,
    )

    naive_func(num_entries, source_tensor, destination_tensor, num_blocks)
    torch.testing.assert_close(destination, source)
    destination.zero_()

    ts_func(num_entries, source_tensor, destination_tensor, num_blocks)
    torch.testing.assert_close(destination, source)

    print("PASS")


if __name__ == "__main__":
    run_gmem_copy_kernel_prim()
