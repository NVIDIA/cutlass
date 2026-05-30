# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

"""
Grouped FP8 GEMM with per-row A and blockwise B scaling — sparse-groups
variant. Ported from CUTLASS Example 68
(68_hopper_fp8_warp_specialized_grouped_gemm_with_blockwise_scaling_with_sparse_groups).

For each non-empty group g the kernel computes:

    D_g = alpha_g * accum_g + beta_g * C_g

    accum_g[m, n] = sum_k  SFA_g[m, k] * SFB_g[n // 128, k]
                          * (A_g[m, k*128:(k+1)*128] @ B_g[k*128:(k+1)*128, n])

  - SFA_g shape (M_g, K_g // 128) — per-row A scale (ScaleGranularityM = 1).
  - SFB_g shape (N_g // 128, K_g // 128) — blockwise B (ScaleGranularityN = 128).
  - Only beta = 0 is currently supported (no C input is loaded).

Sparse-groups behaviour: any group with a zero dimension (M, N, or K) is
empty and skipped. The host driver passes empty groups through with stub
GMEM pointers and zeroed problem sizes, so the persistent group tile
scheduler reserves zero linear tile slots for them. The reported GFLOPS
and GBPS use the original (un-padded) sizes, so empty groups contribute
nothing to throughput.

Schedule note: the C++ source uses
``KernelPtrArrayTmaWarpSpecializedPingpongFP8Blockwise``; this Python port
keeps the cooperative schedule from the dense Example 68 variant
(``atom_layout_mnk = (2, 1, 1)``) — the sparse-groups host-side semantics
are independent of pingpong vs cooperative scheduling, and the per-WG
tensormap workspace required for true pingpong is left as a follow-up.

Pipeline (warp-specialized, cooperative; one DMA + two MMA warpgroups):
  - DMA leader: prefetches descriptors, updates A/B TMA descriptors at group
    boundaries, and issues TMA loads for A and B.
  - MMA warpgroups: WGMMA across K-tiles, scaling the previous K-tile's
    contribution by SFA[m, k] * SFB[n // 128, k] before accumulating; alpha
    epilogue; R2S + TMA store D, with the D descriptor updated per group.

Per-row SFA mapping uses a coordinate tensor:
    tCgM_rows = thr_mma_c.partition_C(
        cute.make_tensor(abs_m_start, make_layout((128, 128), stride=(1, 0)))
    )
which yields the absolute M-row of every WGMMA register fragment without
hardcoding the WGMMA register layout.

Run:
    python examples/python/CuTeDSL/hopper/dense_gemm_fp8_grouped_blockwise_sparse_groups.py \\
      --num_groups 8 --problem_sizes "(256,256,256)" \\
      --sparse_fraction 0.5 --seed 11 \\
      --cluster_shape_mn 1,1 --iterations 5 --warmup_iterations 2

Constraints:
  - A/B/D: FP8 E4M3FN; A/B K-major; D M-major (column-major).
  - Accumulator and SFA/SFB: Float32.
  - Per non-empty group, M, N, K must all be multiples of 128. A zero in
    any dim makes the group empty (it is then skipped).
  - Cluster shape M/N: power of two, with total cluster size <= 4.
"""

import argparse
import math
import os
import random
import re
from typing import List, Tuple, Type

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.torch as cutlass_torch
from cutlass.cutlass_dsl import extract_mlir_values, new_from_mlir_values, dsl_user_op, T as _T
from cutlass._mlir.dialects import nvvm as _nvvm_d
from cutlass._mlir.dialects._nvvm_enum_gen import (
    CpAsyncBulkTensorLoadMode as _CpAsyncBulkTensorLoadMode,
)
from cutlass.cute.typing import Int32, Pointer
from cutlass.torch import TensorInitType

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCALE_GRAN_N = 128  # blockwise B scaling
SCALE_GRAN_K = 128  # K-tile granularity (matches MMA K-tile size)

# Set GROUPED_GEMM_FORCE_CUTE_COPY=1 to force the cute.copy fallback for TMA
# loads instead of the lower-overhead NVVM dialect path.
_ENABLE_NVVM_NON_MCAST_LOAD = (
    os.getenv("GROUPED_GEMM_FORCE_CUTE_COPY", "0").lower() not in {"1", "true", "yes", "on"}
)


# ---------------------------------------------------------------------------
# NVVM non-mcast TMA load helper
# ---------------------------------------------------------------------------

@dsl_user_op
def _tma_load_ab_nvvm_no_mcast(
    k_coord: Int32,
    m_coord: Int32,
    n_coord: Int32,
    desc_a: Pointer,
    desc_b: Pointer,
    smem_a: Pointer,
    smem_b: Pointer,
    mbar: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    """Issue paired TMA loads for A and B via the NVVM dialect (non-multicast)."""
    l_coord = Int32(0).ir_value(loc=loc, ip=ip)
    for desc, smem, second_coord in (
        (desc_a, smem_a, m_coord),
        (desc_b, smem_b, n_coord),
    ):
        _nvvm_d.CpAsyncBulkTensorGlobalToSharedClusterOp(
            dstMem=smem.llvm_ptr,
            tmaDescriptor=desc.llvm_ptr,
            coordinates=[
                k_coord.ir_value(loc=loc, ip=ip),
                second_coord.ir_value(loc=loc, ip=ip),
                l_coord,
            ],
            mbar=mbar.llvm_ptr,
            im2colOffsets=[],
            predicate=_nvvm_d.elect_sync(_T.bool(), loc=loc, ip=ip),
            loadMode=_CpAsyncBulkTensorLoadMode.TILE,
            loc=loc,
            ip=ip,
        )


# ---------------------------------------------------------------------------
# Group-aware persistent tile scheduler. Wraps StaticPersistentTileScheduler
# + GroupedGemmTileSchedulerHelper; the wrapping is needed for invalid-tile
# safety when the linear tile index runs past the total tile count.
# ---------------------------------------------------------------------------

class _GroupedWorkTileInfo:
    def __init__(self, is_valid_tile, group_search_result):
        self._is_valid_tile = is_valid_tile
        self.group_search_result = group_search_result

    @property
    def is_valid_tile(self):
        return self._is_valid_tile

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self._is_valid_tile)
        values.extend(extract_mlir_values(self.group_search_result))
        return values

    def __new_from_mlir_values__(self, values):
        n_valid = len(extract_mlir_values(self._is_valid_tile))
        is_valid = new_from_mlir_values(self._is_valid_tile, values[:n_valid])
        gsr = new_from_mlir_values(self.group_search_result, values[n_valid:])
        return _GroupedWorkTileInfo(is_valid, gsr)


class StaticPersistentGroupTileScheduler:
    def __init__(self, tile_sched, group_helper, problem_sizes_mnkl):
        self._tile_sched = tile_sched
        self._group_helper = group_helper
        self._problem_sizes_mnkl = problem_sizes_mnkl

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self._tile_sched)
        values.extend(extract_mlir_values(self._group_helper))
        return values

    def __new_from_mlir_values__(self, values):
        n_tile = len(extract_mlir_values(self._tile_sched))
        tile_sched = new_from_mlir_values(self._tile_sched, values[:n_tile])
        group_helper = new_from_mlir_values(self._group_helper, values[n_tile:])
        return StaticPersistentGroupTileScheduler(tile_sched, group_helper, self._problem_sizes_mnkl)

    @staticmethod
    def create(tile_sched_params, bid, grid_dim, cluster_tile_shape_mnk,
               search_state, group_count, problem_sizes_mnkl):
        tile_sched = utils.StaticPersistentTileScheduler.create(tile_sched_params, bid, grid_dim)
        group_helper = utils.GroupedGemmTileSchedulerHelper(
            group_count, tile_sched_params, cluster_tile_shape_mnk, search_state
        )
        return StaticPersistentGroupTileScheduler(tile_sched, group_helper, problem_sizes_mnkl)

    @staticmethod
    def get_grid_shape(tile_sched_params, max_active_clusters):
        return utils.StaticPersistentTileScheduler.get_grid_shape(tile_sched_params, max_active_clusters)

    def initial_work_tile_info(self):
        return self.get_current_work()

    def get_current_work(self):
        base = self._tile_sched.get_current_work()
        valid_int = base.is_valid_tile.to(cutlass.Int32)
        safe_tile_idx = (base.tile_idx[0], base.tile_idx[1], base.tile_idx[2] * valid_int)
        gsr = self._group_helper.delinearize_z(safe_tile_idx, self._problem_sizes_mnkl)
        return _GroupedWorkTileInfo(base.is_valid_tile, gsr)

    def advance_to_next_work(self, *, advance_count=1):
        self._tile_sched.advance_to_next_work(advance_count=advance_count)

    @property
    def num_tiles_executed(self):
        return self._tile_sched.num_tiles_executed


# ---------------------------------------------------------------------------
# Main kernel class
# ---------------------------------------------------------------------------

class HopperFP8GroupedBlockwiseSparseGroupsGemmKernel:
    """
    Grouped FP8 GEMM with per-row A scaling (ScaleGranularityM=1) and blockwise
    B scaling (ScaleGranularityN=128). Sparse-groups port of CUTLASS Example
    68's pingpong variant
    (68_..._grouped_gemm_with_blockwise_scaling_with_sparse_groups).

    What this port covers:

    - The *sparse-groups* host-side semantics: groups whose problem sizes
      are zero or smaller than the tile shape are passed through as-is,
      aligned up to multiples of 128 for the kernel, and skipped by the
      persistent group tile scheduler (``cta_tile_count_k == 0``).
    - The reported bandwidth (GBPS) is computed against the *original* (un-
      padded) sizes, so empty groups contribute zero bandwidth.

    What it does NOT cover (yet, follow-up):

    - The actual *pingpong* WGMMA schedule. The C++ source uses
      ``KernelPtrArrayTmaWarpSpecializedPingpongFP8Blockwise``, in which two
      MMA warpgroups alternate on independent tiles. Pingpong requires
      per-WG tensormap workspace (since WG0 and WG1 may be in different
      groups concurrently) plus per-WG epilogue SMEM and tile-scheduler
      iteration; it is a substantial kernel rewrite. This port reuses the
      cooperative scheduling from the dense Example 68 variant — same
      ``atom_layout_mnk = (2, 1, 1)`` and one tile per CTA — which still
      handles sparse groups correctly, just without the pingpong throughput
      overlap.

    Tensormap slots: A=0, B=1, D=2 (no separate C slot — beta = 0 only).
    """

    num_tensormaps = 3
    bytes_per_tensormap = 128

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

        # Tile (M, N, K); K filled in by _setup_attributes once dtypes are
        # known. Cooperative atom layout — see the class docstring for the
        # pingpong follow-up.
        self.tile_shape_mnk = (128, 128, 1)
        self.atom_layout_mnk = (2, 1, 1)

        self.occupancy = 1
        self.num_dma_warp_groups = 1
        self.num_mma_warp_groups = math.prod(self.atom_layout_mnk)
        self.num_warps_per_warp_group = 4
        self.num_threads_per_warp_group = self.num_warps_per_warp_group * 32
        self.threads_per_cta = (
            self.num_dma_warp_groups + self.num_mma_warp_groups
        ) * self.num_threads_per_warp_group
        self.num_mma_threads = self.num_mma_warp_groups * self.num_threads_per_warp_group
        self.load_warp_id = 0
        self.epi_store_warp_id = self.num_dma_warp_groups * self.num_warps_per_warp_group
        # Register split: math warpgroups want as many regs as possible to
        # avoid spills in the WGMMA inner loop + scale-and-accumulate path.
        # Sweep (cf. PR1) showed 24/240 dominates 40/232. DMA warps only hold
        # TMA descriptors + barrier addrs, so 24 regs is sufficient.
        self.load_register_requirement = 24
        self.mma_register_requirement = 240
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_90")
        self.buffer_align_bytes = 1024

        # Filled by _setup_attributes once dtypes/layouts are known.
        self.tiled_mma = None
        self.num_mcast_ctas_a = None
        self.num_mcast_ctas_b = None
        self.is_a_mcast = False
        self.is_b_mcast = False
        self.ab_stage = None
        self.epi_stage = None
        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None
        self.shared_storage = None

        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=self.num_mma_threads,
        )

    # ------------------------------------------------------------------
    # Host-side setup
    # ------------------------------------------------------------------

    def _setup_attributes(self):
        self.tiled_mma = sm90_utils.make_trivial_tiled_mma(
            self.a_dtype, self.b_dtype,
            self.a_layout.sm90_mma_major_mode(),
            self.b_layout.sm90_mma_major_mode(),
            self.acc_dtype,
            self.atom_layout_mnk,
            tiler_mn=(64, self.tile_shape_mnk[1]),
        )
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

        self.cluster_tile_shape_mnk = (
            self.tile_shape_mnk[0] * self.cluster_shape_mn[0],
            self.tile_shape_mnk[1] * self.cluster_shape_mn[1],
            self.tile_shape_mnk[2],
        )

        self.epi_tile = self._sm90_compute_tile_shape_or_override(
            self.tile_shape_mnk, self.c_dtype, is_cooperative=True
        )

        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk, self.a_dtype, self.b_dtype,
            self.epi_tile, self.c_dtype, self.smem_capacity, self.occupancy,
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk, self.epi_tile,
            self.a_dtype, self.a_layout,
            self.b_dtype, self.b_layout,
            self.ab_stage, self.c_dtype, self.c_layout, self.epi_stage,
        )

    # ------------------------------------------------------------------
    # JIT entry point
    # ------------------------------------------------------------------

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,       # FP8E4M3FN K-major carrier
        initial_b: cute.Tensor,       # FP8E4M3FN K-major carrier
        initial_d: cute.Tensor,       # FP8E4M3FN M-major carrier (D output)
        group_count: cutlass.Constexpr[int],
        problem_sizes: cute.Tensor,   # (G, 4) Int32: (M, N, K, L)
        strides_abcd: cute.Tensor,    # (G, 3, 2) Int32: A, B, D
        ptrs_abcd: cute.Tensor,       # (G, 3) Int64: A(0), B(1), D(2)
        ptrs_sfa: cute.Tensor,        # (G,) Int64
        ptrs_sfb: cute.Tensor,        # (G,) Int64
        alphas: cute.Tensor,          # (G,) Float32
        betas: cute.Tensor,           # (G,) Float32
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_tensor: cute.Tensor, # (num_sms, 3, 16) Int64
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        self.a_dtype  = initial_a.element_type
        self.b_dtype  = initial_b.element_type
        self.c_dtype  = initial_d.element_type   # D output dtype (FP8)
        self.a_layout = utils.LayoutEnum.from_tensor(initial_a)
        self.b_layout = utils.LayoutEnum.from_tensor(initial_b)
        self.c_layout = utils.LayoutEnum.from_tensor(initial_d)

        self._setup_attributes()

        tma_atom_a, tma_tensor_a = self._make_tma_atoms_and_tensors(
            initial_a, self.a_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[1],
        )
        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            initial_b, self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            self.cluster_shape_mn[0],
        )
        tma_atom_d, tma_tensor_d = self._make_tma_store_atoms_and_tensors(
            initial_d, self.epi_smem_layout_staged, self.epi_tile,
        )

        tile_sched_params, grid = self._compute_grid(
            total_num_clusters, self.cluster_shape_mn, max_active_clusters,
        )

        @cute.struct
        class SharedStorage:
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2,
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
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
            group_count,
            problem_sizes,
            strides_abcd,
            ptrs_abcd,
            ptrs_sfa,
            ptrs_sfb,
            alphas,
            betas,
            tensormap_tensor,
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
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mn3: cute.Tensor,
        strides_abcd: cute.Tensor,
        ptrs_abcd: cute.Tensor,
        ptrs_sfa: cute.Tensor,
        ptrs_sfb: cute.Tensor,
        alphas: cute.Tensor,
        betas: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

        # PDL: wait for prior kernel on this stream before TMA. Paired with
        # use_pdl=True on .launch(); no-op without it.
        cute.arch.griddepcontrol_wait()

        cta_rank_in_cluster = cute.arch.make_warp_uniform(cute.arch.block_idx_in_cluster())
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

        sA = storage.sA.get_tensor(a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner)
        sB = storage.sB.get_tensor(b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner)
        sD = storage.sD.get_tensor(epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner)

        # Local-tile the carrier tensors so cute.copy gets the right TMA
        # coordinate structure; the descriptor's address/extent is patched
        # at runtime via update_tma_descriptor.
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.tile_shape_mnk, (None, 0, None)), (None, None, None),
        )
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.tile_shape_mnk, (0, None, None)), (None, None, None),
        )
        gD_mnl = cute.local_tile(
            mD_mnl, cute.slice_(self.tile_shape_mnk, (None, None, 0)), (None, None, None),
        )

        # TMA load partitions for A and B.
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_a, a_cta_crd, a_cta_layout,
            cute.group_modes(sA, 0, 2), cute.group_modes(gA_mkl, 0, 2),
        )

        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_b, b_cta_crd, b_cta_layout,
            cute.group_modes(sB, 0, 2), cute.group_modes(gB_nkl, 0, 2),
        )

        # MMA warpgroup-level thread slice
        warp_group_idx = cute.arch.make_warp_uniform(tidx // self.num_threads_per_warp_group)
        mma_wg_layout = cute.make_layout(self.num_mma_warp_groups, stride=self.num_threads_per_warp_group)
        thr_mma = tiled_mma.get_slice(mma_wg_layout(warp_group_idx - self.num_dma_warp_groups))

        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)

        # Use tile (0,0,0) of D proxy for acc_shape — shape is the same for all tiles
        tCgD_shape = thr_mma.partition_C(gD_mnl[(None, None, 0, 0, 0)])
        acc_shape = tCgD_shape.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)
        accum_temp   = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        # Per-thread MMA slice for coordinate tensors (abs M-row / N-col lookups)
        tidx_mma = tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
        thr_mma_c = tiled_mma.get_slice(tidx_mma)

        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # Per-SM tensor map slots: A=0, B=1, D=2.
        bid = cute.arch.block_idx()
        grid_dim = cute.arch.grid_dim()
        sm_idx = bid[2] * grid_dim[1] * grid_dim[0] + bid[1] * grid_dim[0] + bid[0]

        tensormap_manager = utils.TensorMapManager(
            utils.TensorMapUpdateMode.GMEM,
            HopperFP8GroupedBlockwiseSparseGroupsGemmKernel.bytes_per_tensormap,
        )
        tensormap_a_ptr = tensormap_manager.get_tensormap_ptr(tensormaps[(sm_idx, 0, None)].iterator)
        tensormap_b_ptr = tensormap_manager.get_tensormap_ptr(tensormaps[(sm_idx, 1, None)].iterator)
        tensormap_d_ptr = tensormap_manager.get_tensormap_ptr(tensormaps[(sm_idx, 2, None)].iterator)

        is_dma_warp_group = warp_group_idx < self.num_dma_warp_groups
        if is_dma_warp_group:
            cute.arch.warpgroup_reg_dealloc(self.load_register_requirement)

        # ==================================================================
        # DMA warpgroup: TMA loads for A and B, update tensormaps A/B per group
        # ==================================================================
        if warp_idx == self.load_warp_id:
            tensormap_manager.init_tensormap_from_atom(tma_atom_a, tensormap_a_ptr, self.load_warp_id)
            tensormap_manager.init_tensormap_from_atom(tma_atom_b, tensormap_b_ptr, self.load_warp_id)
            tensormap_manager.fence_tensormap_initialization()

            last_group_idx = cutlass.Int32(-1)

            tile_sched = StaticPersistentGroupTileScheduler.create(
                tile_sched_params, bid, grid_dim,
                self.cluster_tile_shape_mnk,
                utils.create_initial_search_state(),
                group_count, problem_sizes_mn3,
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.ab_stage,
            )

            while work_tile.is_valid_tile:
                grouped_info = work_tile.group_search_result
                cur_group_idx = grouped_info.group_idx
                cur_k_tile_cnt = grouped_info.cta_tile_count_k

                if cur_k_tile_cnt != 0:
                    is_group_changed = cur_group_idx != last_group_idx

                    if is_group_changed:
                        problem_shape_mnk = (
                            grouped_info.problem_shape_m,
                            grouped_info.problem_shape_n,
                            grouped_info.problem_shape_k,
                        )
                        real_a = self.make_tensor_for_tensormap_update(
                            cur_group_idx, self.a_dtype, problem_shape_mnk,
                            strides_abcd, ptrs_abcd, 0,
                        )
                        real_b = self.make_tensor_for_tensormap_update(
                            cur_group_idx, self.b_dtype, problem_shape_mnk,
                            strides_abcd, ptrs_abcd, 1,
                        )
                        tensormap_manager.update_tensormap(
                            (real_a, real_b), (tma_atom_a, tma_atom_b),
                            (tensormap_a_ptr, tensormap_b_ptr),
                            self.load_warp_id,
                            (None, None),
                        )
                        tensormap_manager.fence_tensormap_update(tensormap_a_ptr)
                        tensormap_manager.fence_tensormap_update(tensormap_b_ptr)

                    mma_coord = (grouped_info.cta_tile_idx_m, grouped_info.cta_tile_idx_n, 0)
                    tAgA_slice = tAgA[(None, mma_coord[0], None, mma_coord[2])]
                    tBgB_slice = tBgB[(None, mma_coord[1], None, mma_coord[2])]

                    tma_a_desc_nvvm = tensormap_manager.get_tensormap_ptr(tensormap_a_ptr, cute.AddressSpace.gmem)
                    tma_b_desc_nvvm = tensormap_manager.get_tensormap_ptr(tensormap_b_ptr, cute.AddressSpace.gmem)
                    tma_a_desc_copy = tensormap_manager.get_tensormap_ptr(tensormap_a_ptr, cute.AddressSpace.generic)
                    tma_b_desc_copy = tensormap_manager.get_tensormap_ptr(tensormap_b_ptr, cute.AddressSpace.generic)

                    _tile_k = self.tile_shape_mnk[2]
                    _tile_m = self.tile_shape_mnk[0]
                    _tile_n = self.tile_shape_mnk[1]
                    use_nvvm_non_mcast = cutlass.const_expr(
                        _ENABLE_NVVM_NON_MCAST_LOAD and not self.is_a_mcast and not self.is_b_mcast
                    )

                    mainloop_producer_state.reset_count()
                    for k_tile in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                        mainloop_pipeline.producer_acquire(mainloop_producer_state)
                        if use_nvvm_non_mcast:
                            _tma_load_ab_nvvm_no_mcast(
                                k_tile * _tile_k,
                                mma_coord[0] * _tile_m,
                                mma_coord[1] * _tile_n,
                                tma_a_desc_nvvm, tma_b_desc_nvvm,
                                tAsA[(None, mainloop_producer_state.index)].iterator,
                                tBsB[(None, mainloop_producer_state.index)].iterator,
                                mainloop_pipeline.producer_get_barrier(mainloop_producer_state),
                            )
                        else:
                            cute.copy(
                                tma_atom_a,
                                tAgA_slice[(None, k_tile)],
                                tAsA[(None, mainloop_producer_state.index)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(mainloop_producer_state),
                                mcast_mask=a_mcast_mask,
                                tma_desc_ptr=tma_a_desc_copy,
                            )
                            cute.copy(
                                tma_atom_b,
                                tBgB_slice[(None, k_tile)],
                                tBsB[(None, mainloop_producer_state.index)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(mainloop_producer_state),
                                mcast_mask=b_mcast_mask,
                                tma_desc_ptr=tma_b_desc_copy,
                            )
                        mainloop_pipeline.producer_commit(mainloop_producer_state)
                        mainloop_producer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                last_group_idx = cur_group_idx

            mainloop_pipeline.producer_tail(mainloop_producer_state)

        # ==================================================================
        # MMA warpgroup: grouped blockwise FP8 K-loop + per-row SFA + epilogue
        # ==================================================================
        if not is_dma_warp_group:
            cute.arch.warpgroup_reg_alloc(self.mma_register_requirement)

            # MMA warpgroup initializes the D tensor map.
            tensormap_manager.init_tensormap_from_atom(tma_atom_d, tensormap_d_ptr, self.epi_store_warp_id)
            tensormap_manager.fence_tensormap_initialization()

            tile_sched = StaticPersistentGroupTileScheduler.create(
                tile_sched_params, bid, grid_dim,
                self.cluster_tile_shape_mnk,
                utils.create_initial_search_state(),
                group_count, problem_sizes_mn3,
            )
            work_tile = tile_sched.initial_work_tile_info()

            mainloop_consumer_read_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )
            mainloop_consumer_release_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )

            num_k_blocks = cute.size(tCrA, mode=[2])
            k_pipe_mmas = 1

            # Epilogue R2S setup
            copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
                self.c_layout, elem_ty_d=self.c_dtype, elem_ty_acc=self.acc_dtype,
            )
            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(self.c_layout.is_m_major_c(), 4),
                self.c_dtype,
            )
            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)
            tiled_copy_r2s = cute.make_tiled_copy_S(copy_atom_r2s, tiled_copy_C_Atom)

            thr_copy_r2s = tiled_copy_r2s.get_slice(tidx_mma)
            tRS_sD   = thr_copy_r2s.partition_D(sD)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD     = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            tRS_rD_out = cute.make_rmem_tensor(tRS_rD_layout.shape, self.c_dtype)
            size_tRS_rD = cute.size(tRS_rD)

            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mma_threads
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            last_group_idx_mma = cutlass.Int32(-1)

            while work_tile.is_valid_tile:
                grouped_info = work_tile.group_search_result
                cur_group_idx = grouped_info.group_idx
                cur_k_tile_cnt = grouped_info.cta_tile_count_k

                # Update tensor map D when the group changes (epi_store warp only).
                is_group_changed = cur_group_idx != last_group_idx_mma
                if is_group_changed and warp_idx == self.epi_store_warp_id:
                    real_d = self.make_tensor_for_tensormap_update(
                        cur_group_idx, self.c_dtype,
                        (grouped_info.problem_shape_m, grouped_info.problem_shape_n,
                         grouped_info.problem_shape_k),
                        strides_abcd, ptrs_abcd, 2,
                    )
                    tensormap_manager.update_tensormap(
                        (real_d,), (tma_atom_d,), (tensormap_d_ptr,),
                        self.epi_store_warp_id, (None,),
                    )
                    tensormap_manager.fence_tensormap_update(tensormap_d_ptr)

                mma_coord = (grouped_info.cta_tile_idx_m, grouped_info.cta_tile_idx_n, 0)
                gD_mnl_slice = gD_mnl[(None, None, *mma_coord)]

                m_g, n_g, k_g = (
                    grouped_info.problem_shape_m,
                    grouped_info.problem_shape_n,
                    grouped_info.problem_shape_k,
                )
                k_tiles_g  = k_g // cutlass.Int32(SCALE_GRAN_K)
                n_blocks_g = n_g // cutlass.Int32(SCALE_GRAN_N)

                alpha_g = alphas[cur_group_idx]
                # ``betas`` is plumbed through but not used: only beta = 0 is
                # supported. The argument is kept as a forward-looking hook for
                # a future beta * C epilogue.

                # SFA_g: (M_g, K_tiles_g) Float32, K-major.
                mSFA_g = cute.make_tensor(
                    cute.make_ptr(cutlass.Float32, ptrs_sfa[cur_group_idx],
                                  cute.AddressSpace.gmem, assumed_align=4),
                    cute.make_layout((m_g, k_tiles_g), stride=(k_tiles_g, cutlass.Int32(1))),
                )
                # SFB_g: (N_blocks_g, K_tiles_g) Float32, K-major.
                mSFB_g = cute.make_tensor(
                    cute.make_ptr(cutlass.Float32, ptrs_sfb[cur_group_idx],
                                  cute.AddressSpace.gmem, assumed_align=4),
                    cute.make_layout((n_blocks_g, k_tiles_g), stride=(k_tiles_g, cutlass.Int32(1))),
                )
                # tile_N == SCALE_GRAN_N == 128, so each N-tile maps to one SFB row.
                sfb_n_idx = mma_coord[1]

                # Coordinate tensor giving the absolute M-row of each
                # accumulator element: stride (1, 0) means dim 0 (M) advances
                # the value, dim 1 (N) does not.
                gM_row_tensor = cute.make_tensor(
                    mma_coord[0] * cutlass.Int32(self.tile_shape_mnk[0]),
                    cute.make_layout(
                        (self.tile_shape_mnk[0], self.tile_shape_mnk[1]),
                        stride=(1, 0),
                    ),
                )
                tCgM_rows = thr_mma_c.partition_C(gM_row_tensor)

                # MAINLOOP: WGMMA into accum_temp; scale by SFA*SFB and
                # add into accumulators once each K-tile completes.
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)

                tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)
                cute.nvgpu.warpgroup.fence()

                prologue_mma_cnt = cutlass.min(k_pipe_mmas, cur_k_tile_cnt)

                # Prologue: first K-tile WGMMA (no pipeline release yet).
                for k_tile in cutlass.range(0, prologue_mma_cnt, 1, unroll=1):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (None, None, k_block_idx, mainloop_consumer_read_state.index)
                        cute.gemm(tiled_mma, accum_temp, tCrA[k_block_coord], tCrB[k_block_coord], accum_temp)
                        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
                    cute.nvgpu.warpgroup.commit_group()
                    mainloop_consumer_read_state.advance()

                # Main loop: scale previous K-tile, WGMMA for current K-tile
                for k_tile in cutlass.range(prologue_mma_cnt, cur_k_tile_cnt, 1, unroll=1):
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)

                    # Wait for previous WGMMA before reading accum_temp
                    cute.nvgpu.warpgroup.wait_group(0)

                    prev_k = mainloop_consumer_read_state.count - 1
                    sfb_val = mSFB_g[(sfb_n_idx, prev_k)]
                    for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                        for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                            for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                                m_row = tCgM_rows[(r1, r2, v)]
                                sfa_val = mSFA_g[(m_row, prev_k)]
                                accumulators[(r1, r2, v)] = (
                                    accumulators[(r1, r2, v)]
                                    + sfa_val * sfb_val * accum_temp[(r1, r2, v)]
                                )

                    # Reset accum_temp for this K-tile
                    cute.nvgpu.warpgroup.fence()
                    tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, False)

                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (None, None, k_block_idx, mainloop_consumer_read_state.index)
                        cute.gemm(tiled_mma, accum_temp, tCrA[k_block_coord], tCrB[k_block_coord], accum_temp)
                        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

                    cute.nvgpu.warpgroup.commit_group()
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()
                    mainloop_consumer_read_state.advance()

                # Apply the last K-tile's scale (its WGMMA was issued in the
                # last iteration above but not yet folded into accumulators).
                cute.nvgpu.warpgroup.wait_group(0)
                if cur_k_tile_cnt > 0:
                    last_k = mainloop_consumer_read_state.count - 1
                    sfb_val = mSFB_g[(sfb_n_idx, last_k)]
                    for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                        for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                            for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                                m_row = tCgM_rows[(r1, r2, v)]
                                sfa_val = mSFA_g[(m_row, last_k)]
                                accumulators[(r1, r2, v)] = (
                                    accumulators[(r1, r2, v)]
                                    + sfa_val * sfb_val * accum_temp[(r1, r2, v)]
                                )

                # Release the K-tile pipeline stages held by the prologue.
                for k_tile in cutlass.range(0, prologue_mma_cnt, 1, unroll=1):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # Epilogue: D = alpha_g * accum (beta * C is not implemented).
                for v in cutlass.range_constexpr(cute.size(acc_shape[2])):
                    for r2 in cutlass.range_constexpr(cute.size(acc_shape[1])):
                        for r1 in cutlass.range_constexpr(cute.size(acc_shape[0])):
                            accumulators[(r1, r2, v)] = alpha_g * accumulators[(r1, r2, v)]

                # R2S + TMA store of D, with the float32 accumulator
                # converted to FP8 on the way out.
                tCgD_for_tma = cute.zipped_divide(gD_mnl_slice, self.epi_tile)
                bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_d, 0, cute.make_layout(1),
                    cute.group_modes(sD, 0, 2),
                    tCgD_for_tma,
                )

                epi_tile_num   = cute.size(tCgD_for_tma, mode=[1])
                epi_tile_shape = tCgD_for_tma.shape[1]
                epi_tile_layout = cute.make_layout(epi_tile_shape, stride=(epi_tile_shape[1], 1))

                num_prev_epi_tiles = tile_sched.num_tiles_executed * epi_tile_num
                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.c_dtype))

                    epi_buffer = (num_prev_epi_tiles + epi_idx) % cute.size(tRS_sD, mode=[3])
                    cute.copy(tiled_copy_r2s, tRS_rD_out, tRS_sD[(None, None, None, epi_buffer)])

                    cute.arch.fence_proxy("async.shared", space="cta")
                    self.epilog_sync_barrier.arrive_and_wait()

                    if warp_idx == self.epi_store_warp_id:
                        cute.copy(
                            tma_atom_d,
                            bSG_sD[(None, epi_buffer)],
                            bSG_gD[(None, gmem_coord)],
                            tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                tensormap_d_ptr, cute.AddressSpace.generic
                            ),
                        )
                        tma_store_pipeline.producer_commit()
                        tma_store_pipeline.producer_acquire()

                    self.epilog_sync_barrier.arrive_and_wait()

                last_group_idx_mma = cur_group_idx
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            tma_store_pipeline.producer_tail()

    # ------------------------------------------------------------------
    # Per-group tensor construction for TMA descriptor updates
    # ------------------------------------------------------------------

    @cute.jit
    def make_tensor_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: tuple,
        strides_abcd: cute.Tensor,
        ptrs_abcd: cute.Tensor,
        tensor_index: int,
    ):
        """Build a 3D CuTe tensor describing real-A/B/D for descriptor update.

        ``tensor_index`` selects A (0, K-major), B (1, K-major), or D (2, M-major).
        The tensor's element type, base pointer, shape (M, K, 1) / (N, K, 1) /
        (M, N, 1), and strides come from the per-group metadata tables; the L
        dim is always extent 1.
        """
        ptr_i64 = ptrs_abcd[(group_idx, tensor_index)]
        tensor_gmem_ptr = cute.make_ptr(dtype, ptr_i64, cute.AddressSpace.gmem, assumed_align=16)

        strides_reg = cute.make_rmem_tensor(cute.make_layout(2), strides_abcd.element_type)
        cute.autovec_copy(strides_abcd[(group_idx, tensor_index, None)], strides_reg)
        stride_0 = strides_reg[0]
        stride_1 = strides_reg[1]
        c0, c1 = cutlass.Int32(0), cutlass.Int32(1)

        m, n, k = problem_shape_mnk
        if cutlass.const_expr(tensor_index == 0):       # A: (M, K, 1) K-major
            shape = (m, k, c1)
        elif cutlass.const_expr(tensor_index == 1):     # B: (N, K, 1) K-major
            shape = (n, k, c1)
        else:                                            # D: (M, N, 1) M-major
            shape = (m, n, c1)
        return cute.make_tensor(
            tensor_gmem_ptr,
            cute.make_layout(shape, stride=(stride_0, stride_1, c0)),
        )

    # ------------------------------------------------------------------
    # Static helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _compute_stages(tile_shape_mnk, a_dtype, b_dtype, epi_tile, c_dtype, smem_capacity, occupancy):
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
    def _sm90_compute_tile_shape_or_override(tile_shape_mnk, element_type, is_cooperative=False,
                                              epi_tile_override=None):
        if epi_tile_override is not None:
            return epi_tile_override
        if is_cooperative:
            tile_m = min(128, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(32,  cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)
        else:
            n_perf = 64 if element_type.width == 8 else 32
            tile_m = min(64, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(n_perf, cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)

    @staticmethod
    def _make_smem_layouts(tile_shape_mnk, epi_tile, a_dtype, a_layout, b_dtype, b_layout,
                           ab_stage, c_dtype, c_layout, epi_stage):
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        a_is_k_major = (a_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K)
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]
        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(a_layout, a_dtype, a_major_mode_size), a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom, cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        b_is_k_major = (b_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K)
        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(b_layout, b_dtype, b_major_mode_size), b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom, cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(c_layout, c_dtype, c_major_mode_size), c_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom, cute.append(epi_tile, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )

        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    @staticmethod
    def _compute_grid(total_num_clusters, cluster_shape_mn, max_active_clusters):
        problem_shape_ntile_mnl = (
            cluster_shape_mn[0], cluster_shape_mn[1], cutlass.Int32(total_num_clusters),
        )
        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (*cluster_shape_mn, 1)
        )
        grid = StaticPersistentGroupTileScheduler.get_grid_shape(tile_sched_params, max_active_clusters)
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


# ===========================================================================
# Host driver
# ===========================================================================


def _parse_ints(s: str):
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError("Expected comma-separated integers.")


def _parse_problem_sizes(s: str) -> List[Tuple[int, int, int]]:
    """Parse "(256,256,256),(512,128,256)" into [(256,256,256),(512,128,256)]."""
    tuples = re.findall(r'\((\d+),(\d+),(\d+)\)', s)
    if not tuples:
        raise argparse.ArgumentTypeError(
            'Expected format: "(M,N,K),(M2,N2,K2),..."'
        )
    return [(int(m), int(n), int(k)) for m, n, k in tuples]


def _device_tensor(
    mode0: int,
    mode1: int,
    is_mode0_major: bool,
    dtype: Type[cutlass.Numeric],
    init_type: TensorInitType = TensorInitType.RANDOM,
) -> torch.Tensor:
    """Allocate a (1, mode0, mode1) device tensor through ``cute_tensor_like``.

    Routing through ``cute_tensor_like`` (rather than using
    ``cutlass_torch.matrix`` directly) ensures the GPU tensor lands in the
    canonical CUDA VA region. Pointers from this region are valid TMA
    descriptor inputs; pointers from the low-VA pool ``cutlass_torch.matrix``
    sometimes returns are not, and lead to ``CUDA_ERROR_ILLEGAL_ADDRESS`` at
    the TMA load.
    """
    cpu = cutlass_torch.matrix(1, mode0, mode1, is_mode0_major, dtype, init_type=init_type)
    _, gpu = cutlass_torch.cute_tensor_like(cpu, dtype, is_dynamic_layout=True, assumed_align=16)
    return gpu


def create_tensors_for_all_groups(
    problem_sizes: List[Tuple[int, int, int]],
):
    """
    Allocate per-group A, B, C, D, SFA, SFB tensors.

    Per group g with (M, N, K):
      A : (M, K, 1) FP8 E4M3FN, K-major (stride = (K, 1))
      B : (N, K, 1) FP8 E4M3FN, K-major
      C : (M, N, 1) FP8 E4M3FN, M-major (currently unused; beta = 0)
      D : (M, N, 1) FP8 E4M3FN, M-major, zero-initialised
      SFA : (M, K // 128) Float32, K-major
      SFB : (N // 128, K // 128) Float32, K-major

    Returns lists of per-group GPU torch tensors plus the ABD stride / pointer
    metadata in the formats the kernel expects:
      strides_abcd : List of length G, each [stride_A, stride_B, stride_D]
                     where each stride is (row_stride, col_stride).
      ptrs_abcd    : List of length G, each [ptr_A, ptr_B, ptr_D] (Int64).
      ptrs_sfa, ptrs_sfb : List of length G of Int64 base pointers.
    """
    fp8 = cutlass.Float8E4M3FN
    f32 = cutlass.Float32
    scalar = TensorInitType.SCALAR

    a_list, b_list, c_list, d_list, sfa_list, sfb_list = [], [], [], [], [], []
    strides_abcd, ptrs_abcd = [], []
    ptrs_sfa, ptrs_sfb = [], []

    # Empty groups (any zero dim) still need valid GMEM pointers in the
    # metadata table — the kernel skips them via the persistent group tile
    # scheduler, but the per-CTA tensormap-update path runs unconditionally
    # and would crash on a null pointer. Allocate one shared stub set.
    stub_extent = SCALE_GRAN_K  # any 128-element-aligned size works
    stub_a   = _device_tensor(stub_extent, stub_extent, is_mode0_major=False, dtype=fp8)
    stub_b   = _device_tensor(stub_extent, stub_extent, is_mode0_major=False, dtype=fp8)
    stub_d   = _device_tensor(stub_extent, stub_extent, is_mode0_major=True,  dtype=fp8, init_type=scalar)
    stub_sfa = _device_tensor(stub_extent, 1, is_mode0_major=False, dtype=f32, init_type=scalar)
    stub_sfb = _device_tensor(1, 1,           is_mode0_major=False, dtype=f32, init_type=scalar)

    def _append(a, b, c, d, sfa, sfb):
        a_list.append(a);   b_list.append(b);   c_list.append(c);   d_list.append(d)
        sfa_list.append(sfa); sfb_list.append(sfb)
        strides_abcd.append([list(a.stride()[:-1]), list(b.stride()[:-1]), list(d.stride()[:-1])])
        ptrs_abcd.append([a.data_ptr(), b.data_ptr(), d.data_ptr()])
        ptrs_sfa.append(sfa.data_ptr())
        ptrs_sfb.append(sfb.data_ptr())

    for m, n, k in problem_sizes:
        if m == 0 or n == 0 or k == 0:
            # Empty group: bind the stubs, skipped by the scheduler.
            _append(stub_a, stub_b, stub_d, stub_d, stub_sfa, stub_sfb)
            continue

        k_tiles = k // SCALE_GRAN_K
        n_tiles = n // SCALE_GRAN_N

        a = _device_tensor(m, k, is_mode0_major=False, dtype=fp8)
        b = _device_tensor(n, k, is_mode0_major=False, dtype=fp8)
        c = _device_tensor(m, n, is_mode0_major=True,  dtype=fp8)             # unused (beta = 0)
        d = _device_tensor(m, n, is_mode0_major=True,  dtype=fp8, init_type=scalar)

        # Random scale factors in [0.5, 1.5] keep FP8 outputs in range.
        sfa_cpu = cutlass_torch.matrix(1, m,       k_tiles, False, f32, init_type=scalar)
        sfb_cpu = cutlass_torch.matrix(1, n_tiles, k_tiles, False, f32, init_type=scalar)
        torch.nn.init.uniform_(sfa_cpu, 0.5, 1.5)
        torch.nn.init.uniform_(sfb_cpu, 0.5, 1.5)
        _, sfa = cutlass_torch.cute_tensor_like(sfa_cpu, f32, is_dynamic_layout=True, assumed_align=16)
        _, sfb = cutlass_torch.cute_tensor_like(sfb_cpu, f32, is_dynamic_layout=True, assumed_align=16)

        _append(a, b, c, d, sfa, sfb)

    return (
        a_list, b_list, c_list, d_list, sfa_list, sfb_list,
        strides_abcd, ptrs_abcd, ptrs_sfa, ptrs_sfb,
    )


# ---------------------------------------------------------------------------
# PyTorch reference (grouped FP8 per-row-SFA × blockwise-SFB GEMM)
# ---------------------------------------------------------------------------

def reference_grouped_blockwise_gemm(
    a_list, b_list, c_list, sfa_list, sfb_list,
    alpha_vals, beta_vals,
):
    """
    Reference for each group g:
      accum[m,n] = sum_k SFA_g[m,k] * SFB_g[n//128,k] * A_g[m,ks:ke] @ B_g[:,ks:ke].T
      D_g[m,n]   = alpha_g * accum[m,n] + beta_g * C_g[m,n]

    All tensors follow CuTe convention (M, K, L), (N, K, L), (M, N, L).
    SFA: (M, K_tiles, L), SFB: (N_tiles, K_tiles, L).
    Returns list of (M, N, 1) Float32 reference D tensors.
    """
    d_ref_list = []
    for g, (a_fp8, b_fp8, c_fp8, sfa, sfb) in enumerate(
        zip(a_list, b_list, c_list, sfa_list, sfb_list)
    ):
        alpha = alpha_vals[g]
        beta  = beta_vals[g]

        # a_fp8: (M, K, 1) stored as int8 bit-pattern by cutlass_torch.matrix
        m, k, _ = a_fp8.shape
        n       = b_fp8.shape[0]
        k_tiles = k // SCALE_GRAN_K
        n_tiles = n // SCALE_GRAN_N

        a_f32 = a_fp8.cpu().view(torch.float8_e4m3fn).to(torch.float32)  # (M, K, 1)
        b_f32 = b_fp8.cpu().view(torch.float8_e4m3fn).to(torch.float32)  # (N, K, 1)
        c_f32 = c_fp8.cpu().view(torch.float8_e4m3fn).to(torch.float32)  # (M, N, 1)

        # Remove batch dim: (M, K), (N, K), (M, N)
        a_f32 = a_f32[:, :, 0]
        b_f32 = b_f32[:, :, 0]
        c_f32 = c_f32[:, :, 0]

        # SFA: (M, K_tiles, 1) → (M, K_tiles)
        sfa_cpu = sfa.cpu()[:, :, 0]   # (M, K_tiles)
        # SFB: (N_tiles, K_tiles, 1) → (N_tiles, K_tiles)
        sfb_cpu = sfb.cpu()[:, :, 0]   # (N_tiles, K_tiles)

        accum = torch.zeros(m, n, dtype=torch.float32)
        for kt in range(k_tiles):
            ks, ke = kt * SCALE_GRAN_K, (kt + 1) * SCALE_GRAN_K
            partial = a_f32[:, ks:ke] @ b_f32[:, ks:ke].t()  # (M, N)
            sfa_k = sfa_cpu[:, kt]                             # (M,)
            sfb_k = sfb_cpu[:, kt]                             # (N_tiles,)
            sfb_k_full = sfb_k.repeat_interleave(SCALE_GRAN_N)[:n]  # (N,)
            accum += sfa_k[:, None] * sfb_k_full[None, :] * partial

        d_ref = alpha * accum + beta * c_f32  # (M, N) float32
        # Clip to FP8 E4M3FN range [-448, 448] before quantisation
        fp8_max = 448.0
        d_ref_clipped = d_ref.clamp(-fp8_max, fp8_max)
        # Quantise to FP8 then back to float32 for comparison
        d_ref_fp8 = d_ref_clipped.to(torch.float8_e4m3fn).to(torch.float32)

        d_ref_list.append(d_ref_fp8)
    return d_ref_list


# ---------------------------------------------------------------------------
# Host driver
# ---------------------------------------------------------------------------

def run(
    problem_sizes: List[Tuple[int, int, int]],
    cluster_shape_mn: Tuple[int, int] = (1, 2),
    swizzle_size: int = 1,
    raster_along_m: bool = True,
    alpha_vals: List[float] = None,
    beta_vals: List[float] = None,
    tolerance: float = 1.0,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
):
    """Build per-group tensors, compile and run the kernel, optionally benchmark."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    num_groups = len(problem_sizes)
    if alpha_vals is None:
        alpha_vals = [1.0] * num_groups
    if beta_vals is None:
        beta_vals = [0.0] * num_groups

    # A group is considered empty when any of its dims is zero. Non-empty
    # groups must have M/N/K aligned to the scale granularity (128).
    for g, (m, n, k) in enumerate(problem_sizes):
        is_empty = m == 0 or n == 0 or k == 0
        if not is_empty and (m % SCALE_GRAN_K or n % SCALE_GRAN_K or k % SCALE_GRAN_K):
            raise ValueError(
                f"Group {g}: M={m}, N={n}, K={k} must all be 0 or multiples of {SCALE_GRAN_K}"
            )

    active_groups = sum(1 for m, n, k in problem_sizes if m and n and k)
    print("Hopper FP8 Grouped Blockwise GEMM (Example 68 sparse-groups)")
    print(f"  num_groups      : {num_groups}  ({active_groups} active, {num_groups - active_groups} empty)")
    for g, ((m, n, k), a, b) in enumerate(zip(problem_sizes, alpha_vals, beta_vals)):
        tag = "" if (m and n and k) else "  [empty]"
        print(f"  group {g:2d}        : ({m},{n},{k})  alpha={a} beta={b}{tag}")
    print(f"  cluster_shape   : {cluster_shape_mn}")
    print(f"  swizzle_size    : {swizzle_size}")

    # ------------------------------------------------------------------
    # Allocate per-group tensors.
    # ------------------------------------------------------------------
    (
        a_list, b_list, c_list, d_list, sfa_list, sfb_list,
        strides_abcd, ptrs_abcd, ptrs_sfa_raw, ptrs_sfb_raw,
    ) = create_tensors_for_all_groups(problem_sizes)

    # ------------------------------------------------------------------
    # Carrier tensors: small placeholders that only carry dtype + majorness;
    # ``cute.compile`` records them in the TMA atoms, then real per-group
    # pointers/strides patch the descriptor at runtime.
    # ------------------------------------------------------------------
    fp8 = cutlass.Float8E4M3FN
    _min = 16 * 8 // fp8.width   # 16 elements: 16-byte aligned for FP8
    _carrier_keepalive: List[torch.Tensor] = []

    def _carrier(is_mode0_major: bool):
        cpu = cutlass_torch.matrix(1, _min, _min, is_mode0_major, fp8)
        ct, gpu = cutlass_torch.cute_tensor_like(cpu, fp8, is_dynamic_layout=True, assumed_align=16)
        _carrier_keepalive.append(gpu)
        return ct

    initial_a = _carrier(is_mode0_major=False)   # K-major
    initial_b = _carrier(is_mode0_major=False)   # K-major
    initial_d = _carrier(is_mode0_major=True)    # M-major

    # ------------------------------------------------------------------
    # Device metadata tensors.
    #
    # The GPU torch tensor returned by ``cute_tensor_like`` (second tuple
    # element) owns the underlying GMEM allocation; if it is dropped while a
    # CuTe view still references it, the kernel will read freed memory.
    # ------------------------------------------------------------------
    def _device(tensor: torch.Tensor, dtype):
        view, gpu = cutlass_torch.cute_tensor_like(
            tensor, dtype, is_dynamic_layout=False, assumed_align=16,
        )
        _carrier_keepalive.append(gpu)
        return view

    # Zero out *every* dim of an empty group before handing the table to
    # the kernel. The persistent group tile scheduler computes a group's
    # tile count from M*N alone (it doesn't gate on K), so a group with
    # M, N > 0 but K = 0 would still consume M*N linear tile slots and
    # offset every later group's tiles. Forcing all dims to zero makes the
    # scheduler reserve zero tiles uniformly. The original sizes are kept
    # for the reference / GBPS path.
    problem_sizes_mnkl = [
        ((m, n, k, 1) if (m and n and k) else (0, 0, 0, 1))
        for m, n, k in problem_sizes
    ]
    problem_sizes_tensor = _device(torch.tensor(problem_sizes_mnkl, dtype=torch.int32), cutlass.Int32)
    strides_tensor       = _device(torch.tensor(strides_abcd, dtype=torch.int32),       cutlass.Int32)
    ptrs_abcd_tensor     = _device(torch.tensor(ptrs_abcd, dtype=torch.int64),          cutlass.Int64)
    ptrs_sfa_tensor      = _device(torch.tensor(ptrs_sfa_raw, dtype=torch.int64),       cutlass.Int64)
    ptrs_sfb_tensor      = _device(torch.tensor(ptrs_sfb_raw, dtype=torch.int64),       cutlass.Int64)
    alphas_tensor        = _device(torch.tensor(alpha_vals, dtype=torch.float32),       cutlass.Float32)
    betas_tensor         = _device(torch.tensor(beta_vals, dtype=torch.float32),        cutlass.Float32)

    # ------------------------------------------------------------------
    # Tensor map workspace: (num_sms, 3, 16) Int64 — one slot per A/B/D.
    # ------------------------------------------------------------------
    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1],
    )
    bytes_per_tensormap = HopperFP8GroupedBlockwiseSparseGroupsGemmKernel.bytes_per_tensormap
    tensormap_shape = (
        sm_count,
        HopperFP8GroupedBlockwiseSparseGroupsGemmKernel.num_tensormaps,
        bytes_per_tensormap // 8,
    )
    tensormap_tensor = _device(torch.empty(tensormap_shape, dtype=torch.int64), cutlass.Int64)

    # ------------------------------------------------------------------
    # Compile the kernel. Tile shape (M, N) is 128x128 — see the kernel class.
    # ------------------------------------------------------------------
    cluster_tile_m = 128 * cluster_shape_mn[0]
    cluster_tile_n = 128 * cluster_shape_mn[1]
    # Empty groups (any zero dim) contribute zero work.
    total_num_clusters = sum(
        ((m + cluster_tile_m - 1) // cluster_tile_m)
        * ((n + cluster_tile_n - 1) // cluster_tile_n)
        for m, n, k in problem_sizes
        if m and n and k
    )

    # All-empty edge case: nothing to compute, nothing to validate. Return
    # before the kernel/benchmark calls (compile would still need a non-zero
    # grid, so we early-out instead).
    if total_num_clusters == 0:
        print("  No active groups — nothing to compute.")
        return 0

    kernel = HopperFP8GroupedBlockwiseSparseGroupsGemmKernel(
        cluster_shape_mn,
        swizzle_size=swizzle_size,
        raster_along_m=raster_along_m,
    )

    stream = cutlass_torch.default_stream()

    compiled_kernel = cute.compile(
        kernel,
        initial_a, initial_b, initial_d,
        num_groups,
        problem_sizes_tensor,
        strides_tensor,
        ptrs_abcd_tensor,
        ptrs_sfa_tensor,
        ptrs_sfb_tensor,
        alphas_tensor,
        betas_tensor,
        total_num_clusters,
        tensormap_tensor,
        max_active_clusters,
        stream,
    )

    # ------------------------------------------------------------------
    # Correctness check
    # ------------------------------------------------------------------
    if not skip_ref_check:
        compiled_kernel(
            initial_a, initial_b, initial_d,
            problem_sizes_tensor,
            strides_tensor,
            ptrs_abcd_tensor,
            ptrs_sfa_tensor,
            ptrs_sfb_tensor,
            alphas_tensor,
            betas_tensor,
            tensormap_tensor,
            stream,
        )
        torch.cuda.synchronize()

        # Reference is computed only for active (non-empty) groups; the
        # remaining groups bind the shared stub tensors and have no output.
        active = [g for g, (m, n, k) in enumerate(problem_sizes) if m and n and k]
        active_lists = lambda lst: [lst[g] for g in active]
        d_ref_list = reference_grouped_blockwise_gemm(
            active_lists(a_list), active_lists(b_list), active_lists(c_list),
            active_lists(sfa_list), active_lists(sfb_list),
            active_lists(alpha_vals), active_lists(beta_vals),
        )

        for d_ref, g in zip(d_ref_list, active):
            d_gpu = d_list[g].cpu().view(torch.float8_e4m3fn).to(torch.float32)[:, :, 0]
            diff = (d_gpu - d_ref).abs()
            print(f"  Group {g}: max_diff={diff.max():.4f}  mean_diff={diff.mean():.4f}")
            torch.testing.assert_close(
                d_gpu, d_ref, atol=tolerance, rtol=1e-2,
                msg=f"Group {g} output does not match reference",
            )
        print(f"  Correctness check: PASSED ({len(active)} active groups)")

    if iterations <= 0:
        return 0

    # ------------------------------------------------------------------
    # Benchmarking
    # ------------------------------------------------------------------
    def _to_device_int(values, dtype, *, shape_dtype):
        view, gpu = cutlass_torch.cute_tensor_like(
            torch.tensor(values, dtype=shape_dtype),
            dtype, is_dynamic_layout=False, assumed_align=16,
        )
        return view, gpu

    def generate_tensors():
        (
            a_ws, b_ws, c_ws, d_ws, sfa_ws, sfb_ws,
            strides_ws_raw, ptrs_abcd_ws_raw, ptrs_sfa_ws_raw, ptrs_sfb_ws_raw,
        ) = create_tensors_for_all_groups(problem_sizes)

        strides_ws,  strides_ws_gpu  = _to_device_int(strides_ws_raw,  cutlass.Int32, shape_dtype=torch.int32)
        ptrs_abcd_ws, ptrs_abcd_ws_gpu = _to_device_int(ptrs_abcd_ws_raw, cutlass.Int64, shape_dtype=torch.int64)
        ptrs_sfa_ws,  ptrs_sfa_ws_gpu  = _to_device_int(ptrs_sfa_ws_raw,  cutlass.Int64, shape_dtype=torch.int64)
        ptrs_sfb_ws,  ptrs_sfb_ws_gpu  = _to_device_int(ptrs_sfb_ws_raw,  cutlass.Int64, shape_dtype=torch.int64)
        tmap_ws, tmap_ws_gpu = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64, is_dynamic_layout=False,
        )
        args = testing.JitArguments(
            initial_a, initial_b, initial_d,
            problem_sizes_tensor,
            strides_ws, ptrs_abcd_ws,
            ptrs_sfa_ws, ptrs_sfb_ws,
            alphas_tensor, betas_tensor,
            tmap_ws,
            stream,
        )
        # Anchor every backing GPU torch tensor to *this* JitArguments
        # instance. With --use_cold_l2 ``testing.benchmark`` pre-generates
        # multiple workspaces and keeps each set of args alive in a list;
        # storing the keepalive as a per-instance attribute means each
        # workspace's tensors live for the full benchmark, instead of being
        # overwritten by the next call to generate_tensors().
        args._keepalive = (
            a_ws, b_ws, c_ws, d_ws, sfa_ws, sfb_ws,
            strides_ws_gpu, ptrs_abcd_ws_gpu, ptrs_sfa_ws_gpu, ptrs_sfb_ws_gpu, tmap_ws_gpu,
        )
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.numel() * t.element_size()
            for tlist in (a_list, b_list, c_list, d_list)
            for t in tlist
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations,
        )

    exec_time_us = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    fp8_bytes = 1
    f32_bytes = 4
    total_flops = sum(2.0 * m * n * k for m, n, k in problem_sizes)
    # Bandwidth: only active groups contribute. A/B are read, D is written;
    # SFA/SFB are read once per K-tile.
    total_bytes = 0
    for m, n, k in problem_sizes:
        if not (m and n and k):
            continue
        k_tiles = k // SCALE_GRAN_K
        n_tiles = n // SCALE_GRAN_N
        total_bytes += m * k * fp8_bytes        # A
        total_bytes += n * k * fp8_bytes        # B
        total_bytes += m * n * fp8_bytes        # D (written)
        total_bytes += m * k_tiles * f32_bytes  # SFA
        total_bytes += n_tiles * k_tiles * f32_bytes  # SFB
    runtime_s = exec_time_us * 1e-6
    gflops = total_flops / runtime_s / 1e9
    gbps = total_bytes / runtime_s / 1e9
    print(f"  Avg runtime : {exec_time_us / 1e3:.4f} ms")
    print(f"  GFLOPS      : {gflops:.1f}")
    print(f"  GBPS        : {gbps:.1f}")

    return exec_time_us


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Hopper FP8 Grouped Blockwise GEMM "
                    "(port of CUTLASS Example 68)."
    )
    parser.add_argument("--num_groups", type=int, default=4)
    parser.add_argument(
        "--problem_sizes", type=_parse_problem_sizes,
        default=[(256, 256, 256), (512, 128, 256), (128, 512, 256), (256, 384, 256)],
        help='Per-group (M,N,K): "(256,256,256),(512,128,256)"',
    )
    parser.add_argument(
        "--cluster_shape_mn", type=_parse_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 2),
    )
    parser.add_argument("--swizzle_size", type=int, default=1)
    parser.add_argument(
        "--raster_order", choices=["along_m", "along_n"], default="along_m"
    )
    parser.add_argument("--tolerance", type=float, default=1.0,
                        help="Max abs diff for FP8 output (wide tolerance expected)")
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--use_cold_l2", action="store_true", default=False)
    parser.add_argument(
        "--sparse_fraction", type=float, default=0.0,
        help="Randomly empty out this fraction of groups (in [0, 1]). The "
             "selected groups have all dims zeroed and are skipped by the "
             "kernel. Useful for exercising the sparse-groups path.",
    )
    parser.add_argument("--seed", type=int, default=0,
                        help="RNG seed for --sparse_fraction selection.")
    args = parser.parse_args()

    if len(args.problem_sizes) != args.num_groups:
        # Replicate the first problem size to fill num_groups if only one given
        if len(args.problem_sizes) == 1:
            args.problem_sizes = args.problem_sizes * args.num_groups
        else:
            parser.error(
                f"--problem_sizes has {len(args.problem_sizes)} entries "
                f"but --num_groups={args.num_groups}"
            )

    # Apply --sparse_fraction by randomly zeroing out the chosen groups.
    if args.sparse_fraction > 0.0:
        if not 0.0 <= args.sparse_fraction <= 1.0:
            parser.error("--sparse_fraction must be in [0, 1]")
        rng = random.Random(args.seed)
        n_empty = int(round(args.num_groups * args.sparse_fraction))
        empty_indices = set(rng.sample(range(args.num_groups), n_empty))
        args.problem_sizes = [
            (0, 0, 0) if g in empty_indices else size
            for g, size in enumerate(args.problem_sizes)
        ]

    return args


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    args = parse_arguments()
    run(
        problem_sizes=args.problem_sizes,
        cluster_shape_mn=args.cluster_shape_mn,
        swizzle_size=args.swizzle_size,
        raster_along_m=(args.raster_order == "along_m"),
        alpha_vals=[1.0] * args.num_groups,
        beta_vals=[0.0] * args.num_groups,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
    )
    print("PASS")
