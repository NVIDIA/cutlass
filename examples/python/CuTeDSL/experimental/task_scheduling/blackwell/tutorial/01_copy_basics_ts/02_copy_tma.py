# Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""CTA-local TMA copy TS example.

This example builds on ``01_copy_grid_stride.py`` by adding a
pipelined SMEM resource and a split load/store task schedule. The load task
produces SMEM stages with TMA, and the store task consumes those stages and
writes GMEM output.

The row and column counts must be positive, and the column count must be a
multiple of ``tile_size``. ``store()`` writes ``tile_size`` elements per CTA
block, so ``run_tma_copy_kernel_prim`` raises a ``ValueError`` for invalid shapes
or partial column tiles.

Resource/task flow:

                   +-------------------+
                   | InputGmemResource |
                   |  row coordinate   |
                   +---------+---------+
                             |
             LoadTask:       | gmem_idx
             TMA into SMEM   v
                   +---------+---------+
                   |   SmemResource    |
                   |  TMA async pipe   |
                   +---------+---------+
                             |
             StoreTask: wait full stage,
             read SMEM, release stage
                             v
                   +---------+---------+
                   | OutputGmemResource|
                   |  GMEM store       |
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
    schedule,
    domain_loop,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

num_stages = 1
tile_size = 128


########################################################
# Resource definitions
########################################################


@dataclass
class InputGmemResource(MemoryResource):
    """
    Coordinate-only GMEM source: emits the TMA load row coordinate.
    """

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
        # Compute the loaded tile index in the tensor.
        # Emits the gmem-row coordinate consumed downstream by SmemResource.
        return bx * tile_size


@dataclass
class SmemResource(MemoryResource):
    """Pipelined SMEM tile filled by TMA, consumed by the epilogue warps.

    SMEM storage is declared via ``get_smem_requirements()`` and resolved
    by the unified :class:`SmemAllocator`; the typed ``cutlass.Array`` view is
    materialised by auxiliary work from ``stage_info.context.smem_base``.
    Pipeline barrier storage is also managed by
    the allocator (``barrier_ptr`` is intentionally omitted from the
    pipeline config so the allocator can place it).
    """

    tma_desc_a: Any = field(init=False, default=None)
    shared_memory_values: Any = field(init=False, default=None)
    smem_val: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()
    _alloc_smem: cutlass.Constexpr = field(init=False, default=None)

    def __init__(self, tma_desc_a: cutlass.Pointer, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.tma_desc_a = tma_desc_a
        self.smem_val = TaskLocalVariable(
            dtype=cutlass.Float16,
            default=cutlass.Float16(0),
            docs="SMEM-loaded value consumed by the GMEM store.",
        )
        # Create the SMEM allocation for this resource.
        self._alloc_smem = SmemAllocation(
            "smem_data",
            dtype=cutlass.Float16,
            count=num_stages * tile_size,
            alignment=128,
        )
        nullptr = cutlass.inttoptr(0, mem_space=3, dtype=cutlass.Float16)
        self.shared_memory_values = cutlass.Array(
            nullptr,
            dtype=cutlass.Float16,
            shape=(num_stages * tile_size,),
            addrspace=3,
        )

    def get_smem_requirements(self):
        # Override the base class method to return the SMEM allocation for this resource.
        return [self._alloc_smem]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        # Derive the typed SMEM array view from the unified allocator base.
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
        # Read the SMEM value from the SMEM array.
        # The SMEM array is a 2D array of Float16 values: [num_stages, tile_size].
        smem_val = self.shared_memory_values[stage_info.stage_idx * tile_size + tx]
        # Return the consumed SMEM value to the producer work of OutputGmemResource.
        # Emits smem_val downstream; producer-side gmem_idx is auto-mirrored.
        return smem_val

    @producer_work
    @cute.jit
    def tma_load(self, stage_info: StageInfo, *, gmem_idx: cutlass.Int32) -> None:
        # Load the TMA descriptor from the GMEM tensor.
        if prims.elect_sync():
            # Load the TMA descriptor from the GMEM tensor at the given gmem_idx
            # into the SMEM array at the given stage index.
            prims.cp_async_bulk_tensor_shared_cta_global(
                self.shared_memory_values.subview(stage_info.stage_idx * tile_size),
                self.tma_desc_a,
                (gmem_idx, stage_info.loop_offset),
                stage_info.barrier,
            )


@dataclass
class OutputGmemResource(MemoryResource):
    """GMEM sink: stores the SMEM-loaded value into matrix B.

    Pure sink.  The producer-side ``smem_val`` slot is
    auto-allocated by ``Task.init_variables`` from the upstream
    ``SmemResource``'s emitted consumer var.
    """

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
        # Store the SMEM value to the matrix B tensor.
        self.matrix_b[stage_info.loop_offset, m_idx] = smem_val


########################################################
# Kernel
########################################################


@cute.kernel
def tma_copy_kernel(
    rows_cols: Tuple[int, int],
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    matrix_b: cute.Tensor,
    box_dim: cutlass.Constexpr,
):
    num_rows, num_cols = rows_cols

    # Prefetch TMA Descriptor (mbarrier storage is owned by SmemAllocator).
    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())

    ########################################################
    # Resource construction
    ########################################################

    num_warps_epilogue = 4
    # No barrier_ptr: the SmemAllocator places the barrier storage inside the
    # unified SMEM block and patches it onto the pipeline config during
    # task_manager.setup_resources_and_tasks().
    # Create the pipeline configuration for the TMA async pipeline.
    pipeline_config = PipelineConfig.create_tma_async_pipeline_cfg(
        num_stages=num_stages,
        num_bytes=box_dim[0] * box_dim[1] * cutlass.Float16.width // 8,
        # Both producer and consumer number of threads are verified by the TaskManager for correctness.
        #
        # Producer is load task with 1 warp (32 threads), but only
        # one thread is elected to issue the TMA load and signal the barrier.
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        # Consumer is store task with 4 warps (128 threads).
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            num_warps_epilogue * 32,
        ),
    )

    input_gmem_resource = InputGmemResource(name="inputGmemResource")
    smem_resource = SmemResource(
        name="smemResource",
        tma_desc_a=tma_desc_a.get_ptr(),
        pipeline_config=pipeline_config,
    )
    output_gmem_resource = OutputGmemResource(
        name="outputGmemResource",
        matrix_b=matrix_b,
    )

    # Unified SMEM allocator: data buffers + pipeline barriers in one block.
    allocator = SmemAllocator()
    allocator.add_resource(smem_resource)
    allocator.compute_layout()

    ########################################################
    # Task schedule construction
    ########################################################

    # Captured load schedule (warp 4): coords -> acquire SMEM -> TMA -> commit.
    @schedule
    def load_schedule(input_gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        with domain_loop(0, num_rows, box_dim[1]):
            # Compute the TMA coordinates.
            gmem_idx = input_gmem.compute_coords()
            # Try to acquire the SMEM stage.
            smem.try_acquire()
            # Block until the SMEM stage is acquired.
            smem.acquire()
            # Load the TMA descriptor from the GMEM tensor.
            smem.tma_load(gmem_idx=gmem_idx)
            # Commit the SMEM stage.
            smem.commit()

    # Captured store schedule (warps 0-3): wait SMEM -> read -> release -> store.
    @schedule
    def store_schedule(smem: MemoryResource, output_gmem: MemoryResource) -> None:
        smem.init_read_state()
        with domain_loop(0, num_rows, box_dim[1]):
            # Wait for the SMEM stage to be ready.
            smem.try_wait()
            # Block until the SMEM stage is ready.
            smem.wait()
            # Read the SMEM value from the SMEM array.
            smem_val = smem.read_smem()
            # Release the SMEM stage.
            smem.release()
            # Store the SMEM value to the matrix B tensor.
            output_gmem.store(smem_val=smem_val)

    load_result = load_schedule(input_gmem_resource, smem_resource)
    store_result = store_schedule(smem_resource, output_gmem_resource)

    @schedule
    def padding_schedule() -> None:
        with domain_loop(0, num_rows, box_dim[1]):
            pass

    padding_result = padding_schedule()

    load_task = Task(
        name="LoadTask",
        src_resources=[input_gmem_resource],
        dst_resources=[smem_resource],
        warp_idx=4,
        num_warps=1,
        schedule=load_result,
        num_registers=40,
    )

    store_task = Task(
        name="StoreTask",
        src_resources=[smem_resource],
        dst_resources=[output_gmem_resource],
        warp_idx=0,
        num_warps=num_warps_epilogue,
        schedule=store_result,
        num_registers=160,
    )

    # Padding task to cover warps 5-7 in the same warp group as LoadTask (warp 4).
    # All warps in a warp group of 4 must have matching num_registers.
    padding_task = Task(
        name="PaddingTask",
        src_resources=[],
        dst_resources=[],
        warp_idx=5,
        num_warps=3,
        schedule=padding_result,
        num_registers=40,
    )

    # Chain dependency graph: SmemResource depends on InputGmemResource,
    # and OutputGmemResource depends on SmemResource.

    ########################################################
    # TaskManager construction and execution
    ########################################################

    resource_dependency_graph = {
        smem_resource: [input_gmem_resource],
        output_gmem_resource: [smem_resource],
    }

    task_manager = TaskManager(
        tasks=[load_task, store_task, padding_task],
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
    )
    # Barriers are initialized and function variables are created
    # inside setup_resources_and_tasks()
    task_manager.setup_resources_and_tasks()

    # Fence mbarrier init before sync_threads (like bare metal)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Run the tasks
    # This will select the appropriate warps for each task based on the warp_idx.
    # Then it will launch the loops, call all variables initialization functions,
    # and execute the specified schedules for the selected warps.
    task_manager.run()


########################################################
# Raw baseline kernel
########################################################


# The raw kernel that does not use the resource/task
@cute.kernel
def tma_copy_raw_kernel(
    rows_cols: Tuple[int, int],
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    matrix_b: cute.Tensor,
    box_dim: cutlass.Constexpr,
):
    num_rows, num_cols = rows_cols

    # Initialize mbarrier and prefetch TMA Descriptor
    if prims.elect_sync():
        prims.prefetch_tensormap(tma_desc_a.get_ptr())

    shared_memory_values = cutlass.Array(
        cutlass.Float16, (num_stages, tile_size), space=cutlass.AddressSpace.smem
    )
    barrier_storage = cutlass.Array(
        cutlass.Int64, num_stages * 2, space=cutlass.AddressSpace.smem
    )
    barrier_ptr = cute.make_ptr(
        cutlass.Int64, barrier_storage.data_ptr(), mem_space=cutlass.AddressSpace.smem
    )
    num_warps_epilogue = 4

    ab_producer, ab_consumer = pipeline.PipelineTmaAsync.create(
        num_stages=num_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_warps_epilogue
        ),
        tx_count=box_dim[0] * box_dim[1] * cutlass.Float16.width // 8,
        barrier_storage=barrier_ptr,  # barrier_storage_ptr,
    ).make_participants()

    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if warp_idx == 4:
        for k_tile_idx in range(num_rows):
            ab_empty = ab_producer.acquire_and_advance()
            # Async TMA Load
            if prims.elect_sync():
                bidxx, _, _ = cute.arch.block_idx()
                bdimx, _, _ = cute.arch.block_dim()
                prims.cp_async_bulk_tensor_shared_cta_global(
                    shared_memory_values.subview(ab_empty.index * tile_size),
                    tma_desc_a.get_ptr(),
                    (bidxx * tile_size, ab_empty.count),
                    cutlass.Array(ab_empty.barrier, shape=(1,)),
                )
                tx, ty, tz = cute.arch.thread_idx()
    else:
        for k_tile_idx in range(num_rows):
            ab_full = ab_consumer.wait_and_advance()
            tx, ty, tz = cute.arch.thread_idx()
            smem_val = shared_memory_values[ab_full.index, tx]
            bidxx, _, _ = cute.arch.block_idx()
            ab_full.release()
            matrix_b[ab_full.count, tx + bidxx * tile_size] = smem_val


########################################################
# Host runners and CLI
########################################################


@cute.jit
def tma_copy_kernel_host(
    rows_cols: Tuple[int, int],
    matrix_a: cute.Tensor,
    matrix_b: cute.Tensor,
    run_raw_kernel: bool,
):
    box_dim = (tile_size, 1)
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a, box_dims=box_dim[::-1], swizzle=cuda.TensorMapSwizzle.none
    )

    # Launch the kernel
    grid = (cute.ceil_div(matrix_a.shape[1], box_dim[0]), 1, 1)
    if run_raw_kernel:
        # Raw kernel uses 5 warps (160 threads)
        block = (160, 1, 1)
        tma_copy_raw_kernel(rows_cols, tma_desc_a, matrix_b, box_dim).launch(
            grid=grid, block=block
        )
    else:
        # TS kernel uses 8 warps (256 threads): 4 store + 1 load + 3 padding
        block = (256, 1, 1)
        tma_copy_kernel(rows_cols, tma_desc_a, matrix_b, box_dim).launch(
            grid=grid, block=block
        )


def run_tma_copy_kernel_prim(rows_cols: Tuple[int, int], run_raw_kernel: bool):
    print("===================================================================")
    print("Running TMA copy kernel with schedule with:")
    print(f"  rows_cols: {rows_cols}")
    print("===================================================================")
    print()

    rows, cols = rows_cols
    if rows <= 0:
        raise ValueError(f"rows={rows} must be positive")
    if cols <= 0:
        raise ValueError(f"cols={cols} must be positive")
    if cols % tile_size != 0:
        raise ValueError(f"cols must be a multiple of tile_size={tile_size}")

    a = torch.randn(rows, cols).to(torch.float16).cuda()
    b = torch.zeros_like(a)

    matrix_a = from_dlpack(a)
    matrix_b = from_dlpack(b)
    func = cute.compile(
        tma_copy_kernel_host, rows_cols, matrix_a, matrix_b, run_raw_kernel
    )
    func(rows_cols, matrix_a, matrix_b, run_raw_kernel)

    torch.testing.assert_close(b, a)
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

    parser = argparse.ArgumentParser(description="TMA copy kernel with schedule")
    parser.add_argument(
        "--rows_cols",
        type=parse_comma_separated_ints,
        default=[256, 512],
        help="Num rows and cols (comma-separated)",
    )
    parser.add_argument(
        "--run-raw-kernel",
        action="store_true",
        help="Whether running the raw kernel",
    )
    args = parser.parse_args()
    print(args)
    if len(args.rows_cols) != 2:
        parser.error("--rows_cols must contain exactly 2 values")

    run_tma_copy_kernel_prim(
        rows_cols=args.rows_cols, run_raw_kernel=args.run_raw_kernel
    )
