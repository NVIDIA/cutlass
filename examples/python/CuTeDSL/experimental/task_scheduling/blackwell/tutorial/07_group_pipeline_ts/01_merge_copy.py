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

"""Tutorial 07 — Merge copy kernel (PipelineGroup test).

This example demonstrates a **Merge** ``PipelineGroup``: two load producers
(SmemA, SmemB) share one consumer release via ``ab_sync.release()``, so the
store task issues fewer mbarrier arrives than per-member release (performance
only; correctness matches releasing each member separately).

Two producers load different tiles into SMEM.  SmemA always uses global memory load
(AsyncAsync pipeline).  SmemB is configurable via ``use_tma_for_b``:

- ``True``  → TMA load (TmaAsync) — heterogeneous Merge(AsyncAsync + TmaAsync)
- ``False`` → global memory load (AsyncAsync) — homogeneous Merge(AsyncAsync + AsyncAsync)

A single consumer reads both SMEM buffers and stores them to separate
GMEM outputs.

Resources::

    GmemA ──→ SmemA (AsyncAsync)             ──┐
                                               ├── ab_sync (PipelineGroup, Merge)
    GmemB ──→ SmemB (TmaAsync or AsyncAsync) ──┘
                                               │
                                               ▼
                                        StoreResource

Validation: GmemDA == A_tile, GmemDB == B_tile
"""

import argparse
from functools import lru_cache
from dataclasses import dataclass, field

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

from cutlass.experimental.task_scheduling.enums import (
    WorkAttr,
    PipelineGroupMode,
)
from cutlass.experimental.task_scheduling.memory import SmemAllocation, SmemAllocator
from cutlass.experimental.task_scheduling.resources import (
    MemoryResource,
    StageInfo,
    PipelineConfig,
    PipelineGroup,
    TaskLocalVariable,
    consumer_work,
    producer_work,
)
from cutlass.experimental.task_scheduling.schedule_builder import (
    domain_loop,
    schedule,
)
from cutlass.experimental.task_scheduling.task import Task
from cutlass.experimental.task_scheduling.task_manager import TaskManager
from cutlass.experimental import primitives as prims

# ──────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────

io_dtype = cutlass.Float16
tile_m = 128  # elements per tile for A (rows * cols flattened)
tile_n = 128  # elements per tile for B

num_stages = 4

num_store_warps = 4
num_load_a_warps = 1
num_load_b_warps = 1
num_padding_warps = 2

total_warps = num_store_warps + num_load_a_warps + num_load_b_warps + num_padding_warps
assert total_warps == 8

bytes_b = tile_n * (io_dtype.width // 8)

use_tma_for_b = True

debug_print = False


# ──────────────────────────────────────────────────────────────────────
# Resource definitions
# ──────────────────────────────────────────────────────────────────────


@dataclass
class GmemAResource(MemoryResource):
    """
    Coordinate computation for global memory load of tile A.
    """

    gmem_offset: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __post_init__(self) -> None:
        self.gmem_offset = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="GMEM offset for A tile copies.",
        )

    @consumer_work(returns=gmem_offset)
    @cute.jit
    def compute_offset(self, stage_info: StageInfo) -> cutlass.Int32:
        return stage_info.loop_offset * tile_m


@dataclass
class GmemBResource(MemoryResource):
    """
    Coordinate computation for TMA copy of tile B.
    """

    gmem_offset: cutlass.Constexpr[TaskLocalVariable] = (
        TaskLocalVariable.uninitialized()
    )

    def __post_init__(self) -> None:
        self.gmem_offset = TaskLocalVariable(
            dtype=cutlass.Int32,
            default=cutlass.Int32(0),
            docs="GMEM offset for B tile copies.",
        )

    @consumer_work(returns=gmem_offset)
    @cute.jit
    def compute_offset(self, stage_info: StageInfo) -> cutlass.Int32:
        return stage_info.loop_offset * tile_n


@dataclass
class SmemAResource(MemoryResource):
    """
    SMEM buffer filled by global memory load (AsyncAsync pipeline).
    """

    gA: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_a: cutlass.Constexpr = field(init=False, default=None)
    _alloc_a: cutlass.Constexpr = field(init=False, default=None)

    def __init__(self, gA: cutlass.Array, **kwargs: object) -> None:
        super().__init__(**kwargs)
        self.gA = gA
        elem_size = io_dtype.width // 8
        self._alloc_a = SmemAllocation("smem_a", tile_m * num_stages * elem_size)

    def get_smem_requirements(self):
        return [self._alloc_a]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        self.shared_smem_a = cutlass.Array(
            smem_base.data_ptr() + self._alloc_a.offset,
            dtype=io_dtype,
            shape=(tile_m * num_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work
    @cute.jit
    def consume_tile(self, stage_info: StageInfo) -> None:
        del stage_info

    @producer_work
    @cute.jit
    def load(self, stage_info: StageInfo, *, gmem_offset: cutlass.Int32) -> None:
        tx, _, _ = cute.arch.thread_idx()
        lane = tx % 32

        sA_curr = self.shared_smem_a.subview(tile_m * stage_info.stage_idx)
        elems_per_thread = tile_m // 32

        for i in cutlass.range_constexpr(elems_per_thread):
            idx = lane * elems_per_thread + i
            val = self.gA.load(gmem_offset + idx)
            sA_curr.store(val, idx=idx)


@dataclass
class SmemBResource(MemoryResource):
    """
    SMEM buffer filled by TMA or global memory load depending on ``use_tma_for_b``.
    """

    tma_desc: cutlass.Constexpr = field(init=False, default=None)
    gB: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_b: cutlass.Constexpr = field(init=False, default=None)
    _alloc_b: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        *,
        tma_desc: cutlass.Pointer = None,
        gB: cutlass.Array = None,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.tma_desc = tma_desc
        self.gB = gB
        elem_size = io_dtype.width // 8
        self._alloc_b = SmemAllocation("smem_b", tile_n * num_stages * elem_size)

    def get_smem_requirements(self):
        return [self._alloc_b]

    @cute.jit
    def _init_smem_state(self, stage_info: StageInfo) -> None:
        smem_base = stage_info.context.smem_base
        self.shared_smem_b = cutlass.Array(
            smem_base.data_ptr() + self._alloc_b.offset,
            dtype=io_dtype,
            shape=(tile_n * num_stages,),
            addrspace=3,
        )

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_load_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_store_state(self, stage_info: StageInfo) -> None:
        self._init_smem_state(stage_info)

    @consumer_work
    @cute.jit
    def consume_tile(self, stage_info: StageInfo) -> None:
        del stage_info

    @producer_work
    @cute.jit
    def load(self, stage_info: StageInfo, *, gmem_offset: cutlass.Int32) -> None:
        if cutlass.const_expr(use_tma_for_b):
            if prims.elect_sync():
                sB_curr = self.shared_smem_b.subview(tile_n * stage_info.stage_idx)
                prims.cp_async_bulk_tensor_shared_cta_global(
                    sB_curr,
                    self.tma_desc,
                    (gmem_offset, 0),
                    stage_info.barrier,
                )
        else:
            tx, _, _ = cute.arch.thread_idx()
            lane = tx % 32
            sB_curr = self.shared_smem_b.subview(tile_n * stage_info.stage_idx)
            elems_per_thread = tile_n // 32
            for i in cutlass.range_constexpr(elems_per_thread):
                idx = lane * elems_per_thread + i
                val = self.gB.load(gmem_offset + idx)
                sB_curr.store(val, idx=idx)


# ──────────────────────────────────────────────────────────────────────
# Store task resource — reads both SMEM buffers and stores to GMEM
# ──────────────────────────────────────────────────────────────────────


@dataclass
class StoreResource(MemoryResource):
    """
    Combined store resource that reads smem_a and smem_b and writes to gmem.
    """

    gDA: cutlass.Constexpr = field(init=False, default=None)
    gDB: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_a_ref: cutlass.Constexpr = field(init=False, default=None)
    shared_smem_b_ref: cutlass.Constexpr = field(init=False, default=None)

    def __init__(
        self,
        gDA: cutlass.Array,
        gDB: cutlass.Array,
        smem_a_resource: SmemAResource,
        smem_b_resource: SmemBResource,
        **kwargs: object,
    ) -> None:
        super().__init__(**kwargs)
        self.gDA = gDA
        self.gDB = gDB
        self.smem_a_resource = smem_a_resource
        self.smem_b_resource = smem_b_resource

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo) -> None:
        tx, _, _ = cute.arch.thread_idx()
        gmem_a_offset = stage_info.loop_offset * tile_m
        gmem_b_offset = stage_info.loop_offset * tile_n

        sidx = stage_info.loop_offset % num_stages
        sA = self.smem_a_resource.shared_smem_a.subview(tile_m * sidx)
        sB = self.smem_b_resource.shared_smem_b.subview(tile_n * sidx)

        tid = tx
        total_threads = num_store_warps * 32

        for i in cutlass.range_constexpr(tile_m // total_threads):
            idx = tid + i * total_threads
            val = sA.load(idx)
            self.gDA.store(val, idx=gmem_a_offset + idx)

        for i in cutlass.range_constexpr(tile_n // total_threads):
            idx = tid + i * total_threads
            val = sB.load(idx)
            self.gDB.store(val, idx=gmem_b_offset + idx)


# ──────────────────────────────────────────────────────────────────────
# Resource construction helpers
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def create_smem_a_resource(gA: cutlass.Array) -> SmemAResource:
    """
    Build SmemA with AsyncAsync pipeline configuration.
    """
    cfg = PipelineConfig.create_async_async_pipeline_cfg(
        num_stages=num_stages,
        producer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_load_a_warps * 32,
        ),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=num_store_warps * 32,
        ),
        cta_layout_vmnk=(1, 1, 1, 1),
    )
    return SmemAResource(gA=gA, pipeline_config=cfg, name="smem_a")


@cute.jit
def create_smem_b_resource(
    *,
    tma_desc: cutlass.Pointer = None,
    gB: cutlass.Array = None,
) -> SmemBResource:
    """
    Build SmemB with TmaAsync or AsyncAsync pipeline per ``use_tma_for_b``.
    """
    if cutlass.const_expr(use_tma_for_b):
        cfg = PipelineConfig.create_tma_async_pipeline_cfg(
            num_stages=num_stages,
            num_bytes=bytes_b,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                num_store_warps,
            ),
            cta_layout_vmnk=(1, 1, 1, 1),
        )
    else:
        cfg = PipelineConfig.create_async_async_pipeline_cfg(
            num_stages=num_stages,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_load_b_warps * 32,
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                size=num_store_warps * 32,
            ),
            cta_layout_vmnk=(1, 1, 1, 1),
        )
    return SmemBResource(
        tma_desc=tma_desc,
        gB=gB,
        pipeline_config=cfg,
        name="smem_b",
    )


@cute.jit
def create_ab_sync_group(
    smem_a: SmemAResource,
    smem_b: SmemBResource,
) -> PipelineGroup:
    """
    Merge SmemA and SmemB so one ``release()`` covers both empty barriers.
    """
    return PipelineGroup(
        name="ab_sync",
        members=[smem_a, smem_b],
        mode=PipelineGroupMode.Merge,
    )


# ──────────────────────────────────────────────────────────────────────
# Kernel
# ──────────────────────────────────────────────────────────────────────


@cute.kernel
def merge_copy_kernel(
    gA: cutlass.Array,
    gB: cutlass.Array,
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    gDA: cutlass.Array,
    gDB: cutlass.Array,
    num_iters: cutlass.Constexpr,
) -> None:
    """
    Load A/B tiles through a Merge group and store to separate GMEM outputs.
    """
    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    if cutlass.const_expr(use_tma_for_b):
        if warp_idx == 5:
            prims.prefetch_tensormap(tma_b_desc.get_ptr())

    # Resource construction
    allocator = SmemAllocator()

    gmem_a = GmemAResource(name="gmem_a")
    gmem_b = GmemBResource(name="gmem_b")
    smem_a = create_smem_a_resource(gA)
    smem_b = create_smem_b_resource(
        tma_desc=tma_b_desc.get_ptr() if use_tma_for_b else None,
        gB=gB if not use_tma_for_b else None,
    )
    # Merge two SMEM resources into a single PipelineGroup
    ab_sync = create_ab_sync_group(smem_a, smem_b)

    store_res = StoreResource(
        gDA=gDA,
        gDB=gDB,
        smem_a_resource=smem_a,
        smem_b_resource=smem_b,
        name="store_res",
    )

    allocator.add_resource(smem_a)
    allocator.add_resource(smem_b)
    # Do not forget to add the pipeline group to the allocator
    allocator.add_pipeline_group(ab_sync)

    # Task schedule construction
    @schedule
    def load_a_schedule(gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        with domain_loop(0, num_iters, 1):
            gmem_offset = gmem.compute_offset()
            smem.try_acquire()
            smem.acquire()
            smem.load(gmem_offset=gmem_offset)
            smem.commit()

    # Pass grouped resource ab_sync.smem_a to the schedule
    load_a_result = load_a_schedule(gmem_a, ab_sync.smem_a)

    load_a_task = Task(
        src_resources=[gmem_a],
        dst_resources=[smem_a],
        warp_idx=4,
        num_warps=num_load_a_warps,
        schedule=load_a_result,
        num_registers=40,
        name="LoadA",
        debug_print=debug_print,
    )

    @schedule
    def load_b_schedule(gmem: MemoryResource, smem: MemoryResource) -> None:
        smem.init_load_state()
        with domain_loop(0, num_iters, 1):
            gmem_offset = gmem.compute_offset()
            smem.try_acquire()
            smem.acquire()
            smem.load(gmem_offset=gmem_offset)
            smem.commit()

    # Pass grouped resource ab_sync.smem_b to the schedule
    load_b_result = load_b_schedule(gmem_b, ab_sync.smem_b)

    load_b_task = Task(
        src_resources=[gmem_b],
        dst_resources=[smem_b],
        warp_idx=5,
        num_warps=num_load_b_warps,
        schedule=load_b_result,
        num_registers=40,
        name="LoadB",
        debug_print=debug_print,
    )

    @schedule
    def store_schedule(
        smem_a_ref: MemoryResource,
        smem_b_ref: MemoryResource,
        store: MemoryResource,
        group: MemoryResource,
    ) -> None:
        smem_a_ref.init_store_state()
        smem_b_ref.init_store_state()
        with domain_loop(0, num_iters, 1):
            # Call waits on both shared SMEM resources and then works on both members.
            smem_a_ref.try_wait()
            smem_a_ref.wait()
            smem_b_ref.try_wait()
            smem_b_ref.wait()
            smem_a_ref.consume_tile()
            smem_b_ref.consume_tile()
            store.store()
            # Release the pipeline group, not the individual members
            group.release()

    # Pass grouped resources ab_sync.smem_a and ab_sync.smem_b to the schedule
    store_result = store_schedule(ab_sync.smem_a, ab_sync.smem_b, store_res, ab_sync)

    store_task = Task(
        # Task gets original resources, not the grouped resource
        src_resources=[smem_a, smem_b],
        dst_resources=[store_res],
        warp_idx=0,
        num_warps=num_store_warps,
        schedule=store_result,
        num_registers=160,
        name="StoreTask",
        debug_print=debug_print,
    )

    @schedule
    def padding_schedule() -> None:
        with domain_loop(0, num_iters, 1):
            pass

    padding_result = padding_schedule()

    padding_task = Task(
        src_resources=[],
        dst_resources=[],
        warp_idx=6,
        num_warps=num_padding_warps,
        schedule=padding_result,
        num_registers=40,
        name="PaddingTask",
        debug_print=debug_print,
    )

    # TaskManager construction and execution
    # PipelineGroup is not a resource, it does not participate in the dependency graph
    resource_dependency_graph = {
        smem_a: [gmem_a],
        smem_b: [gmem_b],
        store_res: [smem_a, smem_b],
    }

    allocator.compute_layout()

    task_manager = TaskManager(
        tasks=[load_a_task, load_b_task, store_task, padding_task],
        resource_dependency_graph=resource_dependency_graph,
        smem_allocator=allocator,
    )

    task_manager.setup_resources_and_tasks()

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    task_manager.run()


# ──────────────────────────────────────────────────────────────────────
# Host runners and CLI
# ──────────────────────────────────────────────────────────────────────


@cute.jit
def host_function(
    a: cutlass.Array,
    b: cutlass.Array,
    da: cutlass.Array,
    db: cutlass.Array,
    num_iters: cutlass.Constexpr,
) -> None:
    """
    Host JIT entry: build TMA descriptor and launch ``merge_copy_kernel``.
    """
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(1, tile_n),
        swizzle=cuda.TensorMapSwizzle.none,
        stride_order=(1, 0),
    )

    grid = (1, 1, 1)
    block = (total_warps * cute.arch.WARP_SIZE, 1, 1)

    merge_copy_kernel(a, b, tma_b_desc, da, db, num_iters).launch(
        grid=grid,
        block=block,
    )


# ──────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────


@lru_cache(maxsize=4)
def _prepare(n_elements: int, tma_for_b: bool):
    """
    Allocate tensors, set ``use_tma_for_b``, and return cached ``cute.compile`` fn.
    """
    global use_tma_for_b
    use_tma_for_b = tma_for_b

    import torch

    a = torch.randn(n_elements, dtype=torch.float16, device="cuda")
    b = torch.randn(1, n_elements, dtype=torch.float16, device="cuda")
    da = torch.zeros_like(a)
    db = torch.zeros(1, n_elements, dtype=torch.float16, device="cuda")

    a_ = from_dlpack(a).mark_layout_dynamic()
    b_ = from_dlpack(b).mark_layout_dynamic()
    da_ = from_dlpack(da).mark_layout_dynamic()
    db_ = from_dlpack(db).mark_layout_dynamic()

    num_iters = n_elements // tile_m

    compiled_fn = cute.compile[cute.FrontendNext, cute.GenerateLineInfo(True)](
        host_function,
        a_,
        b_,
        da_,
        db_,
        num_iters,
    )
    return compiled_fn, (a, b, da, db, a_, b_, da_, db_)


def run(
    n_elements: int = 1024,
    tolerance: float = 0.0,
    tma_for_b: bool = True,
) -> None:
    """Run the Merge copy kernel and validate.

    Args:
        tma_for_b: ``True`` for Merge(AsyncAsync + TmaAsync),
                   ``False`` for Merge(AsyncAsync + AsyncAsync).
    """
    import torch

    assert n_elements % tile_m == 0, f"n_elements must be divisible by {tile_m}"
    assert n_elements % tile_n == 0, f"n_elements must be divisible by {tile_n}"

    torch.manual_seed(42)

    compiled_fn, (a, b, da, db, a_, b_, da_, db_) = _prepare(n_elements, tma_for_b)
    compiled_fn(a_, b_, da_, db_)
    torch.cuda.synchronize()

    print(f"da[:8] = {da[:8]}")
    print(f"a[:8]  = {a[:8]}")
    print(f"db[:8] = {db.view(-1)[:8]}")
    print(f"b[:8]  = {b.view(-1)[:8]}")
    torch.testing.assert_close(da, a, atol=tolerance, rtol=0.0)
    torch.testing.assert_close(db.view(-1), b.view(-1), atol=tolerance, rtol=0.0)


if __name__ == "__main__":
    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)

    parser = argparse.ArgumentParser(
        description="Merge copy kernel (configurable TMA/global memory load for B)"
    )
    parser.add_argument("--n", type=int, default=1024, help="Number of elements")
    parser.add_argument(
        "--no-tma",
        action="store_true",
        help="Use global memory load instead of TMA for SmemB",
    )
    args = parser.parse_args()

    run(n_elements=args.n, tma_for_b=not args.no_tma)
    print("PASS")
