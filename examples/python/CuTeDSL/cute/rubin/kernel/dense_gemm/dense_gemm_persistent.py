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
from typing import Optional, Tuple, Type, Union, Literal
from functools import lru_cache

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
from cutlass.utils import create_cute_tensor_for_fp8, is_fp8_dtype
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.nvgpu.tcgen05 import CollectorOp
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.dense_gemm.dense_gemm_persistent import (
    PersistentDenseGemmKernel as BlackwellPersistentDenseGemmKernel,
    bmm,
    prepare_tensors,
)

"""
A high-performance persistent batched dense GEMM example for the NVIDIA Rubin SM107 architecture
using CuTe DSL, extending the Blackwell implementation.

Comparison: SM107 (Rubin) vs. SM100 (Blackwell)
- Shared memory (SMEM): 328 KiB on SM107; 228 KiB on SM100
- Tensor memory (TMEM): 576 columns for SM107; 512 columns for SM100
- MMA K dimension: SM107 supports both K=32 and K=64 (SM100 only supports K=32)
- CollectorOp: Enhanced support in SM107 for advanced TMEM accumulator handling

.. code-block:: bash

    python examples/cute/rubin/kernel/dense_gemm/dense_gemm_persistent.py                      \
        --a_dtype Float8E4M3FN --b_dtype Float8E5M2                     \
        --c_dtype Float16 --acc_dtype Float32                           \
        --mma_tiler 512,256,128 --mma_inst_shape 256,256,64             \
        --cluster_shape_mn 2,1                                          \
        --mnkl 8192,8192,8192,1                                         \
        --use_tma_store --use_2cta_instrs

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/cute/rubin/kernel/dense_gemm/dense_gemm_persistent.py                  \
        --a_dtype Float8E4M3FN --b_dtype Float8E4M3FN                   \
        --c_dtype Float16 --acc_dtype Float32                           \
        --mma_tiler 256,256,128 --mma_inst_shape 256,256,64             \
        --cluster_shape_mn 2,1                                          \
        --mnkl 8192,8192,8192,1                                         \
        --use_tma_store --use_2cta_instrs                               \
        --warmup_iterations 1 --iterations 10 --skip_ref_check


Additional constraints:
- Supported A/B input types: Float16, BFloat16, TFloat32, Float8E4M3FN, Float8E5M2
- Bkeep-Breuse pattern (mma_tiler[0] == 2 * mma_inst_shape[0]) is only supported for FP8 inputs
- mma_inst_shape K=64 (FP8 only): M in the MMA tiler must be 128 (1 CTA) or 256 (2 CTAs)
- mma_inst_shape K=32 (FP8 only): same M constraints as Blackwell
- mma_inst_shape K=16 (Float16/BFloat16): same M constraints as Blackwell
- mma_inst_shape K=8 (TFloat32): same M constraints as Blackwell
"""


class SM107PersistentDenseGemmKernel(BlackwellPersistentDenseGemmKernel):
    """Persistent dense GEMM kernel for Rubin.

    Extends `BlackwellPersistentDenseGemmKernel` with SM107-specific behavior and limits.

    SM107 adds support for the Bkeep-Breuse pattern optimization which reuses
    the B matrix across two separate GEMM operations.

    :param acc_dtype: Data type for accumulation during computation.
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation.
    :type use_2cta_instrs: bool
    :param mma_tiler: Overall GEMM tile shape (M, N, K). Controls the Bkeep-Breuse
        pattern when ``mma_tiler[0] == 2 * mma_inst_shape[0]``.
    :type mma_tiler: Tuple[int, int, int]
    :param mma_inst_shape: MMA instruction shape (M, N, K).
    :type mma_inst_shape: Tuple[int, int, int]
    :param cluster_shape_mn: Cluster dimensions (M, N)
    :type cluster_shape_mn: Tuple[int, int]
    :param use_tma_store: Whether to use Tensor Memory Access (TMA) for storing results.
    :type use_tma_store: bool
    :param swizzle_size: Swizzle size for shared memory layout. Default is 1.
    :type swizzle_size: int
    :param raster_along: Rasterization direction for tile scheduling, ``"m"`` or ``"n"``. Default is ``"m"``.
    :type raster_along: Literal["m", "n"]

    notes:
    - Data types: Float16, BFloat16, TFloat32, Float8E4M3FN, Float8E5M2
    - mma_inst_shape K=64 constraint (FP8 only): M must be 128 (1 CTA) or 256 (2 CTAs)
    - Resources: larger SMEM (328 KiB) and TMEM (576 columns)
    - Bkeep-Breuse pattern: Optimizes B matrix reuse
    **Example:**

    .. code-block:: python

        gemm = SM107PersistentDenseGemmKernel(
            acc_dtype=cutlass.Float32,
            use_2cta_instrs=True,
            mma_tiler=(256, 128, 128),
            mma_inst_shape=(256, 128, 64),
            cluster_shape_mn=(2, 1),
            use_tma_store=True,
            swizzle_size=1,
            raster_along="m",
        )
    """

    @staticmethod
    def _is_breuse_requested(
        mma_tiler: Tuple[int, int, int], mma_inst_shape: Tuple[int, int, int]
    ):
        return mma_tiler[0] == 2 * mma_inst_shape[0]

    @staticmethod
    def _is_breuse_supported(a_dtype, b_dtype):
        supported_dtype = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        return all(d in supported_dtype for d in (a_dtype, b_dtype))

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        swizzle_size: int = 1,
        raster_along: Literal["m", "n"] = "m",
    ):
        """Initialize the Rubin persistent dense GEMM kernel.

        :param mma_tiler: MMA tiler (M, N, K).
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: MMA instruction shape (M, N, K).
        :type mma_inst_shape: Tuple[int, int, int]

        Other parameters are identical to the base class.
        """
        super().__init__(
            acc_dtype,
            use_2cta_instrs,
            mma_inst_shape[0:2],
            cluster_shape_mn,
            use_tma_store,
            swizzle_size,
            raster_along,
        )
        self.arch = "sm_107"
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)
        self.mma_tiler = mma_tiler
        self.mma_inst_shape = mma_inst_shape
        # Bkeep-Breuse pattern is controlled by mma_inst_shape and mma_tiler
        # There are also currently some limitations with respect to runtime data
        # types which will be enforced when __call__ is called
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
        """Create TiledMma for keep operation (with fill collector for B).

        This is used in the Bkeep-Breuse pattern for the first GEMM operation.
        The 'fill' collector operation indicates that B data should be kept
        for reuse in subsequent operations.
        """
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
        """Create TiledMma for reuse operation (with lastuse collector for B).

        This is used in the Bkeep-Breuse pattern for the second GEMM operation.
        The 'lastuse' collector operation indicates that this is the last use
        of the B data that was kept from the previous operation.
        """
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
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/B/C stage counts in shared memory
        - Computing A/B/C shared memory layout
        - Computing tensor memory allocation columns
        """
        # Configure tiled mma
        tiled_mma = self._create_tiled_mma()

        # Compute mma/cluster/tile shapes
        self.mma_inst_tile_k = self.mma_tiler[2] // self.mma_inst_shape[2]

        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
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
        self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        from blackwell.kernel.dense_gemm.dense_gemm_persistent import _compute_stages

        _, self.num_ab_stage, self.num_c_stage = _compute_stages(
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
            f"ab={self.num_ab_stage}, c={self.num_c_stage}, acc={self.num_acc_stage} "
            f"(tmem_cols_per_stage={cols_per_acc_stage}, tmem_total={self.num_tmem_alloc_cols})"
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

    # GPU device kernel
    @cute.jit
    def kernel_impl(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
        tiled_mma_bkeep: Optional[cute.TiledMma],
        tiled_mma_breuse: Optional[cute.TiledMma],
        cluster_shape_mn: Tuple[int, int],
        is_a_mcast: bool,
        is_b_mcast: bool,
    ):
        """
        GPU device kernel implementation performing the Persistent batched GEMM computation.
        """
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
        bidx, _, _ = cute.arch.block_idx()
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
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

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

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape_mn, is_relaxed=True)

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
        if cutlass.const_expr(is_a_mcast or is_b_mcast or use_2cta_instrs):
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
        pipeline_init_wait(cluster_shape_mn=cluster_shape_mn)

        #
        # Construct the scheduler
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
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

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    # TMA load A/B
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
                    )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
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
                        # Conditionally wait for AB buffer full
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        # tCtAcc += tCrA * tCrB
                        tile_crd = (None, None, None, handle.index)

                        # Get current stage tensors (3D)
                        # tCrA has shape (MMA, MMA_M, MMA_K, STAGE) → (MMA, MMA_M, MMA_K)
                        tCrA_stage = tCrA[tile_crd]
                        # tCrB has shape (MMA, MMA_N, MMA_K, STAGE) → (MMA, MMA_N, MMA_K)
                        tCrB_stage = tCrB[tile_crd]

                        # Check if we should use Bkeep-Breuse pattern
                        if cutlass.const_expr(self.enable_breuse):
                            # Slice accumulator once (shared across k_phase)
                            tCtAcc_keep = tCtAcc[(None, 0, 0)]
                            tCtAcc_reuse = tCtAcc[(None, 1, 0)]

                            for k_phase in range(self.mma_inst_tile_k):
                                # Bkeep-Breuse pattern

                                # B slice - select N=0 from (MMA, MMA_N, MMA_K) → (MMA, MMA_K)
                                # C++ SliceOp(tcrb, coord(_, 0))
                                tCrB_slice = tCrB_stage[(None, 0, k_phase)]

                                # Keep operation - first A slice
                                # Select M=0 from (MMA, MMA_M, MMA_K) → (MMA, MMA_K)
                                # C++ SliceOp(tcra, coord(_, 0))
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

                                # Reuse operation - second A slice
                                # Select M=1 from (MMA, MMA_M, MMA_K) → (MMA, MMA_K)
                                # C++ SliceOp(tcra, coord(_, 1))
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
                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA_stage,
                                tCrB_stage,
                                tCtAcc,
                            )

                        # Async arrive AB buffer empty
                        handle.release()

                        # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
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

            tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

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

                num_tiles_executed = tile_sched.num_tiles_executed
                if cutlass.const_expr(self.use_tma_store):
                    acc_consumer_state = utils.gemm.sm100.epilogue_tma_store(
                        self,
                        tidx,
                        warp_idx,
                        tma_atom_c,
                        tCtAcc,
                        sC,
                        tCgC,
                        epi_tile,
                        num_tiles_executed,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        c_pipeline,
                    )
                else:
                    acc_consumer_state = utils.gemm.sm100.epilogue(
                        self,
                        tidx,
                        tCtAcc,
                        tCgC,
                        epi_tile,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
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
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
        tiled_mma_bkeep: Optional[cute.TiledMma] = None,
        tiled_mma_breuse: Optional[cute.TiledMma] = None,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.
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
            c_smem_layout_staged,
            epi_tile,
            tile_sched_params,
            epilogue_op,
            tiled_mma_bkeep,
            tiled_mma_breuse,
            self.cluster_shape_mn,
            self.is_a_mcast,
            self.is_b_mcast,
        )

    def check_supported_dtypes(self, a_dtype, b_dtype, c_dtype):
        """Validate data types for Rubin.

        Supported A/B input types: Float16, BFloat16, TFloat32, Float8E4M3FN, Float8E5M2.
        For Float16/BFloat16/TFloat32: both A and B must be the same type.
        The accumulator must be Float32 or Float16.

        :raises testing.CantImplementError: If the dtypes are not supported
        """
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if a_dtype not in valid_ab_dtypes or b_dtype not in valid_ab_dtypes:
            raise testing.CantImplementError(
                f"Unsupported input types: {a_dtype} and {b_dtype}. "
                f"Supported: Float16, BFloat16, TFloat32, Float8E4M3FN, Float8E5M2"
            )
        if not is_fp8_dtype(a_dtype) and a_dtype != b_dtype:
            raise testing.CantImplementError(
                f"Float16/BFloat16/TFloat32 requires matching A and B types, got {a_dtype} and {b_dtype}"
            )
        if self.acc_dtype not in {cutlass.Float32, cutlass.Float16}:
            raise testing.CantImplementError(
                f"This example only supports Float32 or Float16 accumulator, got {self.acc_dtype}"
            )

        # Call parent to check additional constraints (acc/ab/c compatibility)
        return super().check_supported_dtypes(a_dtype, b_dtype, c_dtype)

    def check_mma_tiler_and_cluster_shape(
        self,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
    ):
        """Validate the MMA tiler and cluster shape for Rubin.

        :param a_dtype: Data type for input tensor A.
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Data type for input tensor B.
        :type b_dtype: Type[cutlass.Numeric]
        :raises testing.CantImplementError: If the mma tiler is invalid
        """
        # Check for F16/BF16/TF32 data types
        if a_dtype == cutlass.TFloat32 and b_dtype == cutlass.TFloat32:
            if self.mma_inst_shape[2] != 8:
                raise testing.CantImplementError(
                    f"K=8 MMA instruction is expected with A = B = TFloat32, "
                    f"got mma_inst_shape.k = {self.mma_inst_shape[2]}"
                )
        if a_dtype in (cutlass.Float16, cutlass.BFloat16) and b_dtype == a_dtype:
            if self.mma_inst_shape[2] != 16:
                raise testing.CantImplementError(
                    f"K=16 MMA instruction is expected with A = B = Float16/BFloat16, "
                    f"got mma_inst_shape.k = {self.mma_inst_shape[2]}"
                )

        # K=64 is only supported for FP8 input types on both A and B
        if self.mma_inst_shape[2] == 64:
            if not is_fp8_dtype(a_dtype) or not is_fp8_dtype(b_dtype):
                raise testing.CantImplementError(
                    f"K=64 MMA instruction is only supported for FP8 input types, "
                    f"got a_dtype={a_dtype}, b_dtype={b_dtype}"
                )
            if not self.use_2cta_instrs and self.mma_inst_shape[0] != 128:
                raise testing.CantImplementError(
                    f"For K=64 with use_2cta_instrs=False, mma_inst_shape M must be 128, got {self.mma_inst_shape[0]}"
                )
            elif self.use_2cta_instrs and self.mma_inst_shape[0] != 256:
                raise testing.CantImplementError(
                    f"For K=64 with use_2cta_instrs=True, mma_inst_shape M must be 256, got {self.mma_inst_shape[0]}"
                )

        if self._is_breuse_requested(
            self.mma_tiler, self.mma_inst_shape
        ) and not self._is_breuse_supported(a_dtype, b_dtype):
            raise testing.CantImplementError(
                f"B-reuse is requested for an unsupported data type in this example: a={a_dtype}, b={b_dtype}"
            )

        if (
            self.mma_tiler[0] // self.mma_inst_shape[0] != 2
            and self.mma_tiler[0] // self.mma_inst_shape[0] != 1
        ) or self.mma_tiler[1] != self.mma_inst_shape[1]:
            raise testing.CantImplementError(
                f"Invalid mma tiler: {self.mma_tiler} with mma_inst_shape: {self.mma_inst_shape}"
            )
        # Call parent to check common constraints
        super().check_mma_tiler_and_cluster_shape()

    def can_implement(
        self,
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        """Determine if the given tensor configuration can be implemented by this kernel.

        Overrides the base class to pass ``a_dtype`` and ``b_dtype`` explicitly to
        ``check_mma_tiler_and_cluster_shape``, which requires them before ``__call__``
        sets ``self.a_dtype`` / ``self.b_dtype``.

        :param mnkl: Problem size as a tuple (M, N, K, L).
        :type mnkl: Tuple[int, int, int, int]
        :param a_dtype: Data type for input tensor A.
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Data type for input tensor B.
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: Data type for output tensor C.
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: Major dimension of the A tensor layout ("m" or "k").
        :type a_major: str
        :param b_major: Major dimension of the B tensor layout ("n" or "k").
        :type b_major: str
        :param c_major: Major dimension of the C tensor layout ("m" or "n").
        :type c_major: str
        :return: True if the kernel supports the given configuration, False otherwise.
        :rtype: bool
        """
        try:
            self.check_supported_dtypes(a_dtype, b_dtype, c_dtype)
            self.check_mma_tiler_and_cluster_shape(a_dtype, b_dtype)
            m, n, k, l = mnkl
            self.check_tensor_alignment(
                m, n, k, l, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )
            self.check_epilog_store_option(m, n)
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    def check_epilog_store_option(self, m: int, n: int):
        """Validate epilogue store option for Rubin.

        The base class uses ``mma_tiler_mn`` (which maps to ``mma_inst_shape``
        in Rubin) to compute the CTA tile shape.  Rubin's actual CTA tile is
        derived from ``self.mma_tiler`` which can be 2x larger in M due to the
        Bkeep-Breuse pattern.  We must use the real CTA tile here so that
        out-of-bounds configurations are correctly rejected.

        :raises testing.CantImplementError: If the problem shape is incompatible
        """
        cta_tile_shape_mn = (
            self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
            self.mma_tiler[1],
        )
        if not self.use_tma_store:
            if not (m % cta_tile_shape_mn[0] == 0 and n % cta_tile_shape_mn[1] == 0):
                raise testing.CantImplementError(
                    f"Problem shape {m}, {n} must be divisible by cta tile shape "
                    f"{cta_tile_shape_mn} for non TMA store"
                )
            m_per_swizzle = (m // cta_tile_shape_mn[0]) // self.cluster_shape_mn[0]
            n_per_swizzle = (n // cta_tile_shape_mn[1]) // self.cluster_shape_mn[1]
            if m_per_swizzle == 0 or n_per_swizzle == 0:
                raise testing.CantImplementError(
                    f"Problem shape {m}, {n} does not have enough tiles for "
                    f"cluster shape {self.cluster_shape_mn} with cta tile "
                    f"{cta_tile_shape_mn}"
                )
            if (m_per_swizzle % self.swizzle_size != 0) or (
                n_per_swizzle % self.swizzle_size != 0
            ):
                raise testing.CantImplementError(
                    f"Problem shape {m}, {n} must be divisible by swizzle size "
                    f"{self.swizzle_size} for non TMA store"
                )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Override parent __call__ to pass Bkeep-Breuse tiled_mma objects to kernel."""
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

        # Bkeep-Breuse is enabled if it is requested and data types are supported
        self.enable_breuse = self._is_breuse_requested(
            self.mma_tiler, self.mma_inst_shape
        ) and self._is_breuse_supported(self.a_dtype, self.b_dtype)

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

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

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

        # Launch the kernel synchronously with Bkeep-Breuse parameters
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            epilogue_op,
            tiled_mma_bkeep,  # Pass Bkeep tiled_mma
            tiled_mma_breuse,  # Pass Breuse tiled_mma
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
        )


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
    mma_tiler: Tuple[int, int, int] = (256, 256, 128),
    mma_inst_shape: Tuple[int, int, int] = (256, 256, 64),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    max_active_clusters: cutlass.Constexpr = None,
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Compile a batched matrix multiplication kernel for Rubin.

    :param mnkl: Problem dimensions (M, N, K, L)
    :param a: Input tensor A
    :param b: Input tensor B
    :param c: Output tensor C
    :param acc_dtype: Accumulator data type
    :param a_major: Major dimension of A ("k" or "m")
    :param b_major: Major dimension of B ("k" or "n")
    :param c_major: Major dimension of C ("n" or "m")
    :param mma_tiler: MMA tile shape (M, N, K)
    :param mma_inst_shape: MMA instruction shape (M, N, K)
    :param cluster_shape_mn: Cluster shape (M, N)
    :param max_active_clusters: Maximum active clusters
    :param use_2cta_instrs: Use 2CTA instructions
    :param use_tma_store: Use TMA store
    :param swizzle_size: Swizzle size
    :param raster_along: Raster along dimension ("m" or "n")
    :param use_tvm_ffi: Use TVM FFI
    :param epilogue_op: Epilogue operation
    :return: Compiled kernel function
    """
    from cutlass.cute.runtime import make_fake_stream

    # Build GEMM object
    gemm = SM107PersistentDenseGemmKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
        use_tma_store,
        swizzle_size,
        raster_along,
    )

    # Check if configuration can be implemented
    can_implement = gemm.can_implement(
        mnkl, a.element_type, b.element_type, c.element_type, a_major, b_major, c_major
    )

    if not can_implement:
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, mma_inst_shape = {mma_inst_shape}, cluster_shape_mn = {cluster_shape_mn}, "
            f"use_tma_store = {use_tma_store},"
            f"swizzle_size = {swizzle_size}, "
            f"raster_along = {raster_along}"
        )

    stream = make_fake_stream()
    return cute.compile(bmm, gemm, a, b, c, max_active_clusters, stream, epilogue_op)


def run(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int] = (256, 256, 128),
    mma_inst_shape: Tuple[int, int, int] = (256, 256, 64),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    benchmark: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """
    Execute a persistent batched dense GEMM operation on Rubin architecture with performance benchmarking.

    Prepares input tensors, configures and launches the persistent GEMM kernel,
    optionally performs reference validation, and benchmarks execution.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: Tuple[int, int, int, int]
    :param a_dtype: Data type for input tensor A.
    :type a_dtype: Type[cutlass.Numeric]
    :param b_dtype: Data type for input tensor B.
    :type b_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type for the matrix multiplication.
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Memory layout of tensor A.
    :type a_major: str
    :param b_major: Memory layout of tensor B.
    :type b_major: str
    :param c_major: Memory layout of tensor C.
    :type c_major: str
    :param mma_tiler: MMA tiling size (M, N, K), defaults to (256, 256, 128).
    :type mma_tiler: Tuple[int, int, int], optional
    :param mma_inst_shape: MMA instruction shape (M, N, K), defaults to (256, 256, 64).
    :type mma_inst_shape: Tuple[int, int, int], optional
    :param cluster_shape_mn: Cluster shape (M, N), defaults to (2, 1).
    :type cluster_shape_mn: Tuple[int, int], optional
    :param swizzle_size: Swizzling size in the unit of cluster for improving L2 cache hit rate, defaults to 1.
    :type swizzle_size: int, optional
    :param raster_along: Rasterization order of clusters ('m' or 'n'), defaults to 'm'.
    :type raster_along: Literal["m", "n"], optional
    :param use_2cta_instrs: Whether to use 2CTA MMA instructions, defaults to True.
    :type use_2cta_instrs: bool, optional
    :param use_tma_store: Whether to use TMA store, defaults to True.
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance for reference validation, defaults to 1e-01.
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 0.
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 1.
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference result validation, defaults to False.
    :type skip_ref_check: bool, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False.
    :type use_cold_l2: bool, optional
    :param benchmark: Whether to only benchmark the kernel, defaults to False.
    :type benchmark: bool, optional
    :param init_normal: Whether to use normal (Gaussian) initialization for tensors, defaults to False.
        When True, tensors are initialized with normal distribution N(normal_mean, normal_std).
    :type init_normal: bool, optional
    :param normal_mean: Mean of the normal distribution for initialization, defaults to 0.0.
    :type normal_mean: float, optional
    :param normal_std: Standard deviation of the normal distribution for initialization, defaults to 1.0.
    :type normal_std: float, optional
    :raises RuntimeError: If CUDA GPU is not available.
    :raises ValueError: If the configuration is invalid or unsupported by the kernel.
    :return: Execution time of the GEMM kernel.
    :rtype: float
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Check if configuration can be implemented
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Int8 and Uint8 are not supported for normal initialization
    if a_dtype in {cutlass.Int8, cutlass.Uint8} or b_dtype in {
        cutlass.Int8,
        cutlass.Uint8,
    }:
        pass

    # Run and verify BMM with torch
    a_f32, b_f32, c_f32, a_storage, b_storage, c_storage = prepare_tensors(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        init_random=not init_normal,
        normal_mean=normal_mean,
        normal_std=normal_std,
    )

    leading_dim_a = 2 if a_major == "k" else 1
    leading_dim_b = 1 if b_major == "k" else 2
    leading_dim_c = 2 if c_major == "n" else 1

    # Create CuTe tensors, passing float32 source for fp8 conversion
    a_ = create_cute_tensor_for_fp8(
        a_storage, a_dtype, leading_dim_a, source_f32_tensor=a_f32
    )
    b_ = create_cute_tensor_for_fp8(
        b_storage, b_dtype, leading_dim_b, source_f32_tensor=b_f32
    )
    c_ = create_cute_tensor_for_fp8(
        c_storage, c_dtype, leading_dim_c, source_f32_tensor=c_f32
    )

    m, n, k, l = mnkl
    compiled_fn = compile_bmm(
        mnkl,
        a_,
        b_,
        c_,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
        max_active_clusters,
        use_2cta_instrs,
        use_tma_store,
        swizzle_size,
        raster_along,
        epilogue_op=lambda x: x,
    )

    print("Running Rubin Persistent Dense GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"Mma Tiler (M, N, K): {mma_tiler}")
    print(f"Mma Instruction Shape (M, N, K): {mma_inst_shape}")
    print(f"Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Use 2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Use TMA Store: {'True' if use_tma_store else 'False'}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(f"Swizzle Size: {swizzle_size}")
    print(f"Raster Along: {raster_along}")

    if not skip_ref_check:
        # Use small random number for deterministic result for reference check
        compiled_fn(a_, b_, c_, current_stream)

        # Manually quantize to be comparable
        # Use float32 source data for reference calculation
        ref = (
            torch.bmm(a_f32, b_f32)
            .to(dtype=torch_dtype(c_dtype))
            .to(dtype=torch.float32)
        )
        torch.testing.assert_close(
            c_storage.view(torch_dtype(c_dtype)).to(dtype=torch.float32),
            ref,
            atol=tolerance,
            rtol=1e-03,
        )

    if not benchmark:
        return 0

    def generate_tensors():
        # Use init_normal from outer scope, but force random init for Int8/Uint8 types
        use_normal_init = init_normal and (
            a_dtype not in [cutlass.Int8, cutlass.Uint8]
            and b_dtype not in [cutlass.Int8, cutlass.Uint8]
        )
        a_f32, b_f32, c_f32, a_st, b_st, c_st = prepare_tensors(
            mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_random=not use_normal_init,
            normal_mean=normal_mean,
            normal_std=normal_std,
        )

        a_ = create_cute_tensor_for_fp8(
            a_st, a_dtype, leading_dim_a, source_f32_tensor=a_f32
        )
        b_ = create_cute_tensor_for_fp8(
            b_st, b_dtype, leading_dim_b, source_f32_tensor=b_f32
        )
        c_ = create_cute_tensor_for_fp8(
            c_st, c_dtype, leading_dim_c, source_f32_tensor=c_f32
        )
        return testing.JitArguments(a_, b_, c_, current_stream)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_storage.numel() * a_storage.element_size()
            + b_storage.numel() * b_storage.element_size()
            + c_storage.numel() * c_storage.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Return execution time in microseconds
    exec_time = testing.benchmark(
        compiled_fn,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )
    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Dense Persistent GEMM on Rubin."
    )

    parser.add_argument(
        "--mnkl",
        type=_parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=[
            "default",
            "none",
        ],
        help="Benchmark the kernel with nsight or default (cutlass.testing.benchmark) or none",
    )

    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
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
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal (Gaussian) initialization for tensors instead of uniform random",
    )

    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean of normal distribution for initialization (default: 0.0)",
    )

    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation of normal distribution for initialization (default: 1.0)",
    )

    # Kernel Configurations
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float8E5M2)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")

    parser.add_argument(
        "--use_tma_store", action="store_true", help="Use tma store or not"
    )

    parser.add_argument(
        "--cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )

    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )

    parser.add_argument(
        "--mma_tiler",
        type=_parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )

    parser.add_argument(
        "--mma_inst_shape",
        type=_parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma instruction shape (M, N, K) (comma-separated)",
    )

    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )

    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    print("[DSL INFO] Compiling Rubin Persistent Dense GEMM with:")
    print(
        f"[DSL INFO] A dtype: {args.a_dtype}, B dtype: {args.b_dtype}, C dtype: {args.c_dtype}, Acc dtype: {args.acc_dtype}"
    )
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Mma Tiler (M, N, K): {args.mma_tiler}")
    print(f"[DSL INFO] Mma Instruction Shape (M, N, K): {args.mma_inst_shape}")
    print(f"[DSL INFO] Cluster Shape (M, N): {args.cluster_shape_mn}")
    print(
        f"[DSL INFO] 2CTA MMA instructions: {'True' if args.use_2cta_instrs else 'False'}"
    )
    print(f"[DSL INFO] Use TMA Store: {'True' if args.use_tma_store else 'False'}")
    print(
        f"[DSL INFO] B-reuse feature is {'enabled' if args.mma_tiler[0] // args.mma_inst_shape[0] == 2 else 'disabled'}"
    )

    run(
        args.mnkl,
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
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.benchmark == "default",
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
