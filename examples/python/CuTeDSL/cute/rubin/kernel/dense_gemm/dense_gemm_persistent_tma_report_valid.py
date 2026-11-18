# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import os
import sys
from typing import Optional, Tuple, Type, Union, Literal
from functools import lru_cache

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass._mlir.dialects.nvvm import MBarrierScopeKind
from cutlass.experimental.primitives.nvvm_wrapper import fence_sync_restrict, MemOrder
from pathlib import Path

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.dense_gemm.dense_gemm_persistent import (
    PersistentDenseGemmKernel as BlackwellPersistentDenseGemmKernel,
    _compute_stages,
)


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    max_active_clusters: cutlass.Constexpr,
    stream: cuda.CUstream,
    pdl_early_launch_next: cutlass.Constexpr,
    pdl_early_start: cutlass.Constexpr,
    check_b_valid: cutlass.Constexpr,
    eager_launch_next: cutlass.Constexpr,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(
        a,
        b,
        c,
        max_active_clusters,
        stream,
        pdl_early_launch_next,
        pdl_early_start,
        check_b_valid,
        eager_launch_next,
        epilogue_op,
    )


class SM107TmaReportValidGemmKernel(BlackwellPersistentDenseGemmKernel):
    """Persistent dense GEMM kernel for Rubin supporting data-driven synchronization
    between producer and consumer using Rubin's TMA report_valid feature.

    Inherits from BlackwellPersistentDenseGemmKernel for broad dtype support
    (Float16, BFloat16, etc.) using SM100 MMA instructions (backward compatible
    on SM107). Overrides arch to use Rubin's larger SMEM and TMEM resources.

    :param check_b_valid: Activate TMA report_valid and the retry warp.
    :type check_b_valid: bool
    :param pdl_early_launch_next: Call griddepcontrol_launch_dependents. True for all
        non-last kernels. Fires at kernel start when eager_launch_next=True.
    :type pdl_early_launch_next: bool
    :param pdl_early_start: Kernel was launched early via PDL. Consumers not using data-driven sync
        call griddepcontrol_wait before data loads.
    :type pdl_early_start: bool
    :param eager_launch_next: Fire griddepcontrol_launch_dependents at kernel start.
        When False, defer it to after all TMA loads (ab_producer.tail()). Default True
        for both data-driven and regular PDL synchronization.
    :type eager_launch_next: bool
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        swizzle_size: int = 1,
        raster_along: Literal["m", "n"] = "m",
        pdl_early_launch_next: bool = False,
        pdl_early_start: bool = False,
        check_b_valid: bool = False,
        eager_launch_next: bool = True,
        producer_sentinel_init: bool = False,
        positive_zero_only: bool = False,
    ):
        super().__init__(
            acc_dtype,
            use_2cta_instrs,
            mma_tiler_mn,
            cluster_shape_mn,
            use_tma_store,
            swizzle_size,
            raster_along,
        )
        # Use Rubin's larger SMEM and TMEM resources
        self.arch = "sm_107"
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

        self.retry_warp_id = 6
        self.producer_sentinel_init = producer_sentinel_init
        # Canonicalize the producer's -0.0 sentinel to +0.0 in the epilogue via
        # the .pzo convert (sm_107a). See utils.gemm.sm100.epilogue.
        self.positive_zero_only = positive_zero_only
        self.sentinel_init_warp_id = None
        if cutlass.const_expr(producer_sentinel_init):
            self.sentinel_init_warp_id = self.retry_warp_id + (
                1 if check_b_valid else 0
            )
        if cutlass.const_expr(check_b_valid):
            self.threads_per_cta += 32
        if cutlass.const_expr(producer_sentinel_init):
            self.threads_per_cta += 32

    @staticmethod
    def _kernel_name_prefix(
        pdl_early_launch_next: bool,
        pdl_early_start: bool,
        check_b_valid: bool,
        eager_launch_next: bool,
    ) -> str:
        return (
            ("early_launch_" if pdl_early_launch_next else "no_early_launch_")
            + ("early_start_" if pdl_early_start else "no_early_start_")
            + ("report_valid_" if check_b_valid else "no_report_valid_")
            + ("immediate_launch" if eager_launch_next else "deferred_launch")
        )

    def _setup_attributes(self):
        # Configure tiled mma
        tiled_mma = self._create_tiled_mma()

        # Compute mma/cluster/tile shapes
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // atom_thr_size,
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Compute epilogue subtile
        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = _compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
            self.use_tma_store,
            c_smem_layout,
        )

        # Compute A/B/C shared memory layout
        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )

        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

        # Compute the number of tensor memory allocation columns
        self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
            tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
        )

    # Copied from Blackwell dense_gemm_persistent
    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        pdl_early_launch_next: cutlass.Constexpr,
        pdl_early_start: cutlass.Constexpr,
        check_b_valid: cutlass.Constexpr,
        eager_launch_next: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        self.c_dtype: Type[cutlass.Numeric] = c.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

        tiled_mma = self._create_tiled_mma()

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.select(
            self.a_smem_layout_staged,
            mode=list(range(cute.rank(self.a_smem_layout_staged) - 1)),
        )
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.select(
            self.b_smem_layout_staged,
            mode=list(range(cute.rank(self.b_smem_layout_staged) - 1)),
        )
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size
        self.num_tma_load_bytes_a = a_copy_size * atom_thr_size
        self.num_tma_load_bytes_b = b_copy_size * atom_thr_size

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), c, epi_smem_layout, self.epi_tile
            )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
            max_active_clusters,
        )

        # Launch the kernel synchronously
        self.kernel.set_name_prefix(
            self._kernel_name_prefix(
                pdl_early_launch_next,
                pdl_early_start,
                check_b_valid,
                eager_launch_next,
            )
        )
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            c,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            pdl_early_launch_next,
            pdl_early_start,
            check_b_valid,
            eager_launch_next,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            use_pdl=pdl_early_start,
        )
        return

    # Based on Blackwell dense_gemm_persistent with a retry warp for Rubin TMA
    # report_valid loads.
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        c_gmem: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        pdl_early_launch_next: cutlass.Constexpr,
        pdl_early_start: cutlass.Constexpr,
        check_b_valid: cutlass.Constexpr,
        eager_launch_next: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation
        with data-driven (report_valid) synchronization support.
        """
        # Launch the successor at kernel start (unless deferred to after all TMA loads).
        # With producer_sentinel_init, the sentinel-init warp owns the launch instead.
        if cutlass.const_expr(
            pdl_early_launch_next
            and eager_launch_next
            and not self.producer_sentinel_init
        ):
            cute.arch.griddepcontrol_launch_dependents()

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        need_peer_retry = cutlass.const_expr(check_b_valid and self.use_2cta_instrs)

        peer_retry_coord_buf_type = cute.struct.MemRange[
            cutlass.Int32, 5
        ]  # mnkl+stage_idx

        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            retry_cluster_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_ab_stage
            ]
            peer_retry_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 2]
            tmem_dealloc_mbar: cutlass.Int64
            peer_retry_coord_buf: cute.struct.Align[peer_retry_coord_buf_type, 16]
            tmem_holding_buf: cutlass.Int32
            sentinel_init_count: cutlass.Int32

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # Compute peer CTA rank for dsmem addressing (2-CTA: flip V-dim bit)
        peer_cta_rank = None
        if cutlass.const_expr(need_peer_retry):
            peer_cta_rank = cta_rank_in_cluster ^ 1

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_mma_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        if cutlass.const_expr(check_b_valid):
            ab_pipeline_consumer_group_retry = pipeline.CooperativeGroup(
                pipeline.Agent.Warp
            )
            # Retry and MMA warps independently wait/release the same stage buffers.
            ab_pipeline = pipeline.PipelineTmaUmmaRetry.create(
                barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
                num_stages=self.num_ab_stage,
                producer_group=ab_pipeline_producer_group,
                consumer_group_umma=ab_pipeline_mma_consumer_group,
                consumer_group_retry=ab_pipeline_consumer_group_retry,
                tx_count=self.num_tma_load_bytes,
                cta_layout_vmnk=cluster_layout_vmnk,
                enable_multicast_signaling=True,
                defer_sync=True,
            )
            ab_producer, ab_consumer, _ = ab_pipeline.make_participants()

            # Ping-pong mbarriers protect retry coordinates sent through dsmem.
            full_mbar_ptr = None
            empty_mbar_ptr = None
            local_coord_ptr = None
            if cutlass.const_expr(need_peer_retry):
                full_mbar_ptr = storage.peer_retry_mbar_ptr.data_ptr()
                empty_mbar_ptr = full_mbar_ptr + 1
                local_coord_ptr = storage.peer_retry_coord_buf.data_ptr()
                if warp_idx == 0:
                    with cute.arch.elect_one():
                        cute.arch.mbarrier_init(full_mbar_ptr, 1)
                        cute.arch.mbarrier_init(empty_mbar_ptr, 32)
        else:
            ab_pipeline = pipeline.PipelineTmaUmma.create(
                barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
                num_stages=self.num_ab_stage,
                producer_group=ab_pipeline_producer_group,
                consumer_group=ab_pipeline_mma_consumer_group,
                tx_count=self.num_tma_load_bytes,
                cta_layout_vmnk=cluster_layout_vmnk,
                enable_multicast_signaling=True,
                defer_sync=True,
            )
            ab_producer, ab_consumer = ab_pipeline.make_participants()

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if use_2cta_instrs else 1
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem_dealloc_barrier = None
        if cutlass.const_expr(not self.use_tma_store):
            tmem_dealloc_barrier = pipeline.NamedBarrier(
                barrier_id=self.tmem_dealloc_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Initialize retry sync barriers for multicast TMA re-issue coordination
        retry_cluster_mbar = None
        retry_dst_rank = None
        retry_is_signalling = None
        need_retry_sync = cutlass.const_expr(check_b_valid and self.is_b_mcast)
        if cutlass.const_expr(need_retry_sync):
            num_mcast = self.num_mcast_ctas_b
            retry_sync_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_mcast - 1
            )
            retry_cluster_mbar = pipeline.MbarrierArray(
                barrier_storage=storage.retry_cluster_mbar_ptr.data_ptr(),
                num_stages=self.num_ab_stage,
                agent=(pipeline.PipelineOp.AsyncThread, retry_sync_group),
            )
            cta_layout_for_retry = (
                cute.make_layout(cluster_layout_vmnk.shape)
                if cluster_layout_vmnk is not None
                else cute.make_layout((1, 1, 1, 1))
            )
            # B multicast spans the M dimension, so only those CTAs join retry sync.
            retry_mcast_mode = (0, 1)
            retry_dst_rank, retry_is_signalling = (
                pipeline.PipelineTmaAsync.init_empty_barrier_arrive_signal(
                    cta_layout_for_retry, tidx, retry_mcast_mode
                )
            )
            retry_is_signalling = retry_is_signalling & (
                retry_dst_rank != cta_rank_in_cluster
            )

        if cutlass.const_expr(self.producer_sentinel_init):
            if warp_idx == 0:
                with cute.arch.elect_one():
                    cute.arch.store(
                        storage.sentinel_init_count.ptr,
                        cutlass.Int32(0),
                        ss="cta",
                        sem="relaxed",  # pipeline_init_wait() guarantees this is visible
                        scope="cta",
                    )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # Consumer not using data-driven sync waits for predecessor's signal before loading data.
        if cutlass.const_expr(pdl_early_start and not check_b_valid):
            cute.arch.griddepcontrol_wait()

        #
        # Construct the scheduler
        #
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((atom_v, rest_v), RestK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), RestK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # Peek (try_wait) AB buffer empty for k_tile = 0
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                        report_valid=check_b_valid,
                    )

                    # Peek (try_wait) AB buffer empty for next k_tile
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait A/B buffer empty
            #
            ab_producer.tail()
            # Deferred launch: signal successor after all TMA loads are issued.
            # (The sentinel-init warp owns the launch when producer_sentinel_init is set.)
            if cutlass.const_expr(
                pdl_early_launch_next
                and not eager_launch_next
                and not self.producer_sentinel_init
            ):
                cute.arch.griddepcontrol_launch_dependents()

        #
        # Specialized Retry warp
        #
        if cutlass.const_expr(check_b_valid):
            # Only executed by leader CTA because a 2-CTA TMA load only signals leader CTA's full barrier
            if warp_idx == self.retry_warp_id and is_leader_cta:
                state = pipeline.PerStagePipelineState(self.num_ab_stage)

                #
                # Each stage has an mbarrier (retry_cluster_mbar) for multicast re-tries, which the CTAs in a multicast use to
                # synchronize before re-issuing the TMA. Without it, one CTA in the multicast can re-issue a TMA
                # while the previous TMA in a different CTA is completing.
                #
                # We track per-stage:
                #    retry_cluster_phases[i]  = the phase of that barrier
                #    retry_cluster_arrived[i] = whether or not the CTA already arrived,
                #        so we don't arrive multiple times (needed since different CTAs may
                #        process loop iterations in a different order).
                retry_cluster_phases = None
                retry_cluster_arrived = None
                if cutlass.const_expr(need_retry_sync):
                    retry_cluster_phases = cute.make_rmem_tensor(
                        (self.num_ab_stage), cutlass.Int32
                    )
                    retry_cluster_phases.fill(0)
                    retry_cluster_arrived = cute.make_rmem_tensor(
                        (self.num_ab_stage), cutlass.Int32
                    )
                    retry_cluster_arrived.fill(0)

                tile_sched = StaticPersistentTileScheduler.create(
                    tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()

                # a new work tile may start in middle stage buffer, so we need to track the start stage offset
                stage_offset = cutlass.Int32(0)
                empty_phase = cutlass.Int32(1)
                while work_tile.is_valid_tile:
                    processed_k_tiles = cutlass.Int32(0)
                    state.reset_count()

                    # Compute tAgA_slice for this tile (same as DMA warp)
                    cur_tile_coord = work_tile.tile_idx
                    mma_tile_coord_mnl = (
                        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                        cur_tile_coord[1],
                        cur_tile_coord[2],
                    )

                    # Cycle over all stages buffers until all k_tiles for an output tile contain valid data
                    while processed_k_tiles < k_tile_cnt:
                        for _ in range(self.num_ab_stage):
                            stage_idx = state.index

                            k_tile_for_stage = (
                                pipeline.PerStagePipelineState.compute_producer_count(
                                    stage_idx,
                                    state.count,
                                    stage_offset,
                                    self.num_ab_stage,
                                )
                            )

                            if k_tile_for_stage < k_tile_cnt:
                                tma_done, data_valid = ab_pipeline.consumer_test_valid(
                                    state
                                )

                                if tma_done and data_valid:
                                    ab_pipeline.retry_release(state)
                                    state.mark_valid()  # update stage buffer state for next k_tile
                                    processed_k_tiles += 1
                                elif tma_done:
                                    do_reissue = cutlass.Boolean(True)
                                    # Check if peer multicast CTAs are also ready to re-issue
                                    if cutlass.const_expr(
                                        need_retry_sync
                                    ):  # ignore if not using TMA multicast
                                        # Arrive on peer's retry sync barrier (once per round)
                                        if not retry_cluster_arrived[stage_idx]:
                                            if retry_is_signalling:
                                                cute.arch.mbarrier_arrive(
                                                    retry_cluster_mbar.get_barrier(
                                                        stage_idx
                                                    ),
                                                    retry_dst_rank,
                                                    num_mcast - 1,
                                                )
                                            retry_cluster_arrived[stage_idx] = 1

                                        do_reissue = retry_cluster_mbar.test_wait(
                                            stage_idx,
                                            retry_cluster_phases[stage_idx],
                                        )

                                    if do_reissue:
                                        # Peer arrived, reset sync flags
                                        if cutlass.const_expr(need_retry_sync):
                                            retry_cluster_phases[stage_idx] = (
                                                retry_cluster_phases[stage_idx] ^ 1
                                            )
                                            retry_cluster_arrived[stage_idx] = 0

                                        # Re-arm and re-issue TMA for operand B
                                        retry_gX_slice = tBgB[
                                            (
                                                None,
                                                mma_tile_coord_mnl[1],
                                                None,
                                                mma_tile_coord_mnl[2],
                                            )
                                        ]
                                        retry_bytes = self.num_tma_load_bytes_b

                                        # Signal peer CTA to re-issue its half of the collaborative cute.copy
                                        if cutlass.const_expr(need_peer_retry):
                                            # Acquire: wait for peer to free the dsmem buffer.
                                            cute.arch.mbarrier_wait(
                                                empty_mbar_ptr, empty_phase
                                            )
                                            empty_phase ^= 1
                                            with cute.arch.elect_one():
                                                cute.arch.mbarrier_arrive_and_expect_tx(
                                                    full_mbar_ptr,
                                                    peer_retry_coord_buf_type.size_in_bytes,
                                                    peer_cta_rank,
                                                    relaxed=True,
                                                    scope=MBarrierScopeKind.CLUSTER,
                                                )
                                                cute.arch.store_async_dsmem(
                                                    local_coord_ptr,
                                                    (
                                                        stage_idx,
                                                        k_tile_for_stage,
                                                        mma_tile_coord_mnl[0],
                                                        mma_tile_coord_mnl[1],
                                                    ),
                                                    full_mbar_ptr,
                                                    peer_cta_rank,
                                                )
                                                cute.arch.store_async_dsmem(
                                                    local_coord_ptr + 4,
                                                    mma_tile_coord_mnl[2],
                                                    full_mbar_ptr,
                                                    peer_cta_rank,
                                                )

                                        ab_pipeline.retry_expect_tx(state, retry_bytes)

                                        state.mark_invalid()  # update stage buffer state for re-issuing TMA
                                        cute.copy(
                                            tma_atom_b,
                                            retry_gX_slice[(None, k_tile_for_stage)],
                                            tBsB[(None, stage_idx)],
                                            tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                                state
                                            ),
                                            mcast_mask=b_full_mcast_mask,
                                            report_valid=True,
                                        )
                            state.next()  # advance to next stage buffer

                    # Update stage_offset for next tile (TMA continues round-robin)
                    stage_offset = (stage_offset + k_tile_cnt) % self.num_ab_stage
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

                # -1 in stage_idx tells the peer CTA to exit.
                if cutlass.const_expr(need_peer_retry):
                    # Acquire: wait for peer to free the dsmem buffer.
                    cute.arch.mbarrier_wait(empty_mbar_ptr, empty_phase)
                    empty_phase ^= 1
                    with cute.arch.elect_one():
                        cute.arch.mbarrier_arrive_and_expect_tx(
                            full_mbar_ptr,
                            cutlass.Int32.width / 8,
                            peer_cta_rank,
                            relaxed=True,
                            scope=MBarrierScopeKind.CLUSTER,
                        )
                        cute.arch.store_async_dsmem(
                            local_coord_ptr, -1, full_mbar_ptr, peer_cta_rank
                        )
                    # Tail: drain the peer's release of the final (-1) message so the
                    # empty_mbar has no dangling arrives after kernel exit.
                    cute.arch.mbarrier_wait(empty_mbar_ptr, empty_phase)

            if cutlass.const_expr(need_peer_retry):
                # Peer CTA simply waits for the leader to send re-issue coordinates through dsmem, and re-issues the copy
                if warp_idx == self.retry_warp_id and not is_leader_cta:
                    full_phase = cutlass.Int32(0)

                    retry_stage_idx = 0
                    while retry_stage_idx != -1:
                        cute.arch.mbarrier_wait(full_mbar_ptr, full_phase)
                        full_phase ^= 1
                        retry_stage_idx = local_coord_ptr[0]
                        retry_k_tile = local_coord_ptr[1]
                        retry_coord_n = local_coord_ptr[3]
                        retry_coord_l = local_coord_ptr[4]

                        # orders local shared memory reads before the arrive
                        fence_sync_restrict(MemOrder.RELEASE)
                        cute.arch.mbarrier_arrive(
                            empty_mbar_ptr,
                            peer_cta_rank,
                            scope=MBarrierScopeKind.CLUSTER,
                            relaxed=True,
                        )

                        if retry_stage_idx != -1:
                            retry_gX_slice = tBgB[
                                (None, retry_coord_n, None, retry_coord_l)
                            ]
                            cute.copy(
                                tma_atom_b,
                                retry_gX_slice[(None, retry_k_tile)],
                                tBsB[(None, retry_stage_idx)],
                                tma_bar_ptr=ab_pipeline.sync_object_full.get_barrier(
                                    retry_stage_idx
                                ),
                                mcast_mask=b_full_mcast_mask,
                                report_valid=True,
                            )

        #
        # Specialized sentinel-init warp (producer_sentinel_init)
        #
        if cutlass.const_expr(self.producer_sentinel_init):
            if warp_idx == self.sentinel_init_warp_id:
                self._sentinel_init_warp(
                    c_gmem,
                    tile_sched_params,
                    storage.sentinel_init_count.ptr,
                    pdl_early_launch_next,
                )

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        # tCtAcc += tCrA * tCrB
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, handle.index)
                        cute.gemm(
                            tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc
                        )

                        handle.release()

                        # Peek (try_wait) AB buffer full for next k_tile
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

                #
                # Async arrive accumulator buffer full
                #
                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)

        sC = None
        if cutlass.const_expr(self.use_tma_store):
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC = smem.allocate_tensor(
                element_type=self.c_dtype,
                layout=c_smem_layout_staged.outer,
                byte_alignment=128,
                swizzle=c_smem_layout_staged.inner,
            )

        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop for epilogue
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            if cutlass.const_expr(self.use_tma_store):
                assert tma_atom_c is not None and sC is not None
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilogue_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage, producer_group=c_producer_group
                )

            output_tile_cnt = cutlass.Int32(0)
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                #
                # Pre-advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

                if cutlass.const_expr(self.producer_sentinel_init):
                    # Init warp and epilogue walk tiles in the same order; wait for the
                    # sentinel counter to reach this tile's index before storing.
                    output_tile_cnt += 1
                    output_tiles_sent_inited = cutlass.Int32(0)
                    while output_tiles_sent_inited < output_tile_cnt:
                        output_tiles_sent_inited = cute.arch.load(
                            storage.sentinel_init_count.ptr,
                            cutlass.Int32,
                            ss="cta",
                            sem="acquire",
                            scope="cta",
                        )

                num_tiles_executed = tile_sched.num_tiles_executed
                if cutlass.const_expr(self.use_tma_store):
                    acc_consumer_state = utils.gemm.sm100.epilogue_tma_store(
                        self,
                        tidx,
                        warp_idx,
                        tma_atom_c,
                        tCtAcc_base,
                        sC,
                        tCgC,
                        epi_tile,
                        num_tiles_executed,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        c_pipeline,
                        pzo_convert=self.positive_zero_only,
                    )
                else:
                    acc_consumer_state = utils.gemm.sm100.epilogue(
                        self,
                        tidx,
                        tCtAcc_base,
                        tCgC,
                        epi_tile,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        pzo_convert=self.positive_zero_only,
                    )

            if cutlass.const_expr(self.use_tma_store):
                # Wait for C store complete
                c_pipeline.producer_tail()
            else:
                # Synchronize before TMEM dealloc (done by the caller)
                tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

    @cute.jit
    def _sentinel_init_warp(
        self, c_gmem, tile_sched_params, sentinel_count_ptr, pdl_early_launch_next
    ):
        # Write the -0.0 sentinel to every output tile, then launch dependents. A
        # per-tile counter (released here, awaited in the epilogue) orders the
        # sentinels before the epilogue stores.
        # (CTA_M, CTA_N, REST_M, REST_N, REST_L)
        gC_cta_tiled = cute.local_tile(
            c_gmem, self.cta_tile_shape_mnk[:2], (None, None, None)
        )
        coord_full = cute.make_identity_tensor(c_gmem.shape)  # for predication
        # (CTA_M, CTA_N, REST_M, REST_N, REST_L)
        gC_coord_tiled = cute.local_tile(
            coord_full, self.cta_tile_shape_mnk[:2], (None, None, None)
        )

        # Coalesced + vectorized store: each lane writes one 128-bit vector of vec_elems
        # elements, and consecutive lanes cover consecutive vectors. Build the 32-lane
        # thread layout so its stride-1 mode lies on C's contiguous axis.
        # TMA store ensure 16B alignment
        vec_elems = 128 // self.c_dtype.width
        vec_copy_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), self.c_dtype, num_bits_per_copy=128
        )
        if cutlass.const_expr(self.c_layout.is_m_major_c()):
            # M contiguous: the vector spans M.
            m_lanes = min(self.cta_tile_shape_mnk[0] // vec_elems, cute.arch.WARP_SIZE)
            n_lanes = cute.arch.WARP_SIZE // m_lanes
            thr_layout = cute.make_ordered_layout((m_lanes, n_lanes), (0, 1))
            val_layout = cute.make_layout((vec_elems, 1))
        else:
            # N contiguous: the vector spans N.
            n_lanes = min(self.cta_tile_shape_mnk[1] // vec_elems, cute.arch.WARP_SIZE)
            m_lanes = cute.arch.WARP_SIZE // n_lanes
            thr_layout = cute.make_ordered_layout((m_lanes, n_lanes), (1, 0))
            val_layout = cute.make_layout((1, vec_elems))
        assert m_lanes * n_lanes == cute.arch.WARP_SIZE
        vec_tiled_copy = cute.make_tiled_copy_tv(vec_copy_atom, thr_layout, val_layout)
        lane_id = cute.arch.lane_idx()

        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        sentinels_written = cutlass.Int32(0)
        while work_tile.is_valid_tile:
            cur = work_tile.tile_idx

            cta_tile = gC_cta_tiled[
                (None, None, cur[0], cur[1], cur[2])
            ]  # (CTA_M, CTA_N)
            cta_coord = gC_coord_tiled[
                (None, None, cur[0], cur[1], cur[2])
            ]  # (CTA_M, CTA_N)

            # Contiguous C dim is 16B-aligned, so a vector never straddles the tile
            # edge: one bounds check per vector suffices.
            thr = vec_tiled_copy.get_slice(lane_id)
            my_tile = thr.partition_D(cta_tile)  # ((VEC, 1), REST_M, REST_N)
            my_tile = cute.make_tensor(my_tile.iterator.align(16), my_tile.layout)
            my_sentinel = cute.make_fragment_like(my_tile)
            my_sentinel.fill(self.c_dtype(-0.0))
            # partition_D gives a coord per element; keep only the first element of each
            # vector (drop mode-0 sub-0) so there is one bounds check per vector.
            my_coord = thr.partition_D(cta_coord)[
                ((0, None), None, None)
            ]  # (1, REST_M, REST_N)
            my_pred = cute.make_rmem_tensor(my_coord.shape, cutlass.Boolean)
            for i in range(cute.size(my_pred)):
                my_pred[i] = cute.elem_less(my_coord[i], c_gmem.shape)
            cute.copy(vec_tiled_copy, my_sentinel, my_tile, pred=my_pred)
            # All lanes done storing before the counter release below.
            cute.arch.sync_warp()

            sentinels_written += 1
            with cute.arch.elect_one():
                cute.arch.store(
                    sentinel_count_ptr,
                    sentinels_written,
                    ss="cta",
                    sem="release",
                    scope="cta",
                )

            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()

        cute.arch.fence_acq_rel_gpu()  # publish all sentinel stores to L2 (device scope)
        if cutlass.const_expr(pdl_early_launch_next):
            with cute.arch.elect_one():
                cute.arch.griddepcontrol_launch_dependents()


@lru_cache(maxsize=1)
def compile_bmm(
    mnkl: Tuple[int, int, int, int],
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    max_active_clusters: cutlass.Constexpr = None,
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    pdl_early_launch_next: cutlass.Constexpr = None,
    pdl_early_start: cutlass.Constexpr = None,
    check_b_valid: cutlass.Constexpr = None,
    eager_launch_next: cutlass.Constexpr = True,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    producer_sentinel_init: bool = False,
    positive_zero_only: bool = False,
):
    from cutlass.cute.runtime import make_fake_stream

    if pdl_early_launch_next is None:
        raise ValueError("pdl_early_launch_next must be explicitly specified")
    if pdl_early_start is None:
        raise ValueError("pdl_early_start must be explicitly specified")
    if check_b_valid is None:
        raise ValueError("check_b_valid must be explicitly specified")

    gemm = SM107TmaReportValidGemmKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        cluster_shape_mn,
        use_tma_store,
        swizzle_size,
        raster_along,
        pdl_early_launch_next,
        pdl_early_start,
        check_b_valid,
        eager_launch_next,
        producer_sentinel_init,
        positive_zero_only,
    )

    # Check if configuration can be implemented
    can_implement = gemm.can_implement(
        mnkl, a.element_type, b.element_type, c.element_type, a_major, b_major, c_major
    )
    if not can_implement:
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, cluster_shape_mn = {cluster_shape_mn}, "
            f"use_tma_store = {use_tma_store}, "
            f"swizzle_size = {swizzle_size}, "
            f"raster_along = {raster_along}"
        )

    stream = make_fake_stream()
    func = cute.compile(
        bmm,
        gemm,
        a,
        b,
        c,
        max_active_clusters,
        stream,
        pdl_early_launch_next,
        pdl_early_start,
        check_b_valid,
        eager_launch_next,
        epilogue_op,
        options="--generate-line-info",
    )
    return func
