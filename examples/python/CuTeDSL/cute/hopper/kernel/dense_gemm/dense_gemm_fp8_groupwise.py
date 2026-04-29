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

"""
Hopper FP8 GEMM with groupwise (per-row A) scaling, ported from CUTLASS
Example 67's groupwise variant
(67_hopper_fp8_warp_specialized_gemm_with_groupwise_scaling).

The kernel computes:

    D = scale_d * relu(alpha * scale_a * scale_b * accum)

    accum[m, n] = sum_k  SFA[m, k] * SFB[n // 128, k]
                          * (A[m, k*128:(k+1)*128] @ B[k*128:(k+1)*128, n])

ScaleGranularityM = 1: one Float32 scale factor per M row per K-tile for A,
plus one per 128-column block of B per K-tile (SFB). The per-row SFA is
applied per accumulator element via a coordinate tensor that maps each
WGMMA register fragment to its absolute M row, so the scale lookup does
not depend on the WGMMA register layout.

Pipeline (warp-specialized, cooperative; one DMA + two MMA warpgroups):
  - DMA warpgroup: TMA loads A and B into a multi-stage SMEM ring.
  - MMA warpgroups: WGMMA per K-tile, scale by SFA * SFB and accumulate,
    apply alpha/scale_a/scale_b/scale_d + ReLU epilogue, R2S + TMA store D.

Run:

    python examples/python/CuTeDSL/hopper/dense_gemm_fp8_groupwise.py \\
        --mnkl 2816,3072,16384,1 --cluster_shape_mn 1,2 \\
        --alpha 1.0 --scale_a 1.0 --scale_b 1.0 --scale_d 1.0 \\
        --raster_order along_m --swizzle_size 2

Constraints:
  - A/B: FP8 E4M3FN, K-major. D: BFloat16, N-major. SFA/SFB: Float32.
  - Accumulator: Float32.
  - Tile shape fixed at (256, 128, 128); cooperative atom layout (2, 1, 1).
  - Cluster shape M/N: positive power of two, total cluster size <= 4.
  - M, N, K must all be multiples of 128.
"""

import argparse
import math
from typing import Tuple, Type

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from cutlass.torch import TensorInitType

SCALE_GRAN_N = 128  # blockwise B scaling
SCALE_GRAN_K = 128  # K-tile granularity (matches MMA K-tile size)


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def _parse_ints(s: str):
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError("Expected comma-separated integers.")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Hopper FP8 GEMM with groupwise (per-row A) scaling "
                    "(port of CUTLASS Example 67 groupwise variant)."
    )
    parser.add_argument("--mnkl", type=_parse_ints, default=(2816, 3072, 16384, 1))
    parser.add_argument(
        "--cluster_shape_mn", type=_parse_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 2),
    )
    parser.add_argument("--swizzle_size", type=int, default=2)
    parser.add_argument(
        "--raster_order", choices=["along_m", "along_n"], default="along_m"
    )
    parser.add_argument("--alpha",   type=float, default=1.0)
    parser.add_argument("--scale_a", type=float, default=1.0)
    parser.add_argument("--scale_b", type=float, default=1.0)
    parser.add_argument("--scale_d", type=float, default=1.0)
    parser.add_argument("--tolerance", type=float, default=5e-2)
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--use_cold_l2", action="store_true", default=False)

    args = parser.parse_args()
    if len(args.mnkl) != 4:
        parser.error("--mnkl must have 4 values")
    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must have 2 values")
    return args


# ---------------------------------------------------------------------------
# Kernel class
# ---------------------------------------------------------------------------

class HopperFP8GroupwiseGemmKernel:
    """
    Hopper FP8 GEMM with groupwise (per-row A) scaling.

    Computes:
        D = scale_d * relu(alpha * scale_a * scale_b * accum)
    where accum uses per-row SFA and blockwise SFB (see module docstring).

    Tile shape is fixed at (256, 128, 128) with cooperative atom_layout (2, 1, 1).

    :param cluster_shape_mn: Cluster shape (M, N).
    :param swizzle_size: Swizzle factor for CTA rasterisation (1, 2, 4, or 8).
    :param raster_along_m: If True, rasterise along M; otherwise along N.
    """

    def __init__(
        self,
        cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_along_m: bool,
    ):
        self.acc_dtype = cutlass.Float32
        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m

        # Tile shape: fixed (256, 128, K).  K filled in by _setup_attributes.
        self.tile_shape_mnk = (256, 128, 1)
        # Always cooperative for 256-wide tiles
        self.atom_layout_mnk = (2, 1, 1)

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
        self.load_warp_id = 0
        self.epi_store_warp_id = (
            self.num_dma_warp_groups * self.num_warps_per_warp_group
        )
        self.load_register_requirement = 40
        self.mma_register_requirement = 232
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_90")

        self.ab_stage = None
        self.epi_stage = None
        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None
        self.shared_storage = None
        self.buffer_align_bytes = 1024

        self.num_mma_threads = (
            self.num_mma_warp_groups * self.num_threads_per_warp_group
        )
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=self.num_mma_threads
        )

    # ------------------------------------------------------------------
    # Host-side setup helpers
    # ------------------------------------------------------------------

    def _setup_attributes(self):
        """Derive shapes and layouts that depend on input tensor types."""
        self.tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_layout.sm90_mma_major_mode(),
            self.b_layout.sm90_mma_major_mode(),
            self.acc_dtype,
            self.atom_layout_mnk,
            tiler_mn=(64, self.tile_shape_mnk[1]),
        )
        # Tile K = 4 * MMA instruction K (matches the WGMMA pipelining used
        # for FP8 below).
        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        self.tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.tile_shape_mnk[1],
            mma_inst_shape_k * 4,
        )

        self.cta_layout_mnk = cute.make_layout((*self.cluster_shape_mn, 1))
        self.num_mcast_ctas_a = self.cluster_shape_mn[1]
        self.num_mcast_ctas_b = self.cluster_shape_mn[0]
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Cooperative epilogue tile
        self.epi_tile = self._sm90_compute_tile_shape_or_override(
            self.tile_shape_mnk, self.c_dtype, is_cooperative=True
        )

        self.ab_stage, self.epi_stage = self._compute_stages(
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
        ) = self._make_smem_layouts(
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

    # ------------------------------------------------------------------
    # JIT entry point
    # ------------------------------------------------------------------

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,       # (M, K, L) FP8 E4M3FN, K-major
        b: cute.Tensor,       # (N, K, L) FP8 E4M3FN, K-major
        sfa: cute.Tensor,     # (M, K//128, L) Float32 per-row scales for A
        sfb: cute.Tensor,     # (N//128, K//128, L) Float32 blockwise scales for B
        d: cute.Tensor,       # (M, N, L) BFloat16, N-major (output)
        alpha:   cute.Tensor, # scalar Float32
        scale_a: cute.Tensor, # per-tensor epilogue scale for A
        scale_b: cute.Tensor, # per-tensor epilogue scale for B
        scale_d: cute.Tensor, # per-tensor epilogue scale for D
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.c_dtype = d.element_type   # BFloat16
        self.a_layout = utils.LayoutEnum.from_tensor(a)
        self.b_layout = utils.LayoutEnum.from_tensor(b)
        self.c_layout = utils.LayoutEnum.from_tensor(d)

        self._setup_attributes()

        tma_atom_a, tma_tensor_a = self._make_tma_atoms_and_tensors(
            a,
            self.a_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[1],
        )
        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            b,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[0],
        )
        tma_atom_d, tma_tensor_d = self._make_tma_store_atoms_and_tensors(
            d,
            self.epi_smem_layout_staged,
            self.epi_tile,
        )

        tile_sched_params, grid = self._compute_grid(
            d,
            self.tile_shape_mnk,
            self.cluster_shape_mn,
            self.swizzle_size,
            self.raster_along_m,
            max_active_clusters,
        )

        @cute.struct
        class SharedStorage:
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[self.a_dtype, cute.cosize(self.a_smem_layout_staged)],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[self.b_dtype, cute.cosize(self.b_smem_layout_staged)],
                self.buffer_align_bytes,
            ]
            sD: cute.struct.Align[
                cute.struct.MemRange[self.c_dtype, cute.cosize(self.epi_smem_layout_staged)],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        self.kernel(
            tma_atom_a, tma_tensor_a,
            tma_atom_b, tma_tensor_b,
            tma_atom_d, tma_tensor_d,
            sfa, sfb,
            alpha, scale_a, scale_b, scale_d,
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            min_blocks_per_mp=1,
            stream=stream,
        )

    # ------------------------------------------------------------------
    # GPU device kernel
    # ------------------------------------------------------------------

    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        mSFA: cute.Tensor,     # (M, K//128, L) Float32, per-row scales for A
        mSFB: cute.Tensor,     # (N//128, K//128, L) Float32, blockwise scales for B
        alpha:   cute.Tensor,
        scale_a: cute.Tensor,
        scale_b: cute.Tensor,
        scale_d: cute.Tensor,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """
        Warp-specialised groupwise FP8 GEMM kernel.

        DMA warpgroup  : TMA loads for A and B.
        MMA warpgroups : per-K-tile WGMMA + per-row-SFA scale-and-accumulate + epilogue.

        Groupwise accumulation loop (one iteration per K-tile of width 128):
            accum_temp = A_tile @ B_tile          (WGMMA, zeros accum_temp first)
            for each accumulator element (r1, r2, v) at M-row m:
                accum[r1,r2,v] += SFA[m, k] * SFB[n//128, k] * accum_temp[r1,r2,v]

        Epilogue (no C residual):
            pre_act = alpha * scale_a * scale_b * accum
            D       = scale_d * relu(pre_act)
        """
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        a_mcast_mask = cute.make_layout_image_mask(cta_layout_mnk, cluster_coord_mnk, mode=1)
        b_mcast_mask = cute.make_layout_image_mask(cta_layout_mnk, cluster_coord_mnk, mode=0)
        a_mcast_mask = a_mcast_mask if self.is_a_mcast else 0
        b_mcast_mask = b_mcast_mask if self.is_b_mcast else 0

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = (
            cute.size_in_bytes(self.a_dtype, a_smem_layout)
            + cute.size_in_bytes(self.b_dtype, b_smem_layout)
        )

        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()

        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
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

        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sD = storage.sD.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        # Tile the global tensors
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.tile_shape_mnk, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.tile_shape_mnk, (0, None, None)), (None, None, None)
        )
        gD_mnl = cute.local_tile(
            mD_mnl, cute.slice_(self.tile_shape_mnk, (None, None, 0)), (None, None, None)
        )

        # TMA partitions for A
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_a, a_cta_crd, a_cta_layout,
            cute.group_modes(sA, 0, 2), cute.group_modes(gA_mkl, 0, 2),
        )

        # TMA partitions for B
        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_b, b_cta_crd, b_cta_layout,
            cute.group_modes(sB, 0, 2), cute.group_modes(gB_nkl, 0, 2),
        )

        # MMA thread partition
        warp_group_idx = cute.arch.make_warp_uniform(
            tidx // self.num_threads_per_warp_group
        )
        mma_warp_group_thread_layout = cute.make_layout(
            self.num_mma_warp_groups, stride=self.num_threads_per_warp_group
        )
        thr_mma = tiled_mma.get_slice(
            mma_warp_group_thread_layout(warp_group_idx - self.num_dma_warp_groups)
        )

        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)

        tCgD = thr_mma.partition_C(gD_mnl)
        acc_shape = tCgD.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)
        accum_temp   = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        is_dma_warp_group = warp_group_idx < self.num_dma_warp_groups
        if is_dma_warp_group:
            cute.arch.warpgroup_reg_dealloc(self.load_register_requirement)

        # =================================================================
        # DMA warpgroup: TMA loads for A and B
        # =================================================================
        if warp_idx == self.load_warp_id:
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.ab_stage
            )

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                tAgA_mkl = tAgA[(None, tile_coord_mnl[0], None, tile_coord_mnl[2])]
                tBgB_nkl = tBgB[(None, tile_coord_mnl[1], None, tile_coord_mnl[2])]

                mainloop_producer_state.reset_count()

                for k_tile in range(k_tile_cnt):
                    mainloop_pipeline.producer_acquire(mainloop_producer_state)

                    tAgA_k = tAgA_mkl[(None, mainloop_producer_state.count)]
                    tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]
                    tBgB_k = tBgB_nkl[(None, mainloop_producer_state.count)]
                    tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                    cute.copy(
                        tma_atom_a, tAgA_k, tAsA_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(mainloop_producer_state),
                        mcast_mask=a_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b, tBgB_k, tBsB_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(mainloop_producer_state),
                        mcast_mask=b_mcast_mask,
                    )

                    mainloop_pipeline.producer_commit(mainloop_producer_state)
                    mainloop_producer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            mainloop_pipeline.producer_tail(mainloop_producer_state)

        # =================================================================
        # MMA warpgroup: groupwise K-loop + epilogue
        # =================================================================
        if not is_dma_warp_group:
            cute.arch.warpgroup_reg_alloc(self.mma_register_requirement)

            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_consumer_read_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )
            mainloop_consumer_release_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )

            num_k_blocks = cute.size(tCrA, mode=[2])

            # Epilogue R2S copy setup
            copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )
            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(self.c_layout.is_m_major_c(), 4),
                self.c_dtype,
            )
            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)
            tiled_copy_r2s = cute.make_tiled_copy_S(copy_atom_r2s, tiled_copy_C_Atom)

            thr_copy_r2s = tiled_copy_r2s.get_slice(
                tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
            )
            tRS_sD   = thr_copy_r2s.partition_D(sD)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            rD_shape   = cute.shape(thr_copy_r2s.partition_S(sD))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD     = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            tRS_rD_out = cute.make_rmem_tensor(tRS_rD_layout.shape, self.c_dtype)
            size_tRS_rD = cute.size(tRS_rD)

            k_pipe_mmas = 1
            prologue_mma_cnt = min(k_pipe_mmas, k_tile_cnt)

            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mma_threads
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            # Per-tensor epilogue scalars (same for all output tiles)
            alpha_val   = alpha[0]
            scale_a_val = scale_a[0]
            scale_b_val = scale_b[0]
            scale_d_val = scale_d[0]
            combined = alpha_val * scale_a_val * scale_b_val

            # Per-thread MMA slice for coordinate tensor partition_C.
            # Must use per-thread get_slice(tidx_mma), not get_slice(0).
            # This is needed to correctly map each accumulator element to its global
            # M-row so we can look up the per-row SFA value.
            tidx_mma = tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
            thr_mma_c = tiled_mma.get_slice(tidx_mma)

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]

                # Blockwise SFB index: sfb_n_idx = tile_n (since tile_N == sg == 128)
                sfb_n_idx = (tile_coord_mnl[1] * self.tile_shape_mnk[1]) // SCALE_GRAN_K

                # ------------------------------------------------------------------
                # GROUPWISE SFA: coordinate tensor maps each accumulator element
                # to its absolute M-row.
                #
                # cute.make_tensor(integer, layout) creates a coordinate tensor
                # T[coord] = integer + layout(coord), supported in device kernels
                # via ArithTupleIteratorType (tensor.py lines 716-721).
                #
                # Layout (tile_M, tile_N) with stride (1, 0):
                #   T[m, n] = abs_m_start + m*1 + n*0 = abs_m_start + m
                # After partition_C, tCgM_rows[(r1,r2,v)] = absolute M-row.
                # ------------------------------------------------------------------
                abs_m_start = tile_coord_mnl[0] * self.tile_shape_mnk[0]
                gM_row_tensor = cute.make_tensor(
                    abs_m_start,
                    cute.make_layout(
                        (self.tile_shape_mnk[0], self.tile_shape_mnk[1]),
                        stride=(1, 0),   # stride 1 in M, 0 (broadcast) in N
                    )
                )
                tCgM_rows = thr_mma_c.partition_C(gM_row_tensor)

                # ---------------------------------------------------------
                # GROUPWISE MAINLOOP
                # Each K-tile: WGMMA → wait → per-row SFA * blockwise SFB → accum
                # ---------------------------------------------------------
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)

                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)
                cute.nvgpu.warpgroup.fence()

                # Prologue: issue WGMMA for first K-tile
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)

                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None, None, k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accum_temp,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accum_temp,
                        )
                        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

                    cute.nvgpu.warpgroup.commit_group()
                    mainloop_consumer_read_state.advance()

                # Main loop: remaining K-tiles
                for k_tile in range(prologue_mma_cnt, k_tile_cnt):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)

                    # Wait for previous WGMMA to finish, then apply per-row scale
                    cute.nvgpu.warpgroup.wait_group(0)

                    prev_k = mainloop_consumer_read_state.count - 1
                    sfb_val = mSFB[(sfb_n_idx, prev_k, tile_coord_mnl[2])]
                    for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                        for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                            for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                                m_row = tCgM_rows[(r1, r2, v)]
                                sfa_val = mSFA[(m_row, prev_k, tile_coord_mnl[2])]
                                scale_k = sfa_val * sfb_val
                                accumulators[(r1, r2, v)] = (
                                    accumulators[(r1, r2, v)]
                                    + scale_k * accum_temp[(r1, r2, v)]
                                )

                    # Reset accum_temp for next K-tile
                    cute.nvgpu.warpgroup.fence()
                    tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)

                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None, None, k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accum_temp,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accum_temp,
                        )
                        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

                    cute.nvgpu.warpgroup.commit_group()

                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()
                    mainloop_consumer_read_state.advance()

                # Wait for the last K-tile's WGMMA and apply its scale
                cute.nvgpu.warpgroup.wait_group(0)

                last_k = mainloop_consumer_read_state.count - 1
                sfb_val = mSFB[(sfb_n_idx, last_k, tile_coord_mnl[2])]
                for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                    for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                        for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                            m_row = tCgM_rows[(r1, r2, v)]
                            sfa_val = mSFA[(m_row, last_k, tile_coord_mnl[2])]
                            scale_k = sfa_val * sfb_val
                            accumulators[(r1, r2, v)] = (
                                accumulators[(r1, r2, v)]
                                + scale_k * accum_temp[(r1, r2, v)]
                            )

                # Release remaining prologue pipeline stages
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # ---------------------------------------------------------
                # EPILOGUE: D = scale_d * relu(alpha * scale_a * scale_b * accum)
                # No beta/C term.
                # ---------------------------------------------------------
                for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                    for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                        for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                            acc_val  = accumulators[(r1, r2, v)]
                            pre_act  = combined * acc_val
                            relu_val = pre_act * (pre_act > 0.0)
                            accumulators[(r1, r2, v)] = scale_d_val * relu_val

                # Store D via R2S + TMA
                tCgD_for_tma_partition = cute.zipped_divide(gD_mnl_slice, self.epi_tile)
                bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_d, 0, cute.make_layout(1),
                    cute.group_modes(sD, 0, 2),
                    tCgD_for_tma_partition,
                )

                epi_tile_num    = cute.size(tCgD_for_tma_partition, mode=[1])
                epi_tile_shape  = tCgD_for_tma_partition.shape[1]
                epi_tile_layout = cute.make_layout(epi_tile_shape, stride=(epi_tile_shape[1], 1))

                num_prev_epi_tiles = tile_sched.num_tiles_executed * epi_tile_num
                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.c_dtype))

                    epi_buffer = (num_prev_epi_tiles + epi_idx) % cute.size(tRS_sD, mode=[3])
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD_out,
                        tRS_sD[(None, None, None, epi_buffer)],
                    )

                    cute.arch.fence_proxy("async.shared", space="cta")
                    self.epilog_sync_barrier.arrive_and_wait()

                    if warp_idx == self.epi_store_warp_id:
                        cute.copy(
                            tma_atom_d,
                            bSG_sD[(None, epi_buffer)],
                            bSG_gD[(None, gmem_coord)],
                        )
                        tma_store_pipeline.producer_commit()
                        tma_store_pipeline.producer_acquire()

                    self.epilog_sync_barrier.arrive_and_wait()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            tma_store_pipeline.producer_tail()

    # ------------------------------------------------------------------
    # Static helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _compute_stages(tile_shape_mnk, a_dtype, b_dtype, epi_tile, c_dtype,
                        smem_capacity, occupancy):
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
    def _sm90_compute_tile_shape_or_override(
        tile_shape_mnk, element_type, is_cooperative=False, epi_tile_override=None
    ):
        if epi_tile_override is not None:
            return epi_tile_override
        if is_cooperative:
            return (min(128, cute.size(tile_shape_mnk, mode=[0])),
                    min(32,  cute.size(tile_shape_mnk, mode=[1])))
        n_perf = 64 if element_type.width == 8 else 32
        return (min(64, cute.size(tile_shape_mnk, mode=[0])),
                min(n_perf, cute.size(tile_shape_mnk, mode=[1])))

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk, epi_tile,
        a_dtype, a_layout,
        b_dtype, b_layout,
        ab_stage,
        c_dtype, c_layout,
        epi_stage,
    ):
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        a_is_k_major = (
            a_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        b_is_k_major = (
            b_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]
        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(a_layout, a_dtype, a_major_mode_size), a_dtype
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(b_layout, b_dtype, b_major_mode_size), b_dtype
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        c_smem_shape = epi_tile
        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(c_layout, c_dtype, c_major_mode_size), c_dtype
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom,
            cute.append(c_smem_shape, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )
        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    @staticmethod
    def _compute_grid(d, tile_shape_mnk, cluster_shape_mn, swizzle_size,
                      raster_along_m, max_active_clusters):
        c_shape = cute.slice_(tile_shape_mnk, (None, None, 0))
        gd = cute.zipped_divide(d, tiler=c_shape)
        num_ctas_mnl = gd[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)
        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl, swizzle_size, raster_along_m
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        return tile_sched_params, grid

    @staticmethod
    def _make_tma_store_atoms_and_tensors(tensor_d, epi_smem_layout_staged, epi_tile):
        epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))
        tma_atom_d, tma_tensor_d = cute.nvgpu.cpasync.make_tiled_tma_atom(
            cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
            tensor_d, epi_smem_layout, epi_tile,
        )
        return tma_atom_d, tma_tensor_d

    @staticmethod
    def _make_tma_atoms_and_tensors(tensor, smem_layout_staged, smem_tile, mcast_dim):
        op = (
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp()
        )
        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op, tensor, smem_layout, smem_tile, num_multicast=mcast_dim,
        )
        return tma_atom, tma_tensor


# ---------------------------------------------------------------------------
# PyTorch groupwise-aware reference
# ---------------------------------------------------------------------------

def reference_groupwise_gemm(
    a_fp8, b_fp8, sfa, sfb,
    alpha, scale_a, scale_b, scale_d,
    scale_gran_k: int = SCALE_GRAN_K,
    scale_gran_n: int = SCALE_GRAN_N,
):
    """
    Compute the groupwise reference result on GPU using PyTorch.

    Tensor conventions (all on GPU):
      a_fp8 : (M, K, L)  FP8, K-major
      b_fp8 : (N, K, L)  FP8, K-major
      sfa   : (M, K_tiles, L)  Float32, K-major   (per-row SFA)
      sfb   : (N_tiles, K_tiles, L)  Float32, K-major  (blockwise SFB)

    accum[m, n] = sum_k  SFA[m, k] * SFB[n // sg_n, k]
                          * (A_f32[m, k*sg_k:(k+1)*sg_k] @ B_f32[k*sg_k:(k+1)*sg_k, n])
    D = scale_d * relu(alpha * scale_a * scale_b * accum)

    Returns D in (M, N, L) layout (N-major in memory, matching BFloat16 output).
    """
    M, K, L = a_fp8.shape
    N = b_fp8.shape[0]
    K_t = K // scale_gran_k
    N_t = N // scale_gran_n

    a_f32 = a_fp8.to(torch.float32).permute(2, 0, 1)   # (L, M, K)
    b_f32 = b_fp8.to(torch.float32).permute(2, 0, 1)   # (L, N, K)
    # sfa: (M, K_tiles, L) → (L, M, K_tiles)
    sfa_l = sfa.permute(2, 0, 1)   # (L, M, K_tiles)
    # sfb: (N_tiles, K_tiles, L) → (L, N_tiles, K_tiles)
    sfb_l = sfb.permute(2, 0, 1)   # (L, N_tiles, K_tiles)

    accum = torch.zeros(L, M, N, dtype=torch.float32, device=a_fp8.device)

    for k in range(K_t):
        ks, ke = k * scale_gran_k, (k + 1) * scale_gran_k
        A_tile = a_f32[:, :, ks:ke]                                   # (L, M, sg_k)
        B_tile = b_f32[:, :, ks:ke]                                   # (L, N, sg_k)
        partial = torch.bmm(A_tile, B_tile.transpose(1, 2))           # (L, M, N)

        # Per-row SFA: shape (L, M) → expand to (L, M, 1)
        sfa_k = sfa_l[:, :, k].unsqueeze(2)                          # (L, M, 1)
        # Blockwise SFB: shape (L, N_tiles) → expand to (L, 1, N) via repeat
        sfb_k = sfb_l[:, :, k]                                       # (L, N_tiles)
        sfb_k_full = sfb_k.repeat_interleave(scale_gran_n, dim=1)    # (L, N)
        sfb_k_full = sfb_k_full[:, :N].unsqueeze(1)                  # (L, 1, N)

        accum += sfa_k * sfb_k_full * partial

    pre_act = alpha * scale_a * scale_b * accum       # (L, M, N)
    d_lmn = scale_d * torch.relu(pre_act)
    # Return (M, N, L) — N-major in the MN plane (contiguous in N)
    return d_lmn.permute(1, 2, 0).contiguous()        # (M, N, L)


# ---------------------------------------------------------------------------
# Host driver
# ---------------------------------------------------------------------------

def run(
    mnkl: Tuple[int, int, int, int],
    cluster_shape_mn: Tuple[int, int] = (1, 2),
    swizzle_size: int = 2,
    raster_along_m: bool = True,
    alpha_val: float = 1.0,
    scale_a_val: float = 1.0,
    scale_b_val: float = 1.0,
    scale_d_val: float = 1.0,
    tolerance: float = 5e-2,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
):
    """
    Allocate tensors, compile and run the groupwise FP8 GEMM kernel,
    compare against the PyTorch groupwise reference, and report timing.
    """
    m, n, k, l = mnkl
    sg = SCALE_GRAN_K  # 128

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    if k % 16 != 0:
        raise ValueError(f"K={k} must be a multiple of 16 for FP8 alignment")
    if m % sg != 0 or n % sg != 0 or k % sg != 0:
        raise ValueError(
            f"M={m}, N={n}, K={k} must all be multiples of {sg} for groupwise scaling"
        )

    a_dtype = cutlass.Float8E4M3FN
    b_dtype = cutlass.Float8E4M3FN
    d_dtype = cutlass.BFloat16

    print("Hopper FP8 Groupwise GEMM")
    print(f"  mnkl          : {mnkl}")
    print(f"  tile_shape_mn : (256, 128)  cluster_shape_mn : {cluster_shape_mn}")
    print(f"  swizzle       : {swizzle_size}   raster : {'along_m' if raster_along_m else 'along_n'}")
    print(f"  alpha={alpha_val}  scale_a={scale_a_val}  scale_b={scale_b_val}  scale_d={scale_d_val}")

    # ------------------------------------------------------------------
    # Tensor shapes:
    #   A:   (M, K, L)  FP8, K-major
    #   B:   (N, K, L)  FP8, K-major
    #   D:   (M, N, L)  BFloat16, N-major (is_mode0_major=False → stride 1 in N)
    #   SFA: (M, K_tiles, L)  Float32, K-major   (per-row: M rows, not M//128)
    #   SFB: (N_tiles, K_tiles, L)  Float32, K-major
    # ------------------------------------------------------------------
    a_torch = cutlass_torch.matrix(l, m, k, False, a_dtype)          # (M, K, L) K-major
    b_torch = cutlass_torch.matrix(l, n, k, False, b_dtype)          # (N, K, L) K-major
    # N-major D: is_mode0_major=False → leading dim = mode1 (N) → stride 1 in N
    d_torch = cutlass_torch.matrix(l, m, n, False, d_dtype,
                                   init_type=TensorInitType.SCALAR)  # (M, N, L) N-major

    k_tiles = k // sg
    n_tiles = n // sg
    # SFA: (M, K_tiles, L) K-major — note M (full), not M//128
    sfa_torch = cutlass_torch.matrix(l, m, k_tiles, False, cutlass.Float32,
                                     init_type=TensorInitType.SCALAR)
    sfb_torch = cutlass_torch.matrix(l, n_tiles, k_tiles, False, cutlass.Float32,
                                     init_type=TensorInitType.SCALAR)
    torch.nn.init.uniform_(sfa_torch, -1.0, 1.0)
    torch.nn.init.uniform_(sfb_torch, -1.0, 1.0)

    # Build CuTe tensors
    a_tensor, _    = cutlass_torch.cute_tensor_like(a_torch, a_dtype, is_dynamic_layout=True,  assumed_align=16)
    b_tensor, _    = cutlass_torch.cute_tensor_like(b_torch, b_dtype, is_dynamic_layout=True,  assumed_align=16)
    d_tensor, d_gpu = cutlass_torch.cute_tensor_like(d_torch, d_dtype, is_dynamic_layout=True, assumed_align=16)
    sfa_tensor, _  = cutlass_torch.cute_tensor_like(sfa_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)
    sfb_tensor, _  = cutlass_torch.cute_tensor_like(sfb_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)

    def _scalar(v):
        t = torch.tensor([v], dtype=torch.float32, device="cuda")
        tensor, _ = cutlass_torch.cute_tensor_like(t, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)
        return tensor

    alpha_t   = _scalar(alpha_val)
    scale_a_t = _scalar(scale_a_val)
    scale_b_t = _scalar(scale_b_val)
    scale_d_t = _scalar(scale_d_val)

    gemm = HopperFP8GroupwiseGemmKernel(cluster_shape_mn, swizzle_size, raster_along_m)

    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    compiled_gemm = cute.compile(
        gemm,
        a_tensor, b_tensor,
        sfa_tensor, sfb_tensor,
        d_tensor,
        alpha_t, scale_a_t, scale_b_t, scale_d_t,
        max_active_clusters, stream,
    )

    if not skip_ref_check:
        compiled_gemm(
            a_tensor, b_tensor,
            sfa_tensor, sfb_tensor,
            d_tensor,
            alpha_t, scale_a_t, scale_b_t, scale_d_t,
            stream,
        )
        torch.cuda.synchronize()

        d_ref = reference_groupwise_gemm(
            a_torch, b_torch, sfa_torch, sfb_torch,
            alpha_val, scale_a_val, scale_b_val, scale_d_val,
        )
        # d_ref and d_gpu are both (M, N, L) N-major
        d_gpu_f32  = d_gpu.cpu().to(torch.float32)
        d_ref_f32  = d_ref.cpu().to(torch.float32)
        diff = (d_gpu_f32 - d_ref_f32).abs()
        print(f"  max_diff={diff.max():.4f}  mean_diff={diff.mean():.4f}")
        torch.testing.assert_close(
            d_gpu_f32, d_ref_f32,
            atol=tolerance, rtol=1e-2,
            msg="Groupwise GEMM output does not match reference",
        )
        print("  Correctness check: PASSED")

    def generate_tensors():
        a_ws, _ = cutlass_torch.cute_tensor_like(a_torch, a_dtype, is_dynamic_layout=True, assumed_align=16)
        b_ws, _ = cutlass_torch.cute_tensor_like(b_torch, b_dtype, is_dynamic_layout=True, assumed_align=16)
        d_ws, _ = cutlass_torch.cute_tensor_like(d_torch, d_dtype, is_dynamic_layout=True, assumed_align=16)
        return testing.JitArguments(
            a_ws, b_ws,
            sfa_tensor, sfb_tensor,
            d_ws,
            alpha_t, scale_a_t, scale_b_t, scale_d_t,
            stream,
        )

    if iterations <= 0:
        return 0

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch.numel() * a_torch.element_size()
            + b_torch.numel() * b_torch.element_size()
            + d_torch.numel() * d_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time_us = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    flops = 2.0 * m * n * k * l
    gflops = flops / (exec_time_us * 1e-6) / 1e9
    print(f"  Avg runtime : {exec_time_us / 1e3:.4f} ms")
    print(f"  GFLOPS      : {gflops:.1f}")

    return exec_time_us


if __name__ == "__main__":
    args = parse_arguments()
    run(
        mnkl=args.mnkl,
        cluster_shape_mn=args.cluster_shape_mn,
        swizzle_size=args.swizzle_size,
        raster_along_m=(args.raster_order == "along_m"),
        alpha_val=args.alpha,
        scale_a_val=args.scale_a,
        scale_b_val=args.scale_b,
        scale_d_val=args.scale_d,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
    )
    print("PASS")
