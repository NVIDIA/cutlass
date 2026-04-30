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
from typing import Optional, Tuple, Type
import math
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils

"""
A high-performance FP8 GEMM (D = scale_a * scale_b * A * B) example for the NVIDIA Hopper
architecture using CuTe DSL, featuring the 2xAcc (double accumulation) technique for improved
FP8 numerical accuracy.

This is a CuTeDSL port of CUTLASS Example 54:
  examples/54_hopper_fp8_warp_specialized_gemm/54_hopper_fp8_warp_specialized_gemm.cu

The 2xAcc technique addresses FP8 precision loss by maintaining two accumulators:
  - accum_temp: A temporary accumulator that WGMMA writes into directly
  - accum: The main accumulator that collects promoted partial results

Every `mma_promotion_interval` MMA instructions, accum_temp is promoted (element-wise added)
into accum, then reset to zero for the next batch of MMAs. This periodic promotion prevents
precision degradation from accumulating too many low-precision FP8 products.

The C++ reference for the 2xAcc algorithm is in:
  include/cutlass/gemm/collective/fp8_accumulation.hpp
  include/cutlass/gemm/collective/sm90_mma_tma_gmma_ss_warpspecialized_fp8.hpp

- Matrix A is MxKxL (FP8 E4M3, k-major only)
- Matrix B is NxKxL (FP8 E4M3, k-major only)
- Matrix D is MxNxL (configurable output dtype)

This GEMM kernel supports the following features:
    - FP8 (E4M3FN) inputs with Float32 accumulation
    - 2xAcc (double accumulation) for improved FP8 numerical accuracy
    - Scalar scale_a and scale_b factors applied in the epilogue
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Hopper's WGMMA for matrix multiply-accumulate (MMA) operations
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support persistent tile scheduling to better overlap memory load/store with MMA between tiles
    - Support warp specialization to avoid explicit pipelining between mainloop load and MMA

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/hopper/dense_gemm_fp8_2xacc.py             \
      --mnkl 2048,2048,2048,1 --tile_shape_mn 128,128                          \
      --cluster_shape_mn 1,2 --mma_promotion_interval 4                        \
      --c_dtype Float16 --scale_a 1.0 --scale_b 1.0

Constraints:
* Input data types: FP8 E4M3FN only, k-major layout
* Accumulation dtype: Float32
* Output dtype: Float16, Float32, or Float8E4M3FN
* CTA tile shape M must be 64/128
* CTA tile shape N must be 64/128/256
* Cluster shape M/N must be positive and power of 2, total cluster size <= 4
* The contiguous dimension of tensors must be at least 16 bytes aligned (16 elements for FP8)
* mma_promotion_interval must be a multiple of num_k_blocks per k_tile (typically 4)
"""


# Helpers to parse args
def parse_comma_separated_ints(s: str):
    try:
        return tuple([int(x.strip()) for x in s.split(",")])
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="FP8 GEMM with 2xAcc on Hopper (port of CUTLASS Example 54)."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(4096, 4096, 4096, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tile_shape_mn",
        type=parse_comma_separated_ints,
        choices=[(128, 128), (128, 256), (128, 64), (64, 64)],
        default=(128, 128),
        help="Cta tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        choices=[(1, 1), (2, 1), (1, 2), (2, 2)],
        default=(1, 2),
        help="Cluster shape (comma-separated)",
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
        choices=["along_m", "along_n"],
        default="along_m",
        help="Rasterization order of clusters",
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Output dtype (Float16, Float32, or Float8E4M3FN)",
    )
    parser.add_argument(
        "--mma_promotion_interval",
        type=int,
        default=4,
        help="Number of MMA instructions between accumulator promotions (default: 4)",
    )
    parser.add_argument(
        "--scale_a",
        type=float,
        default=1.0,
        help="Scalar scale factor for A",
    )
    parser.add_argument(
        "--scale_b",
        type=float,
        default=1.0,
        help="Scalar scale factor for B",
    )
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

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")
    if len(args.tile_shape_mn) != 2:
        parser.error("--tile_shape_mn must contain exactly 2 values")
    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    return args


class HopperFP8WarpSpecialized2xAccGemmKernel:
    """
    FP8 GEMM kernel with 2xAcc (double accumulation) for improved numerical accuracy.

    This kernel implements D = scale_a * scale_b * (A @ B) where A and B are FP8 E4M3FN
    tensors. The 2xAcc technique uses a temporary accumulator that is periodically promoted
    into the main accumulator to prevent precision loss from FP8 overflow.

    Based on the warp-specialized persistent tile scheduling pattern from dense_gemm_persistent.py,
    with the mainloop modified to implement the 2xAcc algorithm from CUTLASS's
    sm90_mma_tma_gmma_ss_warpspecialized_fp8.hpp.

    :param tile_shape_mn: Shape of the CTA tile (M,N)
    :type tile_shape_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]
    :param mma_promotion_interval: Number of MMA instructions between accumulator promotions
    :type mma_promotion_interval: int

    :note: Constraints:
        - Input types: FP8 E4M3FN only, k-major layout
        - Accumulation type: Float32
        - CTA tile M must be 64/128
        - CTA tile N must be 64/128/256
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 4
    """

    def __init__(
        self,
        tile_shape_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        swizzle_size: int,
        raster_along_m: bool,
        mma_promotion_interval: int = 4,
    ):
        self.acc_dtype = cutlass.Float32
        self.mma_promotion_interval = mma_promotion_interval

        self.cluster_shape_mn = cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m
        self.mma_inst_shape_mn = None
        # K dimension is deferred in _setup_attributes
        self.tile_shape_mnk = (*tile_shape_mn, 1)
        # For large tile size, using two warp groups is preferred because using only one warp
        # group may result in register spill
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

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs."""

        # check the cta tile shape
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

        # Validate that mma_promotion_interval is a multiple of num_k_blocks
        # so the counter hits the interval exactly (promotion uses == not >=)
        num_k_blocks = mma_inst_tile_k
        if self.mma_promotion_interval % num_k_blocks != 0:
            raise ValueError(
                f"mma_promotion_interval ({self.mma_promotion_interval}) must be a "
                f"multiple of num_k_blocks ({num_k_blocks})"
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

        # Compute stage before compute smem layout
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

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        d: cute.Tensor,
        scale_a: cute.Tensor,
        scale_b: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """Execute the FP8 GEMM with 2xAcc.

        :param a: Input tensor A (FP8 E4M3FN)
        :param b: Input tensor B (FP8 E4M3FN)
        :param d: Output tensor D
        :param scale_a: Scalar scale factor for A (1-element Float32 tensor)
        :param scale_b: Scalar scale factor for B (1-element Float32 tensor)
        :param max_active_clusters: Maximum number of active clusters
        :param stream: CUDA stream
        """

        # setup static attributes before smem/grid/tma computation
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
            sD: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.epi_smem_layout_staged),
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
            scale_a,
            scale_b,
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
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        scale_a: cute.Tensor,
        scale_b: cute.Tensor,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """
        GPU device kernel performing FP8 GEMM with 2xAcc.

        The mainloop uses two accumulators:
        - accum_temp: temporary accumulator that WGMMA writes into
        - accumulators: main accumulator that collects promoted partial results

        Every mma_promotion_interval MMA instructions, accum_temp is promoted
        (element-wise added) into accumulators, then WGMMA is told to zero
        accum_temp on its next instruction.
        """

        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch Tma desc
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

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

        # Alloc and init AB full/empty + ACC full mbar (pipeline)
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # mbar arrays
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()

        # Threads/warps participating in this pipeline
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread
        )
        # Each warp will contribute to the arrive count with the number of mcast size
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

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # Generate smem tensor A/B/D
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sD = storage.sD.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        # Local_tile partition global tensors
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_(self.tile_shape_mnk, (None, 0, None)),
            (None, None, None),
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_(self.tile_shape_mnk, (0, None, None)),
            (None, None, None),
        )
        # (bM, bN, RestM, RestN, RestL)
        gD_mnl = cute.local_tile(
            mD_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )

        # Partition shared tensor for TMA load A/B
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sA, 0, 2),
            cute.group_modes(gA_mkl, 0, 2),
        )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sB, 0, 2),
            cute.group_modes(gB_nkl, 0, 2),
        )

        # Partition global tensor for TiledMMA_A/B/C
        warp_group_idx = cute.arch.make_warp_uniform(
            tidx // self.num_threads_per_warp_group
        )
        mma_warp_group_thread_layout = cute.make_layout(
            self.num_mma_warp_groups, stride=self.num_threads_per_warp_group
        )
        thr_mma = tiled_mma.get_slice(
            mma_warp_group_thread_layout(warp_group_idx - self.num_dma_warp_groups)
        )

        # Make fragments
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA)
        tCrB = tiled_mma.make_fragment_B(tCsB)

        tCgD = thr_mma.partition_C(gD_mnl)
        acc_shape = tCgD.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)
        # 2xAcc: create temporary accumulator
        accum_temp = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Cluster wait for barrier init
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        is_dma_warp_group = warp_group_idx < self.num_dma_warp_groups
        if is_dma_warp_group:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

        # =====================================================================
        # DMA warp group: TMA loads (identical to dense_gemm_persistent.py)
        # =====================================================================
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
                    # Conditionally wait for AB buffer empty
                    mainloop_pipeline.producer_acquire(mainloop_producer_state)
                    # Slice to global/shared memref to current k_tile
                    tAgA_k = tAgA_mkl[(None, mainloop_producer_state.count)]
                    tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]

                    tBgB_k = tBgB_nkl[(None, mainloop_producer_state.count)]
                    tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_k,
                        tAsA_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                        mcast_mask=a_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_k,
                        tBsB_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                        mcast_mask=b_mcast_mask,
                    )

                    # Mainloop pipeline's producer commit is a NOP
                    mainloop_pipeline.producer_commit(mainloop_producer_state)
                    mainloop_producer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            mainloop_pipeline.producer_tail(mainloop_producer_state)

        # =====================================================================
        # MMA warp group: 2xAcc mainloop + epilogue
        # =====================================================================
        if not is_dma_warp_group:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)
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

            # Partition for epilogue
            copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )

            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(
                    self.c_layout.is_m_major_c(),
                    4,
                ),
                self.c_dtype,
            )

            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)

            tiled_copy_r2s = cute.make_tiled_copy_S(
                copy_atom_r2s,
                tiled_copy_C_Atom,
            )

            # (R2S, R2S_M, R2S_N, PIPE_D)
            thr_copy_r2s = tiled_copy_r2s.get_slice(
                tidx - self.num_dma_warp_groups * self.num_threads_per_warp_group
            )
            # (t)hread-partition for (r)egister to (s)mem copy (tRS_)
            tRS_sD = thr_copy_r2s.partition_D(sD)
            # (R2S, R2S_M, R2S_N)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            # Allocate D registers.
            rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            tRS_rD_out = cute.make_rmem_tensor(tRS_rD_layout.shape, self.c_dtype)
            size_tRS_rD = cute.size(tRS_rD)

            k_pipe_mmas = 1
            prologue_mma_cnt = min(k_pipe_mmas, k_tile_cnt)

            # Initialize tma store pipeline
            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mma_threads,
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            # Load scalar scale factors (all threads load the same values)
            scale_val = scale_a[0] * scale_b[0]

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]

                # =============================================================
                # 2xAcc MAINLOOP
                # =============================================================
                mainloop_consumer_read_state.reset_count()
                mainloop_consumer_release_state.reset_count()
                accumulators.fill(0.0)

                # Start with ACCUMULATE=False so first GMMA zeros accum_temp
                tiled_mma.set(
                    cute.nvgpu.warpgroup.Field.ACCUMULATE, False
                )
                mma_count = 0

                cute.nvgpu.warpgroup.fence()

                # Prologue: first k_pipe_mmas k_tiles (no release)
                for k_tile in range(prologue_mma_cnt):
                    # Wait for TMA copies to complete
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    # WGMMA into accum_temp
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accum_temp,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accum_temp,
                        )
                        tiled_mma.set(
                            cute.nvgpu.warpgroup.Field.ACCUMULATE, True
                        )

                    cute.nvgpu.warpgroup.commit_group()

                    # 2xAcc: promote_if_needed
                    mma_count += num_k_blocks
                    if mma_count == self.mma_promotion_interval:
                        cute.nvgpu.warpgroup.wait_group(0)
                        # Element-wise promotion: accumulators += accum_temp
                        for i in range(cute.size(accumulators)):
                            accumulators[i] = accumulators[i] + accum_temp[i]
                        mma_count = 0
                        # Signal WGMMA to zero accum_temp on next instruction
                        tiled_mma.set(
                            cute.nvgpu.warpgroup.Field.ACCUMULATE, False
                        )

                    mainloop_consumer_read_state.advance()

                # Main loop: remaining k_tiles (with release)
                for k_tile in range(prologue_mma_cnt, k_tile_cnt):
                    # Wait for TMA copies to complete
                    mainloop_pipeline.consumer_wait(mainloop_consumer_read_state)
                    # WGMMA into accum_temp
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_coord = (
                            None,
                            None,
                            k_block_idx,
                            mainloop_consumer_read_state.index,
                        )
                        cute.gemm(
                            tiled_mma,
                            accum_temp,
                            tCrA[k_block_coord],
                            tCrB[k_block_coord],
                            accum_temp,
                        )
                        tiled_mma.set(
                            cute.nvgpu.warpgroup.Field.ACCUMULATE, True
                        )

                    cute.nvgpu.warpgroup.commit_group()
                    # Wait on the wgmma barrier for WGMMA to complete
                    cute.nvgpu.warpgroup.wait_group(k_pipe_mmas)

                    # 2xAcc: promote_if_needed
                    mma_count += num_k_blocks
                    if mma_count == self.mma_promotion_interval:
                        # Wait for all outstanding WGMMA writes to accum_temp
                        # before reading it (matches C++ warpgroup_wait<0>)
                        cute.nvgpu.warpgroup.wait_group(0)
                        # Element-wise promotion: accumulators += accum_temp
                        for i in range(cute.size(accumulators)):
                            accumulators[i] = accumulators[i] + accum_temp[i]
                        mma_count = 0
                        # Signal WGMMA to zero accum_temp on next instruction
                        tiled_mma.set(
                            cute.nvgpu.warpgroup.Field.ACCUMULATE, False
                        )

                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()
                    mainloop_consumer_read_state.advance()

                cute.nvgpu.warpgroup.wait_group(0)

                # 2xAcc: promote_residue - promote any remaining partial results
                if mma_count > 0:
                    for i in range(cute.size(accumulators)):
                        accumulators[i] = accumulators[i] + accum_temp[i]

                # Release remaining pipeline stages from prologue
                for k_tile in range(prologue_mma_cnt):
                    mainloop_pipeline.consumer_release(mainloop_consumer_release_state)
                    mainloop_consumer_release_state.advance()

                # =============================================================
                # Epilogue: apply scaling, then R2S -> S2G
                # =============================================================

                # Apply scale_a * scale_b to accumulators
                for i in range(cute.size(accumulators)):
                    accumulators[i] = accumulators[i] * scale_val

                tCgD_for_tma_partition = cute.zipped_divide(gD_mnl_slice, self.epi_tile)

                # thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
                bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_d,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sD, 0, 2),
                    tCgD_for_tma_partition,
                )

                epi_tile_num = cute.size(tCgD_for_tma_partition, mode=[1])
                epi_tile_shape = tCgD_for_tma_partition.shape[1]
                epi_tile_layout = cute.make_layout(
                    epi_tile_shape, stride=(epi_tile_shape[1], 1)
                )

                num_prev_epi_tiles = tile_sched.num_tiles_executed * epi_tile_num
                for epi_idx in cutlass.range_constexpr(epi_tile_num):
                    # Copy from accumulators to D registers
                    for epi_v in cutlass.range_constexpr(size_tRS_rD):
                        tRS_rD[epi_v] = tRS_rAcc[epi_idx * size_tRS_rD + epi_v]

                    # Type conversion (acc_dtype -> c_dtype)
                    acc_vec = tRS_rD.load()
                    tRS_rD_out.store(acc_vec.to(self.c_dtype))

                    # Copy from D registers to shared memory
                    epi_buffer = (num_prev_epi_tiles + epi_idx) % cute.size(
                        tRS_sD, mode=[3]
                    )
                    cute.copy(
                        tiled_copy_r2s,
                        tRS_rD_out,
                        tRS_sD[(None, None, None, epi_buffer)],
                    )

                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    self.epilog_sync_barrier.arrive_and_wait()

                    gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                    # Copy from shared memory to global memory
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

    @staticmethod
    def _compute_stages(
        tile_shape_mnk: tuple[int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        epi_tile: tuple[int, int],
        c_dtype: type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
    ) -> tuple[int, int]:
        """Computes the number of stages for A/B/C operands based on heuristics."""
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
        tile_shape_mnk: tuple[int, int, int],
        element_type: type[cutlass.Numeric],
        is_cooperative: bool = False,
        epi_tile_override: Optional[tuple[int, int]] = None,
    ) -> tuple[int, int]:
        """Compute the epilogue tile shape or use override if provided."""
        if epi_tile_override is not None:
            return epi_tile_override
        if is_cooperative:
            tile_m = min(128, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(32, cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)
        else:
            n_perf = 64 if element_type.width == 8 else 32
            tile_m = min(64, cute.size(tile_shape_mnk, mode=[0]))
            tile_n = min(n_perf, cute.size(tile_shape_mnk, mode=[1]))
            return (tile_m, tile_n)

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: tuple[int, int, int],
        epi_tile: tuple[int, int],
        a_dtype: type[cutlass.Numeric],
        a_layout: utils.LayoutEnum,
        b_dtype: type[cutlass.Numeric],
        b_layout: utils.LayoutEnum,
        ab_stage: int,
        c_dtype: type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        epi_stage: int,
    ) -> tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Create shared memory layouts for A, B, and D tensors."""
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))

        a_is_k_major = (
            a_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        b_is_k_major = (
            b_layout.sm90_mma_major_mode() == cute.nvgpu.warpgroup.OperandMajorMode.K
        )
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]
        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                a_layout,
                a_dtype,
                a_major_mode_size,
            ),
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
            sm90_utils.get_smem_layout_atom(
                b_layout,
                b_dtype,
                b_major_mode_size,
            ),
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
            sm90_utils.get_smem_layout_atom(
                c_layout,
                c_dtype,
                c_major_mode_size,
            ),
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
        d: cute.Tensor,
        tile_shape_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        swizzle_size: int,
        raster_along_m: bool,
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[int, int, int]:
        """Compute grid shape for the output tensor D."""
        c_shape = cute.slice_(tile_shape_mnk, (None, None, 0))
        gd = cute.zipped_divide(d, tiler=c_shape)
        num_ctas_mnl = gd[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl,
            cluster_shape_mnl,
            swizzle_size,
            raster_along_m,
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        return tile_sched_params, grid

    @staticmethod
    def _make_tma_store_atoms_and_tensors(
        tensor_d: cute.Tensor,
        epi_smem_layout_staged: cute.ComposedLayout,
        epi_tile: tuple[int, int],
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for D tensor storage."""
        epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))
        tma_atom_d, tma_tensor_d = cute.nvgpu.cpasync.make_tiled_tma_atom(
            cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
            tensor_d,
            epi_smem_layout,
            epi_tile,
        )

        return tma_atom_d, tma_tensor_d

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged: cute.ComposedLayout,
        smem_tile: tuple[int, int],
        mcast_dim: int,
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for input tensors."""
        op = (
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp()
        )

        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op,
            tensor,
            smem_layout,
            smem_tile,
            num_multicast=mcast_dim,
        )
        return tma_atom, tma_tensor


def run(
    mnkl: Tuple[int, int, int, int],
    c_dtype: Type[cutlass.Numeric],
    tile_shape_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    swizzle_size: int = 1,
    raster_along_m: bool = True,
    mma_promotion_interval: int = 4,
    scale_a_val: float = 1.0,
    scale_b_val: float = 1.0,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """
    Prepare FP8 A/B tensors, launch GPU kernel with 2xAcc, and reference checking.

    :param mnkl: Problem size (M, N, K, L)
    :param c_dtype: Data type for output tensor D
    :param tile_shape_mn: CTA tile shape (M, N)
    :param cluster_shape_mn: Cluster shape (M, N)
    :param mma_promotion_interval: MMA instructions between accumulator promotions
    :param scale_a_val: Scalar scale factor for A
    :param scale_b_val: Scalar scale factor for B
    :param tolerance: Tolerance value for reference validation
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param skip_ref_check: Whether to skip reference validation
    :param use_cold_l2: Whether to use cold L2 cache strategy
    :return: Execution time in microseconds
    """
    import torch
    import cutlass.torch as cutlass_torch

    a_dtype = cutlass.Float8E4M3FN
    b_dtype = cutlass.Float8E4M3FN
    acc_dtype = cutlass.Float32

    print("Running Hopper FP8 Dense GEMM with 2xAcc:")
    print(f"mnkl: {mnkl}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, D dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Tile Shape: {tile_shape_mn}, Cluster Shape: {cluster_shape_mn}")
    print(f"MMA promotion interval: {mma_promotion_interval}")
    print(f"scale_a: {scale_a_val}, scale_b: {scale_b_val}")
    print(
        f"Swizzle size: {swizzle_size}, Raster order:",
        "along_m" if raster_along_m else "along_n",
    )
    print(f"Tolerance: {tolerance}")

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Validate alignment
    num_contiguous_elements = 16 * 8 // a_dtype.width  # 16 for FP8
    if k % num_contiguous_elements != 0:
        raise ValueError(
            f"K dimension ({k}) must be aligned to {num_contiguous_elements} elements for FP8"
        )

    # Create FP8 input tensors (k-major)
    a_torch_cpu = cutlass_torch.matrix(l, m, k, False, a_dtype)  # k-major
    b_torch_cpu = cutlass_torch.matrix(l, n, k, False, b_dtype)  # k-major
    d_torch_cpu = cutlass_torch.matrix(l, m, n, False, c_dtype)  # n-major

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, b_dtype, is_dynamic_layout=True, assumed_align=16
    )
    d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
        d_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    # Create scalar scale tensors on GPU
    scale_a_torch = torch.tensor([scale_a_val], dtype=torch.float32, device="cuda")
    scale_b_torch = torch.tensor([scale_b_val], dtype=torch.float32, device="cuda")
    scale_a_tensor, _ = cutlass_torch.cute_tensor_like(
        scale_a_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16
    )
    scale_b_tensor, _ = cutlass_torch.cute_tensor_like(
        scale_b_torch, cutlass.Float32, is_dynamic_layout=True, assumed_align=16
    )

    gemm = HopperFP8WarpSpecialized2xAccGemmKernel(
        tile_shape_mn, cluster_shape_mn, swizzle_size, raster_along_m,
        mma_promotion_interval,
    )

    # Compute max active clusters on current device
    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)
    # Compile gemm kernel
    compiled_gemm = cute.compile(
        gemm, a_tensor, b_tensor, d_tensor, scale_a_tensor, scale_b_tensor,
        max_active_clusters, stream
    )

    if not skip_ref_check:
        compiled_gemm(a_tensor, b_tensor, d_tensor, scale_a_tensor, scale_b_tensor, stream)
        torch.cuda.synchronize()

        # Compute reference result: D = scale_a * scale_b * (A @ B)
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch_cpu.to(dtype=torch.float32),
            b_torch_cpu.to(dtype=torch.float32),
        )
        ref = ref * scale_a_val * scale_b_val

        # Convert ref to c_dtype
        _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
            ref, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        ref_d = ref_torch_gpu.cpu()

        # Assert close results
        torch.testing.assert_close(d_torch_gpu.cpu(), ref_d, atol=tolerance, rtol=1e-03)

    def generate_tensors():
        a_tensor_workspace, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, a_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor_workspace, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, b_dtype, is_dynamic_layout=True, assumed_align=16
        )
        d_tensor_workspace, _ = cutlass_torch.cute_tensor_like(
            d_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(
            a_tensor_workspace, b_tensor_workspace, d_tensor_workspace,
            scale_a_tensor, scale_b_tensor, stream
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + d_torch_cpu.numel() * d_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":
    args = parse_arguments()
    run(
        args.mnkl,
        args.c_dtype,
        args.tile_shape_mn,
        args.cluster_shape_mn,
        args.swizzle_size,
        True if args.raster_order == "along_m" else False,
        args.mma_promotion_interval,
        args.scale_a,
        args.scale_b,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
