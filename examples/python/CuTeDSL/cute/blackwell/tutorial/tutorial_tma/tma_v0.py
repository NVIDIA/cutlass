# Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from typing import Type, Union

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
import torch

"""
TMA V0: Understanding tma_partition - The Foundation of TMA Operations

This tutorial demonstrates TMA (Tensor Memory Accelerator) operations through
a simple copy kernel. It focuses on understanding the fundamental tma_partition
interface, which is the key to all TMA operations.

What This Tutorial Covers:
1. TMA Load (Global Memory -> Shared Memory)
2. TMA Store (Shared Memory -> Global Memory)  
3. Barrier synchronization for TMA (elect_one, mbarrier_init, mbarrier_arrive, mbarrier_wait)
4. Detailed explanation of tma_partition with visual diagrams

Key Learning Points:
- tma_partition: How it transforms tensors for TMA operations
- group_modes: Why and how to group tensor modes to define TMA atom shape
- Indexing: How to select specific tiles from partitioned tensors
- Data flow: Complete visualization from input tensors to TMA copy

Visual Diagrams:
See line ~155 for comprehensive diagrams showing:
- Input tensor shapes and transformations
- group_modes effect on tensor layouts
- tma_partition output structure
- Complete data flow from global/shared memory to TMA copy
- Indexing pattern for CTA-specific tiles

Example Usage:
```bash
python cutlass_ir/compiler/python/examples/cute/blackwell/tutorial/tutorial_tma/tma_v0.py
```
"""


class Sm100SimpleCopyKernel:
    def __init__(self):
        """
        Initializes the configuration for a Blackwell TMA copy kernel.
        """
        self.tile_shape = (128, 128)
        self.tile_m, self.tile_n = self.tile_shape
        self.cluster_shape_mn = (1, 1)
        self.threads_per_cta = 32
        self.buffer_align_bytes = 1024

    @cute.jit
    def __call__(self, src: cute.Tensor, dst: cute.Tensor):
        if cutlass.const_expr(src.element_type != dst.element_type):
            raise TypeError("Source and destination element types must match")

        self.dtype: Type[cutlass.Numeric] = src.element_type

        # layout for each cta: (tile_m, tile_n):(tile_n, 1)
        smem_layout = cute.make_layout(
            (self.tile_m, self.tile_n), stride=(self.tile_n, 1)
        )

        @cute.struct
        class SharedStorage:
            barrier_storage: cute.struct.MemRange[cutlass.Int64, 1]
            smem_data: cute.struct.Align[
                cute.struct.MemRange[self.dtype, cute.cosize(smem_layout)],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage
        self.num_tma_load_bytes = cute.size_in_bytes(self.dtype, smem_layout)

        # cta_tiler: the per-CTA tile extents (M, N) used by TMA.
        # Note: smem_layout may include swizzle or composed layout,
        # so we use product_each(...) to take the product along each logical dimension and get
        # the final (tile_m, tile_n) extents expected by TMA.
        # In this simple example, smem_layout.shape == (tile_m, tile_n), so product_each(...) is
        # just (tile_m, tile_n).
        cta_tiler = cute.product_each(smem_layout.shape)

        tma_atom_src, tma_tensor_src = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileG2SOp(), src, smem_layout, cta_tiler
        )

        tma_atom_dst, tma_tensor_dst = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(), dst, smem_layout, cta_tiler
        )

        # Grid shape is now (M/TileM, N/TileN)
        grid_shape = cute.ceil_div((*src.layout.shape, 1), self.tile_shape)

        self.kernel(
            tma_atom_src, tma_tensor_src, tma_atom_dst, tma_tensor_dst, smem_layout
        ).launch(
            grid=grid_shape,
            block=(self.threads_per_cta, 1, 1),
            cluster=(*self.cluster_shape_mn, 1),
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_src: cute.CopyAtom,
        tma_tensor_src: cute.Tensor,
        tma_atom_dst: cute.CopyAtom,
        tma_tensor_dst: cute.Tensor,
        smem_layout: Union[cute.Layout, cute.ComposedLayout],
    ):
        bidx, bidy, _ = cute.arch.block_idx()

        # Allocate Shared Memory
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize barrier for TMA synchronization
        barrier_ptr = storage.barrier_storage.data_ptr()

        # Initialize the barrier: elect_one ensures only one thread executes this
        # Note: We must use elect_one() instead of "if tid == 0" because:
        # - elect_one() provides proper synchronization semantics
        # - It ensures all threads are aware that exactly one thread is executing
        # - It prevents race conditions and provides memory ordering guarantees
        with cute.arch.elect_one():
            cute.arch.mbarrier_init(barrier_ptr, 1)
            cute.arch.mbarrier_expect_tx(barrier_ptr, self.num_tma_load_bytes)

        # Fence ensures init/expect_tx are visible before proceeding
        cute.arch.mbarrier_init_fence()
        cute.arch.barrier()

        # Tile the (M, N) tensor: ((TileM, TileN), M/TileM, N/TileN)
        gSrc_tiled = cute.local_tile(
            tma_tensor_src, (self.tile_m, self.tile_n), (None, None)
        )
        gDst_tiled = cute.local_tile(
            tma_tensor_dst, (self.tile_m, self.tile_n), (None, None)
        )

        smem_tensor = storage.smem_data.get_tensor(smem_layout)

        # ======================================================================
        # TMA Partition: Tensor Preparation for TMA Operations
        # ======================================================================
        #
        # tma_partition prepares tensors for TMA copy by partitioning them
        # according to the TMA atom's internal layout requirements.
        #
        # Signature:
        #   tma_partition(atom, cta_id, cta_layout, smem_tensor, gmem_tensor)
        #     -> (smem_view, gmem_view)
        #
        # Key Requirement: Mode 0 of both tensors must represent the TMA atom
        #
        # Example: M=512, N=128, TileM=128, TileN=64
        #
        # Input Tensors:
        #   gSrc_tiled:  (128, 64, 4, 2)      # 4 separate modes
        #                 └──┬──┘ └──┬──┘
        #                   Tile    Grid
        #
        #   smem_tensor: (128, 64)            # 2 separate modes
        #                 └──┬──┘
        #                   Tile
        #
        # Apply group_modes(tensor, 0, 2) to group first 2 modes:
        #
        #   group_modes(gSrc_tiled, 0, 2)   =>  ((128, 64), 4, 2)
        #                                         └───┬───┘
        #                                         Mode 0 = Atom
        #
        #   group_modes(smem_tensor, 0, 2)  =>  ((128, 64),)
        #                                         └───┬───┘
        #                                         Mode 0 = Atom
        #
        # After tma_partition:
        #
        #   tAsA: SMEM view with TMA internal layout
        #     Shape: ((TMA_Layout),)
        #     - TMA_Layout: Swizzled/banked layout for efficient SMEM access
        #
        #   tAgA: Global view preserving rest modes
        #     Shape: ((TMA_Layout), 4, 2)
        #            └─────┬─────┘ └──┬──┘
        #            TMA atom      Rest modes (grid)
        #
        # Usage Pattern:
        #   1. Group modes to define atom: group_modes(tensor, 0, 2)
        #   2. Call tma_partition: tAsA, tAgA = tma_partition(...)
        #   3. Select tile for CTA: tAgA_cta = tAgA[(None, bidx, bidy)]
        #      - None: keep entire atom
        #      - bidx, bidy: index into rest modes
        #   4. Issue TMA copy: cute.copy(atom, tAgA_cta, tAsA)
        #
        # Visual Data Flow:
        #
        #   Global Memory (512x128)           Shared Memory (128x64)
        #   ┌────────────────────┐            ┌──────────────┐
        #   │  ┌───┬───┐         │            │              │
        #   │  │0,0│0,1│         │            │  smem_tensor │
        #   │  ├───┼───┤         │            │  (128, 64)   │
        #   │  │1,0│1,1│ 4x2     │            │              │
        #   │  ├───┼───┤ tiles   │            └──────────────┘
        #   │  │2,0│2,1│         │                    │
        #   │  ├───┼───┤         │                    │ group_modes
        #   │  │3,0│3,1│         │                    ↓
        #   │  └───┴───┘         │            ((128, 64),)
        #   └────────────────────┘                    │
        #            │                                 │
        #            │ gSrc_tiled                      │
        #            │ (128, 64, 4, 2)                │
        #            ↓                                 │
        #     group_modes(_, 0, 2)                    │
        #            ↓                                 │
        #     ((128, 64), 4, 2)                       │
        #            │                                 │
        #            └────────┬────────────────────────┘
        #                     ↓
        #              tma_partition
        #                     ↓
        #      ┌──────────────┴──────────────┐
        #      │                             │
        #   tAgA                          tAsA
        #   ((TMA_Layout), 4, 2)         ((TMA_Layout),)
        #      │
        #      ↓ tAgA[(None, bidx, bidy)]
        #   tAgA_cta
        #   ((TMA_Layout),)
        #
        # ======================================================================

        # TMA Load partition
        # Here we only use 1x1 cluster, so cta_id is 0 and cta_layout is (1).
        # More details about how to set cta_coord and cta_layout can be found in the tma_v4.py
        # Note: Smem and gemm should have the same size (atom element size) in the first rank
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_src,
            0,
            cute.make_layout(1),
            cute.group_modes(smem_tensor, 0, 2),
            cute.group_modes(gSrc_tiled, 0, 2),
        )

        # TMA Store partition
        # Same process as TMA Load, but for destination tensor
        # Partitions gDst_tiled and smem_tensor according to TMA Store atom
        _, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_dst,
            0,
            cute.make_layout(1),
            cute.group_modes(smem_tensor, 0, 2),
            cute.group_modes(gDst_tiled, 0, 2),
        )

        # Select specific tile for this CTA from partitioned global views
        # Input:  tAgA with shape ((TMA_Layout), 4, 2)
        # Output: tAgA_cta with shape ((TMA_Layout),)
        # The (None, bidx, bidy) indexing:
        #   - None: keeps the entire TMA atom layout (mode 0)
        #   - bidx: selects from rest mode 1 (M dimension grid)
        #   - bidy: selects from rest mode 2 (N dimension grid)
        tAgA_cta = tAgA[(None, bidx, bidy)]
        tBgB_cta = tBgB[(None, bidx, bidy)]

        # ---------- TMA Load: Global -> Shared ----------
        cute.copy(
            tma_atom_src,
            tAgA_cta,  # Source (TMA Tensor View)
            tAsA,  # Dest (SMEM Tensor View)
            tma_bar_ptr=barrier_ptr,
        )

        # Signal arrival on the barrier after TMA is issued
        with cute.arch.elect_one():
            cute.arch.mbarrier_arrive(barrier_ptr)

        # Wait for TMA to complete
        cute.arch.mbarrier_wait(barrier_ptr, 0)

        # ---------- TMA Store: Shared -> Global ----------
        cute.copy(
            tma_atom_dst,
            tAsA,  # Source (SMEM Tensor View)
            tBgB_cta,  # Dest (Global Tensor View)
        )


def run_tma_copy(M, N, num_warmup=5, num_iters=20):
    """
    Run TMA copy kernel with performance measurement.

    Args:
        M: Matrix dimension M
        N: Matrix dimension N
        num_warmup: Number of warmup iterations
        num_iters: Number of timing iterations
    """
    # Create tensors with shape (M, N)
    a = torch.randn((M, N), dtype=torch.float16, device="cuda")
    b = torch.zeros((M, N), dtype=torch.float16, device="cuda")

    # Notice: We declare N-dimension as the leading dimension should be divisible by 16
    a_cute = (
        from_dlpack(a, assumed_align=16)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=16)
    )
    b_cute = (
        from_dlpack(b, assumed_align=16)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=16)
    )

    copy_kernel = Sm100SimpleCopyKernel()
    compiled_kernel = cute.compile(copy_kernel, a_cute, b_cute)

    # Warmup runs
    for _ in range(num_warmup):
        compiled_kernel(a_cute, b_cute)
    torch.cuda.synchronize()

    # Timed runs
    start_event = torch.cuda.Event(enable_timing=True)
    end_event = torch.cuda.Event(enable_timing=True)

    start_event.record()
    for _ in range(num_iters):
        compiled_kernel(a_cute, b_cute)
    end_event.record()
    torch.cuda.synchronize()

    # Calculate performance metrics
    elapsed_time_ms = start_event.elapsed_time(end_event)
    avg_time_ms = elapsed_time_ms / num_iters

    # Calculate throughput
    # For copy: read M*N elements + write M*N elements
    bytes_per_element = a.element_size()
    total_bytes = 2 * M * N * bytes_per_element  # Read + Write
    throughput_gb_s = (total_bytes / 1e9) / (avg_time_ms / 1000)

    # Print performance metrics
    print(f"Matrix size: {M}×{N}")
    print(f"Tile shape: {copy_kernel.tile_shape}")
    print(f"Average time: {avg_time_ms:.4f} ms")
    print(f"Throughput: {throughput_gb_s:.2f} GB/s")

    # Verify
    if torch.allclose(a, b, atol=1e-3):
        print("Verification: PASSED ✓")
    else:
        print("Verification: FAILED ✗")
        diff = (a - b).abs()
        print(f"Max diff: {diff.max()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="TMA V0: Understanding tma_partition - The Foundation of TMA Operations"
    )
    parser.add_argument("--M", type=int, default=512, help="Matrix dimension M")
    parser.add_argument("--N", type=int, default=128, help="Matrix dimension N")
    parser.add_argument(
        "--num_warmup", type=int, default=5, help="Number of warmup iterations"
    )
    parser.add_argument(
        "--num_iters", type=int, default=20, help="Number of timing iterations"
    )
    args = parser.parse_args()

    run_tma_copy(
        M=args.M,
        N=args.N,
        num_warmup=args.num_warmup,
        num_iters=args.num_iters,
    )
