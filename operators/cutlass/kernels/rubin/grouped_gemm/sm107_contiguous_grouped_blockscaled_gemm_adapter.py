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

"""Cumulative-offset adapter for Rubin contiguous grouped block-scaled GEMM."""

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute

from cutlass.kernels.rubin.grouped_gemm.sm107_contiguous_grouped_blockscaled_gemm import (
    Sm107BlockScaledContiguousGroupedGemmKernel,
)


class Sm107BlockScaledContiguousGroupedGemmAdapter(
    Sm107BlockScaledContiguousGroupedGemmKernel
):
    """Bridge index-pointer Operator arguments to the source kernel interface.

    This adapter:

    - Converts the Operator API's cumulative M offsets into the source kernel's
      tile-to-group map and valid-tile count.
    - Converts the Operator API's MK, LKN, and MN tensor layouts into the source
      kernel's MKL, NKL, and MNL layouts.
    - Invokes the source GEMM kernel with the converted schedule and layouts.

    The ``Int32`` workspace layout is::

        [tile_idx_to_group_idx[physical_tile_count], num_valid_tiles]

    """

    _threads_per_block = 128

    def get_workspace_size(self, m: int) -> int:
        """Return the workspace size in bytes for the allocated M capacity."""
        # Reserve the tile-to-group map plus one element for the valid-tile count.
        return (cute.ceil_div(m, self.mma_tiler[0]) + 1) * (cutlass.Int32.width // 8)

    @staticmethod
    def get_workspace_aligment() -> int:
        """Return the required workspace pointer alignment in bytes."""
        return cutlass.Int32.width // 8

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        out: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        offsets: cute.Tensor,
        workspace: cute.Pointer,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        global_scale_a: cute.Tensor,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Build the schedule, normalize layouts, and launch the GEMM."""
        # Size the map from the allocated M capacity. The final offset can be
        # smaller, for example when a fixed-size buffer holds a shorter batch.
        physical_tile_count = cute.ceil_div(a.shape[0], self.mma_tiler[0])
        tile_idx_to_group_idx = cute.make_tensor(workspace, (physical_tile_count,))
        num_valid_tiles = cute.make_tensor(workspace + physical_tile_count, (1,))
        self.offsets_to_tiled_schedule(
            offsets,
            tile_idx_to_group_idx,
            num_valid_tiles,
            self.mma_tiler[0],
        ).launch(
            grid=[
                cute.ceil_div(cute.size(offsets), self._threads_per_block),
                1,
                1,
            ],
            block=[self._threads_per_block, 1, 1],
            stream=stream,
        )

        # Materialize the source kernel's MKL, NKL, and MNL views without moving
        # data: A and out gain a singleton L mode, while B reorders LKN to NKL.
        a = cute.make_tensor(a.iterator, cute.append(a.layout, cute.make_layout(1)))
        b = cute.make_tensor(b.iterator, cute.select(b.layout, [2, 1, 0]))
        out = cute.make_tensor(
            out.iterator, cute.append(out.layout, cute.make_layout(1))
        )
        super().__call__(
            a,
            b,
            out,
            sfa,
            sfb,
            tile_idx_to_group_idx,
            num_valid_tiles,
            global_scale_a,
            max_active_clusters,
            stream,
            epilogue_op,
        )

    @cute.kernel
    def offsets_to_tiled_schedule(
        self,
        offsets: cute.Tensor,
        tile_idx_to_group_idx: cute.Tensor,
        num_valid_tiles: cute.Tensor,
        tile_m: cutlass.Constexpr,
    ):
        """Convert cumulative M offsets into a tile-to-group lookup table.

        ``offsets[g]`` is group ``g``'s exclusive cumulative M boundary. Tile
        alignment makes integer division by ``tile_m`` exact, so consecutive
        boundaries define the group's half-open tile interval::

            group_start_tile = offsets[g - 1] // tile_m  # 0 when g == 0
            group_end_tile   = offsets[g] // tile_m

        For example, ``offsets=[1024, 1536]`` and ``tile_m=512`` produce tile
        intervals ``[0, 2)`` and ``[2, 3)``, hence
        ``tile_idx_to_group_idx=[0, 0, 1]`` and ``num_valid_tiles=3``.

        One thread handles each group.
        """
        thread_idx, _, _ = cute.arch.thread_idx()
        block_idx, _, _ = cute.arch.block_idx()
        group_count = cute.size(offsets)
        group_idx = block_idx * self._threads_per_block + thread_idx

        if group_idx < group_count:
            group_start_m = cutlass.Int32(0)
            if group_idx > 0:
                group_start_m = offsets[group_idx - 1]
            group_end_m = offsets[group_idx]
            group_start_tile = group_start_m // tile_m
            group_end_tile = group_end_m // tile_m
            for tile_idx in cutlass.range(
                group_start_tile,
                group_end_tile,
                1,
                unroll=1,
            ):
                tile_idx_to_group_idx[tile_idx] = group_idx

        # Only the valid prefix is consumed by the source kernel scheduler.
        if block_idx == 0 and thread_idx == 0:
            num_valid_tiles[0] = offsets[group_count - 1] // tile_m
