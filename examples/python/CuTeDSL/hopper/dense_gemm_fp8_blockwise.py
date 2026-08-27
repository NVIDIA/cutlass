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
Hopper FP8 GEMM with trivial blockwise scaling, ported from CUTLASS Example 67
(67_hopper_fp8_warp_specialized_gemm_with_blockwise_scaling) — the variant
where scale granularity equals the tile size.

The kernel computes:

    D = scale_d * relu(alpha * scale_a * scale_b * accum + beta * scale_c * C)

    accum[m, n] = sum_k  SFA[m // 128, k // 128] * SFB[n // 128, k // 128]
                          * (A[m, k*128:(k+1)*128] @ B[k*128:(k+1)*128, n])

One float32 scale factor per 128-row block of A (SFA) and per 128-column block
of B (SFB), indexed by K-tile. Each K-tile's partial accumulator is multiplied
by SFA*SFB before being added to the running accumulator; the per-tensor
``scale_a`` / ``scale_b`` factors are folded into the epilogue.

Pipeline (warp-specialized):
  - DMA warpgroup: TMA loads A and B into a multi-stage SMEM ring.
  - MMA warpgroup: WGMMA per K-tile, scale-and-accumulate, ReLU epilogue,
    R2S + TMA store of D.

Run:

    python examples/python/CuTeDSL/hopper/dense_gemm_fp8_blockwise.py \\
        --mnkl 2816,3072,16384,1 \\
        --tile_shape_mn 128,128 --cluster_shape_mn 1,2 \\
        --alpha 1.0 --beta 0.0 --scale_a 1.0 --scale_b 1.0 \\
        --scale_c 1.0 --scale_d 1.0 \\
        --raster_order along_m --swizzle_size 2

Constraints:
  - A/B: FP8 E4M3FN, K-major. C/D: Float32, M-major. SFA/SFB: Float32.
  - Accumulator: Float32.
  - Tile shape M in {64, 128}; tile shape N in {64, 128, 256}.
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

SCALE_GRAN = 128  # trivial blockwise: scale granularity equals the tile size


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
        description="Hopper FP8 GEMM with trivial blockwise scaling "
                    "(port of CUTLASS Example 67 blockwise variant)."
    )
    parser.add_argument("--mnkl", type=_parse_ints, default=(2816, 3072, 16384, 1))
    parser.add_argument(
        "--tile_shape_mn", type=_parse_ints,
        # tile_N == 256 (atom_layout (2,1,1)) would span two SFB entries; the
        # blockwise mainloop only indexes one, so (128, 256) is not supported.
        choices=[(128, 128), (128, 64), (64, 64)],
        default=(128, 128),
    )
    parser.add_argument(
        "--cluster_shape_mn", type=_parse_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 2),
    )
    parser.add_argument(
        "--swizzle_size", type=int, default=None,
        help="Rasterisation swizzle. Defaults to cluster-aware optimum "
             "(1 for multicast clusters, 2 for the single-CTA case).",
    )
    parser.add_argument(
        "--raster_order", choices=["along_m", "along_n"], default="along_m"
    )
    parser.add_argument("--alpha",   type=float, default=1.0)
    parser.add_argument("--beta",    type=float, default=0.0)
    parser.add_argument("--scale_a", type=float, default=1.0)
    parser.add_argument("--scale_b", type=float, default=1.0)
    parser.add_argument("--scale_c", type=float, default=1.0)
    parser.add_argument("--scale_d", type=float, default=1.0)
    parser.add_argument("--tolerance", type=float, default=5e-2)
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--use_cold_l2", action="store_true", default=False)

    args = parser.parse_args()
    if len(args.mnkl) != 4:
        parser.error("--mnkl must have 4 values")
    if len(args.tile_shape_mn) != 2:
        parser.error("--tile_shape_mn must have 2 values")
    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must have 2 values")
    return args


# ---------------------------------------------------------------------------
# Kernel class
# ---------------------------------------------------------------------------

class HopperFP8BlockwiseGemmKernel:
    """
    Hopper FP8 GEMM with trivial blockwise A/B scaling.

    Computes:
        D = scale_d * relu(alpha * scale_a * scale_b * accum + beta * scale_c * C)
    where accum is the blockwise-scaled accumulator (see module docstring).

    :param tile_shape_mn: CTA tile shape (M, N).  K is set by MMA instruction.
    :param cluster_shape_mn: Cluster shape (M, N).
    :param swizzle_size: Swizzle factor for CTA rasterisation (1, 2, 4, or 8).
    :param raster_along_m: If True, rasterise along M; otherwise along N.
    """

    def __init__(
        self,
        tile_shape_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_along_m: bool,
    ):
        self.acc_dtype = cutlass.Float32
        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m

        # K is filled in by _setup_attributes after seeing the MMA instruction shape.
        self.tile_shape_mnk = (*tile_shape_mn, 1)

        # Use two MMA warpgroups only for tiles wider than 128 in N
        # (matches CUTLASS cooperative heuristic).
        self.atom_layout_mnk = (
            (2, 1, 1)
            if tile_shape_mn[0] > 64 and tile_shape_mn[1] > 128
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
        self.load_warp_id = 0
        self.epi_store_warp_id = (
            self.num_dma_warp_groups * self.num_warps_per_warp_group
        )
        # Register split: math warpgroups want as many regs as possible to
        # avoid spills in the WGMMA inner loop + scale-and-accumulate path.
        # Sweep on H100 (4096^3): 24/240 wins by ~25% over the standard 40/232,
        # 32/240 is within noise of 24/240, 48/224 regresses. DMA warps only
        # hold TMA descriptors + barrier addrs, so 24 regs is enough.
        self.load_register_requirement = 24
        self.mma_register_requirement = 240
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
    # Host-side setup helpers (called from __call__)
    # ------------------------------------------------------------------

    def _setup_attributes(self):
        """Derive shapes and layouts that depend on input tensor types."""
        if self.tile_shape_mnk[0] not in (64, 128):
            raise ValueError("tile M must be 64 or 128")
        if self.tile_shape_mnk[1] not in (64, 128, 256):
            raise ValueError("tile N must be 64, 128, or 256")

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

        is_cooperative = self.atom_layout_mnk == (2, 1, 1)
        self.epi_tile = self._sm90_compute_tile_shape_or_override(
            self.tile_shape_mnk, self.c_dtype, is_cooperative=is_cooperative
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
    # JIT entry point (runs on host, sets up TMA/grid, launches kernel)
    # ------------------------------------------------------------------

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,           # (M, K, L) FP8 E4M3FN, k-major
        b: cute.Tensor,           # (N, K, L) FP8 E4M3FN, k-major
        c: cute.Tensor,           # (M, N, L) Float32, m-major
        sfa: cute.Tensor,         # (M//128, K//128, L) Float32 blockwise scales for A
        sfb: cute.Tensor,         # (N//128, K//128, L) Float32 blockwise scales for B
        d: cute.Tensor,           # (M, N, L) Float32, m-major  (output)
        alpha:   cute.Tensor,     # scalar (1-element Float32)
        beta:    cute.Tensor,     # scalar
        scale_a: cute.Tensor,     # per-tensor epilogue scale for A
        scale_b: cute.Tensor,     # per-tensor epilogue scale for B
        scale_c: cute.Tensor,     # per-tensor epilogue scale for C
        scale_d: cute.Tensor,     # per-tensor epilogue scale for D
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        # Derive static attributes from input tensor types/layouts.
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.c_dtype = d.element_type
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
            c, sfa, sfb,
            alpha, beta, scale_a, scale_b, scale_c, scale_d,
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
            use_pdl=True,
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
        mC_mnl: cute.Tensor,      # C matrix: (M, N, L) Float32, m-major
        mSFA: cute.Tensor,        # blockwise scales A: (M//128, K//128, L) Float32
        mSFB: cute.Tensor,        # blockwise scales B: (N//128, K//128, L) Float32
        alpha:   cute.Tensor,
        beta:    cute.Tensor,
        scale_a: cute.Tensor,
        scale_b: cute.Tensor,
        scale_c: cute.Tensor,
        scale_d: cute.Tensor,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """
        Warp-specialised blockwise FP8 GEMM kernel.

        DMA warpgroup  : TMA loads for A and B.
        MMA warpgroup  : per-K-tile WGMMA + blockwise scale-and-accumulate + epilogue.

        Blockwise accumulation loop (one iteration per K-tile of width 128):
            accum_temp = A_tile @ B_tile          (WGMMA, zeros accum_temp first)
            accum     += SFA[m, k] * SFB[n, k] * accum_temp

        Epilogue:
            pre_act = alpha * scale_a * scale_b * accum + beta * scale_c * C
            D       = scale_d * relu(pre_act)
        """
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

        # PDL: wait for the prior kernel on this stream to drain before any TMA
        # loads. Lets the runtime pre-launch this grid (overlapping prologue
        # setup with the prior kernel's tail) while still preventing data
        # hazards. No-op when the launch attribute is not set.
        cute.arch.griddepcontrol_wait()

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
        # C is accessed per-thread in the epilogue (same tile shape as D)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.tile_shape_mnk, (None, None, 0)), (None, None, None)
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
        # MMA warpgroup: blockwise K-loop + epilogue
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

            # Epilogue R2S copy setup.
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

            # 1-stage lookahead (same pipelining as 2xacc example)
            k_pipe_mmas = 1
            prologue_mma_cnt = min(k_pipe_mmas, k_tile_cnt)

            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mma_threads
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            # Load per-tensor epilogue scalars once (same for every output tile)
            alpha_val   = alpha[0]
            beta_val    = beta[0]
            scale_a_val = scale_a[0]
            scale_b_val = scale_b[0]
            scale_c_val = scale_c[0]
            scale_d_val = scale_d[0]
            # Combined per-tensor A*B scale applied after blockwise accumulation
            scale_ab_val = scale_a_val * scale_b_val

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]
                # C tile slice for this output tile (used in epilogue R2S loop)
                gC_mnl_slice = gC_mnl[(None, None, *tile_coord_mnl)]

                # Blockwise scale factor indices.
                # tile_shape_mnk[2] == sg == 128: the K-tile size equals the scale granularity.
                # For tile_M == sg: sfa_m_idx = tile_m.
                # For tile_M < sg (e.g. 64): sfa_m_idx = (tile_m * 64) // 128 = tile_m // 2.
                # NOTE: tile_N == 256 (atom_layout (2,1,1)) is unsupported for blockwise scaling
                # because it spans two SFB entries; sfb_n_idx only covers the first N-block.
                sg = self.tile_shape_mnk[2]
                sfa_m_idx = (tile_coord_mnl[0] * self.tile_shape_mnk[0]) // sg
                sfb_n_idx = (tile_coord_mnl[1] * self.tile_shape_mnk[1]) // sg

                # ---------------------------------------------------------
                # BLOCKWISE MAINLOOP
                # Each K-tile: WGMMA -> wait -> scale by SFA*SFB -> accum
                # ---------------------------------------------------------
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)

                # Zero accum_temp on the very first WGMMA via ACCUMULATE=False
                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)
                cute.nvgpu.warpgroup.fence()

                # Prologue: issue WGMMA for first k_tile without releasing pipeline
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

                    # Wait for previous K-tile's WGMMA to complete before reading accum_temp
                    cute.nvgpu.warpgroup.wait_group(0)

                    prev_k = mainloop_consumer_read_state.count - 1
                    sfa_val = mSFA[(sfa_m_idx, prev_k, tile_coord_mnl[2])]
                    sfb_val = mSFB[(sfb_n_idx, prev_k, tile_coord_mnl[2])]
                    scale_k = sfa_val * sfb_val
                    for i in range(cute.size(accumulators)):
                        accumulators[i] = accumulators[i] + scale_k * accum_temp[i]

                    # Reset accum_temp for this K-tile
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
                sfa_val = mSFA[(sfa_m_idx, last_k, tile_coord_mnl[2])]
                sfb_val = mSFB[(sfb_n_idx, last_k, tile_coord_mnl[2])]
                scale_k = sfa_val * sfb_val
                for i in range(cute.size(accumulators)):
                    accumulators[i] = accumulators[i] + scale_k * accum_temp[i]

                # Release remaining prologue pipeline stages
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # ---------------------------------------------------------
                # EPILOGUE
                # pre_act = alpha * scale_ab * accum + beta * scale_c * C
                # D       = scale_d * relu(pre_act)
                #
                # Per-thread partition_C: thr_mma uses get_slice(0) which is a
                # warpgroup-level slice — all threads map to the same (M,N).
                # For reading C we need get_slice(per-thread index) so each thread
                # reads its own output elements from global C.
                # C tensor must have is_dynamic_layout=False so that partition_C
                # sees static strides; dynamic strides cause all offsets to be zero.
                # ---------------------------------------------------------
                combined = alpha_val * scale_ab_val

                # Per-thread MMA slice for correct per-element C reads.
                tidx_mma = tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
                thr_mma_c = tiled_mma.get_slice(tidx_mma)
                tCgC_tile = thr_mma_c.partition_C(gC_mnl_slice)

                # Apply epilogue element-wise using explicit shape coordinates.
                for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                    for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                        for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                            c_val    = tCgC_tile[(r1, r2, v)]
                            acc_val  = accumulators[(r1, r2, v)]
                            pre_act  = combined * acc_val + beta_val * scale_c_val * c_val
                            relu_val = pre_act * (pre_act > 0.0)
                            accumulators[(r1, r2, v)] = scale_d_val * relu_val

                # Store D via R2S + TMA.
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
                        # Lazy acquire: wait for THIS epi-buffer to be free
                        # (its prior TMA store, epi_stage iterations ago, drained)
                        # before issuing the next store. Lets up to epi_stage
                        # stores run in flight without per-iter serialization.
                        tma_store_pipeline.producer_acquire()
                        cute.copy(
                            tma_atom_d,
                            bSG_sD[(None, epi_buffer)],
                            bSG_gD[(None, gmem_coord)],
                        )
                        tma_store_pipeline.producer_commit()

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
        # Cluster-aware swizzle: with TMA multicast on either axis, swizzle=1
        # (tighter rasterisation) keeps the multicast peer's tile resident in
        # L2 across consecutive CTAs and consistently beats sz=2 by 1-2% on
        # H100. Without multicast, swizzle=2 is best.
        if swizzle_size is None:
            swizzle_size = 2 if cluster_shape_mn == (1, 1) else 1
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
# PyTorch blockwise-aware reference (runs on GPU for speed)
# ---------------------------------------------------------------------------

def reference_blockwise_gemm(
    a_fp8, b_fp8, c_f32, sfa, sfb,
    alpha, beta, scale_a, scale_b, scale_c, scale_d,
    scale_gran: int = SCALE_GRAN,
):
    """
    Compute the reference result on GPU using PyTorch.

    All input tensors follow the CuTe (M, K, L) / (N, K, L) / (M, N, L)
    convention (the leading L dim is the batch). Returns the reference D in
    (M, N, L) M-major.

        accum[m, n] = sum_k  SFA[m // sg, k // sg] * SFB[n // sg, k // sg]
                              * (A[m, k*sg:(k+1)*sg] @ B[k*sg:(k+1)*sg, n])
        D = scale_d * relu(alpha * scale_a * scale_b * accum + beta * scale_c * C)
    """
    M, K, L = a_fp8.shape
    N = b_fp8.shape[0]
    M_t = M // scale_gran
    K_t = K // scale_gran
    N_t = N // scale_gran

    # Convert to (L, M, K) / (L, N, K) for batched matmul
    a_f32 = a_fp8.to(torch.float32).permute(2, 0, 1)  # (L, M, K)
    b_f32 = b_fp8.to(torch.float32).permute(2, 0, 1)  # (L, N, K)
    # c_f32 is (M, N, L) M-major → (L, M, N)
    c_lmn = c_f32.permute(2, 0, 1).contiguous()       # (L, M, N)
    # sfa (M_tiles, K_tiles, L) → (L, M_tiles, K_tiles)
    sfa_l = sfa.permute(2, 0, 1)   # (L, M_tiles, K_tiles)
    # sfb (N_tiles, K_tiles, L) → (L, N_tiles, K_tiles)
    sfb_l = sfb.permute(2, 0, 1)   # (L, N_tiles, K_tiles)

    accum = torch.zeros(L, M, N, dtype=torch.float32, device=a_fp8.device)

    for k in range(K_t):
        ks, ke = k * scale_gran, (k + 1) * scale_gran
        A_tile = a_f32[:, :, ks:ke]              # (L, M, sg)
        B_tile = b_f32[:, :, ks:ke]              # (L, N, sg)
        partial = torch.bmm(A_tile, B_tile.transpose(1, 2))  # (L, M, N)

        sfa_k = sfa_l[:, :, k]  # (L, M_tiles)
        sfb_k = sfb_l[:, :, k]  # (L, N_tiles)
        sfa_k_full = sfa_k.repeat_interleave(scale_gran, dim=1)[:, :M, None]  # (L,M,1)
        sfb_k_full = sfb_k.repeat_interleave(scale_gran, dim=1)[:, :N, None]  # (L,N,1)
        accum += sfa_k_full * sfb_k_full.transpose(1, 2) * partial

    pre_act = alpha * scale_a * scale_b * accum + beta * scale_c * c_lmn
    d_ref_lmn = scale_d * torch.relu(pre_act)  # (L, M, N)
    # Return in (M, N, L) M-major layout to match kernel output
    return d_ref_lmn.permute(1, 2, 0)  # (M, N, L)


# ---------------------------------------------------------------------------
# Host driver
# ---------------------------------------------------------------------------

def run(
    mnkl: Tuple[int, int, int, int],
    tile_shape_mn: Tuple[int, int] = (128, 128),
    cluster_shape_mn: Tuple[int, int] = (1, 2),
    swizzle_size: int | None = None,
    raster_along_m: bool = True,
    alpha_val: float = 1.0,
    beta_val: float = 0.0,
    scale_a_val: float = 1.0,
    scale_b_val: float = 1.0,
    scale_c_val: float = 1.0,
    scale_d_val: float = 1.0,
    tolerance: float = 5e-2,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
):
    """
    Allocate tensors, compile and run the blockwise FP8 GEMM kernel,
    compare against the PyTorch blockwise reference, and report timing.
    """
    m, n, k, l = mnkl
    sg = SCALE_GRAN  # 128

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    # Alignment check: K must be 16-element aligned for FP8
    if k % 16 != 0:
        raise ValueError(f"K={k} must be a multiple of 16 for FP8 alignment")
    if m % sg != 0 or n % sg != 0 or k % sg != 0:
        raise ValueError(
            f"M={m}, N={n}, K={k} must all be multiples of {sg} "
            f"for trivial blockwise scaling"
        )

    a_dtype = cutlass.Float8E4M3FN
    b_dtype = cutlass.Float8E4M3FN
    c_dtype = cutlass.Float32
    # D output uses BF16: halves SMEM-D footprint and TMA-store bytes vs FP32.
    d_dtype = cutlass.BFloat16

    print("Hopper FP8 Blockwise GEMM")
    print(f"  mnkl          : {mnkl}")
    print(f"  tile_shape_mn : {tile_shape_mn}  cluster_shape_mn : {cluster_shape_mn}")
    effective_swizzle = (
        swizzle_size if swizzle_size is not None
        else (2 if cluster_shape_mn == (1, 1) else 1)
    )
    print(f"  swizzle       : {effective_swizzle}   raster : {'along_m' if raster_along_m else 'along_n'}")
    print(f"  alpha={alpha_val}  beta={beta_val}  scale_a={scale_a_val}  scale_b={scale_b_val}")
    print(f"  scale_c={scale_c_val}  scale_d={scale_d_val}")

    # ------------------------------------------------------------------ #
    # Tensor shapes follow the CuTe convention: (mode0, mode1, L)        #
    #   A:   (M, K, L)  K-major  → leading_dim=1 (K stride 1)           #
    #   B:   (N, K, L)  K-major  → leading_dim=1                        #
    #   C,D: (M, N, L)  M-major  → leading_dim=0 (M stride 1)           #
    #   SFA: (M_tiles, K_tiles, L) K-major                               #
    #   SFB: (N_tiles, K_tiles, L) K-major                               #
    # ------------------------------------------------------------------ #
    a_torch = cutlass_torch.matrix(l, m, k, False, a_dtype)    # (M, K, L) k-major
    b_torch = cutlass_torch.matrix(l, n, k, False, b_dtype)    # (N, K, L) k-major
    # C and D: M-major (column-major / ColumnMajor in CUTLASS)
    c_torch = cutlass_torch.matrix(l, m, n, True, c_dtype)     # (M, N, L) m-major
    d_torch = cutlass_torch.matrix(l, m, n, True, d_dtype,
                                   init_type=TensorInitType.SCALAR)  # (M, N, L) m-major BF16

    # Blockwise scale factors: shape (M_tiles/N_tiles, K_tiles, L), k-major
    m_tiles = m // sg
    k_tiles = k // sg
    n_tiles = n // sg
    sfa_torch = cutlass_torch.matrix(l, m_tiles, k_tiles, False, c_dtype,
                                     init_type=TensorInitType.SCALAR)  # (M_tiles, K_tiles, L)
    sfb_torch = cutlass_torch.matrix(l, n_tiles, k_tiles, False, c_dtype,
                                     init_type=TensorInitType.SCALAR)  # (N_tiles, K_tiles, L)
    torch.nn.init.uniform_(sfa_torch, -1.0, 1.0)
    torch.nn.init.uniform_(sfb_torch, -1.0, 1.0)

    # Build CuTe tensors (same shape/strides as torch tensors)
    a_tensor, _   = cutlass_torch.cute_tensor_like(a_torch, a_dtype, is_dynamic_layout=True, assumed_align=16)
    b_tensor, _   = cutlass_torch.cute_tensor_like(b_torch, b_dtype, is_dynamic_layout=True, assumed_align=16)
    # is_dynamic_layout=False: partition_C needs static strides for correct offset computation.
    # Dynamic strides from mark_layout_dynamic cause tiled_mma_partition to compute zero offsets.
    c_tensor, _   = cutlass_torch.cute_tensor_like(c_torch, c_dtype, is_dynamic_layout=False, assumed_align=16)
    d_tensor, d_gpu = cutlass_torch.cute_tensor_like(d_torch, d_dtype, is_dynamic_layout=True, assumed_align=16)
    sfa_tensor, _ = cutlass_torch.cute_tensor_like(sfa_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)
    sfb_tensor, _ = cutlass_torch.cute_tensor_like(sfb_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)

    def _scalar(v):
        t = torch.tensor([v], dtype=torch.float32, device="cuda")
        tensor, _ = cutlass_torch.cute_tensor_like(t, cutlass.Float32, is_dynamic_layout=True, assumed_align=16)
        return tensor

    alpha_t   = _scalar(alpha_val)
    beta_t    = _scalar(beta_val)
    scale_a_t = _scalar(scale_a_val)
    scale_b_t = _scalar(scale_b_val)
    scale_c_t = _scalar(scale_c_val)
    scale_d_t = _scalar(scale_d_val)

    gemm = HopperFP8BlockwiseGemmKernel(
        tile_shape_mn, cluster_shape_mn, swizzle_size, raster_along_m
    )

    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    compiled_gemm = cute.compile(
        gemm,
        a_tensor, b_tensor, c_tensor,
        sfa_tensor, sfb_tensor,
        d_tensor,
        alpha_t, beta_t, scale_a_t, scale_b_t, scale_c_t, scale_d_t,
        max_active_clusters, stream,
    )

    if not skip_ref_check:
        compiled_gemm(
            a_tensor, b_tensor, c_tensor,
            sfa_tensor, sfb_tensor,
            d_tensor,
            alpha_t, beta_t, scale_a_t, scale_b_t, scale_c_t, scale_d_t,
            stream,
        )
        torch.cuda.synchronize()

        # PyTorch blockwise reference (GPU).
        # All tensors use CuTe convention: (M,K,L), (N,K,L), (M,N,L), etc.
        d_ref = reference_blockwise_gemm(
            a_torch, b_torch, c_torch,
            sfa_torch, sfb_torch,
            alpha_val, beta_val, scale_a_val, scale_b_val, scale_c_val, scale_d_val,
        )

        # Both d_gpu and d_ref have shape (M, N, L) in M-major layout.
        # Upcast to FP32 for the comparison so BF16 quantization noise lands
        # in the rtol term rather than atol.
        d_gpu_f32 = d_gpu.cpu().to(torch.float32)
        d_ref_f32 = d_ref.cpu().to(torch.float32)
        diff = (d_gpu_f32 - d_ref_f32).abs()
        print(f"  max_diff={diff.max():.4f}  mean_diff={diff.mean():.4f}")
        torch.testing.assert_close(
            d_gpu_f32, d_ref_f32,
            atol=tolerance, rtol=1e-2,
            msg="Blockwise GEMM output does not match reference",
        )
        print("  Correctness check: PASSED")

    def generate_tensors():
        a_ws, _ = cutlass_torch.cute_tensor_like(a_torch, a_dtype, is_dynamic_layout=True, assumed_align=16)
        b_ws, _ = cutlass_torch.cute_tensor_like(b_torch, b_dtype, is_dynamic_layout=True, assumed_align=16)
        c_ws, _ = cutlass_torch.cute_tensor_like(c_torch, c_dtype, is_dynamic_layout=True, assumed_align=16)
        d_ws, _ = cutlass_torch.cute_tensor_like(d_torch, d_dtype, is_dynamic_layout=True, assumed_align=16)
        return testing.JitArguments(
            a_ws, b_ws, c_ws,
            sfa_tensor, sfb_tensor,
            d_ws,
            alpha_t, beta_t, scale_a_t, scale_b_t, scale_c_t, scale_d_t,
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
        tile_shape_mn=args.tile_shape_mn,
        cluster_shape_mn=args.cluster_shape_mn,
        swizzle_size=args.swizzle_size,
        raster_along_m=(args.raster_order == "along_m"),
        alpha_val=args.alpha,
        beta_val=args.beta,
        scale_a_val=args.scale_a,
        scale_b_val=args.scale_b,
        scale_c_val=args.scale_c,
        scale_d_val=args.scale_d,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
    )
    print("PASS")
