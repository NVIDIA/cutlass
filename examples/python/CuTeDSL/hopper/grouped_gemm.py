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

import argparse
import functools
import math
from inspect import isclass
from typing import List, Optional, Tuple, Type

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.torch as cutlass_torch
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.cute.nvgpu import cpasync

"""
A grouped GEMM example for the NVIDIA Hopper SM90 architecture using CuTe DSL.

This example demonstrates an implementation of grouped GEMM using TMA plus Hopper SM90
WGMMA warp-specialized persistent kernel. BF16 inputs are the primary supported dtype,
making this kernel well-suited for accuracy-sensitive model serving workloads such as
Mixture-of-Experts (MoE) / grouped expert GEMM on Hopper.

The grouped GEMM workload computes a batch of GEMM operations with distinct problem sizes.
Pointers to matrices in global memory are passed to the kernel in an array (also held in
global memory). Similarly, problem shapes and strides are stored in arrays in GMEM.

This differs from "Batched Array" GEMM since each GEMM problem in the grouped concept
may have distinct M, N, K dimensions.

This is the Hopper (SM90) CuTeDSL equivalent of examples/57_hopper_grouped_gemm, which
only exists in C++ and only supports FP8. This example adds BF16 support and a
Python/CuTeDSL implementation.

To run this example:

.. code-block:: bash

    python examples/hopper/grouped_gemm.py                                                \\
      --ab_dtype BFloat16 --c_dtype BFloat16 --acc_dtype Float32                          \\
      --tile_shape_mn 128,128 --cluster_shape_mn 1,1                                       \\
      --problem_sizes_mnkl "(8192,1280,128,1),(16,384,1536,1),(640,1280,128,1)"            \\
      --num_groups 3

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/hopper/grouped_gemm.py                                            \\
      --ab_dtype BFloat16 --c_dtype BFloat16 --acc_dtype Float32                          \\
      --tile_shape_mn 128,128 --cluster_shape_mn 1,1                                       \\
      --problem_sizes_mnkl "(8192,1280,128,1),(16,384,1536,1),(640,1280,128,1)"            \\
      --num_groups 3 --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* Supported input data types: BFloat16, Float16 (A and B must have the same type)
* Output data types: Float16, BFloat16, Float32
* BFloat16 inputs require Float32 accumulation
* CTA tile shape M must be 64/128
* CTA tile shape N must be 64/128/256
* CTA tile shape K must be 64
* Cluster shape M/N must be positive powers of 2, total cluster size <= 4
* The contiguous dimension of each tensor must be at least 16 bytes aligned
* The l mode (batch size) for each group must be 1
* The majorness for A, B, and C must be the same across all groups
"""


class HopperWgmmaGroupedGemmKernel:
    """
    Grouped GEMM kernel for NVIDIA Hopper SM90 using WGMMA and TMA with warp specialization.

    Implements a persistent tile scheduler that distributes work across groups. Each group
    may have a distinct (M, N, K) problem size. TMA descriptors are updated on-the-fly
    as the kernel transitions between groups.

    :param acc_dtype: Accumulator data type (Float32 recommended for BFloat16 inputs).
    :type acc_dtype: type[cutlass.Numeric]
    :param tile_shape_mn: CTA tile shape (M, N).
    :type tile_shape_mn: tuple[int, int]
    :param cluster_shape_mn: Cluster shape (M, N).
    :type cluster_shape_mn: tuple[int, int]
    :param swizzle_size: Swizzle size in clusters for L2 cache hit rate improvement.
    :type swizzle_size: int
    :param raster_along_m: Whether to rasterize clusters along M first.
    :type raster_along_m: bool
    :param tensormap_update_mode: Mode for TMA descriptor updates (SMEM or GMEM).
    :type tensormap_update_mode: utils.TensorMapUpdateMode
    """

    # Each TMA descriptor is 128 bytes; we manage one for A, B, and C.
    bytes_per_tensormap = 128
    num_tensormaps = 3
    # Reserved SMEM for mbarriers and optional tensormap buffer.
    reserved_smem_bytes = 1024

    def __init__(
        self,
        acc_dtype: type[cutlass.Numeric],
        tile_shape_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        swizzle_size: int = 1,
        raster_along_m: bool = True,
        tensormap_update_mode: utils.TensorMapUpdateMode = utils.TensorMapUpdateMode.SMEM,
    ):
        self.acc_dtype = acc_dtype
        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m
        self.tensormap_update_mode = tensormap_update_mode
        # When using SMEM mode, delegate tensormap A/B init to the MMA warp group
        # so that the TMA warp can start loading as soon as the init is complete.
        self.delegate_tensormap_ab_init = (
            tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        )

        # K dimension is deferred to _setup_attributes once dtypes are known.
        self.tile_shape_mnk = (*tile_shape_mn, 1)

        # For large tiles, two warp groups avoid register spill on SM90.
        self.atom_layout_mnk = (
            (2, 1, 1)
            if self.tile_shape_mnk[0] > 64 and self.tile_shape_mnk[1] > 128
            else (1, 1, 1)
        )

        self.num_mcast_ctas_a = None
        self.num_mcast_ctas_b = None
        self.is_a_mcast = False
        self.is_b_mcast = False
        self.tiled_mma = None

        self.occupancy = 1
        self.num_dma_warp_groups = 1
        self.num_mma_warp_groups = math.prod(self.atom_layout_mnk)
        self.num_warps_per_warp_group = 4
        self.num_threads_per_warp_group = self.num_warps_per_warp_group * 32
        self.threads_per_cta = (
            self.num_dma_warp_groups + self.num_mma_warp_groups
        ) * self.num_threads_per_warp_group

        # Warp 0 in the DMA warp group issues TMA loads and updates tensormaps for A/B.
        self.load_warp_id = 0
        # First warp of the first MMA warp group issues TMA stores and updates tensormap C.
        self.epi_store_warp_id = (
            self.num_dma_warp_groups * self.num_warps_per_warp_group
        )

        self.load_register_requirement = 40
        self.mma_register_requirement = 232

        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_90")

        self.num_mma_threads = (
            self.num_mma_warp_groups * self.num_threads_per_warp_group
        )

        # Barrier for epilogue register -> SMEM -> GMEM pipeline.
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=self.num_mma_threads
        )
        # Barrier signalling tensormap A/B initialisation is complete.
        # Participants: all MMA threads (producers) + 1 DMA warp (consumer).
        self.tensormap_ab_init_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=self.num_mma_threads + self.num_threads_per_warp_group,
        )

        self.ab_stage = None
        self.epi_stage = None
        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None
        self.shared_storage = None
        self.buffer_align_bytes = 1024

    def _setup_attributes(self):
        """Configure tile shapes, MMA atom, SMEM layouts, and stage counts.

        Called from ``__call__`` after input dtype/layout information is captured.
        """
        if self.tile_shape_mnk[0] not in [64, 128]:
            raise ValueError("CTA tile shape M must be 64/128")
        if self.tile_shape_mnk[1] not in [64, 128, 256]:
            raise ValueError("CTA tile shape N must be 64/128/256")

        self.tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_layout.sm90_mma_major_mode(),
            self.b_layout.sm90_mma_major_mode(),
            self.acc_dtype,
            self.atom_layout_mnk,
            tiler_mn=(64, self.tile_shape_mnk[1]),
        )

        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.tile_shape_mnk[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        self.cta_layout_mnk = cute.make_layout((*self.cluster_shape_mn, 1))
        self.num_mcast_ctas_a = self.cluster_shape_mn[1]
        self.num_mcast_ctas_b = self.cluster_shape_mn[0]
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        is_cooperative = self.atom_layout_mnk == (2, 1, 1)
        self.epi_tile = sm90_utils.compute_tile_shape_or_override(
            self.tile_shape_mnk, self.c_dtype, is_cooperative=is_cooperative
        )

        self.ab_stage, self.epi_stage = HopperWgmmaGroupedGemmKernel._compute_stages(
            self.tile_shape_mnk,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = HopperWgmmaGroupedGemmKernel._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.a_layout,
            self.b_dtype,
            self.b_layout,
            self.ab_stage,
            self.c_dtype,
            self.c_layout,
            self.epi_stage,
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
        """Set up TMA atoms, compute the grid, define shared storage, and launch the kernel.

        The ``initial_*`` tensors carry only dtype and layout information; the actual
        per-group shapes, strides, and addresses are supplied via the device tensors.

        :param initial_a: Template tensor A (dtype/layout only).
        :param initial_b: Template tensor B (dtype/layout only).
        :param initial_c: Template tensor C (dtype/layout only).
        :param group_count: Total number of GEMM groups.
        :param problem_shape_mnkl: Device tensor of shape (num_groups, 4) with (M,N,K,L) per group.
        :param strides_abc: Device tensor of shape (num_groups, 3, 2) with strides per group.
        :param tensor_address_abc: Device tensor of shape (num_groups, 3) with base pointers.
        :param total_num_clusters: Total cluster tiles across all groups (for grid sizing).
        :param tensormap_cute_tensor: Workspace for per-SM TMA descriptor storage.
        :param max_active_clusters: Hardware limit on concurrently active clusters.
        :param stream: CUDA stream for asynchronous execution.
        """
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.c_dtype = initial_c.element_type
        self.a_layout = utils.LayoutEnum.from_tensor(initial_a)
        self.b_layout = utils.LayoutEnum.from_tensor(initial_b)
        self.c_layout = utils.LayoutEnum.from_tensor(initial_c)

        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type mismatch: A={self.a_dtype} B={self.b_dtype}")

        self._setup_attributes()

        # Build TMA atoms from the template tensors. Per-group descriptors are
        # injected at runtime via tma_desc_ptr in cute.copy.
        tma_atom_a, tma_tensor_a = HopperWgmmaGroupedGemmKernel._make_tma_atoms_and_tensors(
            initial_a,
            self.a_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[1],
        )
        tma_atom_b, tma_tensor_b = HopperWgmmaGroupedGemmKernel._make_tma_atoms_and_tensors(
            initial_b,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[0],
        )
        tma_atom_c, tma_tensor_c = HopperWgmmaGroupedGemmKernel._make_tma_store_atoms_and_tensors(
            initial_c,
            self.epi_smem_layout_staged,
            self.epi_tile,
        )

        tile_sched_params, grid = HopperWgmmaGroupedGemmKernel._compute_grid(
            total_num_clusters, self.cluster_shape_mn, max_active_clusters
        )

        # Tensormap SMEM buffer: 3 descriptors × 128 bytes each, stored as Int64 words.
        self.size_tensormap_in_i64 = (
            0
            if self.tensormap_update_mode == utils.TensorMapUpdateMode.GMEM
            else HopperWgmmaGroupedGemmKernel.num_tensormaps
            * HopperWgmmaGroupedGemmKernel.bytes_per_tensormap
            // 8
        )

        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.epi_smem_layout_staged),
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c,
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            min_blocks_per_mp=1,
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """GPU device kernel for grouped GEMM.

        Warp specialization:
        - Warp group 0, warp 0: TMA loads for A and B, updates tensormaps A/B per group.
        - Warp groups 1+: WGMMA compute, epilogue (reg -> SMEM -> GMEM), updates tensormap C.
          When SMEM tensormap mode is active, warp groups 1+ also initialise tensormaps A/B.
        """
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch TMA descriptors into L1 for faster first-use.
        if warp_idx == 0:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_c)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        a_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=1
        )
        b_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=0
        )
        a_mcast_mask = a_mcast_mask if self.is_a_mcast else 0
        b_mcast_mask = b_mcast_mask if self.is_b_mcast else 0

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = cute.size_in_bytes(
            self.a_dtype, a_smem_layout
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout)

        # ── Shared memory allocation ──────────────────────────────────────────
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Unpack tensormap SMEM pointers (only used in SMEM mode).
        tensormap_a_smem_ptr = None
        tensormap_b_smem_ptr = None
        tensormap_c_smem_ptr = None
        if cutlass.const_expr(
            self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        ):
            base = storage.tensormap_buffer.data_ptr()
            tensormap_a_smem_ptr = base
            tensormap_b_smem_ptr = (
                base + HopperWgmmaGroupedGemmKernel.bytes_per_tensormap // 8
            )
            tensormap_c_smem_ptr = (
                tensormap_b_smem_ptr
                + HopperWgmmaGroupedGemmKernel.bytes_per_tensormap // 8
            )

        # ── Mainloop pipeline (A/B full/empty barriers) ───────────────────────
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread
        )
        mcast_size = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        consumer_arrive_cnt = (
            mcast_size * self.num_mma_warp_groups * self.num_warps_per_warp_group
        )
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, consumer_arrive_cnt
        )
        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=mainloop_pipeline_array_ptr,
            num_stages=self.ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=tma_copy_bytes,
            cta_layout_vmnk=cute.make_layout((1, *cta_layout_mnk.shape)),
            defer_sync=True,
        )

        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # ── Shared memory tensors ─────────────────────────────────────────────
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sC = storage.sC.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        # ── Partition global template tensors for TMA coordinate structure ────
        # The template tensor provides tile indices; actual addresses come from
        # the per-group TMA descriptor injected via tma_desc_ptr at load time.
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_(self.tile_shape_mnk, (None, 0, None)),
            (None, None, None),
        )
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_(self.tile_shape_mnk, (0, None, None)),
            (None, None, None),
        )
        gC_mnl = cute.local_tile(
            mC_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )

        # TMA partition for A (multicast along N in cluster).
        a_cta_layout = cute.make_layout(
            cute.slice_(cta_layout_mnk, (0, None, 0)).shape
        )
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sA, 0, 2),
            cute.group_modes(gA_mkl, 0, 2),
        )

        # TMA partition for B (multicast along M in cluster).
        b_cta_layout = cute.make_layout(
            cute.slice_(cta_layout_mnk, (None, 0, 0)).shape
        )
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sB, 0, 2),
            cute.group_modes(gB_nkl, 0, 2),
        )

        # ── MMA warp group partitioning ───────────────────────────────────────
        warp_group_idx = cute.arch.make_warp_uniform(
            tidx // self.num_threads_per_warp_group
        )
        mma_warp_group_thread_layout = cute.make_layout(
            self.num_mma_warp_groups, stride=self.num_threads_per_warp_group
        )
        thr_mma = tiled_mma.get_slice(
            mma_warp_group_thread_layout(
                warp_group_idx - self.num_dma_warp_groups
            )
        )
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)
        tCgC = thr_mma.partition_C(gC_mnl)
        acc_shape = tCgC.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        is_dma_warp_group = warp_group_idx < self.num_dma_warp_groups
        if is_dma_warp_group:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

        # ── Per-SM tensormap workspace ────────────────────────────────────────
        bid = cute.arch.block_idx()
        grid_dim = cute.arch.grid_dim()
        tensormap_workspace_idx = (
            bid[2] * grid_dim[1] * grid_dim[0] + bid[1] * grid_dim[0] + bid[0]
        )
        tensormap_manager = utils.TensorMapManager(
            self.tensormap_update_mode,
            HopperWgmmaGroupedGemmKernel.bytes_per_tensormap,
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

        if cutlass.const_expr(
            self.tensormap_update_mode == utils.TensorMapUpdateMode.SMEM
        ):
            tensormap_a_init_ptr = tensormap_a_smem_ptr
            tensormap_b_init_ptr = tensormap_b_smem_ptr
            tensormap_c_init_ptr = tensormap_c_smem_ptr
        else:
            tensormap_a_init_ptr = tensormap_a_ptr
            tensormap_b_init_ptr = tensormap_b_ptr
            tensormap_c_init_ptr = tensormap_c_ptr

        # Cluster tile shape used by the grouped scheduler.
        cluster_tile_shape_mnk = tuple(
            t * c for t, c in zip(self.tile_shape_mnk, (*self.cluster_shape_mn, 1))
        )

        # Persistent grouped tile scheduler. Each warp has an independent copy
        # (register state), both DMA and MMA paths iterate over the same tiles.
        tile_sched = utils.StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            bid,
            grid_dim,
            cluster_tile_shape_mnk,
            utils.create_initial_search_state(),
            group_count,
            problem_sizes_mnkl,
        )
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        # =====================================================================
        # DMA warp (warp 0): TMA loads + tensormap A/B updates per group
        # =====================================================================
        if warp_idx == self.load_warp_id and initial_work_tile_info.is_valid_tile:
            # If not delegating, this warp initialises tensormaps A/B directly.
            if cutlass.const_expr(self.delegate_tensormap_ab_init == False):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_init_ptr, self.load_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_init_ptr, self.load_warp_id
                )

            tensormap_init_done = cutlass.Boolean(False)
            last_group_idx = cutlass.Int32(-1)
            work_tile = initial_work_tile_info
            mainloop_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.ab_stage
            )

            while work_tile.is_valid_tile:
                info = work_tile.group_search_result
                cur_k_tile_cnt = info.cta_tile_count_k
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                cur_group_idx = info.group_idx

                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    if is_group_changed:
                        # Rebuild tensors for the new group so the TMA descriptor
                        # points to the correct global memory region.
                        real_tensor_a = self.make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.a_dtype,
                            (info.problem_shape_m, info.problem_shape_n, info.problem_shape_k),
                            strides_abc,
                            ptrs_abc,
                            0,
                        )
                        real_tensor_b = self.make_tensor_for_tensormap_update(
                            cur_group_idx,
                            self.b_dtype,
                            (info.problem_shape_m, info.problem_shape_n, info.problem_shape_k),
                            strides_abc,
                            ptrs_abc,
                            1,
                        )
                        if not tensormap_init_done:
                            if cutlass.const_expr(self.delegate_tensormap_ab_init):
                                self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_manager.fence_tensormap_initialization()
                            tensormap_init_done = True

                        tensormap_manager.update_tensormap(
                            (real_tensor_a, real_tensor_b),
                            (tma_atom_a, tma_atom_b),
                            (tensormap_a_ptr, tensormap_b_ptr),
                            self.load_warp_id,
                            (tensormap_a_smem_ptr, tensormap_b_smem_ptr),
                        )

                    mma_tile_coord_mnl = (
                        info.cta_tile_idx_m,
                        info.cta_tile_idx_n,
                        0,
                    )
                    tAgA_slice = tAgA[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    tBgB_slice = tBgB[
                        (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                    ]

                    mainloop_producer_state.reset_count()

                    if is_group_changed:
                        tensormap_manager.fence_tensormap_update(tensormap_a_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_b_ptr)

                    for k_tile in range(cur_k_tile_cnt):
                        mainloop_pipeline.producer_acquire(mainloop_producer_state)
                        tAgA_k = tAgA_slice[(None, mainloop_producer_state.count)]
                        tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]
                        tBgB_k = tBgB_slice[(None, mainloop_producer_state.count)]
                        tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                        cute.copy(
                            tma_atom_a,
                            tAgA_k,
                            tAsA_pipe,
                            tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                mainloop_producer_state
                            ),
                            mcast_mask=a_mcast_mask,
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_a_ptr, cute.AddressSpace.generic
                            ),
                        )
                        cute.copy(
                            tma_atom_b,
                            tBgB_k,
                            tBsB_pipe,
                            tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                mainloop_producer_state
                            ),
                            mcast_mask=b_mcast_mask,
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_b_ptr, cute.AddressSpace.generic
                            ),
                        )
                        mainloop_pipeline.producer_commit(mainloop_producer_state)
                        mainloop_producer_state.advance()
                else:
                    # Even when k_tile_cnt is 0, the init fence must complete.
                    if not tensormap_init_done:
                        if cutlass.const_expr(self.delegate_tensormap_ab_init):
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_manager.fence_tensormap_initialization()
                        tensormap_init_done = True

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            mainloop_pipeline.producer_tail(mainloop_producer_state)

        # =====================================================================
        # MMA warp groups: WGMMA compute + epilogue + tensormap C updates
        # =====================================================================
        if not is_dma_warp_group and initial_work_tile_info.is_valid_tile:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            # Initialise tensormaps A/B when delegated (SMEM mode).
            if cutlass.const_expr(self.delegate_tensormap_ab_init):
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_init_ptr, self.epi_store_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_init_ptr, self.epi_store_warp_id
                )
                self.tensormap_ab_init_barrier.arrive_and_wait()

            # Initialise tensormap C; this warp group always owns C updates.
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c, tensormap_c_init_ptr, self.epi_store_warp_id
            )
            tensormap_manager.fence_tensormap_initialization()

            # ── Epilogue setup ────────────────────────────────────────────────
            copy_atom_r2s = sm90_utils.get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )
            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(
                    self.c_layout.is_m_major_c(), 4
                ),
                self.c_dtype,
            )
            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)
            tiled_copy_r2s = cute.make_tiled_copy_S(copy_atom_r2s, tiled_copy_C_Atom)
            thr_copy_r2s = tiled_copy_r2s.get_slice(
                tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
            )
            tRS_sD = thr_copy_r2s.partition_D(sC)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)
            rD_shape = cute.shape(thr_copy_r2s.partition_S(sC))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            tRS_rD_out = cute.make_rmem_tensor(tRS_rD_layout.shape, self.c_dtype)
            size_tRS_rD = cute.size(tRS_rD)

            num_k_blocks = cute.size(tCrA, mode=[2])
            k_pipe_mmas = 1

            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mma_threads
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            work_tile = initial_work_tile_info
            last_group_idx = cutlass.Int32(-1)
            mainloop_consumer_read_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )
            mainloop_consumer_release_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )

            while work_tile.is_valid_tile:
                info = work_tile.group_search_result
                cur_group_idx = info.group_idx
                cur_k_tile_cnt = info.cta_tile_count_k
                is_group_changed = cur_group_idx != last_group_idx

                mma_tile_coord_mnl = (info.cta_tile_idx_m, info.cta_tile_idx_n, 0)
                gC_mnl_slice = gC_mnl[(None, None, *mma_tile_coord_mnl)]

                # Update tensormap C when the group changes.
                if is_group_changed:
                    real_tensor_c = self.make_tensor_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (info.problem_shape_m, info.problem_shape_n, info.problem_shape_k),
                        strides_abc,
                        ptrs_abc,
                        2,
                    )
                    tensormap_manager.update_tensormap(
                        (real_tensor_c,),
                        (tma_atom_c,),
                        (tensormap_c_ptr,),
                        self.epi_store_warp_id,
                        (tensormap_c_smem_ptr,),
                    )

                # ── WGMMA mainloop ────────────────────────────────────────────
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
                cute.nvgpu.warpgroup.fence()

                prologue_mma_cnt = min(k_pipe_mmas, cur_k_tile_cnt)
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accumulators,
                        )
                    cute.nvgpu.warpgroup.commit_group()
                    mainloop_consumer_read_state.advance()

                for k_tile in range(prologue_mma_cnt, cur_k_tile_cnt):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accumulators,
                        )
                    cute.nvgpu.warpgroup.commit_group()
                    cute.nvgpu.warpgroup.wait_group(k_pipe_mmas)
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()
                    mainloop_consumer_read_state.advance()

                cute.nvgpu.warpgroup.wait_group(0)
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # ── Epilogue: reg -> SMEM -> GMEM ─────────────────────────────
                # Ensure tensormap C update is visible before first store.
                if is_group_changed:
                    if warp_idx == self.epi_store_warp_id:
                        tensormap_manager.fence_tensormap_update(tensormap_c_ptr)

                tCgC_for_tma_partition = cute.zipped_divide(gC_mnl_slice, self.epi_tile)
                bSG_sD, bSG_gD = cpasync.tma_partition(
                    tma_atom_c,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sC, 0, 2),
                    tCgC_for_tma_partition,
                )
                epi_tile_num = cute.size(tCgC_for_tma_partition, mode=[1])
                epi_tile_shape = tCgC_for_tma_partition.shape[1]
                epi_tile_layout = cute.make_layout(
                    epi_tile_shape, stride=(epi_tile_shape[1], 1)
                )

                num_prev_epi_tiles = tile_sched.num_tiles_executed * epi_tile_num
                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.c_dtype))

                    epi_buffer = (num_prev_epi_tiles + epi_idx) % cute.size(
                        tRS_sD, mode=[3]
                    )
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD_out,
                        tRS_sD[(None, None, None, epi_buffer)],
                    )
                    cute.arch.fence_proxy("async.shared", space="cta")
                    self.epilog_sync_barrier.arrive_and_wait()

                    gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                    if warp_idx == self.epi_store_warp_id:
                        cute.copy(
                            tma_atom_c,
                            bSG_sD[(None, epi_buffer)],
                            bSG_gD[(None, gmem_coord)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_c_ptr, cute.AddressSpace.generic
                            ),
                        )
                        tma_store_pipeline.producer_commit()
                        tma_store_pipeline.producer_acquire()

                    self.epilog_sync_barrier.arrive_and_wait()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            tma_store_pipeline.producer_tail()

    @cute.jit
    def make_tensor_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_index: int,
    ):
        """Construct a per-group CuTe global tensor for TMA descriptor update.

        :param group_idx: Group index within the grouped GEMM.
        :param dtype: Element type of the tensor.
        :param problem_shape_mnk: (M, N, K) for the current group.
        :param strides_abc: Device tensor (num_groups, 3, 2) of strides.
        :param tensor_address_abc: Device tensor (num_groups, 3) of base pointers.
        :param tensor_index: 0=A, 1=B, 2=C.
        :return: A CuTe global tensor for the requested operand and group.
        """
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(f"dtype must be cutlass.Numeric, got {type(dtype)}")

        ptr_i64 = tensor_address_abc[(group_idx, tensor_index)]
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cute.AddressSpace.gmem, assumed_align=16
        )

        strides_gmem = strides_abc[(group_idx, tensor_index, None)]
        strides_reg = cute.make_rmem_tensor(
            cute.make_layout(2), strides_abc.element_type
        )
        cute.autovec_copy(strides_gmem, strides_reg)
        stride_mn = strides_reg[0]
        stride_k = strides_reg[1]
        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(tensor_index == 0):  # A: (M, K, 1)
            m, k = problem_shape_mnk[0], problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        elif cutlass.const_expr(tensor_index == 1):  # B: (N, K, 1)
            n, k = problem_shape_mnk[1], problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((n, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        else:  # C: (M, N, 1)
            m, n = problem_shape_mnk[0], problem_shape_mnk[1]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, n, c1), stride=(stride_mn, stride_k, c0)),
            )

    # ── Static helpers ────────────────────────────────────────────────────────

    @staticmethod
    def _compute_stages(
        tile_shape_mnk: tuple,
        a_dtype: type,
        b_dtype: type,
        epi_tile: tuple,
        c_dtype: type,
        smem_capacity: int,
        occupancy: int,
    ) -> tuple:
        a_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        b_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        ab_bytes_per_stage = (
            cute.size(a_shape) * a_dtype.width // 8
            + cute.size(b_shape) * b_dtype.width // 8
        )
        c_bytes_per_stage = cute.size(epi_tile) * c_dtype.width // 8
        epi_stage = 4
        epi_bytes = c_bytes_per_stage * epi_stage
        mbar_helpers_bytes = 1024
        ab_stage = (
            smem_capacity // occupancy - (mbar_helpers_bytes + epi_bytes)
        ) // ab_bytes_per_stage
        return ab_stage, epi_stage

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: tuple,
        epi_tile: tuple,
        a_dtype: type,
        a_layout,
        b_dtype: type,
        b_layout,
        ab_stage: int,
        c_dtype: type,
        c_layout,
        epi_stage: int,
    ) -> tuple:
        from cutlass.cute.nvgpu.warpgroup import OperandMajorMode

        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        a_is_k_major = (
            a_layout.sm90_mma_major_mode() == OperandMajorMode.K
        )
        b_is_k_major = (
            b_layout.sm90_mma_major_mode() == OperandMajorMode.K
        )
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]
        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(a_layout, a_dtype, a_major_mode_size),
            a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(b_layout, b_dtype, b_major_mode_size),
            b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        c_smem_shape = epi_tile
        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(c_layout, c_dtype, c_major_mode_size),
            c_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom,
            cute.append(c_smem_shape, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )

        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    @staticmethod
    def _compute_grid(
        total_num_clusters: int,
        cluster_shape_mn: tuple,
        max_active_clusters,
    ) -> tuple:
        problem_shape_ntile_mnl = (
            cluster_shape_mn[0],
            cluster_shape_mn[1],
            cutlass.Int32(total_num_clusters),
        )
        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (*cluster_shape_mn, 1)
        )
        grid = utils.StaticPersistentGroupTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        return tile_sched_params, grid

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged,
        smem_tile: tuple,
        mcast_dim: int,
    ) -> tuple:
        op = (
            cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cpasync.CopyBulkTensorTileG2SMulticastOp()
        )
        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cpasync.make_tiled_tma_atom(
            op, tensor, smem_layout, smem_tile, num_multicast=mcast_dim
        )
        return tma_atom, tma_tensor

    @staticmethod
    def _make_tma_store_atoms_and_tensors(
        tensor_c: cute.Tensor,
        epi_smem_layout_staged,
        epi_tile: tuple,
    ) -> tuple:
        epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(), tensor_c, epi_smem_layout, epi_tile
        )
        return tma_atom_c, tma_tensor_c


# ── Host-side helpers ─────────────────────────────────────────────────────────


def create_tensor_and_stride(
    l: int,
    mode0: int,
    mode1: int,
    is_mode0_major: bool,
    dtype: type,
    torch_tensor_cpu: torch.Tensor = None,
) -> tuple:
    """Allocate or reuse a CPU tensor and mirror it to the GPU as a CuTe tensor."""
    if torch_tensor_cpu is None:
        torch_tensor_cpu = cutlass_torch.matrix(l, mode0, mode1, is_mode0_major, dtype)
    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        torch_tensor_cpu, dtype, is_dynamic_layout=True, assumed_align=16
    )
    return (
        torch_tensor.data_ptr(),
        torch_tensor,
        cute_tensor,
        torch_tensor_cpu,
        torch_tensor.stride()[:-1],
    )


def create_tensors_for_all_groups(
    problem_sizes_mnkl: List[tuple],
    ab_dtype: type,
    c_dtype: type,
    a_major: str,
    b_major: str,
    c_major: str,
    torch_fp32_tensors_abc: List[List[torch.Tensor]] = None,
) -> tuple:
    """Create per-group GPU tensors and collect pointers/strides for the kernel."""
    new_torch_fp32_tensors_abc = (
        [] if torch_fp32_tensors_abc is None else torch_fp32_tensors_abc
    )
    torch_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    for group_idx, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        existing_a = (
            torch_fp32_tensors_abc[group_idx][0] if torch_fp32_tensors_abc else None
        )
        existing_b = (
            torch_fp32_tensors_abc[group_idx][1] if torch_fp32_tensors_abc else None
        )
        existing_c = (
            torch_fp32_tensors_abc[group_idx][2] if torch_fp32_tensors_abc else None
        )

        ptr_a, t_a, ct_a, fp32_a, stride_a = create_tensor_and_stride(
            l, m, k, a_major == "m", ab_dtype, existing_a
        )
        ptr_b, t_b, ct_b, fp32_b, stride_b = create_tensor_and_stride(
            l, n, k, b_major == "n", ab_dtype, existing_b
        )
        ptr_c, t_c, ct_c, fp32_c, stride_c = create_tensor_and_stride(
            l, m, n, c_major == "m", c_dtype, existing_c
        )

        if torch_fp32_tensors_abc is None:
            new_torch_fp32_tensors_abc.append([fp32_a, fp32_b, fp32_c])

        ptrs_abc.append([ptr_a, ptr_b, ptr_c])
        torch_tensors_abc.append([t_a, t_b, t_c])
        strides_abc.append([stride_a, stride_b, stride_c])
        cute_tensors_abc.append((ct_a, ct_b, ct_c))

    return ptrs_abc, torch_tensors_abc, cute_tensors_abc, strides_abc, new_torch_fp32_tensors_abc


def run(
    num_groups: int,
    problem_sizes_mnkl: List[tuple],
    host_problem_shape_available: bool,
    ab_dtype: type,
    c_dtype: type,
    acc_dtype: type,
    a_major: str,
    b_major: str,
    c_major: str,
    tile_shape_mn: tuple,
    cluster_shape_mn: tuple,
    tensormap_update_mode: utils.TensorMapUpdateMode,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Allocate tensors, compile and launch the grouped GEMM kernel, and verify results.

    :param use_cold_l2: Use circular buffer workspaces to keep L2 cold during benchmarking.
    :return: Kernel execution time in microseconds.
    """
    print("Running Hopper BF16 Grouped GEMM with:")
    print(f"  {num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"  Group {i}: M={m} N={n} K={k} L={l}")
    print(f"  AB dtype: {ab_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}")
    print(f"  Matrix majors — A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"  Tile shape (M,N): {tile_shape_mn}, Cluster shape (M,N): {cluster_shape_mn}")
    print(f"  Tensormap update mode: {tensormap_update_mode}")
    print(f"  Tolerance: {tolerance}, Skip ref check: {skip_ref_check}")

    # ── Dtype validation ──────────────────────────────────────────────────────
    if ab_dtype not in {cutlass.Float16, cutlass.BFloat16}:
        raise ValueError(f"Unsupported ab_dtype: {ab_dtype}")
    if c_dtype not in {cutlass.Float16, cutlass.BFloat16, cutlass.Float32}:
        raise ValueError(f"Unsupported c_dtype: {c_dtype}")
    if acc_dtype not in {cutlass.Float32, cutlass.Float16}:
        raise ValueError(f"Unsupported acc_dtype: {acc_dtype}")
    if ab_dtype == cutlass.BFloat16 and acc_dtype == cutlass.Float16:
        raise ValueError("BFloat16 inputs require Float32 accumulation on SM90")

    is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
    if (
        cluster_shape_mn[0] * cluster_shape_mn[1] > 4
        or not is_power_of_2(cluster_shape_mn[0])
        or not is_power_of_2(cluster_shape_mn[1])
    ):
        raise ValueError(f"Invalid cluster shape {cluster_shape_mn}")

    def check_16b_alignment(dtype, is_mode0_major, shape):
        idx = 0 if is_mode0_major else 1
        return shape[idx] % (16 * 8 // dtype.width) == 0

    for m, n, k, l in problem_sizes_mnkl:
        if l != 1:
            raise ValueError("l must be 1 for all groups")
        if (
            not check_16b_alignment(ab_dtype, a_major == "m", (m, k))
            or not check_16b_alignment(ab_dtype, b_major == "n", (n, k))
            or not check_16b_alignment(c_dtype, c_major == "m", (m, n))
        ):
            raise ValueError(
                f"Group {(m,n,k,l)}: contiguous dimension is not 16-byte aligned"
            )

    if not torch.cuda.is_available():
        raise RuntimeError("A CUDA GPU is required to run this example.")

    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        torch_fp32_tensors_abc,
    ) = create_tensors_for_all_groups(
        problem_sizes_mnkl, ab_dtype, c_dtype, a_major, b_major, c_major
    )

    # Minimum-size initial tensors — used only for TMA atom construction.
    alignment = 16
    min_ab = alignment * 8 // ab_dtype.width
    min_c = alignment * 8 // c_dtype.width
    initial_abc = [
        create_tensor_and_stride(1, min_ab, min_ab, a_major == "m", ab_dtype)[2],
        create_tensor_and_stride(1, min_ab, min_ab, b_major == "n", ab_dtype)[2],
        create_tensor_and_stride(1, min_c, min_c, c_major == "m", c_dtype)[2],
    ]

    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Per-SM tensormap workspace.
    tensormap_shape = (
        sm_count,
        HopperWgmmaGroupedGemmKernel.num_tensormaps,
        HopperWgmmaGroupedGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_gemm = HopperWgmmaGroupedGemmKernel(
        acc_dtype,
        tile_shape_mn,
        cluster_shape_mn,
        tensormap_update_mode=tensormap_update_mode,
    )

    tensor_of_dim_size_mnkl, _ = cutlass_torch.cute_tensor_like(
        torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    def compute_total_num_clusters(sizes, cluster_tile_mn):
        total = 0
        for m, n, _, _ in sizes:
            nm = (m + cluster_tile_mn[0] - 1) // cluster_tile_mn[0]
            nn = (n + cluster_tile_mn[1] - 1) // cluster_tile_mn[1]
            total += nm * nn
        return total

    cluster_tile_shape_mn = tuple(
        t * c for t, c in zip(tile_shape_mn, cluster_shape_mn)
    )

    if host_problem_shape_available:
        print("  Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, cluster_tile_shape_mn
        )
    else:
        print("  Problem shapes available only on device")
        total_num_clusters = max_active_clusters

    current_stream = cutlass_torch.default_stream()

    try:
        from cutlass import CUDA_VERSION
        opt_level = (
            3
            if CUDA_VERSION.major < 13
            or (CUDA_VERSION.major == 13 and CUDA_VERSION.minor < 1)
            else 2
        )
    except ImportError:
        opt_level = 3

    compiled_gemm = cute.compile(
        grouped_gemm,
        initial_abc[0],
        initial_abc[1],
        initial_abc[2],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
        options=f"--opt-level {opt_level}",
    )

    if not skip_ref_check:
        compiled_gemm(
            initial_abc[0],
            initial_abc[1],
            initial_abc[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_tensormap,
            current_stream,
        )
        torch.cuda.synchronize()

        for i, (a, b, c) in enumerate(torch_tensors_abc):
            ref = torch.einsum(
                "mkl,nkl->mnl",
                a.cpu().to(dtype=torch.float32),
                b.cpu().to(dtype=torch.float32),
            )
            print(f"  Checking group {i} … ", end="")
            torch.testing.assert_close(
                c.cpu(),
                ref.to(cutlass_torch.dtype(c_dtype)),
                atol=tolerance,
                rtol=1e-05,
            )
            print("OK")

    if iterations <= 0:
        return 0

    def generate_tensors():
        ptrs_w, tt_w, _, st_w, _ = create_tensors_for_all_groups(
            problem_sizes_mnkl,
            ab_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            torch_fp32_tensors_abc,
        )
        initial_w = [
            create_tensor_and_stride(1, min_ab, min_ab, a_major == "m", ab_dtype)[2],
            create_tensor_and_stride(1, min_ab, min_ab, b_major == "n", ab_dtype)[2],
            create_tensor_and_stride(1, min_c, min_c, c_major == "m", c_dtype)[2],
        ]
        strides_w, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(st_w, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )
        ptrs_w_t, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_w, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )
        tmap_w, _ = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )
        args = testing.JitArguments(
            initial_w[0],
            initial_w[1],
            initial_w[2],
            tensor_of_dim_size_mnkl,
            strides_w,
            ptrs_w_t,
            tmap_w,
            current_stream,
        )
        args.add_to_scope([tt_w])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.numel() * t.element_size()
            for group in torch_tensors_abc
            for t in group
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    runtime_s = exec_time / 1.0e6
    fmas = sum(m * n * k for m, n, k, _ in problem_sizes_mnkl)
    gflops = 2 * fmas / 1.0e9 / runtime_s
    print(f"  Average runtime : {exec_time / 1000:.3f} ms")
    print(f"  GFLOPS          : {gflops:.1f}")
    return exec_time


if __name__ == "__main__":

    def parse_ints(s: str) -> tuple:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError("Expected comma-separated integers.")

    def parse_tuples(s: str) -> List[tuple]:
        s = s.strip()
        if s.startswith("("):
            parts = s.strip("()").split("),(")
            return [tuple(int(x) for x in p.split(",")) for p in parts]
        raise argparse.ArgumentTypeError("Expected list of tuples like (m,n,k,l),...")

    parser = argparse.ArgumentParser(
        description="CuTeDSL BF16 Grouped GEMM for Hopper (SM90)."
    )
    parser.add_argument("--num_groups", type=int, default=3)
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_tuples,
        default=((128, 128, 128, 1), (512, 128, 128, 1), (128, 256, 128, 1)),
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Size grid exactly to required clusters (requires host-side problem shapes).",
    )
    parser.add_argument(
        "--tile_shape_mn",
        type=parse_ints,
        choices=[(128, 128), (128, 256), (128, 64), (64, 64)],
        default=(128, 128),
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 1),
    )
    parser.add_argument(
        "--tensormap_update_mode",
        type=str,
        choices=["GMEM", "SMEM"],
        default="SMEM",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--a_major", choices=["k", "m"], default="k")
    parser.add_argument("--b_major", choices=["k", "n"], default="k")
    parser.add_argument("--c_major", choices=["n", "m"], default="n")
    parser.add_argument("--tolerance", type=float, default=1e-01)
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--use_cold_l2", action="store_true", default=False)

    args = parser.parse_args()

    if len(args.problem_sizes_mnkl) != args.num_groups:
        parser.error("--problem_sizes_mnkl must contain exactly --num_groups tuples")

    tensormap_update_mode = (
        utils.TensorMapUpdateMode.GMEM
        if args.tensormap_update_mode == "GMEM"
        else utils.TensorMapUpdateMode.SMEM
    )

    torch.manual_seed(2025)
    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.host_problem_shape_available,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.tile_shape_mn,
        args.cluster_shape_mn,
        tensormap_update_mode,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
