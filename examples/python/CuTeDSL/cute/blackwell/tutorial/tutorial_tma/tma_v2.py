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
from typing import Tuple, Type, Union
import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import torch

"""
TMA Matrix Transpose with Multi-Stage Pipeline(v2)

This version extends tma_v1.py with:
1. Multi-stage pipeline: Multiple buffers for pipelining TMA loads and stores
2. Pipeline abstraction: Using PipelineTmaAsync for proper producer-consumer coordination
3. Persistent tile scheduler: Efficient work distribution across CTAs

Key Improvements over v1:
- Multi-stage buffers enable overlapping TMA loads, computation, and TMA stores
- Pipeline objects provide cleaner synchronization semantics

Note: TMA multicast is NOT used because each CTA must process different input tiles.

Warp Roles:
- Producer: TMA Load Warp - Loads from Global to Shared memory (multi-stage, multi-tile)
- Consumer: Transpose Warps - Wait for load, transpose sA -> sB (multi-tile)
- Consumer: TMA Store Warp - Wait for transpose, store sB to Global (multi-stage, multi-tile)

Pipeline Stages:
1. Load Pipeline: TMA Load (producer) -> Transpose Warps (consumer)
2. Store Pipeline: Transpose Warps (producer) -> TMA Store (consumer)
"""


class Sm100MatrixTransposeKernelV2:
    def __init__(
        self,
    ):
        """
        Initialize the TMA transpose kernel with multi-stage pipeline support.

        Args:
            tile_shape: Tile dimensions (M, N)
            cluster_shape_mn: Cluster shape for parallel CTA execution (M, N)

        Note:
            - Each CTA processes different tiles independently
            - Stage counts are automatically computed based on available shared memory
            - Persistent scheduler distributes work across CTAs in the cluster
        """
        self.tile_shape = (128, 128)
        self.tile_m, self.tile_n = self.tile_shape
        self.cluster_shape_mn = (1, 1)
        self.cluster_shape_mnl = (*self.cluster_shape_mn, 1)

        # Set specialized warp ids based on tile_shape
        # For 128x128 tile, use 4 transpose warps (same as v1)
        self.max_trans_warps = 4  # Maximum number of transpose warps
        self.num_trans_warps = self.max_trans_warps  # Use all transpose warps
        self.trans_warp_id = tuple(range(self.num_trans_warps))
        self.tma_load_warp_id = self.num_trans_warps
        self.threads_per_cta = 32 * len((self.tma_load_warp_id, *self.trans_warp_id))
        self.num_trans_threads = 32 * len(self.trans_warp_id)

        # Set barriers for producer-consumer sync
        # Barrier 1: Trans warps sync (for internal coordination)
        self.trans_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=32 * len(self.trans_warp_id),
        )
        self.buffer_align_bytes = 128

        # Get shared memory capacity for stage computation
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_100")

    @staticmethod
    def _compute_stages(
        tile_m: int,
        tile_n: int,
        dtype: Type[cutlass.Numeric],
        smem_capacity: int,
    ) -> Tuple[int, int]:
        """
        Compute the number of load and store stages based on shared memory capacity.

        Strategy:
        1. Calculate bytes per stage for load (sA) and store (sB) buffers
        2. Reserve space for barriers and alignment
        3. Divide remaining smem by bytes per stage to get max stages
        4. Clamp to reasonable min/max values

        Args:
            tile_m: Tile dimension M
            tile_n: Tile dimension N
            dtype: Data type of the tensors
            smem_capacity: Total shared memory capacity in bytes

        Returns:
            Tuple of (num_load_stages, num_store_stages)
        """
        # Calculate bytes per tile (assuming row-major and col-major layouts)
        bytes_per_element = dtype.width // 8

        # For sA (load buffer): tile_m x tile_n elements
        sA_bytes_per_stage = tile_m * tile_n * bytes_per_element

        # For sB (store buffer): tile_m x tile_n elements (transposed)
        sB_bytes_per_stage = tile_m * tile_n * bytes_per_element

        # Reserve space for barriers and other metadata
        # Each barrier: 8 bytes (Int64)
        # Estimate: max 16 barriers (load + store stages * 2) + alignment
        reserved_bytes = 1024  # Conservative estimate

        # Available space for staging buffers
        available_smem = smem_capacity - reserved_bytes

        # Calculate max stages we can fit
        # We need space for both load and store stages
        total_bytes_per_stage_pair = sA_bytes_per_stage + sB_bytes_per_stage

        # Max stages (same for load and store for simplicity)
        max_stages = available_smem // total_bytes_per_stage_pair

        # Clamp to reasonable values
        # Min: 2 stages for basic double buffering
        # Max: 8 stages (diminishing returns beyond this)
        num_stages = max(2, min(max_stages, 8))

        return num_stages, num_stages

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[utils.PersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Use persistent tile scheduler to compute the grid size for the output tensor C.

        :param c: The output tensor C
        :type c: cute.Tensor
        :param cta_tile_shape_mn: The shape (M, N) of the CTA tile.
        :type cta_tile_shape_mn: tuple[int, int]
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr

        :return: A tuple containing:
            - tile_sched_params: Parameters for the persistent tile scheduler.
            - grid: Grid shape for kernel launch.
        :rtype: Tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int]]
        """
        c_shape = cute.slice_(cta_tile_shape_mn, (None, None))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mn = gc[(0, (None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)
        num_ctas_mnl = (*num_ctas_mn, 1)
        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @cute.jit
    def __call__(
        self, src: cute.Tensor, dst: cute.Tensor, max_active_clusters: cutlass.Constexpr
    ):
        if cutlass.const_expr(src.element_type != dst.element_type):
            raise TypeError("Source and destination element types must match")

        self.dtype: Type[cutlass.Numeric] = src.element_type

        # Compute optimal stage counts based on tile size and dtype
        self.num_load_stages, self.num_store_stages = self._compute_stages(
            self.tile_m,
            self.tile_n,
            self.dtype,
            self.smem_capacity,
        )

        # Create transposed view of dst for TMA descriptor
        # dst is (N, M), we want to view it as (M, N) transposed
        transed_dst = cute.make_tensor(
            dst.iterator,
            cute.make_layout(
                (dst.shape[1], dst.shape[0]), stride=(dst.stride[1], dst.stride[0])
            ),
        )

        # Create multi-stage layouts for load and store buffers
        # row-major smem layout for sA (tile_m, tile_n)
        smem_layout_sA_staged = sm100_utils.make_smem_layout(
            utils.LayoutEnum.from_tensor(src).mma_major_mode(),
            (self.tile_m, self.tile_n),
            self.dtype,
            self.num_load_stages,
        )

        # col-major smem layout for sB (tile_n, tile_m)
        # sB should match the transposed destination layout
        smem_layout_sB_staged = sm100_utils.make_smem_layout(
            utils.LayoutEnum.from_tensor(transed_dst).mma_major_mode(),
            (self.tile_m, self.tile_n),
            self.dtype,
            self.num_store_stages,
        )

        @cute.struct
        class SharedStorage:
            # Pipeline barriers for multi-stage load
            load_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load_stages
            ]
            load_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load_stages
            ]

            # Pipeline barriers for multi-stage store
            store_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_store_stages
            ]
            store_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_store_stages
            ]

            # Multi-stage shared memory buffers
            sA: cute.struct.Align[
                cute.struct.MemRange[self.dtype, cute.cosize(smem_layout_sA_staged)],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[self.dtype, cute.cosize(smem_layout_sB_staged)],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage
        a_smem_layout = cute.slice_(smem_layout_sA_staged, (None, None, 0))
        self.num_tma_load_bytes = cute.size_in_bytes(self.dtype, a_smem_layout)

        # TMA Atoms
        # Each CTA loads its own tile independently
        tma_load_op = cpasync.CopyBulkTensorTileG2SOp()

        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)), (1,)
        )

        tma_atom_src, tma_tensor_src = cpasync.make_tiled_tma_atom(
            tma_load_op,
            src,
            smem_layout_sA_staged,
            (self.tile_m, self.tile_n),
        )

        tma_atom_dst, tma_tensor_dst = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            transed_dst,
            smem_layout_sB_staged,
            (self.tile_m, self.tile_n),
        )
        tile_sched_params, grid_shape = self._compute_grid(
            transed_dst,
            (self.tile_m, self.tile_n),
            self.cluster_shape_mn,
            max_active_clusters,
        )

        self.kernel(
            tma_atom_src,
            tma_tensor_src,
            tma_atom_dst,
            tma_tensor_dst,
            smem_layout_sA_staged,
            smem_layout_sB_staged,
            cluster_layout_vmnk,
            tile_sched_params,
        ).launch(
            grid=grid_shape,
            block=(self.threads_per_cta, 1, 1),
            cluster=self.cluster_shape_mnl,
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_load: cute.CopyAtom,
        tma_tensor_src: cute.Tensor,
        tma_atom_store: cute.CopyAtom,
        tma_tensor_dst: cute.Tensor,
        smem_layout_sA_staged: Union[cute.Layout, cute.ComposedLayout],
        smem_layout_sB_staged: Union[cute.Layout, cute.ComposedLayout],
        cluster_layout_vmnk: cute.Layout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        tidx, _, _ = cute.arch.thread_idx()

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # ---------------- Shared mem & staged buffers ----------------
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        sA_staged = storage.sA.get_tensor(
            smem_layout_sA_staged.outer, swizzle=smem_layout_sA_staged.inner
        )
        sB_staged = storage.sB.get_tensor(
            smem_layout_sB_staged.outer, swizzle=smem_layout_sB_staged.inner
        )

        load_mbar_ptr = storage.load_full_mbar_ptr.data_ptr()
        _store_mbar_ptr = storage.store_full_mbar_ptr.data_ptr()

        load_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 1)
        load_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, self.num_trans_warps
        )

        load_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=load_mbar_ptr,
            num_stages=self.num_load_stages,
            producer_group=load_producer_group,
            consumer_group=load_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        store_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, self.num_trans_threads
        )
        store_pipeline = pipeline.PipelineTmaStore.create(
            num_stages=self.num_store_stages,
            producer_group=store_producer_group,
        )

        # Critical: Initialize pipeline barriers across cluster
        # This must happen after pipeline creation and before any producer/consumer work
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        gA = cute.local_tile(tma_tensor_src, self.tile_shape, (None, None))

        _cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, None, 0)).shape
        )
        # ((TileM, TileK), loopM, LoopK)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_load,
            0,
            cute.make_layout(1),
            cute.group_modes(sA_staged, 0, 2),
            cute.group_modes(gA, 0, 2),
        )

        gDst_cta = cute.local_tile(tma_tensor_dst, self.tile_shape, (None, None))
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_store,
            0,
            cute.make_layout(1),
            cute.group_modes(sB_staged, 0, 2),
            cute.group_modes(gDst_cta, 0, 2),
        )

        # ------------------------------------------------------------------
        # PRODUCER: TMA Load Warp (G -> sA)
        # ------------------------------------------------------------------
        if warp_idx == self.tma_load_warp_id:
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            load_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load_stages
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                tAgA_slice = tAgA[(None, cur_tile_coord[0], cur_tile_coord[1])]

                load_pipeline.producer_acquire(load_producer_state)

                cute.copy(
                    tma_atom_load,
                    tAgA_slice,
                    tAsA[(None, load_producer_state.index)],
                    tma_bar_ptr=load_pipeline.producer_get_barrier(load_producer_state),
                )

                load_producer_state.advance()
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            load_pipeline.producer_tail(load_producer_state)

        # ------------------------------------------------------------------
        # CONSUMER: Transpose Warps (sA -> Reg -> sB)
        # ------------------------------------------------------------------
        if warp_idx < self.tma_load_warp_id:
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            trans_tid = tidx % self.num_trans_threads

            load_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_load_stages
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx

                # Wait for load pipeline to have data
                load_pipeline.consumer_wait(load_consumer_state)

                atom = cute.make_copy_atom(
                    cute.nvgpu.CopyUniversalOp(),
                    self.dtype,
                    num_bits_per_copy=self.dtype.width,
                )
                copy_elems = 1

                thread_layout = cute.make_layout(
                    (self.num_trans_threads, 1),
                    stride=(1, self.num_trans_threads),
                )
                value_layout = cute.make_layout((1, copy_elems))
                tiled_copy = cute.make_tiled_copy_tv(atom, thread_layout, value_layout)
                thr_copy = tiled_copy.get_slice(trans_tid)

                # sA -> Reg
                tCsA = thr_copy.partition_S(sA_staged)

                tCrA = cute.make_rmem_tensor(
                    tCsA[(None, None, None, 0)].shape, self.dtype
                )
                tCrA = tiled_copy.retile(tCrA)

                cute.copy(
                    tiled_copy,
                    tCsA[(None, None, None, load_consumer_state.index)],
                    tCrA,
                )

                # release load pipeline
                load_pipeline.consumer_release(load_consumer_state)
                load_consumer_state.advance()

                index = tile_sched.num_tiles_executed % self.num_store_stages
                # Reg -> sB
                tCsB = thr_copy.partition_D(sB_staged)
                cute.copy(tiled_copy, tCrA, tCsB[(None, None, None, index)])

                # Fence to ensure smem writes are visible
                cute.arch.fence_proxy(
                    "async.shared",
                    space="cta",
                )
                self.trans_sync_barrier.arrive_and_wait()

                if warp_idx == self.trans_warp_id[0]:
                    cute.copy(
                        tma_atom_store,
                        tBsB[(None, index)],
                        tBgB[(None, cur_tile_coord[0], cur_tile_coord[1])],
                    )
                    store_pipeline.producer_commit()
                    store_pipeline.producer_acquire()
                self.trans_sync_barrier.arrive_and_wait()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            self.trans_sync_barrier.arrive_and_wait()

            store_pipeline.producer_tail()


def run_transpose(M, N, max_active_clusters=0, num_warmup=5, num_iters=20):
    """
    Run TMA transpose kernel with automatic stage calculation and performance measurement.

    Args:
        M: Matrix dimension M
        N: Matrix dimension N
        max_active_clusters: Maximum number of active clusters (0 for auto)
        num_warmup: Number of warmup iterations
        num_iters: Number of timing iterations

    Performance Metrics:
        - Throughput: Actual achieved bandwidth in GB/s
        - Theoretical BW: Peak memory bandwidth (2048 B/clk × 4000 MHz = 8.192 TB/s)
        - Bandwidth Efficiency: Percentage of theoretical peak achieved
    """
    torch.manual_seed(1111)
    # Input (M, N)
    input_data = torch.randn((M, N), device="cuda", dtype=torch.float16)
    # Output (N, M)
    output_data = torch.zeros((N, M), device="cuda", dtype=torch.float16)

    # CuTe Wrappers
    tensor_src = (
        from_dlpack(input_data, assumed_align=16)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=16)
    )
    tensor_dst = (
        from_dlpack(output_data, assumed_align=16)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=16)
    )

    transpose_kernel = Sm100MatrixTransposeKernelV2()

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(1)
    # Compile and Run
    compiled_kernel = cute.compile(
        transpose_kernel,
        tensor_src,
        tensor_dst,
        max_active_clusters,
        options="--generate-line-info",
    )

    # Warmup runs
    for _ in range(num_warmup):
        compiled_kernel(tensor_src, tensor_dst)
    torch.cuda.synchronize()

    # Timed runs
    start_event = torch.cuda.Event(enable_timing=True)
    end_event = torch.cuda.Event(enable_timing=True)

    start_event.record()
    for _ in range(num_iters):
        compiled_kernel(tensor_src, tensor_dst)
    end_event.record()
    torch.cuda.synchronize()

    # Calculate performance metrics
    elapsed_time_ms = start_event.elapsed_time(end_event)
    avg_time_ms = elapsed_time_ms / num_iters

    # Calculate throughput
    # For transpose: read M*N elements + write M*N elements
    bytes_per_element = input_data.element_size()
    total_bytes = 2 * M * N * bytes_per_element  # Read + Write
    throughput_gb_s = (total_bytes / 1e9) / (avg_time_ms / 1000)

    # Theoretical bandwidth limit
    # Blackwell: 2048 B/clk at 4000 MHz
    bytes_per_clk = 2048
    freq_mhz = 4000
    theoretical_bw_gb_s = bytes_per_clk * freq_mhz * 1e6 / 1e9  # Convert to GB/s
    theoretical_bw_tb_s = theoretical_bw_gb_s / 1000  # Convert to TB/s
    bandwidth_efficiency = (throughput_gb_s / theoretical_bw_gb_s) * 100  # Percentage

    # Print computed stage counts after compilation
    print(f"Matrix size: {M}×{N}")
    print(f"Tile shape: {transpose_kernel.tile_shape}")
    print(
        f"Computed stages: Load={transpose_kernel.num_load_stages}, Store={transpose_kernel.num_store_stages}"
    )
    print(f"Average time: {avg_time_ms:.4f} ms")
    print(f"Throughput: {throughput_gb_s:.2f} GB/s")
    print(
        f"Theoretical BW: {theoretical_bw_tb_s:.2f} TB/s ({theoretical_bw_gb_s:.2f} GB/s)"
    )
    print(f"Bandwidth Efficiency: {bandwidth_efficiency:.2f}%")

    # Verification
    expected = input_data.t()
    if torch.allclose(output_data, expected, atol=1e-2):
        print("Verification: PASSED ✓")
    else:
        print("Verification: FAILED ✗")
        print(f"Max diff: {(output_data - expected).abs().max()}")


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="TMA Matrix Transpose with Multi-Stage Pipeline and Cluster Support (v2)"
    )
    parser.add_argument("--M", type=int, default=128, help="Matrix dimension M")
    parser.add_argument("--N", type=int, default=128, help="Matrix dimension N")
    parser.add_argument(
        "--num_warmup", type=int, default=5, help="Number of warmup iterations"
    )
    parser.add_argument(
        "--num_iters", type=int, default=20, help="Number of timing iterations"
    )
    args = parser.parse_args()

    run_transpose(
        args.M,
        args.N,
        num_warmup=args.num_warmup,
        num_iters=args.num_iters,
    )
