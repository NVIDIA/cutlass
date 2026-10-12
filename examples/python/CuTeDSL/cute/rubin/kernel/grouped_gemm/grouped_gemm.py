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

import os
import sys
import argparse
import functools
from typing import Tuple, Type, Union, List, Optional

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.nvgpu.tcgen05 import CollectorOp
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.torch as cutlass_torch

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.grouped_gemm.grouped_gemm import (
    GroupedGemmKernel as BlackwellGroupedGemmKernel,
    create_tensors_for_all_groups,
    create_tensor_and_stride,
)


class Sm107GroupedGemmKernel(BlackwellGroupedGemmKernel):
    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode = cutlass.tensor_utils.TensorMapUpdateMode.SMEM,
        use_cached_problem_shapes: bool = True,
    ):
        """Initializes the configuration for a Rubin grouped GEMM kernel.

        Besides configurations for dense persistent GEMM, there is an extra config specific to grouped GEMM:

        Tensormap Update Mode:
        - tensormap_update_mode: Specifies whether the tensormap is
            updated in global memory(GMEM) or shared memory(SMEM).
           The 2 modes are functionally equivalent and the difference are:
            - We buffer 3 tensormaps in SMEM for A, B, and C tensors (each TMA descriptor takes 128B) when TMA updates performed on SMEM.
            - Performance varies between modes depending on problem size; optimal choice differs across workloads.

        :param acc_dtype: Data type of the accumulator.
        :type acc_dtype: type[cutlass.Numeric]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param mma_tiler: MMA tiler (M, N, K).
        :type mma_tiler: tuple[int, int, int]
        :param mma_inst_shape: tuple (M, N, K) shape of the MMA instruction.
        :type mma_inst_shape: tuple[int, int, int]
        :param cluster_shape_mn: tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: tuple[int, int]
        :param tensormap_update_mode: Mode for updating the tensormap (GMEM or SMEM), defaults to SMEM.
        :type tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode, optional
        :param use_cached_problem_shapes: Enable double-buffered caching of problem
            shapes for better performance with many small groups, defaults to True.
        :type use_cached_problem_shapes: bool, optional

        F16 inputs support F16 output with F16/F32 accumulation, BF16 inputs
        support BF16 output with F32 accumulation, and Float32/TFloat32 inputs
        support Float32 output with TF32 MMA and F32 accumulation. These input
        families use K16/K16/K8 instructions and recommend K64/K64/K32 MMA
        tiles, respectively, without collector reuse. Rubin FP8 inputs use a
        K64 instruction and recommend a K128 tile, with or without collector
        reuse.
        """
        super().__init__(
            acc_dtype=acc_dtype,
            use_2cta_instrs=use_2cta_instrs,
            mma_tiler_mn=mma_inst_shape[0:2],
            cluster_shape_mn=cluster_shape_mn,
            tensormap_update_mode=tensormap_update_mode,
            use_cached_problem_shapes=use_cached_problem_shapes,
        )
        self.use_cached_problem_shapes = use_cached_problem_shapes
        self.arch = "sm_107"
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)
        self.mma_tiler = mma_tiler
        self.mma_inst_shape = mma_inst_shape
        self.request_breuse = mma_tiler[0] // mma_inst_shape[0] == 2
        self.enable_breuse = False

    def _get_mma_permutation_mnk(self):
        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape[0] // 2, 2, 2),
                stride=(1, self.mma_inst_shape[0], self.mma_inst_shape[0] // 2),
            )
            return (m_layout, self.mma_inst_shape[1], self.mma_inst_shape[2])

        else:
            return (1, 1, 1)

    def _create_tiled_mma(self):
        return utils.sm107.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_inst_shape,
            permutation_mnk=self._get_mma_permutation_mnk(),
        )

    def _create_tiled_mma_bkeep(self):
        return utils.sm107.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_inst_shape,
            permutation_mnk=self._get_mma_permutation_mnk(),
            b_collector_op=CollectorOp.FILL,
        )

    def _create_tiled_mma_breuse(self):
        return utils.sm107.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_inst_shape,
            permutation_mnk=self._get_mma_permutation_mnk(),
            b_collector_op=CollectorOp.LASTUSE,
        )

    def _setup_attributes(self):
        # Configure tiled mma
        tiled_mma = self._create_tiled_mma()

        # Compute mma/cluster/tile shapes
        self.mma_inst_tile_k = self.mma_tiler[2] // self.mma_inst_shape[2]

        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.cluster_tile_shape_mnk = tuple(
            x * y for x, y in zip(self.cta_tile_shape_mnk, (*self.cluster_shape_mn, 1))
        )

        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Compute epilogue subtile
        self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        _, self.num_ab_stage, self.num_epi_stage, _ = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.smem_capacity,
            self.occupancy,
        )

        # Each acc stage occupies cta_tile_n TMEM columns; Bkeep-Breuse doubles this
        # because it maintains two independent accumulators (keep + reuse) simultaneously.
        # For example, CTA_N = 160/192/224/256 + b-reuse would all have 1 acc stage in TMEM
        cols_per_acc_stage = self.cta_tile_shape_mnk[1] * (
            2 if self.enable_breuse else 1
        )
        self.num_acc_stage = min(2, self.num_tmem_alloc_cols // cols_per_acc_stage)
        if self.num_acc_stage == 0:
            raise ValueError(
                f"No accumulator stages fit in TMEM: arch={self.arch}, "
                f"tmem_capacity={self.num_tmem_alloc_cols}, cols_per_acc_stage={cols_per_acc_stage} "
                f"(cta_tile_n={self.cta_tile_shape_mnk[1]}, enable_breuse={self.enable_breuse})"
            )

        print(
            f"[DSL INFO] Stage counts: "
            f"ab={self.num_ab_stage}, epi={self.num_epi_stage}, acc={self.num_acc_stage} "
            f"(tmem_cols_per_stage={cols_per_acc_stage}, tmem_total={self.num_tmem_alloc_cols})"
        )

        # Compute A/B/C shared memory layout
        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )
        self.epi_smem_layout_staged = utils.sm100.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, self.num_epi_stage
        )

        mbar_smem_bytes = self._get_mbar_smem_bytes(
            num_acc_stage=self.num_acc_stage,
            num_ab_stage=self.num_ab_stage,
            num_epi_stage=self.num_epi_stage,
        )
        tensormap_smem_bytes = self._get_tensormap_smem_bytes(
            self.tensormap_update_mode
        )
        if (
            mbar_smem_bytes
            + tensormap_smem_bytes
            + Sm107GroupedGemmKernel.tensor_memory_management_bytes
            > self.reserved_smem_bytes
        ):
            raise ValueError(
                f"smem consumption for mbar and tensormap {mbar_smem_bytes + tensormap_smem_bytes} exceeds the "
                f"reserved smem bytes {self.reserved_smem_bytes}"
            )

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.c_dtype = initial_c.element_type
        self.enable_breuse = self.request_breuse and self.a_dtype in (
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        )

        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_c)

        tiled_mma = self._create_tiled_mma()
        # Create Bkeep-Breuse tiled_mma variants if enabled
        tiled_mma_bkeep = None
        tiled_mma_breuse = None
        if cutlass.const_expr(self.enable_breuse):
            tiled_mma_bkeep = self._create_tiled_mma_bkeep()
            tiled_mma_breuse = self._create_tiled_mma_breuse()

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

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
            initial_a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
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
            initial_b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        epi_smem_layout = cute.select(
            self.epi_smem_layout_staged,
            mode=list(range(cute.rank(self.epi_smem_layout_staged) - 1)),
        )
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            initial_c,
            epi_smem_layout,
            self.epi_tile,
        )

        self.tile_sched_params, grid = super()._compute_grid(
            total_num_clusters, self.cluster_shape_mn, max_active_clusters
        )

        self.buffer_align_bytes = 1024
        self.size_tensormap_in_i64 = (
            0
            if self.tensormap_update_mode
            == cutlass.tensor_utils.TensorMapUpdateMode.GMEM
            else Sm107GroupedGemmKernel.num_tensormaps
            * Sm107GroupedGemmKernel.bytes_per_tensormap
            // 8
        )

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.epi_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensormap_cute_tensor,
            tiled_mma_bkeep,
            tiled_mma_breuse,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
        )

    # GPU device kernel
    @cute.jit
    def kernel_impl(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        tensormaps: cute.Tensor,
        tiled_mma_bkeep: Optional[cute.TiledMma],
        tiled_mma_breuse: Optional[cute.TiledMma],
        cluster_shape_mn: Tuple[int, int],
        is_a_mcast: bool,
        is_b_mcast: bool,
    ):
        """
        GPU device kernel implementation performing the grouped GEMM computation.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coord inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: tensormap buffer, a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        tensormap_a_smem_ptr = None
        tensormap_b_smem_ptr = None
        tensormap_c_smem_ptr = None
        if cutlass.const_expr(
            self.tensormap_update_mode == cutlass.tensor_utils.TensorMapUpdateMode.SMEM
        ):
            tensormap_smem_ptr = storage.tensormap_buffer.data_ptr()
            tensormap_a_smem_ptr = tensormap_smem_ptr
            tensormap_b_smem_ptr = (
                tensormap_a_smem_ptr + Sm107GroupedGemmKernel.bytes_per_tensormap // 8
            )
            tensormap_c_smem_ptr = (
                tensormap_b_smem_ptr + Sm107GroupedGemmKernel.bytes_per_tensormap // 8
            )

        #  init barrier for loading A, B with TMA
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )
        # Accumulator barrier init
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilog_warp_id) * (
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
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=self.tmem_alloc_barrier,
            allocator_warp_id=self.epilog_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
            arch=self.arch,
        )
        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/C
        #
        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sC = storage.sC.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )

        #
        # Compute multicast mask for A/B buffer full and empty
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        ab_empty_mcast_mask = None
        if cutlass.const_expr(is_a_mcast or is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            ab_empty_mcast_mask = a_full_mcast_mask | b_full_mcast_mask
        if cutlass.const_expr(use_2cta_instrs):
            block_in_cluster_coord_vmnk_peer = (
                block_in_cluster_coord_vmnk[0] ^ 1,
                *block_in_cluster_coord_vmnk[1:],
            )
            a_full_mcast_mask_peer = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk_peer, mcast_mode=2
            )
            b_full_mcast_mask_peer = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk_peer, mcast_mode=1
            )
            ab_empty_mcast_mask = (
                a_full_mcast_mask_peer
                | b_full_mcast_mask_peer
                | cutlass.Int16(
                    0 if ab_empty_mcast_mask is None else ab_empty_mcast_mask
                )
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
        # Partition global/shared tensor for load A, B with TMA
        #
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
        pipeline_init_wait(cluster_shape_mn=cluster_shape_mn)

        #
        # Get tensormap buffer address
        #
        grid_dim = cute.arch.grid_dim()
        tensormap_workspace_idx = (
            bidz * grid_dim[1] * grid_dim[0] + bidy * grid_dim[0] + bidx
        )

        tensormap_manager = cutlass.tensor_utils.TensorMapManager(
            self.tensormap_update_mode, Sm107GroupedGemmKernel.bytes_per_tensormap
        )
        tensormap_a_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 0, None)].iterator
        )
        tensormap_b_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 1, None)].iterator
        )
        tensormap_c_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 2, None)].iterator
        )
        # Setup tensormap initialization pointer based on the mode
        if cutlass.const_expr(
            self.tensormap_update_mode == cutlass.tensor_utils.TensorMapUpdateMode.SMEM
        ):
            tensormap_a_init_ptr = tensormap_a_smem_ptr
            tensormap_b_init_ptr = tensormap_b_smem_ptr
            tensormap_c_init_ptr = tensormap_c_smem_ptr
        else:
            tensormap_a_init_ptr = tensormap_a_ptr
            tensormap_b_init_ptr = tensormap_b_ptr
            tensormap_c_init_ptr = tensormap_c_ptr

        #
        # Persistent tile scheduling loop
        #
        # When the problem shapes are on device, we launch one CTA per SM.
        # The if condition later prevents the warps from extra CTAs from doing any work.
        tile_sched = utils.StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            (bidx, bidy, bidz),
            grid_dim,
            self.cluster_tile_shape_mnk,
            utils.create_initial_search_state(),
            group_count,
            problem_sizes_mnkl,
            use_cached_problem_shapes=self.use_cached_problem_shapes,
        )
        # Prefetch the problem shapes into caches
        tile_sched.prefetch_problem_shapes()
        # Get the initial tile information
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #
        if warp_idx == self.tma_warp_id and initial_work_tile_info.is_valid_tile:
            # Initialize tensormaps for A, B
            if cutlass.const_expr(not self.delegate_tensormap_ab_init):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_init_ptr, self.tma_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_init_ptr, self.tma_warp_id
                )

            tensormap_init_done = cutlass.Boolean(False)
            # group index of last tile
            last_group_idx = cutlass.Int32(-1)

            work_tile = initial_work_tile_info
            ab_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result

                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                # Do not load any data if cur_k_tile_cnt is 0
                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    # skip tensormap update if we're working on the same group
                    if is_group_changed:
                        real_tensor_a = super().make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.a_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            strides_abc,
                            ptrs_abc,
                            tensor_index=0,  # 0 for tensor A
                        )
                        real_tensor_b = super().make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.b_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            strides_abc,
                            ptrs_abc,
                            1,  # 1 for tensor B
                        )
                        # wait tensormap initialization complete before update
                        if not tensormap_init_done:
                            if cutlass.const_expr(self.delegate_tensormap_ab_init):
                                self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_manager.fence_tensormap_initialization()
                            tensormap_init_done = True

                        tensormap_manager.update_tensormap(
                            (real_tensor_a, real_tensor_b),
                            (tma_atom_a, tma_atom_b),
                            (tensormap_a_ptr, tensormap_b_ptr),
                            self.tma_warp_id,
                            (tensormap_a_smem_ptr, tensormap_b_smem_ptr),
                        )

                    mma_tile_coord_mnl = (
                        grouped_gemm_cta_tile_info.cta_tile_idx_m
                        // cute.size(tiled_mma.thr_id.shape),
                        grouped_gemm_cta_tile_info.cta_tile_idx_n,
                        0,
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

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                    ab_producer_state.reset_count()
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if ab_producer_state.count < cur_k_tile_cnt:
                        peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                            ab_producer_state
                        )
                    # ensure the update to tensormap has completed before using it
                    if is_group_changed:
                        tensormap_manager.fence_tensormap_update(tensormap_a_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_b_ptr)
                        #
                        # Tma load loop
                        #
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        # Wait for AB buffer empty
                        ab_pipeline.producer_acquire(
                            ab_producer_state, peek_ab_empty_status
                        )

                        # Load A/B with TMA
                        cute.copy(
                            tma_atom_a,
                            tAgA_slice[(None, ab_producer_state.count)],
                            tAsA[(None, ab_producer_state.index)],
                            tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                ab_producer_state
                            ),
                            mcast_mask=a_full_mcast_mask,
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_a_ptr,
                                cutlass.AddressSpace.generic,
                            ),
                        )
                        cute.copy(
                            tma_atom_b,
                            tBgB_slice[(None, ab_producer_state.count)],
                            tBsB[(None, ab_producer_state.index)],
                            tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                ab_producer_state
                            ),
                            mcast_mask=b_full_mcast_mask,
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_b_ptr,
                                cutlass.AddressSpace.generic,
                            ),
                        )

                        # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
                        ab_producer_state.advance()
                        peek_ab_empty_status = cutlass.Boolean(1)
                        if ab_producer_state.count < cur_k_tile_cnt:
                            peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                                ab_producer_state
                            )
                else:
                    # If tensormap initialization is not done, wait for it to complete
                    if not tensormap_init_done:
                        if cutlass.const_expr(self.delegate_tensormap_ab_init):
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_manager.fence_tensormap_initialization()
                        tensormap_init_done = True
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            #
            # Wait A/B buffer empty
            #
            ab_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            # Bar sync for retrieve tmem ptr from shared mem
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
            work_tile = initial_work_tile_info
            ab_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            # tile count we have searched
            while work_tile.is_valid_tile:
                cur_group_idx = work_tile.group_search_result.group_idx
                problem_shape_k = work_tile.group_search_result.problem_shape_k

                # MMA warp is only interested in number of tiles along K dimension
                cur_k_tile_cnt = (
                    problem_shape_k + self.cluster_tile_shape_mnk[2] - 1
                ) // self.cluster_tile_shape_mnk[2]
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0

                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer_state.reset_count()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    if ab_consumer_state.count < cur_k_tile_cnt:
                        peek_ab_full_status = ab_pipeline.consumer_try_wait(
                            ab_consumer_state
                        )

                    #
                    # Wait for accumulator buffer empty
                    #
                    if not is_k_tile_cnt_zero:
                        acc_pipeline.producer_acquire(acc_producer_state)

                    #
                    # Mma mainloop
                    #
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        # Wait for AB buffer full
                        ab_pipeline.consumer_wait(
                            ab_consumer_state, peek_ab_full_status
                        )
                        # tCtAcc += tCrA *tCrB
                        tile_crd = (None, None, None, ab_consumer_state.index)
                        tCrA_stage = tCrA[tile_crd]
                        tCrB_stage = tCrB[tile_crd]

                        # Check if we should use Bkeep-Breuse pattern
                        if cutlass.const_expr(self.enable_breuse):
                            tCtAcc_keep = tCtAcc[(None, 0, 0)]
                            tCtAcc_reuse = tCtAcc[(None, 1, 0)]
                            for k_phase in range(self.mma_inst_tile_k):
                                tCrB_slice = tCrB_stage[(None, 0, k_phase)]
                                tCrA_keep = tCrA_stage[(None, 0, k_phase)]
                                tiled_mma_bkeep.set(
                                    tcgen05.Field.ACCUMULATE,
                                    k_tile != 0 or k_phase != 0,
                                )
                                cute.gemm(
                                    tiled_mma_bkeep,
                                    tCtAcc_keep,
                                    tCrA_keep,
                                    tCrB_slice,
                                    tCtAcc_keep,
                                )

                                tCrA_reuse = tCrA_stage[(None, 1, k_phase)]
                                tiled_mma_breuse.set(
                                    tcgen05.Field.ACCUMULATE,
                                    k_tile != 0 or k_phase != 0,
                                )
                                cute.gemm(
                                    tiled_mma_breuse,
                                    tCtAcc_reuse,
                                    tCrA_reuse,
                                    tCrB_slice,
                                    tCtAcc_reuse,
                                )
                        else:
                            # Regular kernel pattern
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                            cute.gemm(tiled_mma, tCtAcc, tCrA_stage, tCrB_stage, tCtAcc)

                        # Async arrive AB buffer full
                        ab_pipeline.consumer_release(ab_consumer_state)

                        # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                        ab_consumer_state.advance()
                        peek_ab_full_status = cutlass.Boolean(1)
                        if ab_consumer_state.count < cur_k_tile_cnt:
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                    #
                    # Async arrive accumulator buffer full
                    #
                    if not is_k_tile_cnt_zero:
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
        # Specialized epilogue warp
        #
        if warp_idx < self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            # initialize tensormap A, B for TMA warp
            if cutlass.const_expr(self.delegate_tensormap_ab_init):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_init_ptr, self.epilog_warp_id[0]
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_init_ptr, self.epilog_warp_id[0]
                )
                # signal tensormap initialization has finished
                self.tensormap_ab_init_barrier.arrive_and_wait()
            # initialize tensormap for C
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c, tensormap_c_init_ptr, self.epilog_warp_id[0]
            )
            # Alloc tensor memory buffer
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Bar sync for retrieve tensor memory ptr from shared memory
            #
            tmem.wait_for_alloc()
            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)

            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)
            # Layout transformation for tCtAcc
            # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, STAGE) -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), STAGE)
            tCtAcc_base = utils.gemm.sm100.transform_partitioned_tensor_layout(tCtAcc)

            # Layout transformation for tCgC
            # ((MMA_ATOM_M, MMA_ATOM_N), MMA_M, MMA_N, TILE_M, TILE_N, TILE_K) -> ((MMA_ATOM_M, MMA_M), (MMA_ATOM_N, MMA_N), TILE_M, TILE_N, TILE_K)
            tCgC_base = utils.gemm.sm100.transform_partitioned_tensor_layout(tCgC)

            #
            # Partition for epilogue
            #
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = utils.gemm.sm100.epilogue_tmem_copy_and_partition(
                self, tidx, tCtAcc_base, tCgC_base, epi_tile, self.use_2cta_instrs
            )

            tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
            tiled_copy_r2s, tRS_rC, tRS_sC = (
                utils.gemm.sm100.epilogue_smem_copy_and_partition(
                    self, tiled_copy_t2r, tTR_rC, tidx, sC
                )
            )

            tCgC_epi = cute.flat_divide(tCgC_base, epi_tile)
            # ((ATOM_V, REST_V), EPI_M, EPI_N)
            # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
            bSG_sC, bSG_gC_partitioned = cpasync.tma_partition(
                tma_atom_c,
                0,
                cute.make_layout(1),
                cute.group_modes(sC, 0, 2),
                cute.group_modes(tCgC_epi, 0, 2),
            )

            #
            # Persistent tile scheduling loop
            #

            work_tile = initial_work_tile_info

            # wait tensormap initialization complete before update
            tensormap_manager.fence_tensormap_initialization()
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            # Threads/warps participating in tma store pipeline
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilog_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_epi_stage,
                producer_group=c_producer_group,
            )
            # group index of last tile
            last_group_idx = cutlass.Int32(-1)
            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                is_group_changed = cur_group_idx != last_group_idx
                # We still need to store 0s when k_tile_cnt is 0
                if is_group_changed:
                    # construct tensor C based on real address, shape and stride information
                    real_tensor_c = self.make_tensor_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (
                            grouped_gemm_cta_tile_info.problem_shape_m,
                            grouped_gemm_cta_tile_info.problem_shape_n,
                            grouped_gemm_cta_tile_info.problem_shape_k,
                        ),
                        strides_abc,
                        ptrs_abc,
                        2,  # 2 for tensor C
                    )
                    tensormap_manager.update_tensormap(
                        ((real_tensor_c),),
                        ((tma_atom_c),),
                        ((tensormap_c_ptr),),
                        self.epilog_warp_id[0],
                        (tensormap_c_smem_ptr,),
                    )

                mma_tile_coord_mnl = (
                    grouped_gemm_cta_tile_info.cta_tile_idx_m
                    // cute.size(tiled_mma.thr_id.shape),
                    grouped_gemm_cta_tile_info.cta_tile_idx_n,
                    0,
                )

                #
                # Slice to per mma tile index
                #
                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gC = bSG_gC_partitioned[
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                #
                # Wait for accumulator buffer full
                #
                # Not waiting for accumulator buffer full when k_tile_cnt is 0
                if not is_k_tile_cnt_zero:
                    acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                # ensure the update to tensormap has completed before using it
                if is_group_changed:
                    if warp_idx == self.epilog_warp_id[0]:
                        tensormap_manager.fence_tensormap_update(tensormap_c_ptr)
                #
                # Store accumulator to global memory in subtiles
                #
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in range(subtile_cnt):
                    #
                    # Store C to shared memory
                    #
                    epi_buffer = (num_prev_subtiles + subtile_idx) % self.num_epi_stage
                    #
                    # Load accumulator from tensor memory buffer to register
                    #
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    if not is_k_tile_cnt_zero:
                        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                        #
                        # Convert to output type
                        #
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        tRS_rC.store(acc_vec.to(self.c_dtype))
                    else:
                        tRS_rC.fill(0)
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rC,
                        tRS_sC[(None, None, None, epi_buffer)],
                    )
                    # Fence and barrier to make sure shared memory store is visible to TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilog_sync_barrier.arrive_and_wait()
                    # TMA store C to global memory
                    if warp_idx == self.epilog_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, epi_buffer)],
                            bSG_gC[(None, subtile_idx)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_c_ptr,
                                cutlass.AddressSpace.generic,
                            ),
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    self.epilog_sync_barrier.arrive_and_wait()
                #
                # Async arrive accumulator buffer empty
                #
                if not is_k_tile_cnt_zero:
                    with cute.arch.elect_one():
                        acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            self.epilog_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)

            #
            # Async arrive accumulator buffer empty
            #
            c_pipeline.producer_tail()

    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        tensormaps: cute.Tensor,
        tiled_mma_bkeep: Optional[cute.TiledMma] = None,
        tiled_mma_breuse: Optional[cute.TiledMma] = None,
    ):
        """
        GPU device kernel performing the grouped GEMM computation.
        """
        self.kernel_impl(
            tiled_mma,
            tma_atom_a,
            mA_mkl,
            tma_atom_b,
            mB_nkl,
            tma_atom_c,
            mC_mnl,
            cluster_layout_vmnk,
            a_smem_layout_staged,
            b_smem_layout_staged,
            epi_smem_layout_staged,
            epi_tile,
            tile_sched_params,
            group_count,
            problem_sizes_mnkl,
            strides_abc,
            ptrs_abc,
            tensormaps,
            tiled_mma_bkeep,
            tiled_mma_breuse,
            self.cluster_shape_mn,
            self.is_a_mcast,
            self.is_b_mcast,
        )

    @staticmethod
    def is_valid_dtypes(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
    ):
        """Check if the dtypes are valid"""
        fp8_dtypes = {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        fp32_tf32_dtypes = {cutlass.Float32, cutlass.TFloat32}
        c_dtypes = {cutlass.Float16, cutlass.BFloat16, cutlass.Float32}
        is_fp8 = a_dtype in fp8_dtypes and b_dtype in fp8_dtypes
        is_f16 = a_dtype is cutlass.Float16 and b_dtype is cutlass.Float16
        is_bf16 = a_dtype is cutlass.BFloat16 and b_dtype is cutlass.BFloat16
        is_fp32_or_tf32 = a_dtype in fp32_tf32_dtypes and b_dtype is a_dtype
        is_valid = (
            (
                is_fp8
                and c_dtype in c_dtypes
                and acc_dtype in {cutlass.Float16, cutlass.Float32}
            )
            or (
                is_f16
                and c_dtype is cutlass.Float16
                and acc_dtype in {cutlass.Float16, cutlass.Float32}
            )
            or (
                is_bf16 and c_dtype is cutlass.BFloat16 and acc_dtype is cutlass.Float32
            )
            or (
                is_fp32_or_tf32
                and c_dtype is cutlass.Float32
                and acc_dtype is cutlass.Float32
            )
        )
        if not is_valid:
            raise testing.CantImplementError(
                f"Unsupported combination of data types: a_dtype={a_dtype}, b_dtype={b_dtype}, c_dtype={c_dtype}, acc_dtype={acc_dtype}"
            )

    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
    ):
        """Check if the mma tiler and cluster shape are valid"""
        if mma_inst_shape[0] != 256 if use_2cta_instrs else mma_inst_shape[0] != 128:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_m: {mma_inst_shape[0]}"
            )
        if mma_inst_shape[1] not in [128, 256]:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_n: {mma_inst_shape[1]}"
            )
        is_fp8 = a_dtype in {cutlass.Float8E4M3FN, cutlass.Float8E5M2} and b_dtype in {
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        is_fp32_or_tf32 = (
            a_dtype
            in {
                cutlass.Float32,
                cutlass.TFloat32,
            }
            and b_dtype is a_dtype
        )
        if is_fp8:
            expected_inst_k = 64
        elif is_fp32_or_tf32:
            expected_inst_k = 8
        else:
            expected_inst_k = 16
        if mma_inst_shape[2] != expected_inst_k:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_k: {mma_inst_shape[2]}"
            )
        if mma_tiler[0] != mma_inst_shape[0] and mma_tiler[0] != mma_inst_shape[0] * 2:
            raise testing.CantImplementError(f"Invalid mma_tiler_m: {mma_tiler[0]}")
        if not is_fp8 and mma_tiler[0] != mma_inst_shape[0]:
            raise testing.CantImplementError(
                "F16/BF16/TF32 MMA does not support collector reuse"
            )
        # A 128-byte MMA tiler K is recommended: 4x the 32-byte instruction K
        # for F16/BF16/FP32/TF32, and 2x Rubin's 64-byte instruction K for FP8.
        if mma_tiler[2] % mma_inst_shape[2] != 0:
            raise testing.CantImplementError(
                "mma_tiler_k must be divisible by mma_inst_shape_k: "
                f"{mma_tiler[2]}, {mma_inst_shape[2]}"
            )
        if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster_shape_m: {cluster_shape_mn[0]}"
            )

        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            or not is_power_of_2(cluster_shape_mn[0])
            or not is_power_of_2(cluster_shape_mn[1])
        ):
            raise testing.CantImplementError(
                f"Invalid cluster_shape: {cluster_shape_mn}"
            )

    @staticmethod
    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        l: int,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ):
        """Check if the tensor alignment is valid"""

        def check_contigous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if not check_contigous_16B_alignment(a_dtype, a_major == "m", (m, k, l)):
            raise testing.CantImplementError("Invalid tensor alignment: A")
        if not check_contigous_16B_alignment(b_dtype, b_major == "n", (n, k, l)):
            raise testing.CantImplementError("Invalid tensor alignment: B")
        if not check_contigous_16B_alignment(c_dtype, c_major == "m", (m, n, l)):
            raise testing.CantImplementError("Invalid tensor alignment: C")

    @staticmethod
    def can_implement(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
    ):
        """Check if the gemm can be implemented"""
        try:
            Sm107GroupedGemmKernel.is_valid_dtypes(a_dtype, b_dtype, c_dtype, acc_dtype)

            Sm107GroupedGemmKernel.is_valid_mma_tiler_and_cluster_shape(
                a_dtype,
                b_dtype,
                mma_tiler,
                mma_inst_shape,
                cluster_shape_mn,
                use_2cta_instrs,
            )

            for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
                Sm107GroupedGemmKernel.is_valid_tensor_alignment(
                    m, n, k, l, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
                )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    # Size of smem we reserved for mbarrier, tensor memory management and tensormap update
    reserved_smem_bytes = 1024
    bytes_per_tensormap = 128
    num_tensormaps = 3
    # size of smem used for tensor memory management
    tensor_memory_management_bytes = 12


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    use_cached_problem_shapes: bool = True,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """Run grouped GEMM example with specified configurations.

    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False
    :type use_cold_l2: bool, optional
    :param use_cached_problem_shapes: Enable double-buffered caching of problem
        shapes for better performance with many small groups, defaults to True.
    :type use_cached_problem_shapes: bool, optional
    :return: Execution time of the GEMM kernel in microseconds
    :rtype: float
    """
    print("Running Rubin Grouped GEMM test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(
        f"Mma Tiler (M, N, K): {mma_tiler}, Mma Inst Shape (M, N, K): {mma_inst_shape}, Cluster Shape (M, N): {cluster_shape_mn}"
    )
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Tensor map update mode: {tensormap_update_mode}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(f"Use cached problem shapes: {use_cached_problem_shapes}")

    import torch

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch_tensors_abc = []
    torch_cpu_f32_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    # Run and verify with torch
    # create cpu tensors
    for group_idx, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        if a_major == "k":
            a_f32 = torch.empty((l, m, k), dtype=torch.float32).permute(1, 2, 0)
        elif a_major == "m":
            a_f32 = torch.empty((l, k, m), dtype=torch.float32).permute(2, 1, 0)
        if b_major == "k":
            b_f32 = torch.empty((l, n, k), dtype=torch.float32).permute(1, 2, 0)
        elif b_major == "n":
            b_f32 = torch.empty((l, k, n), dtype=torch.float32).permute(2, 1, 0)
        if c_major == "n":
            c_f32 = torch.empty((l, m, n), dtype=torch.float32).permute(1, 2, 0)
        elif c_major == "m":
            c_f32 = torch.empty((l, n, m), dtype=torch.float32).permute(2, 1, 0)

        # Initialize tensors with either normal distribution or random integers
        for tensor in [a_f32, b_f32, c_f32]:
            if init_normal:
                tensor.normal_(mean=normal_mean, std=normal_std)
            else:
                tensor.random_(-2, 3)

        torch_cpu_f32_tensors_abc.append([a_f32, b_f32, c_f32])

    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        _,
    ) = create_tensors_for_all_groups(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        torch_cpu_f32_tensors_abc,
    )

    # Setup initial tensors for TMA of A,B and C
    alignment = 16  # 16 bytes aligned
    min_ab_size = alignment * 8 // a_dtype.width
    min_c_size = alignment * 8 // c_dtype.width
    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]

    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Prepare tensormap buffer for each SM
    num_tensormap_buffers = sm_count
    tensormap_shape = (
        num_tensormap_buffers,
        Sm107GroupedGemmKernel.num_tensormaps,
        Sm107GroupedGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_gemm = Sm107GroupedGemmKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
        tensormap_update_mode,
        use_cached_problem_shapes,
    )

    print(f"problem_sizes_mnkl: {problem_sizes_mnkl}")

    # Check if configuration can be implemented
    if not Sm107GroupedGemmKernel.can_implement(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
        use_2cta_instrs,
    ):
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, mma_inst_shape = {mma_inst_shape}, cluster_shape_mn = {cluster_shape_mn}, "
            f"tensormap_update_mode = {tensormap_update_mode}"
        )

    # layout (num_groups, 4):(4, 1)
    tensor_of_dim_size_mnkl, tensor_of_dim_size_mnkl_torch = (
        cutlass_torch.cute_tensor_like(
            torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )
    )

    # layout (num_groups, 3, 2):(6, 2, 1)
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,3):(3, 1)
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # Compute total number of cluster tiles we need to compute for given grouped GEMM problem
    def compute_total_num_clusters(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        cluster_tile_shape_mn: Tuple[int, int],
    ) -> int:
        total_num_clusters = 0
        for m, n, _, _ in problem_sizes_mnkl:
            num_clusters_mn = tuple(
                (x + y - 1) // y for x, y in zip((m, n), cluster_tile_shape_mn)
            )
            total_num_clusters += functools.reduce(lambda x, y: x * y, num_clusters_mn)
        return total_num_clusters

    # Compute cluster tile shape
    def compute_cluster_tile_shape(
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
    ) -> Tuple[int, int]:
        cta_tile_shape_mn = list(mma_tiler)[0:2]
        if use_2cta_instrs:
            cta_tile_shape_mn[0] = cta_tile_shape_mn[0] // 2
        return tuple(x * y for x, y in zip(cta_tile_shape_mn, cluster_shape_mn))

    cluster_tile_shape_mn = compute_cluster_tile_shape(
        mma_tiler, cluster_shape_mn, use_2cta_instrs
    )

    # If the host problem shape is available, we will launch the grid with only
    # the necessary clusters. The function compute_total_num_clusters() does that.
    # If the problem shape only exists on device, we will need to launch all active
    # clusters possible on a device.
    if host_problem_shape_available:
        print("Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, cluster_tile_shape_mn
        )
    else:
        print("Problem shapes available only on device")
        total_num_clusters = max_active_clusters

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    # Compile grouped GEMM kernel
    compiled_grouped_gemm = cute.compile(
        grouped_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
    )

    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_tensormap,
            current_stream,
        )

        # Compute reference result
        for group_idx, (a, b, c) in enumerate(torch_tensors_abc):
            ref = torch.einsum(
                "mkl,nkl->mnl",
                torch_cpu_f32_tensors_abc[group_idx][0].cpu(),
                torch_cpu_f32_tensors_abc[group_idx][1].cpu(),
            )

            print(f"group {group_idx}:")

            torch.testing.assert_close(
                c.cpu(),
                ref.to(cutlass_torch.dtype(c_dtype)),
                atol=tolerance,
                rtol=1e-05,
            )

    if iterations <= 0:
        return 0

    def generate_tensors():
        # Reuse existing CPU tensors and create new GPU tensors from them
        (
            ptrs_abc_workspace,
            torch_tensors_abc_workspace,
            cute_tensors_abc_workspace,
            strides_abc_workspace,
            _,
        ) = create_tensors_for_all_groups(
            problem_sizes_mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            torch_cpu_f32_tensors_abc,
        )

        initial_cute_tensors_abc_workspace = [
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, a_major == "m", a_dtype
            )[2],
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, b_major == "n", b_dtype
            )[2],
            create_tensor_and_stride(
                1, min_c_size, min_c_size, c_major == "m", c_dtype
            )[2],
        ]

        # Create new tensors for this workspace
        tensor_of_strides_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_workspace, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensormap_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.empty(total_num_clusters, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )

        args = testing.JitArguments(
            initial_cute_tensors_abc_workspace[0],
            initial_cute_tensors_abc_workspace[1],
            initial_cute_tensors_abc_workspace[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc_workspace,
            tensor_of_ptrs_abc_workspace,
            tensormap_workspace,
            current_stream,
        )
        args.add_to_scope([torch_tensors_abc_workspace])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                [
                    sum(
                        [
                            torch_tensor.numel() * torch_tensor.element_size()
                            for torch_tensor in group_tensors
                        ]
                    )
                    for group_tensors in torch_tensors_abc
                ]
            )
            +
            # Add size of strides tensor
            tensor_of_strides_abc_torch.numel()
            * tensor_of_strides_abc_torch.element_size()
            +
            # Add size of ptrs tensor
            tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            +
            # Add size of tensormap tensor
            tensor_of_tensormap_torch.numel() * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_comma_separated_tuples(s: str) -> List[Tuple[int, ...]]:
        if s.strip().startswith("("):
            # Split on ),( to separate tuples
            tuples = s.strip("()").split("),(")
            result = []
            tuple_len = None

            for t in tuples:
                # Parse individual tuple
                nums = [int(x.strip()) for x in t.split(",")]

                # Validate tuple length consistency
                if tuple_len is None:
                    tuple_len = len(nums)
                elif len(nums) != tuple_len:
                    raise argparse.ArgumentTypeError(
                        "All tuples must have the same length"
                    )

                result.append(tuple(nums))
            return result

        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers or list of tuples"
        )

    parser = argparse.ArgumentParser(description="Example of Grouped GEMM on Rubin.")
    parser.add_argument(
        "--num_groups",
        type=int,
        default=3,
        help="Number of groups",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=((128, 128, 128, 1), (512, 128, 128, 1), (128, 256, 128, 1)),
        help="a tuple of problem sizes for each group (comma-separated tuples)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Enable the compute of grid based upon host problem shape",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma inst shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--tensormap_update_mode",
        type=str,
        default="SMEM",
        help="Tensor map update mode",
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Data type of the A tensor",
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Data type of the B tensor",
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Data type of the C tensor",
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="Data type of the accumulator tensor",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--no_use_cached_problem_shapes",
        action="store_true",
        default=False,
        help="Disable double-buffered caching of problem shapes. "
        "By default, caching is enabled for better performance with many small groups.",
    )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal distribution for tensor initialization instead of random integers",
    )
    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean for normal distribution initialization",
    )
    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation for normal distribution initialization",
    )

    args = parser.parse_args()

    if (
        len(args.problem_sizes_mnkl) != 0
        and len(args.problem_sizes_mnkl) != args.num_groups
    ):
        parser.error("--problem_sizes_mnkl must contain exactly num_groups tuples")

    # l mode must be 1 for all groups
    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l must be 1 for all groups")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    if args.tensormap_update_mode not in ["GMEM", "SMEM"]:
        parser.error("--tensormap_update_mode must be GMEM or SMEM")

    if args.tensormap_update_mode == "GMEM":
        tensormap_update_mode = cutlass.tensor_utils.TensorMapUpdateMode.GMEM
    else:
        tensormap_update_mode = cutlass.tensor_utils.TensorMapUpdateMode.SMEM

    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.host_problem_shape_available,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler,
        args.mma_inst_shape,
        args.cluster_shape_mn,
        args.use_2cta_instrs,
        tensormap_update_mode,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        not args.no_use_cached_problem_shapes,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
