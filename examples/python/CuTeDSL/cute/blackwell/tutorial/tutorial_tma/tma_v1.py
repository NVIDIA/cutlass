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
from typing import Tuple, Type
import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
import cutlass.pipeline as pipeline
import torch

"""
TMA Matrix Transpose with Producer-Consumer Pattern: TMA load -> S2R --> R2S -> TMA store

Warp Roles (Producer-Consumer Pattern):
- Producer: TMA Load Warp (Warp 4) - Loads from Global to Shared A
- Consumer: Transpose Warps (Warp 0-3) - Wait for load, then transpose sA -> sB
- Consumer: TMA Store Warp (Warp 5) - Wait for transpose, then store sB to Global

Synchronization:
1. load_mbar_ptr: TMA Load (producer) -> Transpose Warps (consumer)
2. store_mbar_ptr: Transpose Warps (producer) -> TMA Store (consumer)

This demonstrates how different warps can use shared memory barriers to coordinate
producer-consumer relationships.
"""


class Sm100MatrixTransposeKernelV1:
    def __init__(self):
        self.tile_shape = (128, 128)
        self.tile_m, self.tile_n = self.tile_shape
        self.cluster_shape_mn = (1, 1)
        self.cluster_shape_mnk = (*self.cluster_shape_mn, 1)

        # Set specialized warp ids based on tile_shape
        self.num_trans_warps = 4  # Maximum number of transpose warps
        self.trans_warp_id = tuple(range(self.num_trans_warps))
        self.tma_load_warp_id = self.num_trans_warps
        self.tma_store_warp_id = self.num_trans_warps + 1
        self.threads_per_cta = 32 * len(
            (self.tma_store_warp_id, self.tma_load_warp_id, *self.trans_warp_id)
        )
        self.num_trans_threads = 32 * len(self.trans_warp_id)

        self.trans_tile = (self.tile_shape[0] // self.num_trans_warps, 8)

        # Set barriers for producer-consumer sync
        # Barrier 1: Trans warps sync (for internal coordination)
        self.trans_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=32 * len(self.trans_warp_id),
        )
        # Barrier 2: TMA Store warp waits after Trans warps finish
        self.store_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=32,  # Only TMA store warp
        )
        self.buffer_align_bytes = 1024

    @cute.jit
    def __call__(self, src: cute.Tensor, dst: cute.Tensor):
        if cutlass.const_expr(src.element_type != dst.element_type):
            raise TypeError("Source and destination element types must match")

        self.dtype: Type[cutlass.Numeric] = src.element_type

        # Create transposed view of dst for TMA descriptor
        # dst is (N, M), we want to view it as (M, N) transposed
        transed_dst = cute.make_tensor(
            dst.iterator,
            cute.make_layout(
                (dst.shape[1], dst.shape[0]), stride=(dst.stride[1], dst.stride[0])
            ),
        )

        # row-major smem layout for sA (tile_m, tile_n)
        smem_layout_sA = sm100_utils.make_smem_layout(
            utils.LayoutEnum.from_tensor(src).mma_major_mode(),
            (self.tile_m, self.tile_n),
            self.dtype,
            1,
        )

        # col-major smem layout for sB (tile_n, tile_m)
        # sB should match the transposed destination layout
        smem_layout_sB = sm100_utils.make_smem_layout(
            utils.LayoutEnum.from_tensor(transed_dst).mma_major_mode(),
            (self.tile_m, self.tile_n),
            self.dtype,
            1,
        )

        @cute.struct
        class SharedStorage:
            # Barrier for TMA Load: producer (TMA) -> consumer (Trans warps)
            load_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1]
            # Barrier for TMA Store: producer (Trans warps) -> consumer (TMA Store)
            store_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1]
            # Single shared memory buffer (sA and sB are different views of this)
            sA: cute.struct.Align[
                cute.struct.MemRange[self.dtype, cute.cosize(smem_layout_sA)], 128
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[self.dtype, cute.cosize(smem_layout_sB)], 128
            ]

        self.shared_storage = SharedStorage
        self.num_tma_load_bytes = cute.size_in_bytes(self.dtype, smem_layout_sA)

        # TMA Atoms
        # Use swizzled layout for TMA atom to handle swizzling during load
        tma_atom_src, tma_tensor_src = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileG2SOp(),
            src,
            smem_layout_sA,
            (self.tile_m, self.tile_n),
        )

        tma_atom_dst, tma_tensor_dst = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            transed_dst,
            smem_layout_sB,
            (self.tile_m, self.tile_n),
        )

        grid_shape = cute.ceil_div((*src.layout.shape, 1), self.tile_shape)
        self.kernel(
            tma_atom_src,
            tma_tensor_src,
            tma_atom_dst,
            tma_tensor_dst,
            smem_layout_sA,
            smem_layout_sB,
        ).launch(
            grid=grid_shape,
            block=(self.threads_per_cta, 1, 1),
            cluster=self.cluster_shape_mnk,
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_load: cute.CopyAtom,
        tma_tensor_src: cute.Tensor,
        tma_atom_store: cute.CopyAtom,
        tma_tensor_dst: cute.Tensor,
        smem_layout_sA: cute.ComposedLayout,
        smem_layout_sB: cute.ComposedLayout,
    ):
        bidx, bidy, _ = cute.arch.block_idx()
        tidx, _, _ = cute.arch.thread_idx()

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Allocate Shared Memory
        # We need two buffers for transpose:
        # sA: Source Tile (swizzled)
        # sB: Destination Tile (swizzled) for TMA Store
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)
        sA = storage.sA.get_tensor(smem_layout_sA.outer, swizzle=smem_layout_sA.inner)
        # sA = cute.make_tensor(storage.sA.iterator, smem_layout_sA)
        sB = storage.sB.get_tensor(smem_layout_sB.outer, swizzle=smem_layout_sB.inner)
        self.num_tma_load_bytes = cute.size_in_bytes(self.dtype, smem_layout_sA)
        load_mbar_ptr = storage.load_mbar_ptr.data_ptr()
        store_mbar_ptr = storage.store_mbar_ptr.data_ptr()

        # ------------------------------------------------------------------
        # Initialize Barriers (all warps participate in initialization)
        # ------------------------------------------------------------------
        if tidx == 0:
            # Barrier for TMA Load: expect 1 arrive (from TMA warp after TMA completes)
            cute.arch.mbarrier_init(load_mbar_ptr, 1)
            cute.arch.mbarrier_expect_tx(load_mbar_ptr, self.num_tma_load_bytes)

            # Barrier for TMA Store: expect arrival from Trans warps
            cute.arch.mbarrier_init(store_mbar_ptr, len(self.trans_warp_id))
        cute.arch.mbarrier_init_fence()

        # Sync all warps after barrier initialization
        cute.arch.barrier()
        # ------------------------------------------------------------------
        # PRODUCER: TMA Load Warp (G -> sA)
        # ------------------------------------------------------------------
        if warp_idx == self.tma_load_warp_id:
            # Issue TMA Load
            # ((TileM, TileK), loopM, LoopK)
            gA = cute.local_tile(tma_tensor_src, self.tile_shape, (None, None))
            # ((TileM, TileK), loopM, LoopK)
            tAsA, tAgA = cpasync.tma_partition(
                tma_atom_load,
                0,
                cute.make_layout(1),
                cute.group_modes(sA, 0, 2),
                cute.group_modes(gA, 0, 2),
            )

            cute.copy(
                tma_atom_load,
                tAgA[(None, bidx, bidy)],
                tAsA[(None, 0)],
                tma_bar_ptr=load_mbar_ptr,
            )

            # Arrive on mbarrier to satisfy the init count of 1
            with cute.arch.elect_one():
                cute.arch.mbarrier_arrive(load_mbar_ptr)

        # ------------------------------------------------------------------
        # CONSUMER: Transpose Warps (sA -> Reg -> sB)
        # ------------------------------------------------------------------
        if warp_idx < self.tma_load_warp_id:
            trans_tid = tidx % self.num_trans_threads

            # Wait for TMA Load to complete (consumer wait on load_mbar)
            cute.arch.mbarrier_wait(load_mbar_ptr, 0)

            atom = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self.dtype,
                num_bits_per_copy=self.dtype.width,  # Copy one element at a time
            )

            copy_elems = 1

            # Use SAME thread layout for both read and write
            # Transpose happens through sB_transposed layout view

            # TV layout notation: T = thread-id, V = value-lane within that thread.
            # In this example `copy_elems = 1` and `thread_layout` has shape (T, V) = (num_trans_threads, 1),
            # so V is always 0 (only one value-lane per thread).
            #
            # Linearization rule (row-major by strides):
            #   idx(Ti, Vj) = i + j * num_trans_threads
            # Therefore here:
            #   idx(Ti, V0) = i
            #
            # Diagram (V is the column, T is the row; showing the first two threads):
            #
            #            V0
            #          ┌──────┐
            #   T0     │ T0V0 │  -> idx 0
            #   T1     │ T1V0 │  -> idx 1
            #   ...    │  ... │
            #          └──────┘
            #
            thread_layout = cute.make_layout(
                (self.num_trans_threads, 1),
                stride=(1, self.num_trans_threads),
            )
            value_layout = cute.make_layout((1, copy_elems))
            # Build a "tiled copy" operator that defines the per-thread copy mapping (T,V) for this warp-group:
            # - It is used twice below via `thr_copy.partition_S(...)` and `thr_copy.partition_D(...)` to
            #   create matching per-thread views of the source and destination tensors.
            # - With the SAME (T,V) mapping, the actual transpose is achieved by changing the tensor view
            #   (`sA` vs `sB` / `sB_transposed`), not by changing which threads perform the copies.
            tiled_copy = cute.make_tiled_copy_tv(atom, thread_layout, value_layout)
            thr_copy = tiled_copy.get_slice(trans_tid)

            # Partition sA (source) for reading
            tCsA = thr_copy.partition_S(sA)
            # When to use `tiled_copy.retile(...)`:
            # - Use it when you allocate/build a register tensor yourself (or slice/reshape it) and its
            #   internal layout doesn't match the TV layout expected by `tiled_copy` for copy-in/out.
            # Why we don't use it here:
            # - `cute.make_fragment_like(tCsA)` creates an rmem fragment with the same per-thread shape/layout
            #   as `tCsA`, so it already matches `tiled_copy`'s view and can be copied into directly.
            tCrA = cute.make_fragment_like(tCsA)
            cute.copy(tiled_copy, tCsA, tCrA)

            # Partition sB for writing
            tCsB = thr_copy.partition_D(sB)

            # Write from register to sB
            cute.copy(tiled_copy, tCrA, tCsB)

            # Fence and barrier to make sure shared memory store is visible to TMA store
            cute.arch.fence_proxy(
                "async.shared",
                space="cta",
            )
            self.trans_sync_barrier.arrive_and_wait()

            # Trans warps signal TMA Store warp: "sB is ready!"
            with cute.arch.elect_one():
                cute.arch.mbarrier_arrive(store_mbar_ptr)

        # ------------------------------------------------------------------
        # CONSUMER: TMA Store Warp (sB -> G)
        # ------------------------------------------------------------------
        if warp_idx == self.tma_store_warp_id:
            # Wait for Trans warp to complete (consumer wait on store_mbar)
            cute.arch.mbarrier_wait(store_mbar_ptr, 0)

            gDst_cta = cute.local_tile(
                tma_tensor_dst, (self.tile_m, self.tile_n), (None, None)
            )
            tBsB, tBgB = cpasync.tma_partition(
                tma_atom_store,
                0,
                cute.make_layout(1),
                cute.group_modes(sB, 0, 2),
                cute.group_modes(gDst_cta, 0, 2),
            )
            cute.copy(tma_atom_store, tBsB[(None, 0)], tBgB[(None, bidx, bidy)])


def run_transpose(M, N, num_warmup=5, num_iters=20):
    """
    Run TMA transpose kernel with performance measurement.

    Args:
        M: Matrix dimension M
        N: Matrix dimension N
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

    transpose_kernel = Sm100MatrixTransposeKernelV1()

    print("Start kernel compilation...")

    # Compile and Run
    compiled_kernel = cute.compile(
        transpose_kernel, tensor_src, tensor_dst, options="--generate-line-info"
    )

    print("Start kernel warmup...")
    # Warmup runs
    for _ in range(num_warmup):
        compiled_kernel(tensor_src, tensor_dst)
    torch.cuda.synchronize()
    print("Kernel warmup completed.")

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

    # Print performance metrics
    print(f"Matrix size: {M}×{N}")
    print(f"Tile shape: {transpose_kernel.tile_shape}")
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
        description="TMA Matrix Transpose with Producer-Consumer Pattern"
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
