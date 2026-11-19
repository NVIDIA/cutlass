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
from typing import Tuple, Type, Union, Literal
from functools import lru_cache
from enum import Enum, auto

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute import experimental as cute_ext
from cutlass import testing
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.cute.nvgpu import cpasync, tcgen05


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.normpath(os.path.join(current_dir, "../../cute")))
    sys.path.insert(0, os.path.join(current_dir, "../.."))

from helpers import cli_helper as cli
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)
from blackwell.kernel.dense_gemm.dense_gemm_persistent import (
    PersistentDenseGemmKernel as BlackwellPersistentDenseGemmKernel,
    _compute_stages,
)


class KernelRole(Enum):
    PRODUCER = auto()
    CONSUMER = auto()
    DATA_DRIVEN_PRODUCER = auto()
    DATA_DRIVEN_CONSUMER = auto()


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    max_active_clusters: cutlass.Constexpr,
    stream: cuda.CUstream,
    kernel_role: cutlass.Constexpr,
    use_pdl: cutlass.Constexpr,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Wrapper API for the report_valid (data-driven sync) persistent GEMM kernel.

    Permutes tensors from PyTorch's (l,m,k) convention to CuTe's (m,k,l),
    then calls the kernel with kernel_role and use_pdl params.
    """
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
        kernel_role,
        use_pdl,
        epilogue_op,
    )


class PersistentDenseGemmKernel(BlackwellPersistentDenseGemmKernel):
    """Persistent dense GEMM kernel for Rubin supporting data-driven synchronization
    between producer and consumer using Rubin's TMA report_valid feature.

    Inherits from BlackwellPersistentDenseGemmKernel for broad dtype support
    (Float16, BFloat16, etc.) using SM100 MMA instructions (backward compatible
    on SM107). Overrides arch to use Rubin's larger SMEM and TMEM resources.

    Adds a retry warp to re-issue TMA loads when data is not yet valid.

    :param kernel_role: Role of this kernel in producer-consumer chain
    :type kernel_role: KernelRole
    :param check_b_valid: If True, retry warp checks/retries B buffer instead of A
    :type check_b_valid: bool
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
        kernel_role: KernelRole = KernelRole.PRODUCER,
        check_b_valid: bool = False,
        arch: str = "sm_107",
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
        # Use Rubin's larger SMEM and TMEM resources.
        self.arch = utils.sm107.canonicalize_rubin_resource_arch(arch)
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

        self.retry_warp_id = 6
        self.kernel_role = kernel_role
        self.check_b_valid = check_b_valid
        if cutlass.const_expr(kernel_role is KernelRole.DATA_DRIVEN_CONSUMER):
            self.threads_per_cta += 32

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

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

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
        kernel_role: KernelRole,
        use_pdl: cutlass.Constexpr,
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
        self.kernel.set_name_prefix(kernel_role.name.lower())
        self.kernel(
            tiled_mma,
            a,
            b,
            c,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            kernel_role,
            use_pdl,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            use_pdl=use_pdl,
        )
        return

    # Copied from Blackwell dense_gemm_persistent, with a retry warp added and small pipeline modifications to support
    # Rubin's TMA valid check feature.
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        a_gmem_mkl: cute.Tensor,
        b_gmem_nkl: cute.Tensor,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        kernel_role: cutlass.Constexpr,
        use_pdl: cutlass.Constexpr,
        epilogue_op: cutlass.Constexpr,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation
        with data-driven (report_valid) synchronization support.
        """

        # producer should immediately unblock the consumer
        if cutlass.const_expr(kernel_role is KernelRole.DATA_DRIVEN_PRODUCER):
            cute.arch.griddepcontrol_launch_dependents()

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

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
        tidx, _, _ = cute.arch.thread_idx()

        need_peer_retry = cutlass.const_expr(
            kernel_role is KernelRole.DATA_DRIVEN_CONSUMER and self.use_2cta_instrs
        )

        @cute.struct
        class RetryCoord:
            stage: cutlass.Int32
            k_tile: cutlass.Int32
            m: cutlass.Int32
            n: cutlass.Int32
            l: cutlass.Int32

        retry_coord_codec = cute_ext.B32PayloadCodec.from_struct(RetryCoord)
        peer_retry_coord_buf_type = cute.struct.Align[
            cute.struct.MemRange[cutlass.Int32, retry_coord_codec.storage_words], 16
        ]

        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            retry_cluster_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_ab_stage
            ]
            tmem_dealloc_mbar: cutlass.Int64
            peer_retry_coord_buf: peer_retry_coord_buf_type
            tmem_holding_buf: cutlass.Int32

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # Compute peer CTA rank for dsmem addressing (2-CTA: flip V-dim bit)
        peer_cta_rank = None
        if cutlass.const_expr(need_peer_retry):
            peer_cta_rank = cta_rank_in_cluster ^ 1

        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        if cutlass.const_expr(use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # Initialize mainloop AB pipeline through LIR. This example intentionally
        # keeps the report_valid TMA -> MMA synchronization path on cute_ext APIs.
        ab_arrival_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast):
            block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
                cta_rank_in_cluster
            )
            peer_v = (
                (block_in_cluster_coord_vmnk[0] ^ 1)
                if cutlass.const_expr(use_2cta_instrs)
                else block_in_cluster_coord_vmnk[0]
            )
            peer_block_in_cluster_coord_vmnk = (
                peer_v,
                *block_in_cluster_coord_vmnk[1:],
            )
            arrival_mask_a = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            arrival_mask_b = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            arrival_mask_a_peer = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, peer_block_in_cluster_coord_vmnk, mcast_mode=2
            )
            arrival_mask_b_peer = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, peer_block_in_cluster_coord_vmnk, mcast_mode=1
            )
            ab_arrival_mask = (
                arrival_mask_a
                | arrival_mask_a_peer
                | arrival_mask_b
                | arrival_mask_b_peer
            )
        elif cutlass.const_expr(use_2cta_instrs):
            block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
                cta_rank_in_cluster
            )
            ab_arrival_mask = cute.make_layout_image_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mode=0
            )

        raw_ab_pipeline, ab_producer_state, ab_consumer_state = (
            cute_ext.create_pipeline(
                self.num_ab_stage,
                tma_operation_type,
                mma_operation_type,
                producer_arv_count=1,
                consumer_arv_count=2 * num_tma_producer,
                arrival_mask=ab_arrival_mask,
                producer_report_valid=True,
            )
        )
        ab_pipeline = cute_ext.GenericPipeline(
            raw_ab_pipeline,
            self.num_ab_stage,
            ab_producer_state,
            ab_consumer_state,
        )

        # The leader CTA sends retry coordinates to the peer CTA through a
        # one-slot DSMEM mailbox. The ST_ASYNC_S producer edge models the
        # remote st.async.shared::cluster writes, and the LD_SHARED consumer edge
        # models the peer CTA reading the payload from its local shared memory.
        coord_pipeline = None
        if cutlass.const_expr(need_peer_retry):
            coord_pipeline = cute_ext.GenericPipeline.create(
                num_stages=1,
                producer=cute_ext.OperationTypeEnum.ST_ASYNC_S,
                consumer=cute_ext.OperationTypeEnum.LD_SHARED,
                producer_arv_count=1,
                consumer_arv_count=32,
                locale=cute_ext.cluster_mailbox.CTA_PAIR_PEER_LOCALE,
            )

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
            arch=self.arch,
        )

        # Initialize retry sync barriers for multicast TMA re-issue coordination
        retry_cluster_mbar = None
        retry_dst_rank = None
        retry_is_signalling = None
        need_retry_sync = cutlass.const_expr(
            kernel_role is KernelRole.DATA_DRIVEN_CONSUMER
            and (
                (self.check_b_valid and self.is_b_mcast)
                or (not self.check_b_valid and self.is_a_mcast)
            )
        )
        if cutlass.const_expr(need_retry_sync):
            num_mcast = (
                self.num_mcast_ctas_b if self.check_b_valid else self.num_mcast_ctas_a
            )
            retry_sync_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_mcast - 1
            )
            retry_cluster_mbar = pipeline.MbarrierArray(
                barrier_storage=storage.retry_cluster_mbar_ptr.data_ptr(),
                num_stages=self.num_ab_stage,
                agent=(pipeline.PipelineOp.AsyncThread, retry_sync_group),
            )
            # Compute DSMEM routing: which remote CTAs to signal (exclude self)
            cta_layout_for_retry = (
                cute.make_layout(cluster_layout_vmnk.shape)
                if cluster_layout_vmnk is not None
                else cute.make_layout((1, 1, 1, 1))
            )
            # Only sync with CTAs in the checked operand's multicast group
            # Checking A → A multicast across N-dim → mcast_mode (1, 0)
            # Checking B → B multicast across M-dim → mcast_mode (0, 1)
            retry_mcast_mode = (0, 1) if self.check_b_valid else (1, 0)
            retry_dst_rank, retry_is_signalling = (
                pipeline.PipelineTmaAsync.init_empty_barrier_arrive_signal(
                    cta_layout_for_retry, tidx, retry_mcast_mode
                )
            )
            retry_is_signalling = retry_is_signalling & (
                retry_dst_rank != cta_rank_in_cluster
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
        #
        # Local_tile partition global tensor C
        #
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )

        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        a_lir_tiler_mk = (self.mma_tiler[0], self.mma_tiler[2])
        b_lir_tiler_nk = (self.mma_tiler[1], self.mma_tiler[2])
        gA_lir = cute.zipped_divide(a_gmem_mkl, a_lir_tiler_mk)
        gB_lir = cute.zipped_divide(b_gmem_nkl, b_lir_tiler_nk)
        k_tile_cnt = cute.size(gA_lir, mode=[1, 1])

        #
        # Get the per-CTA TiledMMA slice
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)

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

        # wait for producer grid-ending MEMBAR
        if cutlass.const_expr(use_pdl and kernel_role is KernelRole.CONSUMER):
            cute.arch.griddepcontrol_wait()

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
                gA_lir_slice = gA_lir[
                    (None, None),
                    (mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2]),
                ]
                gB_lir_slice = gB_lir[
                    (None, None),
                    (mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2]),
                ]
                # Peek (try_wait) AB buffer empty for k_tile = 0
                peek_ab_empty_status = ab_pipeline.producer_try_acquire()

                #
                # Tma load loop
                #
                for tma_k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    stage_token, stage_idx = ab_pipeline.producer_acquire_and_get_stage(
                        token=peek_ab_empty_status
                    )
                    tma_bar_ptr = cute_ext.get_mbarrier(stage_token).result
                    tAgA_lir_slice = thr_mma.partition_A(
                        gA_lir_slice[(None, None, tma_k_tile)]
                    )
                    tBgB_lir_slice = thr_mma.partition_B(
                        gB_lir_slice[(None, None, tma_k_tile)]
                    )
                    # report_valid=True enables TMA to check data for sentinel (reported in mbarrier)
                    if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast):
                        cute_ext.tma_load(
                            tAgA_lir_slice,
                            sA[(None, None, None, stage_idx)],
                            tma_bar_ptr.value,
                            vmnk_layout=cluster_layout_vmnk,
                            tma_operation_type=tma_operation_type,
                            multicast_mode=2,
                            report_valid=not self.check_b_valid,
                        )
                        cute_ext.tma_load(
                            tBgB_lir_slice,
                            sB[(None, None, None, stage_idx)],
                            tma_bar_ptr.value,
                            vmnk_layout=cluster_layout_vmnk,
                            tma_operation_type=tma_operation_type,
                            multicast_mode=1,
                            report_valid=self.check_b_valid,
                        )
                    else:
                        cute_ext.tma_load(
                            tAgA_lir_slice,
                            sA[(None, None, None, stage_idx)],
                            tma_bar_ptr.value,
                            tma_operation_type=tma_operation_type,
                            internal_type=cutlass.TFloat32
                            if self.a_dtype is cutlass.Float32
                            else None,
                            report_valid=not self.check_b_valid,
                        )
                        cute_ext.tma_load(
                            tBgB_lir_slice,
                            sB[(None, None, None, stage_idx)],
                            tma_bar_ptr.value,
                            tma_operation_type=tma_operation_type,
                            internal_type=cutlass.TFloat32
                            if self.b_dtype is cutlass.Float32
                            else None,
                            report_valid=self.check_b_valid,
                        )
                    ab_pipeline.producer_commit(elect_one_sync=True)
                    ab_pipeline.producer_state = cute_ext.pipeline_advance_iterator(
                        ab_pipeline.raw_pipeline, ab_pipeline.producer_state
                    )

                    # Peek (try_wait) AB buffer empty for next k_tile
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if tma_k_tile + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_pipeline.producer_try_acquire()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            ab_pipeline.producer_tail()

        #
        # Specialized Retry warp
        #
        if cutlass.const_expr(kernel_role is KernelRole.DATA_DRIVEN_CONSUMER):
            # Only executed by leader CTA because a 2-CTA TMA load only signals leader CTA's full barrier
            if warp_idx == self.retry_warp_id and is_leader_cta:
                state = pipeline.PerStagePipelineState(self.num_ab_stage)

                #
                # Each stage has an mbarrier (retry_cluster_mbar) for multicast re-tries, which the CTAs in a multicast use to
                # synchronize before re-issuing the TMA. Without it, one CTA in the multicast can re-issue a TMA
                # while the previous TMA in a different CTA is completing.
                #
                # retry_sync_states here is tracking:
                #    retry_sync_states[i, 0] = the phase of that barrier
                #    retry_sync_states[i, 1] = whether or not the CTA already arrived,
                #        so we don't arrive multiple times (needed since different CTAs may
                #        process loop iterations in a different order).
                retry_sync_states = None
                if cutlass.const_expr(need_retry_sync):
                    retry_sync_states = cute.make_rmem_tensor(
                        (self.num_ab_stage, 2), cutlass.Int32
                    )
                    retry_sync_states.fill(0)

                tile_sched = StaticPersistentTileScheduler.create(
                    tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()

                # a new work tile may start in middle stage buffer, so we need to track the start stage offset
                stage_offset = cutlass.Int32(0)
                while work_tile.is_valid_tile:
                    processed_k_tiles = cutlass.Int32(0)
                    state.reset_count()

                    # Compute the tile coordinate used to select the LIR retry slice.
                    cur_tile_coord = work_tile.tile_idx
                    mma_tile_coord_mnl = (
                        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                        cur_tile_coord[1],
                        cur_tile_coord[2],
                    )
                    peer_a_lir_coord_m = cur_tile_coord[0] ^ 1
                    peer_b_lir_coord_n = cute.size(
                        tiled_mma.thr_id.shape
                    ) * cur_tile_coord[1] + (mma_tile_coord_v ^ 1)

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
                                state_lir = cute_ext.create_pipeline_state_at(
                                    ab_pipeline.raw_pipeline,
                                    self.num_ab_stage,
                                    stage_idx,
                                    state.phase,
                                )
                                tma_done, data_valid = ab_pipeline.consumer_test_valid(
                                    state_lir
                                )

                                if tma_done and data_valid:
                                    cute_ext.consumer_release(
                                        ab_pipeline.raw_pipeline,
                                        state_lir,
                                        elect_one_sync=True,
                                    )
                                    state.mark_valid()  # update stage buffer state for next k_tile
                                    processed_k_tiles += 1
                                elif tma_done:
                                    # TMA finished but data is not yet valid - need to retry

                                    # Check if peer multicast CTAs are also ready to re-issue
                                    do_reissue = cutlass.Boolean(True)
                                    if cutlass.const_expr(
                                        need_retry_sync
                                    ):  # ignore if not using TMA multicast
                                        # Arrive on peer's retry sync barrier (once per round)
                                        if not retry_sync_states[stage_idx, 1]:
                                            if retry_is_signalling:
                                                cute.arch.mbarrier_arrive(
                                                    retry_cluster_mbar.get_barrier(
                                                        stage_idx
                                                    ),
                                                    retry_dst_rank,
                                                    num_mcast - 1,
                                                )
                                            retry_sync_states[stage_idx, 1] = 1

                                        do_reissue = retry_cluster_mbar.test_wait(
                                            stage_idx,
                                            retry_sync_states[stage_idx, 0],
                                        )

                                    if do_reissue:
                                        # Peer arrived — reset sync flags
                                        if cutlass.const_expr(need_retry_sync):
                                            retry_sync_states[stage_idx, 0] = (
                                                retry_sync_states[stage_idx, 0] ^ 1
                                            )
                                            retry_sync_states[stage_idx, 1] = 0

                                        # Re-arm and re-issue TMA for the checked operand
                                        if cutlass.const_expr(self.check_b_valid):
                                            retry_gX_slice = gB_lir[
                                                (None, None),
                                                (
                                                    mma_tile_coord_mnl[1],
                                                    None,
                                                    mma_tile_coord_mnl[2],
                                                ),
                                            ]
                                            retry_gX_slice = thr_mma.partition_B(
                                                retry_gX_slice[
                                                    (None, None, k_tile_for_stage)
                                                ]
                                            )
                                            retry_smem_slice = sB[
                                                (None, None, None, stage_idx)
                                            ]
                                            retry_multicast_mode = 1
                                            retry_internal_type = (
                                                cutlass.TFloat32
                                                if self.b_dtype is cutlass.Float32
                                                else None
                                            )
                                        else:
                                            retry_gX_slice = gA_lir[
                                                (None, None),
                                                (
                                                    mma_tile_coord_mnl[0],
                                                    None,
                                                    mma_tile_coord_mnl[2],
                                                ),
                                            ]
                                            retry_gX_slice = thr_mma.partition_A(
                                                retry_gX_slice[
                                                    (None, None, k_tile_for_stage)
                                                ]
                                            )
                                            retry_smem_slice = sA[
                                                (None, None, None, stage_idx)
                                            ]
                                            retry_multicast_mode = 2
                                            retry_internal_type = (
                                                cutlass.TFloat32
                                                if self.a_dtype is cutlass.Float32
                                                else None
                                            )

                                        # Signal peer CTA to re-issue its half of the collaborative cute.copy
                                        if cutlass.const_expr(need_peer_retry):
                                            coord_stage_token, _ = (
                                                coord_pipeline.producer_acquire_and_get_stage()
                                            )
                                            # Keep this helper local to the
                                            # role-specific control-flow region.
                                            # Constructing it is trace-time
                                            # Python work and emits no IR; only
                                            # send_to_pipeline_stage()
                                            # materializes the mailbox protocol.
                                            coord_mailbox = cute_ext.cluster_mailbox.ClusterMailbox(
                                                payload=retry_coord_codec,
                                                storage=storage.peer_retry_coord_buf,
                                            )
                                            coord_mailbox.send_to_pipeline_stage(
                                                coord_stage_token,
                                                peer_rank=peer_cta_rank,
                                                stage=stage_idx,
                                                k_tile=k_tile_for_stage,
                                                m=peer_a_lir_coord_m,
                                                n=peer_b_lir_coord_n,
                                                l=mma_tile_coord_mnl[2],
                                            )
                                            coord_pipeline.producer_commit_and_advance(
                                                elect_one_sync=True
                                            )

                                        state_lir = cute_ext.create_pipeline_state_at(
                                            ab_pipeline.raw_pipeline,
                                            self.num_ab_stage,
                                            stage_idx,
                                            state.phase,
                                        )
                                        stage_token, _ = (
                                            cute_ext.get_pipeline_produce_stage(
                                                ab_pipeline.raw_pipeline, state_lir
                                            )
                                        )
                                        retry_tma_bar_ptr = cute_ext.get_mbarrier(
                                            stage_token
                                        ).result

                                        state.mark_invalid()  # update stage buffer state for re-issuing TMA
                                        if cutlass.const_expr(
                                            self.is_a_mcast or self.is_b_mcast
                                        ):
                                            cute_ext.tma_load(
                                                retry_gX_slice,
                                                retry_smem_slice,
                                                retry_tma_bar_ptr.value,
                                                vmnk_layout=cluster_layout_vmnk,
                                                tma_operation_type=tma_operation_type,
                                                multicast_mode=retry_multicast_mode,
                                                report_valid=True,
                                            )
                                        else:
                                            cute_ext.tma_load(
                                                retry_gX_slice,
                                                retry_smem_slice,
                                                retry_tma_bar_ptr.value,
                                                tma_operation_type=tma_operation_type,
                                                internal_type=retry_internal_type,
                                                report_valid=True,
                                            )
                                        cute_ext.producer_commit(
                                            ab_pipeline.raw_pipeline,
                                            state_lir,
                                            elect_one_sync=True,
                                        )

                            state.next()  # advance to next stage buffer

                    # Update stage_offset for next tile (TMA continues round-robin)
                    stage_offset = (stage_offset + k_tile_cnt) % self.num_ab_stage
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

                # Signal peer CTA to exit by writing -1 to stage_idx in dsmem
                if cutlass.const_expr(need_peer_retry):
                    coord_stage_token, _ = (
                        coord_pipeline.producer_acquire_and_get_stage()
                    )
                    # Keep the helper local to the sender region; constructing
                    # it emits no IR. See the re-issue mailbox send above.
                    coord_mailbox = cute_ext.cluster_mailbox.ClusterMailbox(
                        payload=retry_coord_codec,
                        storage=storage.peer_retry_coord_buf,
                    )
                    # Send a full payload even though only stage=-1 is observed:
                    # the peer decodes the whole mailbox before checking the
                    # sentinel, and this keeps the mailbox protocol uniform.
                    coord_mailbox.send_to_pipeline_stage(
                        coord_stage_token,
                        peer_rank=peer_cta_rank,
                        stage=cutlass.Int32(-1),
                        k_tile=cutlass.Int32(0),
                        m=cutlass.Int32(0),
                        n=cutlass.Int32(0),
                        l=cutlass.Int32(0),
                    )
                    coord_pipeline.producer_commit_and_advance(elect_one_sync=True)
                    coord_pipeline.producer_tail()

            if cutlass.const_expr(need_peer_retry):
                # Peer CTA simply waits for the leader to send re-issue coordinates through dsmem, and re-issues the copy
                if warp_idx == self.retry_warp_id and not is_leader_cta:
                    retry_stage_idx = 0
                    # -1 indicates that all tiles are done and peer CTA should exit
                    while retry_stage_idx != -1:
                        coord_pipeline.consumer_wait_and_get_stage()
                        # Keep the helper local to the receiver region;
                        # constructing it emits no IR. See the re-issue
                        # mailbox receive above.
                        coord_mailbox = cute_ext.cluster_mailbox.ClusterMailbox(
                            payload=retry_coord_codec,
                            storage=storage.peer_retry_coord_buf,
                        )
                        coord = coord_mailbox.recv()
                        retry_stage_idx = coord.stage
                        retry_k_tile = coord.k_tile
                        retry_coord_m = coord.m
                        retry_coord_n = coord.n
                        retry_coord_l = coord.l
                        retry_mma_m = retry_coord_m // num_mma_ctas
                        retry_mma_n = retry_coord_n // num_mma_ctas

                        coord_pipeline.consumer_release_and_advance()

                        if retry_stage_idx != -1:
                            peer_state_lir = cute_ext.create_pipeline_state_at(
                                ab_pipeline.raw_pipeline,
                                self.num_ab_stage,
                                retry_stage_idx,
                                0,
                            )
                            peer_stage_token, _ = cute_ext.get_pipeline_produce_stage(
                                ab_pipeline.raw_pipeline, peer_state_lir
                            )
                            peer_tma_bar_ptr = cute_ext.get_mbarrier(
                                peer_stage_token
                            ).result

                            if cutlass.const_expr(self.check_b_valid):
                                retry_gX_slice = gB_lir[
                                    (None, None), (retry_mma_n, None, retry_coord_l)
                                ]
                                retry_gX_slice = thr_mma.partition_B(
                                    retry_gX_slice[(None, None, retry_k_tile)]
                                )
                                if cutlass.const_expr(
                                    self.is_a_mcast or self.is_b_mcast
                                ):
                                    cute_ext.tma_load(
                                        retry_gX_slice,
                                        sB[(None, None, None, retry_stage_idx)],
                                        peer_tma_bar_ptr.value,
                                        vmnk_layout=cluster_layout_vmnk,
                                        tma_operation_type=tma_operation_type,
                                        multicast_mode=1,
                                        report_valid=True,
                                    )
                                else:
                                    cute_ext.tma_load(
                                        retry_gX_slice,
                                        sB[(None, None, None, retry_stage_idx)],
                                        peer_tma_bar_ptr.value,
                                        tma_operation_type=tma_operation_type,
                                        internal_type=cutlass.TFloat32
                                        if self.b_dtype is cutlass.Float32
                                        else None,
                                        report_valid=True,
                                    )
                            else:
                                retry_gX_slice = gA_lir[
                                    (None, None), (retry_mma_m, None, retry_coord_l)
                                ]
                                retry_gX_slice = thr_mma.partition_A(
                                    retry_gX_slice[(None, None, retry_k_tile)]
                                )
                                if cutlass.const_expr(
                                    self.is_a_mcast or self.is_b_mcast
                                ):
                                    cute_ext.tma_load(
                                        retry_gX_slice,
                                        sA[(None, None, None, retry_stage_idx)],
                                        peer_tma_bar_ptr.value,
                                        vmnk_layout=cluster_layout_vmnk,
                                        tma_operation_type=tma_operation_type,
                                        multicast_mode=2,
                                        report_valid=True,
                                    )
                                else:
                                    cute_ext.tma_load(
                                        retry_gX_slice,
                                        sA[(None, None, None, retry_stage_idx)],
                                        peer_tma_bar_ptr.value,
                                        tma_operation_type=tma_operation_type,
                                        internal_type=cutlass.TFloat32
                                        if self.a_dtype is cutlass.Float32
                                        else None,
                                        report_valid=True,
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
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_pipeline.consumer_try_wait()

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Mma mainloop
                #
                for mma_k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        _, stage_idx = ab_pipeline.consumer_wait_and_get_stage(
                            token=peek_ab_full_status
                        )

                        # tCtAcc += tCrA * tCrB
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, mma_k_tile != 0)
                        tile_crd = (None, None, None, stage_idx)
                        cute.gemm(
                            tiled_mma,
                            tCtAcc,
                            tCrA[tile_crd],
                            tCrB[tile_crd],
                            tCtAcc,
                        )

                        ab_pipeline.consumer_release(elect_one_sync=True)
                        ab_pipeline.consumer_state = cute_ext.pipeline_advance_iterator(
                            ab_pipeline.raw_pipeline,
                            ab_pipeline.consumer_state,
                        )

                        # Peek (try_wait) AB buffer full for next k_tile
                        peek_ab_full_status = cutlass.Boolean(1)
                        if mma_k_tile + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_pipeline.consumer_try_wait()

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
            tCtAcc_lir = utils.gemm.sm100.transform_partitioned_tensor_layout(
                tCtAcc_base
            )

            #
            # Persistent tile scheduling loop for epilogue
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            if cutlass.const_expr(self.use_tma_store):
                c_pipeline = cute_ext.TMAStorePipeline(
                    stages=self.num_c_stage,
                    arv_count=32 * len(self.epilogue_warp_id),
                    barrier_id=self.epilog_sync_bar_id,
                    tma_warp_id=self.epilogue_warp_id[0],
                )
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

                if cutlass.const_expr(self.use_tma_store):
                    acc_pipeline.consumer_wait(acc_consumer_state)
                    tCtAcc = tCtAcc_lir[(None, None, acc_consumer_state.index)]
                    c_pipeline = cute_ext.epilogue_tma_store(
                        self.cta_tile_shape_mnk,
                        use_2cta_instrs,
                        tCtAcc,
                        mC_mnl,
                        cur_tile_coord,
                        c_pipeline,
                        self.epilogue_warp_id[0],
                        epilogue_op,
                        d_major_mode=self.c_layout,
                        tid_x_in_group=tidx,
                    )
                    with cute.arch.elect_one():
                        acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()
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
                    )

            if cutlass.const_expr(self.use_tma_store):
                # Stage reuse across CTA tiles is protected by acquire_sync(),
                # so the pipeline is drained once here instead of per CTA
                # tile. Drain before griddepcontrol_launch_dependents below so
                # dependent-grid visibility is unchanged.
                c_pipeline.tail()

            if cutlass.const_expr(not self.use_tma_store):
                # Synchronize before TMEM dealloc (done by the caller)
                tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            if cutlass.const_expr(use_pdl and kernel_role is KernelRole.PRODUCER):
                cute.arch.griddepcontrol_launch_dependents()
            tmem.free(tmem_ptr)


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
    kernel_role: cutlass.Constexpr = None,
    use_pdl: cutlass.Constexpr = None,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    check_b_valid: bool = False,
    arch: str = "sm_107",
):
    from cutlass.cute.runtime import make_fake_stream

    if kernel_role is None:
        raise ValueError("kernel_role must be explicitly specified")
    if use_pdl is None:
        raise ValueError("use_pdl must be explicitly specified")

    gemm = PersistentDenseGemmKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        cluster_shape_mn,
        use_tma_store,
        swizzle_size,
        raster_along,
        kernel_role,
        check_b_valid,
        arch,
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
        kernel_role,
        use_pdl,
        epilogue_op,
        # Avoid a local libNVVM crash on sm_107a with V1 mbarriers and
        # generated LLVM debug metadata.
        options="",
    )

    return func


def run_standalone_lir_consumer(
    mnk: Tuple[int, int, int] = (512, 256, 128),
    n2: int = 128,
    mma_tiler_mn: Tuple[int, int] = (128, 128),
    cluster_shape_mn: Tuple[int, int] = (2, 2),
    use_2cta_instrs: bool = True,
    transpose: bool = True,
    tolerance: float = 1e-1,
    arch: str = "sm_107",
) -> float:
    import torch
    import cutlass.torch as cutlass_torch
    from cutlass.cute.runtime import from_dlpack

    if len(mnk) != 3:
        raise ValueError("mnk must contain exactly 3 values")
    if len(mma_tiler_mn) != 2:
        raise ValueError("mma_tiler_mn must contain exactly 2 values")

    cuda.cuInit(0)

    m, n, k = mnk
    if transpose:
        m, n = n, m
    l = 1
    torch.manual_seed(1111)
    torch_dtype = cutlass_torch.dtype(cutlass.Float16)
    c_major = "m" if transpose else "n"

    # Match the CuteDSL report_valid producer-consumer test's standalone consumer
    # setup: z1 is already valid input, and the consumer computes z2.
    if transpose:
        z1 = (
            torch.empty(l, n, m, dtype=torch.int32, device="cuda")
            .random_(-1, 2)
            .to(torch_dtype)
        ).permute(0, 2, 1)
        w2 = (
            torch.empty(l, n2, m, dtype=torch.int32, device="cuda")
            .random_(-1, 2)
            .to(torch_dtype)
        )
        z2 = torch.zeros(l, n, n2, dtype=torch_dtype, device="cuda").permute(0, 2, 1)
        consumer_a = w2
        consumer_b = z1
        consumer_c = z2
        consumer_mnkl = (n2, n, m, l)
    else:
        z1 = (
            torch.empty(l, m, n, dtype=torch.int32, device="cuda")
            .random_(-1, 2)
            .to(torch_dtype)
        )
        w2 = (
            torch.empty(l, n2, n, dtype=torch.int32, device="cuda")
            .random_(-1, 2)
            .to(torch_dtype)
        ).permute(0, 2, 1)
        z2 = torch.zeros(l, m, n2, dtype=torch_dtype, device="cuda")
        consumer_a = z1
        consumer_b = w2
        consumer_c = z2
        consumer_mnkl = (m, n2, n, l)

    consumer_a_memref = from_dlpack(consumer_a).mark_layout_dynamic(leading_dim=2)
    consumer_b_memref = from_dlpack(consumer_b).mark_layout_dynamic(leading_dim=1)
    consumer_c_memref = from_dlpack(consumer_c).mark_layout_dynamic(
        leading_dim=1 if transpose else 2
    )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    print("[DSL INFO] Compiling standalone LIR report_valid consumer...")
    compiled = compile_bmm(
        consumer_mnkl,
        consumer_a_memref,
        consumer_b_memref,
        consumer_c_memref,
        cutlass.Float32,
        a_major="k",
        b_major="k",
        c_major=c_major,
        mma_tiler=tuple(mma_tiler_mn),
        cluster_shape_mn=tuple(cluster_shape_mn),
        max_active_clusters=max_active_clusters,
        use_2cta_instrs=use_2cta_instrs,
        use_tma_store=True,
        kernel_role=KernelRole.DATA_DRIVEN_CONSUMER,
        use_pdl=False,
        check_b_valid=transpose,
        arch=arch,
    )

    print("[DSL INFO] Launching standalone LIR report_valid consumer...")
    compiled(
        consumer_a_memref,
        consumer_b_memref,
        consumer_c_memref,
        torch.cuda.current_stream().cuda_stream,
    )
    torch.cuda.synchronize()

    if transpose:
        ref = (w2[0].float() @ z1[0].float()).to(torch_dtype)
    else:
        ref = torch.einsum("mn,np->mp", z1[0].float(), w2[0].float()).to(torch_dtype)
    max_diff = (z2[0] - ref).abs().max().item()
    print(f"[DSL INFO] max_diff: {max_diff}")
    torch.testing.assert_close(z2[0].cpu(), ref.cpu(), atol=tolerance, rtol=1e-5)
    return max_diff


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Standalone LIR report_valid consumer smoke test"
    )
    parser.add_argument(
        "--mnk", type=cli.comma_separated_ints_of(3), default=(512, 256, 128)
    )
    parser.add_argument("--n2", type=int, default=128)
    cli.add_mma_tiler_arg(parser, strict_length=True)
    cli.add_cluster_shape_arg(parser, default=(2, 2), strict_length=True)
    parser.add_argument("--use_2cta_instrs", action="store_true", default=True)
    parser.add_argument(
        "--no_2cta_instrs", dest="use_2cta_instrs", action="store_false"
    )
    parser.add_argument("--transpose", action="store_true", default=True)
    parser.add_argument("--no_transpose", dest="transpose", action="store_false")
    parser.add_argument("--tolerance", type=float, default=1e-1)
    parser.add_argument("--arch", type=str, default="sm_107")
    args = parser.parse_args()

    run_standalone_lir_consumer(
        mnk=tuple(args.mnk),
        n2=args.n2,
        mma_tiler_mn=tuple(args.mma_tiler_mn),
        cluster_shape_mn=tuple(args.cluster_shape_mn),
        use_2cta_instrs=args.use_2cta_instrs,
        transpose=args.transpose,
        tolerance=args.tolerance,
        arch=args.arch,
    )
    print("PASS")
