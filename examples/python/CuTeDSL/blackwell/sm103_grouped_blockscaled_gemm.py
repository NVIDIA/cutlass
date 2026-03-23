# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import argparse
import functools
from typing import List, Type, Tuple, Union
from inspect import isclass
from dataclasses import dataclass, field

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils.blackwell_helpers as sm103_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.runtime import from_dlpack

"""
This example provides an experimental implementation of the SM103 grouped 3xFP4 blockscaled GEMM kernel.

Combines SM103 kernel internals from sm103_dense_blockscaled_gemm_persistent.py with
grouped scheduling from grouped_blockscaled_gemm.py.
"""


class Sm103GroupedBlockScaledGemmKernel:
    """SM103 grouped blockscaled GEMM kernel combining SM103 internals with grouped scheduling.

    :param sf_vec_size: Scalefactor vector size.
    :type sf_vec_size: int
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ):
        self.acc_dtype = cutlass.Float32
        self.sf_vec_size = sf_vec_size
        self.use_2cta_instrs = mma_tiler_mn[0] == 256
        self.cluster_shape_mn = cluster_shape_mn
        # K dimension is deferred in _setup_attributes
        self.mma_tiler = (*mma_tiler_mn, 1)
        # Grouped always uses TMA store
        self.use_tma_store = True

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.tensormap_update_mode = utils.TensorMapUpdateMode.SMEM

        self.occupancy = 1
        # Set specialized warp ids
        self.epilog_warp_id = (
            0,
            1,
            2,
            3,
        )
        self.mma_warp_id = 4
        self.tma_ab_warp_id = 5
        self.tma_sf_warp_id = 6
        self.threads_per_cta = 224  # 7 warps * 32

        # Set barriers
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=128,  # 4 epilogue warps * 32
        )
        self.tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=160,  # MMA + 4 epilogue warps * 32
        )
        # Barrier used by MMA/TMA warps to signal A/B tensormap initialization completion
        self.tensormap_ab_init_barrier = pipeline.NamedBarrier(
            barrier_id=4,
            num_threads=96,  # MMA + TMA_AB + TMA_SF * 32
        )
        self.tmem_dealloc_sync_bar_id = 3
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_103")
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols("sm_103")
        self.sf_buffers_per_tile_k = 4 if self.sf_vec_size == 16 else 2

    def _setup_attributes(self):
        """Set up kernel attributes that depend on runtime tensor inputs."""
        # Compute mma instruction shapes
        self.mma_inst_shape_mn = (self.mma_tiler[0], self.mma_tiler[1])

        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )

        tiled_mma = self.sm103_make_blockscaled_trivial_tiled_mma(
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        dummy_tiled_mma_sfb = self.sm103_make_blockscaled_trivial_tiled_mma(
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )

        # Compute mma/cluster/tile shapes
        self.mma_tiler = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            768,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        blk_mn = 128
        self.cta_n_sf = cute.round_up(cute.size(self.cta_tile_shape_mnk[1]), blk_mn)
        self.mma_sf_tiler = (
            self.cta_tile_shape_mnk[0],
            self.cta_n_sf,
            self.cta_tile_shape_mnk[2] // self.sf_buffers_per_tile_k,
        )

        self.sf_atom = self.Sm103BlockScaledBasicChunk(
            self.sf_vec_size, tiled_mma.op.a_major_mode
        ).layout

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (dummy_tiled_mma_sfb.thr_id.shape,),
        )

        # Compute cluster tile shape (needed for grouped scheduler)
        self.cluster_tile_shape_mnk = tuple(
            x * y for x, y in zip(self.cta_tile_shape_mnk, (*self.cluster_shape_mn, 1))
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1

        # Compute epilogue subtile
        self.epi_tile = sm103_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        self.num_acc_stage, self.num_ab_stage, self.num_sf_stage, self.num_c_stage = (
            self._compute_stages(
                tiled_mma,
                self.mma_tiler,
                self.epi_tile,
                self.c_dtype,
                self.c_layout,
                self.sf_dtype,
                self.sf_vec_size,
                self.smem_capacity,
                self.occupancy,
                self.use_tma_store,
            )
        )

        # Compute A/B/SFA/SFB/C shared memory layout
        self.a_smem_layout_staged = self.sm103_make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
        )

        # 3-stage for hardware circular buffer (TMA uses this)
        self.a_smem_layout_staged_tma = self.sm103_make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            3,
        )

        self.b_smem_layout_staged = self.sm103_make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
        )

        self.b_smem_layout_staged_tma = self.sm103_make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            3,
        )

        self.sfa_smem_layout_staged = self.sm103_make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_sf_stage,
        )

        self.sfb_smem_layout_staged = self.sm103_make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_sf_stage,
        )

        # Grouped always uses TMA store
        self.c_smem_layout_staged = sm103_utils.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
        )

        # Grouped always uses TMA store, so overlapping_accum = False
        self.overlapping_accum = False
        self.epi_tile_n = cute.size(self.epi_tile[1])

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        initial_sfa: cute.Tensor,
        initial_sfb: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_address_sfasfb: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        """Execute the grouped GEMM operation."""
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.sf_dtype = initial_sfa.element_type
        self.c_dtype = initial_c.element_type
        self.is_nvfp4_output = self.c_dtype is cutlass.Float4E2M1FN
        self.a_major_mode = utils.LayoutEnum.from_tensor(initial_a).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(initial_b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(initial_c)
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type mismatch: {self.a_dtype} != {self.b_dtype}")

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_a.shape, self.sf_vec_size
        )
        initial_sfa = cute.make_tensor(initial_sfa.iterator, sfa_layout)

        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_b.shape, self.sf_vec_size
        )
        initial_sfb = cute.make_tensor(initial_sfb.iterator, sfb_layout)

        tiled_mma = self.sm103_make_blockscaled_trivial_tiled_mma(
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        dummy_tiled_mma_sfb = self.sm103_make_blockscaled_trivial_tiled_mma(
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A (SM103 style with recast_tensor + adapt_layout)
        a_op = sm103_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.a_smem_layout_staged_tma
        )
        a_tensor_uint8 = cute.recast_tensor(initial_a, cutlass.Uint8)
        tma_atom_a, tma_tensor_a = cute.nvgpu.cpasync.make_tiled_tma_atom(
            a_op,
            a_tensor_uint8,
            a_smem_layout_tma_ready,
            (cute.size(tiled_mma.tv_layout_A[1][0]), 384),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for B
        b_op = sm103_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.b_smem_layout_staged_tma
        )
        b_tensor_uint8 = cute.recast_tensor(initial_b, cutlass.Uint8)
        tma_atom_b, tma_tensor_b = cute.nvgpu.cpasync.make_tiled_tma_atom(
            b_op,
            b_tensor_uint8,
            b_smem_layout_tma_ready,
            (cute.size(tiled_mma.tv_layout_B[1][0]), 384),
            self.cluster_shape_mn[0] // cute.size(tiled_mma.thr_id.shape),
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for SFA
        sfa_op = sm103_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        sfa_smem_layout_tma_ready = self.adapt_layout_for_tma_sf(sfa_smem_layout)
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfa_op,
            initial_sfa,
            sfa_smem_layout_tma_ready,
            (self.mma_sf_tiler[0], self.mma_sf_tiler[2]),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for SFB
        sfb_op = sm103_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        sfb_smem_layout_tma_ready = self.adapt_layout_for_tma_sf(sfb_smem_layout)
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfb_op,
            initial_sfb,
            sfb_smem_layout_tma_ready,
            (self.mma_sf_tiler[1], self.mma_sf_tiler[2]),
            self.cluster_shape_mn[0] // cute.size(dummy_tiled_mma_sfb.thr_id),
            internal_type=cutlass.Uint8,
        )

        # Setup TMA store for C (always created for grouped)
        epi_smem_layout = cute.slice_(self.c_smem_layout_staged, (None, None, 0))
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            initial_c,
            epi_smem_layout,
            self.epi_tile,
        )

        a_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.slice_(self.a_smem_layout_staged_tma, (None, None, None, 0)),
        )
        b_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.slice_(self.b_smem_layout_staged_tma, (None, None, None, 0)),
        )
        sfa_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.slice_(self.sfa_smem_layout_staged, (None, None, None, 0)),
        )
        sfb_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.slice_(self.sfb_smem_layout_staged, (None, None, None, 0)),
        )
        self.num_tma_load_bytes_ab = (a_copy_size + b_copy_size) * atom_thr_size
        self.num_tma_load_bytes_sf = (sfa_copy_size + sfb_copy_size) * atom_thr_size

        # Compute grid size (SM100 grouped version)
        self.tile_sched_params, grid = self._compute_grid(
            total_num_clusters, self.cluster_shape_mn, max_active_clusters
        )

        self.buffer_align_bytes = 1024
        self.size_tensormap_in_i64 = (
            Sm103GroupedBlockScaledGemmKernel.num_tensormaps
            * Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap
            // 8
        )

        # Define shared storage for kernel
        # Order: tensormap_buffer, sf_full, sf_empty, ab_full, ab_empty, acc_full, acc_empty,
        #        tmem_dealloc, tmem_holding, sC, sA, sB, sSFA, sSFB
        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            sf_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            sf_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.c_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.sfb_smem_layout_staged)
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
            tma_atom_sfa,
            tma_tensor_sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_c,
            tma_tensor_c,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensor_address_sfasfb,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            smem=self.shared_storage.size_in_bytes(),
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr,
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_address_sfasfb: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """GPU device kernel performing the SM103 grouped GEMM computation."""
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch tma desc
        if warp_idx == self.tma_ab_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_c)
        if warp_idx == self.tma_sf_warp_id:
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        # Setup cta/thread coordinates
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        # Alloc and init shared memory storage
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        tensormap_smem_ptr = storage.tensormap_buffer.data_ptr()
        tensormap_a_smem_ptr = tensormap_smem_ptr
        tensormap_b_smem_ptr = (
            tensormap_a_smem_ptr
            + Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8
        )
        tensormap_sfa_smem_ptr = (
            tensormap_b_smem_ptr
            + Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8
        )
        tensormap_sfb_smem_ptr = (
            tensormap_sfa_smem_ptr
            + Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8
        )
        tensormap_c_smem_ptr = (
            tensormap_sfb_smem_ptr
            + Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8
        )

        tmem_dealloc_mbar_ptr = storage.tmem_dealloc_mbar_ptr
        tmem_holding_buf = storage.tmem_holding_buf

        # Initialize mainloop ab_producer and ab_consumer (two separate pipelines)
        ab_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        ab_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_producer_group,
            consumer_group=ab_consumer_group,
            tx_count=self.num_tma_load_bytes_ab,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()

        # Initialize mainloop sf_producer and sf_consumer (separate pipeline)
        sf_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_sf_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        sf_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_sf_tma_producer
        )
        sf_producer, sf_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.sf_full_mbar_ptr.data_ptr(),
            num_stages=self.num_sf_stage,
            producer_group=sf_producer_group,
            consumer_group=sf_consumer_group,
            tx_count=self.num_tma_load_bytes_sf,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()

        # Initialize acc_pipeline (barrier) and states
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

        # Tensor memory dealloc barrier init (for 2cta)
        if use_2cta_instrs:
            if warp_idx == self.tma_ab_warp_id:
                num_tmem_dealloc_threads = 32
                with cute.arch.elect_one():
                    cute.arch.mbarrier_init(
                        tmem_dealloc_mbar_ptr, num_tmem_dealloc_threads
                    )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # Setup smem tensor A/B/SFA/SFB/C
        sC = storage.sC.get_tensor(
            c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
        )
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)

        # Compute multicast mask for A/B/SFA/SFB buffer full
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        sfa_full_mcast_mask = None
        sfb_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )

        # Local_tile partition global tensors (SM103 style)
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_((self.mma_tiler[0], self.mma_tiler[1], 384), (None, 0, None)),
            (None, None, None),
        )
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_((self.mma_tiler[0], self.mma_tiler[1], 384), (0, None, None)),
            (None, None, None),
        )
        gSFA_mkl = cute.local_tile(
            mSFA_mkl,
            cute.slice_(self.mma_sf_tiler, (None, 0, None)),
            (None, None, None),
        )
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_sf_tiler, (0, None, None)),
            (None, None, None),
        )
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )

        # Partition global tensor for TiledMMA (SM103 style)
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)

        # SM103-style tCgA with append_coalesce_layout
        tCgA_mkl_tmp = thr_mma.partition_A(gA_mkl)
        tCgA_layout = self.append_coalesce_layout(tCgA_mkl_tmp.layout)
        cta_tCgA = cute.make_tensor(tCgA_mkl_tmp.iterator, tCgA_layout)
        tCgA = cute.make_tensor(
            cta_tCgA.iterator,
            cute.tiled_divide(
                cta_tCgA.layout, (cute.size(tiled_mma.tv_layout_A[1][0]), 128)
            ),
        )

        tCgB_nkl_tmp = thr_mma.partition_B(gB_nkl)
        tCgB_layout = self.append_coalesce_layout(tCgB_nkl_tmp.layout)
        cta_tCgB = cute.make_tensor(tCgB_nkl_tmp.iterator, tCgB_layout)
        tCgB = cute.make_tensor(
            cta_tCgB.iterator,
            cute.tiled_divide(
                cta_tCgB.layout, (cute.size(tiled_mma.tv_layout_B[1][0]), 128)
            ),
        )

        # SM103-style tCgSFA (4-mode)
        tCgSFA = cute.make_tensor(
            gSFA_mkl.iterator,
            cute.tiled_divide(
                gSFA_mkl.layout, (self.mma_sf_tiler[0], self.mma_sf_tiler[2])
            ),
        )

        tCgSFB = cute.make_tensor(
            gSFB_nkl.iterator,
            cute.tiled_divide(
                gSFB_nkl.layout, (self.mma_sf_tiler[1], self.mma_sf_tiler[2])
            ),
        )

        tCgC = thr_mma.partition_C(gC_mnl)

        # Partition global/shared tensor for TMA load A/B (SM103 style)
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )

        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 1),
        )

        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 1),
        )

        # TMA partition for scale factor A (SM103 style, 4-mode tCgSFA)
        sfa_cta_layout = a_cta_layout
        tAsSFA, tAgSFA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfa,
            block_in_cluster_coord_vmnk[2],
            sfa_cta_layout,
            cute.group_modes(sSFA, 0, 3),
            cute.group_modes(tCgSFA, 0, 3),
        )
        tAsSFA_compact = cute.filter_zeros(tAsSFA)

        # TMA partition for scale factor B
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )
        tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB_compact = cute.filter_zeros(tBsSFB)

        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Cluster wait before tensor memory alloc
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # Get tensormap buffer address
        grid_dim = cute.arch.grid_dim()
        tensormap_workspace_idx = (
            bidz * grid_dim[1] * grid_dim[0] + bidy * grid_dim[0] + bidx
        )

        tensormap_manager = utils.TensorMapManager(
            utils.TensorMapUpdateMode.SMEM,
            Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap,
        )
        tensormap_a_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 0, None)].iterator
        )
        tensormap_b_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 1, None)].iterator
        )
        tensormap_sfa_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 2, None)].iterator
        )
        tensormap_sfb_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 3, None)].iterator
        )
        tensormap_c_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 4, None)].iterator
        )

        # Construct the grouped tile scheduler
        tile_sched = utils.StaticPersistentGroupTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            grid_dim,
            self.cluster_tile_shape_mnk,
            utils.create_initial_search_state(),
            group_count,
            problem_sizes_mnkl,
        )
        initial_work_tile_info = tile_sched.initial_work_tile_info()

        thr_id_size = cute.size(tiled_mma.thr_id.shape)

        #
        # Specialized TMA AB warp (warp 5)
        #
        if warp_idx == self.tma_ab_warp_id and initial_work_tile_info.is_valid_tile:
            buffers_per_k_tile = 3
            tensormap_init_done = cutlass.Boolean(False)
            last_group_idx = cutlass.Int32(-1)
            work_tile = initial_work_tile_info
            ab_producer.reset()
            peek_ab_empty_status = ab_producer.try_acquire()
            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                cta_tile_idx_m = grouped_gemm_cta_tile_info.cta_tile_idx_m
                cta_tile_idx_n = grouped_gemm_cta_tile_info.cta_tile_idx_n
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    if is_group_changed:
                        real_tensor_a = self.make_tensor_abc_for_tensormap_update(
                            cur_group_idx,
                            self.a_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            strides_abc,
                            tensor_address_abc,
                            0,
                        )
                        real_tensor_b = self.make_tensor_abc_for_tensormap_update(
                            cur_group_idx,
                            self.b_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            strides_abc,
                            tensor_address_abc,
                            1,
                        )
                        if not tensormap_init_done:
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_init_done = True
                        tensormap_manager.update_tensormap(
                            (real_tensor_a, real_tensor_b),
                            (tma_atom_a, tma_atom_b),
                            (tensormap_a_gmem_ptr, tensormap_b_gmem_ptr),
                            self.tma_ab_warp_id,
                            (tensormap_a_smem_ptr, tensormap_b_smem_ptr),
                        )

                    mma_tile_coord_mnl = (cta_tile_idx_m // thr_id_size, cta_tile_idx_n, 0)
                    tAgA_slice = tAgA[
                        (None, None, None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    tBgB_slice = tBgB[
                        (None, None, None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                    ]

                    if is_group_changed:
                        tensormap_manager.fence_tensormap_update(tensormap_a_gmem_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_b_gmem_ptr)

                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        for buffer in cutlass.range(buffers_per_k_tile, unroll_full=True):
                            ab_empty = ab_producer.acquire_and_advance(peek_ab_empty_status)
                            cute.copy(
                                tma_atom_a,
                                cute.group_modes(
                                    tAgA_slice[(None, None, buffer, k_tile)], 0, 2
                                ),
                                tAsA[(None, ab_empty.index)],
                                tma_bar_ptr=ab_empty.barrier,
                                mcast_mask=a_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_a_gmem_ptr, cute.AddressSpace.generic
                                ),
                            )
                            cute.copy(
                                tma_atom_b,
                                cute.group_modes(
                                    tBgB_slice[(None, None, buffer, k_tile)], 0, 2
                                ),
                                tBsB[(None, ab_empty.index)],
                                tma_bar_ptr=ab_empty.barrier,
                                mcast_mask=b_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_b_gmem_ptr, cute.AddressSpace.generic
                                ),
                            )
                            peek_ab_empty_status = cutlass.Boolean(1)
                            if not (
                                (k_tile == cur_k_tile_cnt - 1)
                                and (buffer == buffers_per_k_tile - 1)
                            ):
                                peek_ab_empty_status = ab_producer.try_acquire()
                else:
                    if not tensormap_init_done:
                        self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_init_done = True
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx
            ab_producer.tail()

        #
        # Specialized TMA SF warp (warp 6)
        #
        if warp_idx == self.tma_sf_warp_id and initial_work_tile_info.is_valid_tile:
            tensormap_init_done = cutlass.Boolean(False)
            last_group_idx = cutlass.Int32(-1)
            work_tile = initial_work_tile_info
            sf_producer.reset()
            peek_sf_empty_status = sf_producer.try_acquire()
            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                cta_tile_idx_m = grouped_gemm_cta_tile_info.cta_tile_idx_m
                cta_tile_idx_n = grouped_gemm_cta_tile_info.cta_tile_idx_n
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                if not is_k_tile_cnt_zero:
                    is_group_changed = cur_group_idx != last_group_idx
                    if is_group_changed:
                        real_tensor_sfa = self.make_tensor_sfasfb_for_tensormap_update(
                            cur_group_idx,
                            self.sf_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            tensor_address_sfasfb,
                            0,
                        )
                        real_tensor_sfb = self.make_tensor_sfasfb_for_tensormap_update(
                            cur_group_idx,
                            self.sf_dtype,
                            (
                                grouped_gemm_cta_tile_info.problem_shape_m,
                                grouped_gemm_cta_tile_info.problem_shape_n,
                                grouped_gemm_cta_tile_info.problem_shape_k,
                            ),
                            tensor_address_sfasfb,
                            1,
                        )
                        if not tensormap_init_done:
                            self.tensormap_ab_init_barrier.arrive_and_wait()
                            tensormap_init_done = True
                        tensormap_manager.update_tensormap(
                            (real_tensor_sfa, real_tensor_sfb),
                            (tma_atom_sfa, tma_atom_sfb),
                            (tensormap_sfa_gmem_ptr, tensormap_sfb_gmem_ptr),
                            self.tma_sf_warp_id,
                            (tensormap_sfa_smem_ptr, tensormap_sfb_smem_ptr),
                        )

                    # In TMA SF warp, mma_tile_coord_mnl[0] = cta_tile_idx_m (NOT divided)
                    mma_tile_coord_mnl = (cta_tile_idx_m, cta_tile_idx_n, 0)
                    tAgSFA_slice = tAgSFA[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    tBgSFB_slice = tBgSFB[
                        (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                    ]

                    if is_group_changed:
                        tensormap_manager.fence_tensormap_update(tensormap_sfa_gmem_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_sfb_gmem_ptr)

                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        for sf_stage in cutlass.range(
                            self.sf_buffers_per_tile_k, unroll_full=True
                        ):
                            sf_empty = sf_producer.acquire_and_advance(peek_sf_empty_status)
                            tAgSFA_compact = cute.filter_zeros(
                                tAgSFA_slice[
                                    (None, k_tile * self.sf_buffers_per_tile_k + sf_stage)
                                ]
                            )
                            tBgSFB_compact = cute.filter_zeros(
                                tBgSFB_slice[
                                    (None, k_tile * self.sf_buffers_per_tile_k + sf_stage)
                                ]
                            )
                            cute.copy(
                                tma_atom_sfa,
                                tAgSFA_compact,
                                tAsSFA_compact[(None, sf_empty.index)],
                                tma_bar_ptr=sf_empty.barrier,
                                mcast_mask=sfa_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfa_gmem_ptr, cute.AddressSpace.generic
                                ),
                            )
                            cute.copy(
                                tma_atom_sfb,
                                tBgSFB_compact,
                                tBsSFB_compact[(None, sf_empty.index)],
                                tma_bar_ptr=sf_empty.barrier,
                                mcast_mask=sfb_full_mcast_mask,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfb_gmem_ptr, cute.AddressSpace.generic
                                ),
                            )
                            peek_sf_empty_status = cutlass.Boolean(1)
                            if not (
                                k_tile == cur_k_tile_cnt - 1
                                and sf_stage == self.sf_buffers_per_tile_k - 1
                            ):
                                peek_sf_empty_status = sf_producer.try_acquire()
                else:
                    if not tensormap_init_done:
                        self.tensormap_ab_init_barrier.arrive_and_wait()
                        tensormap_init_done = True
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx
            sf_producer.tail()

        #
        # Specialized MMA warp (warp 4)
        #
        if warp_idx == self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            # Init tensormaps for A, B, SFA and SFB
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_a, tensormap_a_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_b, tensormap_b_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_sfa, tensormap_sfa_smem_ptr, self.mma_warp_id
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_sfb, tensormap_sfb_smem_ptr, self.mma_warp_id
            )
            # Indicate tensormap initialization has finished
            self.tensormap_ab_init_barrier.arrive_and_wait()

            # Wait for TMEM alloc
            self.tmem_alloc_barrier.arrive_and_wait()

            # Retrieve tensor memory ptr (direct, not via TmemAllocator)
            acc_tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Make SFA tmem tensor
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base),
                dtype=self.sf_dtype,
            )
            tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
            )

            MMA_M = self.cta_tile_shape_mnk[0]
            MMA_N_SF = self.cta_n_sf
            MMA_K_SF = self.cta_tile_shape_mnk[2] // 2
            mnBasicBlockShape = (32, 4)
            kBasicBlockShape_single = (self.sf_vec_size, 1)
            mma_iter_SFA_shape = (
                (mnBasicBlockShape, MMA_M // 128),
                kBasicBlockShape_single,
            )
            sSFA_iter_shape = (mma_iter_SFA_shape, 1, MMA_K_SF // self.sf_vec_size)
            sSFA_iter_layout = cute.make_layout(sSFA_iter_shape)
            mma_iter_SFB_shape = (
                (mnBasicBlockShape, MMA_N_SF // 128),
                kBasicBlockShape_single,
            )
            sSFB_iter_shape = (mma_iter_SFB_shape, 1, MMA_K_SF // self.sf_vec_size)
            sSFB_iter_layout = cute.make_layout(sSFB_iter_shape)

            tCtSFA_layout_mma = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma, self.mma_tiler, self.sf_vec_size, sSFA_iter_layout
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)
            tCtSFA_mma = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout_mma)

            # Make SFB tmem tensor
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr
                + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                + tcgen05.find_tmem_tensor_col_offset(tCtSFA),
                dtype=self.sf_dtype,
            )
            tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
            )
            tCtSFB_layout_mma = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma, self.mma_tiler, self.sf_vec_size, sSFB_iter_layout
            )
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)
            tCtSFB_mma = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout_mma)

            # Partition for S2T copy of SFA/SFB
            (
                tiled_copy_s2t_sfa,
                tCsSFA_compact_s2t,
                tCtSFA_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFA, tCtSFA)
            (
                tiled_copy_s2t_sfb,
                tCsSFB_compact_s2t,
                tCtSFB_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFB, tCtSFB)

            # Tile scheduling loop
            work_tile = initial_work_tile_info
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )
            MmasPerSfBuffer = 8 // self.sf_buffers_per_tile_k
            sf_stride = 6 if self.sf_vec_size == 16 else 3

            while work_tile.is_valid_tile:
                cur_group_idx = work_tile.group_search_result.group_idx
                problem_shape_k = work_tile.group_search_result.problem_shape_k

                cur_k_tile_cnt = (
                    problem_shape_k + self.cluster_tile_shape_mnk[2] - 1
                ) // self.cluster_tile_shape_mnk[2]
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0

                tCtAcc = tCtAcc_base[(None, 0, 0, acc_producer_state.index)]

                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                sf_consumer.reset()
                peek_sf_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_sf_full_status = sf_consumer.try_wait()

                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
                is_first_iteration = True

                if not is_k_tile_cnt_zero:
                    if is_leader_cta:
                        acc_pipeline.producer_acquire(acc_producer_state)

                for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                    if is_leader_cta:
                        # Conditionally load SFA/SFB for MMA0/MMA1
                        if 0 % MmasPerSfBuffer == 0:
                            sf_full = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t_stage_coord = (None, None, None, None, sf_full.index)
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[s2t_stage_coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[s2t_stage_coord],
                                tCtSFB_compact_s2t,
                            )
                            sf_full.release()
                            peek_sf_full_status = cutlass.Boolean(1)
                            peek_sf_full_status = sf_consumer.try_wait()

                        ab_full0 = ab_consumer.wait_and_advance(peek_ab_full_status)
                        peek_ab_full_status = cutlass.Boolean(1)
                        peek_ab_full_status = ab_consumer.try_wait()

                        if is_first_iteration:
                            is_first_iteration = False

                        # MMA0
                        k_block_coord_cur = (None, 0, 0, ab_full0.index)
                        k_block_coord_next = (None, 0, 0, ab_full0.index)
                        sf_kblock_coord = (None, None, 0 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                        # MMA1
                        k_block_coord_cur = (None, 0, 3, ab_full0.index)
                        k_block_coord_next = (None, 0, 0, ab_full0.index)
                        sf_kblock_coord = (None, None, 1 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        # Conditionally load SFA/SFB for MMA2/MMA3
                        if 2 % MmasPerSfBuffer == 0:
                            sf_full = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t_stage_coord = (None, None, None, None, sf_full.index)
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[s2t_stage_coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[s2t_stage_coord],
                                tCtSFB_compact_s2t,
                            )
                            sf_full.release()
                            peek_sf_full_status = cutlass.Boolean(1)
                            peek_sf_full_status = sf_consumer.try_wait()

                        ab_full1 = ab_consumer.wait_and_advance(peek_ab_full_status)
                        peek_ab_full_status = cutlass.Boolean(1)
                        peek_ab_full_status = ab_consumer.try_wait()

                        # MMA2
                        k_block_coord_cur = (None, 0, 6, ab_full0.index)
                        k_block_coord_next = (None, 0, 0, ab_full1.index)
                        sf_kblock_coord = (None, None, 2 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        ab_full0.release()

                        # MMA3
                        k_block_coord_cur = (None, 0, 1, ab_full1.index)
                        k_block_coord_next = (None, 0, 0, ab_full1.index)
                        sf_kblock_coord = (None, None, 3 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        # Conditionally load SFA/SFB for MMA4/MMA5
                        if 4 % MmasPerSfBuffer == 0:
                            sf_full = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t_stage_coord = (None, None, None, None, sf_full.index)
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[s2t_stage_coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[s2t_stage_coord],
                                tCtSFB_compact_s2t,
                            )
                            sf_full.release()
                            peek_sf_full_status = cutlass.Boolean(1)
                            peek_sf_full_status = sf_consumer.try_wait()

                        # MMA4
                        k_block_coord_cur = (None, 0, 4, ab_full1.index)
                        k_block_coord_next = (None, 0, 0, ab_full1.index)
                        sf_kblock_coord = (None, None, 4 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        ab_full2 = ab_consumer.wait_and_advance(peek_ab_full_status)
                        peek_ab_full_status = cutlass.Boolean(1)
                        if k_tile + 1 < cur_k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

                        # MMA5
                        k_block_coord_cur = (None, 0, 7, ab_full1.index)
                        k_block_coord_next = (None, 0, 0, ab_full2.index)
                        sf_kblock_coord = (None, None, 5 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        # Conditionally load SFA/SFB for MMA6/MMA7
                        if 6 % MmasPerSfBuffer == 0:
                            sf_full = sf_consumer.wait_and_advance(peek_sf_full_status)
                            s2t_stage_coord = (None, None, None, None, sf_full.index)
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[s2t_stage_coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[s2t_stage_coord],
                                tCtSFB_compact_s2t,
                            )
                            sf_full.release()
                            peek_sf_full_status = cutlass.Boolean(1)
                            if k_tile + 1 < cur_k_tile_cnt:
                                peek_sf_full_status = sf_consumer.try_wait()

                        ab_full1.release()

                        # MMA6
                        k_block_coord_cur = (None, 0, 2, ab_full2.index)
                        k_block_coord_next = (None, 0, 0, ab_full2.index)
                        sf_kblock_coord = (None, None, 6 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        # MMA7
                        k_block_coord_cur = (None, 0, 5, ab_full2.index)
                        k_block_coord_next = (None, 0, 0, ab_full2.index)
                        sf_kblock_coord = (None, None, 7 % MmasPerSfBuffer * sf_stride)
                        tiled_mma.set(
                            tcgen05.Field.SFA, tCtSFA_mma[sf_kblock_coord].iterator
                        )
                        tiled_mma.set(
                            tcgen05.Field.SFB, tCtSFB_mma[sf_kblock_coord].iterator
                        )
                        self.make_desc_and_call_mma(
                            tiled_mma,
                            tCtAcc,
                            sA[k_block_coord_cur],
                            sA[k_block_coord_next],
                            sB[k_block_coord_cur],
                            sB[k_block_coord_next],
                            tCtAcc,
                        )

                        ab_full2.release()

                if not is_k_tile_cnt_zero:
                    if is_leader_cta:
                        acc_pipeline.producer_commit(acc_producer_state)
                    acc_producer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            acc_pipeline.producer_tail(acc_producer_state)

        #
        # Specialized epilogue warps (warps 0-3)
        #
        if warp_idx < self.mma_warp_id and initial_work_tile_info.is_valid_tile:
            # Initialize tensormap for C
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c,
                tensormap_c_smem_ptr,
                self.epilog_warp_id[0],
            )
            # Alloc tensor memory buffer (warp 0 only)
            if warp_idx == self.epilog_warp_id[0]:
                cute.arch.alloc_tmem(
                    self.num_tmem_alloc_cols,
                    tmem_holding_buf,
                    is_two_cta=use_2cta_instrs,
                )

            # Bar sync for retrieve tensor memory ptr
            self.tmem_alloc_barrier.arrive_and_wait()

            # Retrieve tensor memory ptr (direct)
            acc_tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Partition for epilogue
            epi_tidx = tidx
            tiled_copy_t2r, tTR_tAcc_base, tTR_rAcc = (
                self.epilog_tmem_copy_and_partition(
                    epi_tidx, tCtAcc_base, tCgC, epi_tile, use_2cta_instrs
                )
            )

            tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
            tiled_copy_r2s, tRS_rC, tRS_sC = self.epilog_smem_copy_and_partition(
                tiled_copy_t2r, tTR_rC, epi_tidx, sC
            )
            tma_atom_c, bSG_sC, bSG_gC_partitioned = (
                self.epilog_gmem_copy_and_partition(
                    epi_tidx, tma_atom_c, tCgC, epi_tile, sC
                )
            )

            # Persistent tile scheduling loop
            work_tile = initial_work_tile_info

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilog_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage,
                producer_group=c_producer_group,
            )
            last_group_idx = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_gemm_cta_tile_info = work_tile.group_search_result
                cur_group_idx = grouped_gemm_cta_tile_info.group_idx
                cur_k_tile_cnt = grouped_gemm_cta_tile_info.cta_tile_count_k
                cta_tile_idx_m = grouped_gemm_cta_tile_info.cta_tile_idx_m
                cta_tile_idx_n = grouped_gemm_cta_tile_info.cta_tile_idx_n
                is_k_tile_cnt_zero = cur_k_tile_cnt == 0
                is_group_changed = cur_group_idx != last_group_idx

                if is_group_changed:
                    real_tensor_c = self.make_tensor_abc_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (
                            grouped_gemm_cta_tile_info.problem_shape_m,
                            grouped_gemm_cta_tile_info.problem_shape_n,
                            grouped_gemm_cta_tile_info.problem_shape_k,
                        ),
                        strides_abc,
                        tensor_address_abc,
                        2,
                    )
                    tensormap_manager.update_tensormap(
                        ((real_tensor_c),),
                        ((tma_atom_c),),
                        ((tensormap_c_gmem_ptr),),
                        self.epilog_warp_id[0],
                        (tensormap_c_smem_ptr,),
                    )

                mma_tile_coord_mnl = (
                    cta_tile_idx_m // thr_id_size,
                    cta_tile_idx_n,
                    0,
                )

                bSG_gC = bSG_gC_partitioned[
                    (None, None, None, *mma_tile_coord_mnl)
                ]

                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]

                if not is_k_tile_cnt_zero:
                    acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                if is_group_changed:
                    if warp_idx == self.epilog_warp_id[0]:
                        tensormap_manager.fence_tensormap_update(tensormap_c_gmem_ptr)

                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in range(subtile_cnt):
                    if not is_k_tile_cnt_zero:
                        tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        tRS_rC.store(acc_vec.to(self.c_dtype))
                    else:
                        tRS_rC.fill(0)

                    c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rC,
                        tRS_sC[(None, None, None, c_buffer)],
                    )
                    cute.arch.fence_proxy("async.shared", space="cta")
                    self.epilog_sync_barrier.arrive_and_wait()

                    if warp_idx == self.epilog_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, c_buffer)],
                            bSG_gC[(None, subtile_idx)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_c_gmem_ptr,
                                cute.AddressSpace.generic,
                            ),
                        )
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    self.epilog_sync_barrier.arrive_and_wait()

                if not is_k_tile_cnt_zero:
                    with cute.arch.elect_one():
                        acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            # Dealloc tensor memory
            if warp_idx == self.epilog_warp_id[0]:
                cute.arch.relinquish_tmem_alloc_permit(is_two_cta=use_2cta_instrs)
            self.epilog_sync_barrier.arrive_and_wait()
            if warp_idx == self.epilog_warp_id[0]:
                if use_2cta_instrs:
                    cute.arch.mbarrier_arrive(
                        tmem_dealloc_mbar_ptr, cta_rank_in_cluster ^ 1
                    )
                    cute.arch.mbarrier_wait(tmem_dealloc_mbar_ptr, 0)
                cute.arch.dealloc_tmem(
                    acc_tmem_ptr, self.num_tmem_alloc_cols, is_two_cta=use_2cta_instrs
                )
            c_pipeline.producer_tail()


    @cute.jit
    def make_tensor_abc_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_index: int,
    ):
        """Extract stride and tensor address for a given group and construct a global tensor for A, B or C."""
        ptr_i64 = tensor_address_abc[(group_idx, tensor_index)]
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(
                f"dtype must be a type of cutlass.Numeric, got {type(dtype)}"
            )
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cute.AddressSpace.gmem, assumed_align=16
        )

        strides_tensor_gmem = strides_abc[(group_idx, tensor_index, None)]
        strides_tensor_reg = cute.make_rmem_tensor(
            cute.make_layout(2),
            strides_abc.element_type,
        )
        cute.autovec_copy(strides_tensor_gmem, strides_tensor_reg)
        stride_mn = strides_tensor_reg[0]
        stride_k = strides_tensor_reg[1]
        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(tensor_index == 0):  # tensor A
            m = problem_shape_mnk[0]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        elif cutlass.const_expr(tensor_index == 1):  # tensor B
            n = problem_shape_mnk[1]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((n, k, c1), stride=(stride_mn, stride_k, c0)),
            )
        else:  # tensor C
            m = problem_shape_mnk[0]
            n = problem_shape_mnk[1]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, n, c1), stride=(stride_mn, stride_k, c0)),
            )

    @cute.jit
    def make_tensor_sfasfb_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        tensor_address_sfasfb: cute.Tensor,
        tensor_index: int,
    ):
        """Extract tensor address for a given group and construct a global tensor for SFA or SFB."""
        ptr_i64 = tensor_address_sfasfb[(group_idx, tensor_index)]
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(
                f"dtype must be a type of cutlass.Numeric, got {type(dtype)}"
            )
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cute.AddressSpace.gmem, assumed_align=16
        )

        c1 = cutlass.Int32(1)
        if cutlass.const_expr(tensor_index == 0):  # tensor SFA
            m = problem_shape_mnk[0]
            k = problem_shape_mnk[2]
            sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
                (m, k, c1), self.sf_vec_size
            )
            return cute.make_tensor(
                tensor_gmem_ptr,
                sfa_layout,
            )
        else:  # tensor SFB
            n = problem_shape_mnk[1]
            k = problem_shape_mnk[2]
            sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
                (n, k, c1), self.sf_vec_size
            )
            return cute.make_tensor(
                tensor_gmem_ptr,
                sfb_layout,
            )

    def mainloop_s2t_copy_and_partition(
        self,
        sSF: cute.Tensor,
        tSF: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for smem to tmem load for scale factor tensor (SM103 style with cute.append)."""
        # (MMA, MMA_MN, MMA_K, STAGE)
        tCsSF_compact = cute.filter_zeros(sSF)
        # (MMA, MMA_MN, MMA_K)
        tCtSF_compact = cute.filter_zeros(tSF)
        tCtSF_compact_copy = cute.make_tensor(
            tCtSF_compact.iterator,
            cute.append(
                cute.append(tCtSF_compact[(None, 0, 0)].layout, cute.make_layout((1))),
                cute.make_layout(1),
            ),
        )
        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact_copy)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t

    def epilog_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for tensor memory load (SM103 style)."""
        copy_atom_t2r = sm103_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.c_layout,
            self.c_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        tAcc_epi = cute.flat_divide(
            tAcc[((None, None), 0, 0, None)],
            epi_tile,
        )
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        gC_mnl_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    def epilog_smem_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for shared memory store (SM103 style)."""
        copy_atom_r2s = sm103_utils.get_smem_store_op(
            self.c_layout, self.c_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sC = thr_copy_r2s.partition_D(sC)
        tRS_rC = tiled_copy_r2s.retile(tTR_rC)
        return tiled_copy_r2s, tRS_rC, tRS_sC

    def epilog_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for global memory store (TMA store version)."""
        gC_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )

        tma_atom_c = atom
        sC_for_tma_partition = cute.group_modes(sC, 0, 2)
        gC_for_tma_partition = cute.group_modes(gC_epi, 0, 2)
        bSG_sC, bSG_gC = cpasync.tma_partition(
            tma_atom_c,
            0,
            cute.make_layout(1),
            sC_for_tma_partition,
            gC_for_tma_partition,
        )
        return tma_atom_c, bSG_sC, bSG_gC

    @staticmethod
    def make_desc_and_call_mma(
        tiled_mma: cute.TiledMma,
        d: cute.Tensor,
        sA_cur: cute.Tensor,
        sA_next: cute.Tensor,
        sB_cur: cute.Tensor,
        sB_next: cute.Tensor,
        c: cute.Tensor,
    ) -> None:
        """Specialized GEMM for circular-buffered A/B from SMEM (SM103 style)."""
        a_desc = tcgen05.make_umma_smem_desc(
            sA_cur.iterator,
            sA_cur.layout,
            "k" if tiled_mma.op.a_major_mode.name == "K" else "mn",
            next_src=sA_next.iterator,
        )
        b_desc = tcgen05.make_umma_smem_desc(
            sB_cur.iterator,
            sB_cur.layout,
            "k" if tiled_mma.op.b_major_mode.name == "K" else "mn",
            next_src=sB_next.iterator,
        )

        view_layout = cute.make_layout(1, stride=0)
        a_tensor = cute.make_tensor(a_desc, view_layout)
        b_tensor = cute.make_tensor(b_desc, view_layout)
        return cute.mma_atom_call(tiled_mma, d, a_tensor, b_tensor, c)

    @staticmethod
    def sm103_make_blockscaled_trivial_tiled_mma(
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        cta_group: tcgen05.CtaGroup,
        mma_tiler_mn: Tuple[int, int],
        a_source: tcgen05.OperandSource = tcgen05.OperandSource.SMEM,
    ) -> cute.TiledMma:
        """Create a blockscaled trivial tiled MMA for SM103 (3xFP4), K fixed to 96."""
        if sf_vec_size == 32:
            mma_op = tcgen05.SM103MmaMXF4Op(
                (*mma_tiler_mn, 96),
                cta_group,
                a_source,
            )
        elif sf_vec_size == 16:
            mma_op = tcgen05.SM103MmaMXF4NVF4Op(
                sf_dtype,
                (*mma_tiler_mn, 96),
                cta_group,
                a_source,
            )
        else:
            raise ValueError(
                f"Unsupported sf_vec_size: {sf_vec_size}. Expected 16 or 32."
            )
        return cute.make_tiled_mma(cute.make_mma_atom(mma_op))

    @staticmethod
    def sm103_make_smem_layout_a(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """Create the SMEM layout for operand A using K_SW128 and Uint8."""
        is_k_major = tiled_mma.op.a_major_mode == tcgen05.OperandMajorMode.K
        a_smem_layout_staged = tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(
                tcgen05.SmemLayoutAtomKind.K_SW128, cutlass.Uint8
            ),
            cute.append(
                (
                    (
                        mma_tiler_mnk[0]
                        // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
                        16,
                    ),
                    1,
                    8,
                ),
                num_stages,
            ),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )
        return a_smem_layout_staged

    @staticmethod
    def sm103_make_smem_layout_b(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """Create the SMEM layout for operand B using K_SW128 and Uint8."""
        is_k_major = tiled_mma.op.b_major_mode == tcgen05.OperandMajorMode.K
        b_smem_layout_staged = tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(
                tcgen05.SmemLayoutAtomKind.K_SW128, cutlass.Uint8
            ),
            cute.append(
                ((mma_tiler_mnk[1] // cute.size(tiled_mma.thr_id.shape), 16), 1, 8),
                num_stages,
            ),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )
        return b_smem_layout_staged

    @dataclass(frozen=True)
    class Sm103BlockScaledBasicChunk:
        """Basic scale-factor atom layout for SM103 BlockScaled MMA Ops."""

        sf_vec_size: int
        major_mode: tcgen05.OperandMajorMode = tcgen05.OperandMajorMode.K
        _layout: cute.Layout = field(init=False, repr=False)

        def __post_init__(self) -> None:
            if self.major_mode == tcgen05.OperandMajorMode.K:
                atom_shape = ((8, 4, 4), (self.sf_vec_size, 4))
                atom_stride = ((16, 128, 4), (0, 1))
            else:
                atom_shape = ((self.sf_vec_size, 4), (8, 4, 4))
                atom_stride = ((0, 1), (16, 128, 4))

            object.__setattr__(
                self, "_layout", cute.make_layout(shape=atom_shape, stride=atom_stride)
            )

        @property
        def layout(self) -> cute.Layout:
            return self._layout

    @staticmethod
    def sm103_make_smem_layout_sfa(
        tiled_mma: cute.TiledMma,
        mma_tiler: cute.Tile,
        sf_vec_size: int,
        num_stages: int,
    ) -> cute.Layout:
        """Make SMEM layout for SFA."""
        mma_shape_mk = tiled_mma.partition_shape_A((mma_tiler[0], mma_tiler[2]))
        sf_atom = Sm103GroupedBlockScaledGemmKernel.Sm103BlockScaledBasicChunk(
            sf_vec_size, tiled_mma.op.a_major_mode
        ).layout
        k_divisor = 4 if sf_vec_size == 16 else 2
        mma_sfa_tiler = (
            mma_shape_mk[0][0] * mma_shape_mk[1],
            mma_shape_mk[0][1] * mma_shape_mk[2] // k_divisor,
        )
        sfa_smem_atom_layout = cute.tiled_product(
            sf_atom,
            cute.make_layout(
                cute.shape_div(mma_sfa_tiler, cute.product_each(sf_atom.shape))
            ),
        )
        sfa_smem_layout_staged = cute.make_layout(
            shape=cute.append(sfa_smem_atom_layout.shape, num_stages),
            stride=cute.append(
                sfa_smem_atom_layout.stride,
                cute.size(cute.filter_zeros(sfa_smem_atom_layout)),
            ),
        )
        return sfa_smem_layout_staged

    @staticmethod
    def sm103_make_smem_layout_sfb(
        tiled_mma: cute.TiledMma,
        mma_tiler: cute.Tile,
        sf_vec_size: int,
        num_stages: int,
    ) -> cute.Layout:
        """Make SMEM layout for SFB."""
        sf_atom = Sm103GroupedBlockScaledGemmKernel.Sm103BlockScaledBasicChunk(
            sf_vec_size, tiled_mma.op.a_major_mode
        ).layout
        k_divisor = 4 if sf_vec_size == 16 else 2
        mma_sfb_tiler = (mma_tiler[1], mma_tiler[2] // k_divisor)
        if mma_sfb_tiler[0] == 128:
            sfb_smem_atom_layout = cute.tiled_product(
                sf_atom,
                cute.make_layout(
                    cute.shape_div(mma_sfb_tiler, cute.product_each(sf_atom.shape))
                ),
            )
        else:
            sf_k_major_atom256 = cute.make_layout(
                shape=(
                    (32, 4, 2),
                    (sf_vec_size, 4),
                ),
                stride=(
                    (16, 4, mma_sfb_tiler[1] // sf_vec_size // 4 * 512),
                    (0, 1),
                ),
            )
            sfb_smem_atom_layout = cute.tiled_product(
                sf_k_major_atom256,
                cute.make_layout(
                    cute.shape_div(
                        mma_sfb_tiler, cute.product_each(sf_k_major_atom256.shape)
                    )
                ),
            )

        sfb_smem_layout_staged = cute.make_layout(
            shape=cute.append(sfb_smem_atom_layout.shape, num_stages),
            stride=cute.append(
                sfb_smem_atom_layout.stride,
                cute.size(cute.filter_zeros(sfb_smem_atom_layout)),
            ),
        )
        return sfb_smem_layout_staged

    @staticmethod
    def _compute_stages(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        epi_tile: cute.Tile,
        c_dtype: Type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        smem_capacity: int,
        occupancy: int,
        use_tma_store: bool,
    ) -> Tuple[int, int, int, int]:
        """Computes the number of stages for A/B, SF, ACC, and C (SM103 version, 4 return values)."""
        # ACC stages
        num_acc_stage = 1 if mma_tiler[1] == 256 else 2

        # Default C stages
        num_c_stage = 2 if use_tma_store else 0

        # Calculate smem layout and size for one stage of A, B, SFA, SFB
        a_smem_layout_stage_one = (
            Sm103GroupedBlockScaledGemmKernel.sm103_make_smem_layout_a(
                tiled_mma,
                mma_tiler,
                1,
            )
        )
        b_smem_layout_staged_one = (
            Sm103GroupedBlockScaledGemmKernel.sm103_make_smem_layout_b(
                tiled_mma,
                mma_tiler,
                1,
            )
        )
        sfa_smem_layout_staged_one = (
            Sm103GroupedBlockScaledGemmKernel.sm103_make_smem_layout_sfa(
                tiled_mma,
                mma_tiler,
                sf_vec_size,
                1,
            )
        )
        sfb_smem_layout_staged_one = (
            Sm103GroupedBlockScaledGemmKernel.sm103_make_smem_layout_sfb(
                tiled_mma,
                mma_tiler,
                sf_vec_size,
                1,
            )
        )

        c_smem_layout_staged_one = sm103_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )

        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * num_c_stage

        ab_bytes_per_stage = cute.size_in_bytes(
            cutlass.Uint8, a_smem_layout_stage_one
        ) + cute.size_in_bytes(cutlass.Uint8, b_smem_layout_staged_one)
        sf_bytes_per_stage = cute.size_in_bytes(
            sf_dtype, sfa_smem_layout_staged_one
        ) + cute.size_in_bytes(sf_dtype, sfb_smem_layout_staged_one)

        # mbar_helpers_bytes accounts for tensormap buffer (5 * 128 bytes)
        mbar_helpers_bytes = 1024 + 5 * 128

        num_ab_stage = (
            smem_capacity // occupancy
            - (mbar_helpers_bytes + sf_bytes_per_stage + c_bytes)
        ) // ab_bytes_per_stage

        num_sf_stage = (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_ab_stage
            - occupancy * mbar_helpers_bytes
            - occupancy * c_bytes
        ) // (occupancy * sf_bytes_per_stage)

        # Refine epilogue stages
        if use_tma_store:
            num_c_stage += (
                smem_capacity
                - occupancy * ab_bytes_per_stage * num_ab_stage
                - occupancy * sf_bytes_per_stage * num_sf_stage
                - occupancy * mbar_helpers_bytes
                - occupancy * c_bytes
            ) // (occupancy * c_bytes_per_stage)

        return num_acc_stage, num_ab_stage, num_sf_stage, num_c_stage

    @staticmethod
    def _compute_grid(
        total_num_clusters: int,
        cluster_shape_mn: tuple[int, int],
        max_active_clusters: cutlass.Constexpr[int],
    ) -> tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int]]:
        """Compute tile scheduler parameters and grid shape (SM100 grouped version)."""
        problem_shape_ntile_mnl = (
            cluster_shape_mn[0],
            cluster_shape_mn[1],
            cutlass.Int32(total_num_clusters),
        )

        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (*cluster_shape_mn, 1)
        )

        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """Check if the dtypes and sf_vec_size are valid for SM103 (Float4E2M1FN only)."""
        is_valid = True

        # SM103 only supports Float4E2M1FN for A/B
        if ab_dtype != cutlass.Float4E2M1FN:
            is_valid = False

        if sf_vec_size not in {16, 32}:
            is_valid = False

        if sf_dtype not in {cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN}:
            is_valid = False

        if sf_dtype == cutlass.Float8E4M3FN and sf_vec_size == 32:
            is_valid = False

        if c_dtype not in {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }:
            is_valid = False

        return is_valid

    @staticmethod
    def is_valid_layouts(
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        """Check if layouts and dtypes are valid combinations."""
        is_valid = True

        if ab_dtype is cutlass.Float4E2M1FN and not (a_major == "k" and b_major == "k"):
            is_valid = False
        return is_valid

    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """Check if the mma tiler and cluster shape are valid."""
        is_valid = True
        if not mma_tiler_mn[0] in [128, 256]:
            is_valid = False
        if not mma_tiler_mn[1] in [128, 256]:
            is_valid = False
        if cluster_shape_mn[0] % (2 if mma_tiler_mn[0] == 256 else 1) != 0:
            is_valid = False
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            or cluster_shape_mn[0] > 4
            or cluster_shape_mn[1] > 4
            or not is_power_of_2(cluster_shape_mn[0])
            or not is_power_of_2(cluster_shape_mn[1])
        ):
            is_valid = False
        return is_valid

    @staticmethod
    def is_valid_tensor_alignment(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        """Check if the tensor alignment is valid for grouped problem sizes."""
        is_valid = True

        def check_contigous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        for m, n, k, l in problem_sizes_mnkl:
            if (
                not check_contigous_16B_alignment(ab_dtype, a_major == "m", (m, k, l))
                or not check_contigous_16B_alignment(
                    ab_dtype, b_major == "n", (n, k, l)
                )
                or not check_contigous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
            ):
                is_valid = False
        return is_valid

    @staticmethod
    def can_implement(
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        problem_sizes_mnkl: List[Tuple],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        """Check if the grouped SM103 GEMM can be implemented."""
        can_implement = True
        if not Sm103GroupedBlockScaledGemmKernel.is_valid_dtypes_and_scale_factor_vec_size(
            ab_dtype, sf_dtype, sf_vec_size, c_dtype
        ):
            can_implement = False
        if not Sm103GroupedBlockScaledGemmKernel.is_valid_layouts(
            ab_dtype, c_dtype, a_major, b_major, c_major
        ):
            can_implement = False
        if not Sm103GroupedBlockScaledGemmKernel.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler_mn, cluster_shape_mn
        ):
            can_implement = False
        if not Sm103GroupedBlockScaledGemmKernel.is_valid_tensor_alignment(
            problem_sizes_mnkl, ab_dtype, c_dtype, a_major, b_major, c_major
        ):
            can_implement = False
        return can_implement

    # Helper function for append and coalesce layout (SM103 style)
    @staticmethod
    def append_coalesce_layout(layout):
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(part1, part2)
        result = cute.append(result, layout[3])
        result = cute.append(result, layout[4])
        result = cute.append(result, layout[5])
        return result

    @staticmethod
    def adapt_layout_for_tma_ab(composed_layout):
        layout = composed_layout.outer
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        part3 = cute.append(part2, layout[3])
        result = cute.append(part1, part3)
        return cute.make_composed_layout(
            composed_layout.inner, composed_layout.offset, result
        )

    @staticmethod
    def adapt_layout_for_tma_sf(layout):
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(cute.group_modes(part1, 0, cute.rank(part1)), part2)
        return result

    # Class constants
    reserved_smem_bytes = 1024
    bytes_per_tensormap = 128
    num_tensormaps = 5
    # 5 tensormaps: A=idx0, B=idx1, SFA=idx2, SFB=idx3, C=idx4
    size_tensormap_in_i64 = 5 * 128 // 8  # = 80
    tensor_memory_management_bytes = 12



@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """Convert scale factor tensor from MKL layout to mma specification M(32x4xrest_m)xK(4xrest_k)xL layout"""
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def create_tensor_and_stride(
    l: int,
    mode0: int,
    mode1: int,
    is_mode0_major: bool,
    dtype: type[cutlass.Numeric],
    is_dynamic_layout: bool = True,
) -> tuple[int, torch.Tensor, cute.Tensor, torch.Tensor, tuple[int, int]]:
    """Create GPU tensor from either a new or existing CPU tensor."""
    torch_tensor_cpu = cutlass_torch.matrix(
        l,
        mode0,
        mode1,
        is_mode0_major,
        cutlass.Float32,
    )

    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        torch_tensor_cpu, dtype, is_dynamic_layout, assumed_align=16
    )

    stride = (1, mode0) if is_mode0_major else (mode1, 1)

    return (
        torch_tensor.data_ptr(),
        torch_tensor,
        cute_tensor,
        torch_tensor_cpu,
        stride,
    )


def create_tensors_abc_for_all_groups(
    problem_sizes_mnkl: List[tuple[int, int, int, int]],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
) -> tuple[
    List[List[int]],
    List[List[torch.Tensor]],
    List[tuple],
    List[List[tuple]],
    List[List[torch.Tensor]],
]:
    ref_torch_fp32_tensors_abc = []
    torch_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    for m, n, k, l in problem_sizes_mnkl:
        (
            ptr_a,
            torch_tensor_a,
            cute_tensor_a,
            ref_torch_fp32_tensor_a,
            stride_mk_a,
        ) = create_tensor_and_stride(l, m, k, a_major == "m", ab_dtype)

        (
            ptr_b,
            torch_tensor_b,
            cute_tensor_b,
            ref_torch_fp32_tensor_b,
            stride_nk_b,
        ) = create_tensor_and_stride(l, n, k, b_major == "n", ab_dtype)

        (
            ptr_c,
            torch_tensor_c,
            cute_tensor_c,
            ref_torch_fp32_tensor_c,
            stride_mn_c,
        ) = create_tensor_and_stride(l, m, n, c_major == "m", c_dtype)

        ref_torch_fp32_tensors_abc.append(
            [ref_torch_fp32_tensor_a, ref_torch_fp32_tensor_b, ref_torch_fp32_tensor_c]
        )

        ptrs_abc.append([ptr_a, ptr_b, ptr_c])
        torch_tensors_abc.append([torch_tensor_a, torch_tensor_b, torch_tensor_c])
        strides_abc.append([stride_mk_a, stride_nk_b, stride_mn_c])
        cute_tensors_abc.append(
            (
                cute_tensor_a,
                cute_tensor_b,
                cute_tensor_c,
            )
        )

    return (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_torch_fp32_tensors_abc,
    )


def create_scale_factor_tensor(l, mn, k, sf_vec_size, dtype):
    def ceil_div(a, b):
        return (a + b - 1) // b

    sf_k = max(1, ceil_div(k, sf_vec_size))
    ref_shape = (l, mn, sf_k)

    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        l,
        ceil_div(mn, atom_m[0] * atom_m[1]),
        ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )

    ref_permute_order = (1, 2, 0)
    mma_permute_order = (3, 4, 1, 5, 2, 0)

    ref_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
        ref_shape,
        torch.float32,
        permute_order=ref_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(
            min_val=1,
            max_val=3,
        ),
    )

    cute_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
        mma_shape,
        torch.float32,
        permute_order=mma_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(
            min_val=0,
            max_val=1,
        ),
    )

    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        from_dlpack(ref_f32_torch_tensor_cpu),
        from_dlpack(cute_f32_torch_tensor_cpu),
    )
    cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

    ref_f32_torch_tensor_cpu = (
        ref_f32_torch_tensor_cpu.permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(*ref_permute_order)
    )
    ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

    cute_tensor, cute_torch_tensor = cutlass_torch.cute_tensor_like(
        cute_f32_torch_tensor_cpu,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )

    cute_tensor = cutlass_torch.convert_cute_tensor(
        cute_f32_torch_tensor,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
    )
    ptr = cute_torch_tensor.data_ptr()
    return ref_f32_torch_tensor_cpu, ptr, cute_tensor, cute_torch_tensor


def create_tensors_sfasfb_for_all_groups(
    problem_sizes_mnkl: List[tuple[int, int, int, int]],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
) -> tuple[
    List[List[int]],
    List[List[torch.Tensor]],
    List[tuple],
    List[List[torch.Tensor]],
]:
    ptrs_sfasfb = []
    torch_tensors_sfasfb = []
    cute_tensors_sfasfb = []
    refs_sfasfb = []

    for m, n, k, l in problem_sizes_mnkl:
        sfa_ref, ptr_sfa, sfa_tensor, sfa_torch = create_scale_factor_tensor(
            l, m, k, sf_vec_size, sf_dtype
        )
        sfb_ref, ptr_sfb, sfb_tensor, sfb_torch = create_scale_factor_tensor(
            l, n, k, sf_vec_size, sf_dtype
        )
        ptrs_sfasfb.append([ptr_sfa, ptr_sfb])
        torch_tensors_sfasfb.append([sfa_torch, sfb_torch])
        cute_tensors_sfasfb.append(
            (
                sfa_tensor,
                sfb_tensor,
            )
        )
        refs_sfasfb.append([sfa_ref, sfb_ref])

    return (
        ptrs_sfasfb,
        torch_tensors_sfasfb,
        cute_tensors_sfasfb,
        refs_sfasfb,
    )


def create_initial_cute_tensors(
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    min_ab_size: int,
    min_sf_size: int,
    min_c_size: int,
) -> tuple[list[cute.Tensor], list[cute.Tensor]]:
    """Create minimal placeholder tensors used for JIT compilation."""
    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", ab_dtype)[2],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", ab_dtype)[2],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]
    initial_cute_tensors_sfasfb = [
        create_tensor_and_stride(1, min_sf_size, min_sf_size, a_major == "m", sf_dtype)[2],
        create_tensor_and_stride(1, min_sf_size, min_sf_size, b_major == "n", sf_dtype)[2],
    ]
    return initial_cute_tensors_abc, initial_cute_tensors_sfasfb


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Run SM103 grouped blockscaled GEMM example with specified configurations."""
    if num_groups != len(problem_sizes_mnkl):
        raise ValueError("num_groups must match len(problem_sizes_mnkl)")
    if any(l != 1 for _, _, _, l in problem_sizes_mnkl):
        raise ValueError("Grouped SM103 example requires l == 1 for all groups")

    print("Running SM103 Grouped BlockScaled GEMM test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(f"AB dtype: {ab_dtype}, SF dtype: {sf_dtype}, SF Vec size: {sf_vec_size}")
    print(f"C dtype: {c_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    if not Sm103GroupedBlockScaledGemmKernel.can_implement(
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_tiler_mn,
        cluster_shape_mn,
        problem_sizes_mnkl,
        a_major,
        b_major,
        c_major,
    ):
        raise TypeError(
            f"Unsupported testcase {ab_dtype}, {sf_dtype}, {sf_vec_size}, {c_dtype}, "
            f"{mma_tiler_mn}, {cluster_shape_mn}, {problem_sizes_mnkl}, {a_major}, {b_major}, {c_major}"
        )

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(2025)

    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_f32_torch_tensors_abc,
    ) = create_tensors_abc_for_all_groups(
        problem_sizes_mnkl,
        ab_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
    )
    (
        ptrs_sfasfb,
        torch_tensors_sfasfb,
        cute_tensors_sfasfb,
        refs_f32_torch_tensors_sfasfb,
    ) = create_tensors_sfasfb_for_all_groups(
        problem_sizes_mnkl,
        sf_dtype,
        sf_vec_size,
    )

    alignment = 16
    divisibility_ab = 32 if ab_dtype == cutlass.Float4E2M1FN else 16
    divisibility_c = 32 if c_dtype == cutlass.Float4E2M1FN else 16
    divisibility_sf = 32 if sf_dtype == cutlass.Float4E2M1FN else 16

    min_ab_size = alignment * 8 // ab_dtype.width
    div_mul_ab = (divisibility_ab + min_ab_size - 1) // min_ab_size
    min_ab_size = min_ab_size * div_mul_ab

    min_c_size = alignment * 8 // c_dtype.width
    div_mul_c = (divisibility_c + min_c_size - 1) // min_c_size
    min_c_size = min_c_size * div_mul_c

    min_sf_size = alignment * 8 // sf_dtype.width
    div_mul_sf = (divisibility_sf + min_sf_size - 1) // min_sf_size
    min_sf_size = min_sf_size * div_mul_sf

    initial_cute_tensors_abc, initial_cute_tensors_sfasfb = create_initial_cute_tensors(
        ab_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        min_ab_size,
        min_sf_size,
        min_c_size,
    )

    hardware_info = cutlass.utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    num_tensormap_buffers = sm_count
    tensormap_shape = (
        num_tensormap_buffers,
        Sm103GroupedBlockScaledGemmKernel.num_tensormaps,
        Sm103GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_blockscaled_gemm = Sm103GroupedBlockScaledGemmKernel(
        sf_vec_size,
        mma_tiler_mn,
        cluster_shape_mn,
    )

    (
        tensor_of_dim_size_mnkl,
        tensor_of_dim_size_mnkl_torch,
    ) = cutlass_torch.cute_tensor_like(
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

    tensor_of_ptrs_sfasfb, tensor_of_ptrs_sfasfb_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_sfasfb, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    def compute_total_num_clusters(
        problem_sizes_mnkl: List[tuple[int, int, int, int]],
        cluster_tile_shape_mn: tuple[int, int],
    ) -> int:
        total_num_clusters = 0
        for m, n, _, _ in problem_sizes_mnkl:
            num_clusters_mn = tuple(
                (x + y - 1) // y for x, y in zip((m, n), cluster_tile_shape_mn)
            )
            total_num_clusters += functools.reduce(lambda x, y: x * y, num_clusters_mn)
        return total_num_clusters

    def compute_cluster_tile_shape(
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
    ) -> tuple[int, int]:
        cta_tile_shape_mn = [128, mma_tiler_mn[1]]
        return tuple(x * y for x, y in zip(cta_tile_shape_mn, cluster_shape_mn))

    cluster_tile_shape_mn = compute_cluster_tile_shape(mma_tiler_mn, cluster_shape_mn)

    current_stream = cutlass_torch.default_stream()

    if host_problem_shape_available:
        print("Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, cluster_tile_shape_mn
        )
    else:
        print("Problem shapes available only on device")
        total_num_clusters = max_active_clusters

    compiled_grouped_gemm = cute.compile(
        grouped_blockscaled_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        initial_cute_tensors_sfasfb[0],
        initial_cute_tensors_sfasfb[1],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        tensor_of_ptrs_sfasfb,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
        options=f"--opt-level 2",
    )

    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            initial_cute_tensors_sfasfb[0],
            initial_cute_tensors_sfasfb[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_ptrs_sfasfb,
            tensor_of_tensormap,
            current_stream,
        )
        print("Verifying results...")

        for i, (
            (a_ref, b_ref, c_ref),
            (sfa_ref, sfb_ref),
            (a_tensor, b_tensor, c_tensor),
            (m, n, k, l),
        ) in enumerate(
            zip(
                ref_f32_torch_tensors_abc,
                refs_f32_torch_tensors_sfasfb,
                cute_tensors_abc,
                problem_sizes_mnkl,
            )
        ):
            ref_res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
            ref_res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
            ref = torch.einsum("mkl,nkl->mnl", ref_res_a, ref_res_b)

            print(f"checking group {i}")
            c_ref_device = c_ref.cuda()

            cute.testing.convert(
                c_tensor,
                from_dlpack(c_ref_device, assumed_align=16).mark_layout_dynamic(
                    leading_dim=(1 if c_major == "n" else 0)
                ),
            )

            c_ref = c_ref_device.cpu()

            if c_dtype in (cutlass.Float32, cutlass.Float16, cutlass.BFloat16):
                torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)
            elif c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
                ref_f8_ = torch.empty(
                    *(l, m, n), dtype=torch.uint8, device="cuda"
                ).permute(1, 2, 0)
                ref_f8 = from_dlpack(ref_f8_, assumed_align=16).mark_layout_dynamic(
                    leading_dim=1
                )
                ref_f8.element_type = c_dtype
                ref_device = ref.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
                ref_tensor = from_dlpack(
                    ref_device, assumed_align=16
                ).mark_layout_dynamic(leading_dim=1)
                cute.testing.convert(ref_tensor, ref_f8)
                cute.testing.convert(ref_f8, ref_tensor)
                ref = ref_device.cpu()
                torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)

    def generate_tensors():
        (
            ptrs_abc_workspace,
            torch_tensors_abc_workspace,
            cute_tensors_abc_workspace,
            strides_abc_workspace,
            _,
        ) = create_tensors_abc_for_all_groups(
            problem_sizes_mnkl,
            ab_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
        )

        (
            ptrs_sfasfb_workspace,
            torch_tensors_sfasfb_workspace,
            cute_tensors_sfasfb_workspace,
            _,
        ) = create_tensors_sfasfb_for_all_groups(
            problem_sizes_mnkl,
            sf_dtype,
            sf_vec_size,
        )

        (
            initial_cute_tensors_abc_workspace,
            initial_cute_tensors_sfasfb_workspace,
        ) = create_initial_cute_tensors(
            ab_dtype,
            sf_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            min_ab_size,
            min_sf_size,
            min_c_size,
        )

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

        tensor_of_ptrs_sfasfb_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_sfasfb_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensormap_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )

        args = cute.testing.JitArguments(
            initial_cute_tensors_abc_workspace[0],
            initial_cute_tensors_abc_workspace[1],
            initial_cute_tensors_abc_workspace[2],
            initial_cute_tensors_sfasfb_workspace[0],
            initial_cute_tensors_sfasfb_workspace[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc_workspace,
            tensor_of_ptrs_abc_workspace,
            tensor_of_ptrs_sfasfb_workspace,
            tensormap_workspace,
            current_stream,
        )
        args.add_to_scope([torch_tensors_abc_workspace, torch_tensors_sfasfb_workspace])
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
                    for group_tensors in torch_tensors_abc + torch_tensors_sfasfb
                ]
            )
            + tensor_of_strides_abc_torch.numel() * tensor_of_strides_abc_torch.element_size()
            + tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            + tensor_of_ptrs_sfasfb_torch.numel() * tensor_of_ptrs_sfasfb_torch.element_size()
            + tensor_of_tensormap_torch.numel() * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = cute.testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = cute.testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    runtime_s = exec_time / 1.0e6
    fmas = 0
    for group in range(num_groups):
        [M, N, K, _] = problem_sizes_mnkl[group]
        fmas += M * N * K
    flop = 2 * fmas
    gflop = flop / 1.0e9
    gflops = gflop / runtime_s

    print("Average Runtime : ", exec_time / 1000, "ms")
    print("GFLOPS          : ", gflops)

    return exec_time


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_comma_separated_tuples(s: str) -> List[tuple[int, ...]]:
        if s.strip().startswith("("):
            tuples = s.strip("()").split("),(")
            result = []
            tuple_len = None

            for t in tuples:
                nums = [int(x.strip()) for x in t.split(",")]

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

    parser = argparse.ArgumentParser(
        description="Example of SM103 Grouped BlockScaled GEMM on Blackwell."
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=2,
        help="Number of groups",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=((128, 128, 128, 1), (128, 128, 128, 1)),
        help="a tuple of problem sizes for each group (comma-separated tuples)",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Enable the compute of grid based upon host problem shape",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
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

    args = parser.parse_args()

    if (
        len(args.problem_sizes_mnkl) != 0
        and len(args.problem_sizes_mnkl) != args.num_groups
    ):
        parser.error("--problem_sizes_mnkl must contain exactly num_groups tuples")

    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l must be 1 for all groups")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.host_problem_shape_available,
        args.ab_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
