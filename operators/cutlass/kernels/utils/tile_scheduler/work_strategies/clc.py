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

"""Work strategy backed by the SM100 CLC (Cluster Launch Control) hardware.

This strategy drives a dynamic persistent tile scheduler: instead of computing
the next tile from a running counter, it queries the CLC unit, which hands back
the coordinates of the next cluster to execute. Work-tile validity is taken
directly from the hardware 'vld' bit returned with each response.

The CLC query/response handshake lives in SMEM and is driven through a pipeline:
``advance_to_next_work`` issues a query (producer side) into a cyclic CLC-response
buffer guarded by mbarriers, and ``fetch_next_work`` waits on and reads back the
response (consumer side). The SMEM workspace layout is a contiguous block of
CLC-response slots (16 bytes each) followed by the full/empty mbarrier pair
(8 bytes each); see ``get_smem_workspace_size`` for the byte sizing.

The launch grid has two compile-time shapes (selected by
``template_params.rasterization_strategy``, via the shared grid work
strategy): ``'none'`` gives a grid proportional to the tile shape, paired with
the identity NoRasterizationStrategy; ``'affine'`` gives the cluster-linear grid
(cluster count on ``grid.x``) for the decoding AffineRasterizationStrategy.
``fetch_next_work`` / ``initial_work`` take this CTA's own physical coordinate in
the launched grid (``block_idx`` for the first tile; the CLC response plus the
cta-in-cluster offset thereafter) and map it through
``GridWorkStrategy.to_work_coord``. This strategy also owns the
``num_tiles_executed`` counter.
"""

import math
from typing import Any

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    Boolean,
    Int32,
    Int64,
    Int128,
    dsl_user_op,
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseWorkStrategy
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.work_strategies.grid import GridWorkStrategy


class ClcDynamicPersistentWorkStrategy(BaseWorkStrategy):
    """Work strategy that sources tile coordinates from the CLC hardware.

    Construct via :meth:`create` (which seeds ``num_tiles_executed`` to 0); the
    constructor itself is also used by ``__new_from_mlir_values__`` to rebuild the
    strategy when it is carried across the persistent loop.
    """

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        clc_response_ptr: cute.Pointer,
        clc_mbar_ptr: cute.Pointer,
        cta_id_in_cluster: cute.Coord,
        num_tiles_executed: Int32 = 0,
        *,
        loc=None,
        ip=None,
    ):
        """Store the pre-carved CLC response / mbarrier SMEM pointers.

        ``clc_response_ptr`` (Int128) and ``clc_mbar_ptr`` (Int64) are the two
        views of this strategy's SMEM block, carved by :meth:`create` from the
        runtime work-SMEM pointer: the first ``num_scheduler_stages`` * 16 bytes
        hold the CLC responses; the mbarrier pair region follows immediately after.

        :param clc_response_ptr: Int128 SMEM pointer to the CLC response slots.
        :param clc_mbar_ptr: Int64 SMEM pointer to the mbarrier pair region.
        :param cta_id_in_cluster: this CTA's ``(x, y, z)`` offset within its
            cluster, sampled once at construction and carried so every fetched CLC
            response (a cluster-leader coordinate) can be offset to this CTA.
        :param num_tiles_executed: initial value of the owned counter (0 for a
            fresh strategy).
        """
        self.template_params = template_params
        self.runtime_params = runtime_params
        # Cross-proxy fence on the CLC response read: always emitted today, kept
        # as an explicit flag (not leftover) so it can be promoted to a template
        # param if the fence ever needs to be configurable from the kernel.
        self.insert_fence = True
        self.clc_response_ptr = clc_response_ptr
        self.clc_mbar_ptr = clc_mbar_ptr
        self.cta_id_in_cluster = cta_id_in_cluster
        self.num_tiles_executed = num_tiles_executed

        self._loc = loc

    @staticmethod
    def get_grid_shape(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback=None,
    ) -> cute.Shape:
        """Launch grid shape (in CTAs) for the CLC-driven persistent kernel.

        ``max_active_clusters_fallback`` is accepted for signature parity with
        the static strategy and ignored: the hardware cluster launch control
        bounds residency itself.

        Shares the grid work strategy's shape: ``'none'`` rasterization gives the
        tile shape (each CTA reads a valid tile from blockIdx); ``'affine'`` gives
        ``(cluster_m * num_clusters, cluster_n, cluster_z)`` -- the cluster count
        over the swizzled raster on ``grid.x``, which
        ``GridWorkStrategy.to_work_coord`` and the AffineRasterizationStrategy
        decode.
        """
        # CLC uses the same grid shape as the grid work strategy.
        return GridWorkStrategy.get_grid_shape(
            template_params,
            problem_shape_mnl,
            swizzle_size,
            raster_along_m,
            max_active_clusters_fallback,
        )

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Bound the launch grid; CLC shares the grid work strategy's grid."""
        return GridWorkStrategy.can_implement(
            template_params, problem_shape_mnkl, swizzle_size, raster_along
        )

    @dsl_user_op
    def coord_from_clc_response(
        self,
        result_addr: cute.Pointer,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ):
        """Decode one CLC response in SMEM into a coordinate plus validity.

        :param result_addr: SMEM address of the 16-byte CLC response to decode.
        :return: a ``((m_idx, n_idx, l_idx), vld)`` tuple, where the coordinate is
            in cluster units and ``vld`` is the hardware validity bit.

        When ``self.insert_fence`` is set, also emits a cross-proxy fence
        so the generic-proxy read of the response is visible to later async-proxy
        operations.
        """
        m_idx, n_idx, l_idx, vld = cute.arch.clc_response(result_addr, loc=loc, ip=ip)

        # Cross-proxy fence to ensure generic proxy access are seen by later
        # async proxy operations.
        if cutlass.const_expr(self.insert_fence):
            cute.arch.fence_proxy("async.shared", space="cta", loc=loc, ip=ip)

        return (m_idx, n_idx, l_idx), vld

    @dsl_user_op
    def fetch_next_work(
        self, work_tile_info, clc_pipeline, clc_consumer_state, *, loc=None, ip=None
    ):
        """Consume one CLC response and return the next work coordinate.

        Waits on the consumer side of the CLC pipeline, decodes the response at the
        current consumer slot, then releases the slot. Bumps the owned
        ``num_tiles_executed`` counter: every warp role that iterates tiles calls
        this once per tile, so the count is consistent across warps (the epilogue
        uses it to rotate the TMA-store staging buffers between tiles).

        The CLC response is the cluster-leader coordinate in the launched grid;
        adding the cta-in-cluster offset yields this CTA's own physical
        coordinate, which ``GridWorkStrategy.to_work_coord`` maps to the work
        coordinate the rasterizer decodes.

        :return: ``(work_coord, is_valid, clc_consumer_state)`` where ``is_valid``
            carries the hardware validity bit, and ``clc_consumer_state`` is
            advanced here and returned for the caller to thread as the loop-carried
            state.
        """
        clc_pipeline.consumer_wait(clc_consumer_state)
        smem_addr = self.clc_response_ptr + clc_consumer_state.index
        tile_coord, is_valid = self.coord_from_clc_response(smem_addr, loc=loc, ip=ip)
        clc_pipeline.consumer_release(clc_consumer_state)

        clc_consumer_state.advance()
        self.num_tiles_executed += Int32(1)

        if cutlass.const_expr(math.prod(self.template_params.cluster_shape) == 1):
            cidx, cidy, cidz = 0, 0, 0
        else:
            cidx, cidy, cidz = self.cta_id_in_cluster

        phys_coord = (tile_coord[0] + cidx, tile_coord[1] + cidy, tile_coord[2] + cidz)
        return (
            GridWorkStrategy.to_work_coord(self.template_params, phys_coord),
            Boolean(is_valid),
            clc_consumer_state,
        )

    @dsl_user_op
    def advance_to_next_work(
        self, work_tile_info, clc_pipeline, clc_producer_state, *, loc=None, ip=None
    ):
        """Issue a CLC query for the next work tile (producer side).

        Acquires a producer slot, then (from a single elected lane) issues a CLC
        query whose result will land in that slot's CLC-response buffer, signalled
        via the slot's mbarrier.

        :return: the advanced ``clc_producer_state`` for the caller to thread.
        """
        clc_pipeline.producer_acquire(clc_producer_state)
        # clc_response_ptr is Int128-typed, so indexing strides 16 bytes per slot.
        _clc_response_ptr = self.clc_response_ptr + clc_producer_state.index

        mbarrier_addr = clc_pipeline.producer_get_barrier(clc_producer_state)

        with cute.arch.elect_one():
            cute.arch.issue_clc_query(mbarrier_addr, _clc_response_ptr, loc=loc, ip=ip)
        clc_producer_state.advance()
        return clc_producer_state

    @staticmethod
    @dsl_user_op
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ):
        """Carve the runtime work-SMEM pointer into CLC response / mbarrier views.

        Builds a strategy with the counter at 0. The first
        ``num_scheduler_stages`` * 16 bytes hold the CLC responses
        (recast to Int128); the mbarrier pair region follows immediately after
        (recast to Int64).
        """
        smem_workspace_ptr = runtime_params.work_smem_workspace_ptr
        clc_response_ptr = cute.recast_ptr(smem_workspace_ptr, dtype=Int128)
        clc_mbar_ptr = cute.recast_ptr(
            smem_workspace_ptr + (template_params.num_scheduler_stages * 16),
            dtype=Int64,
        )
        return ClcDynamicPersistentWorkStrategy(
            template_params,
            runtime_params,
            clc_response_ptr,
            clc_mbar_ptr,
            cute.arch.block_in_cluster_idx(),
            Int32(0),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def initial_work(self, *, loc: Any = None, ip: Any = None):
        """Seed the first work coordinate from this CTA's launch grid, marked valid.

        The first work coordinate is this CTA's own ``block_idx()`` mapped
        through ``GridWorkStrategy.to_work_coord``; the rasterizer maps it to a
        tile.

        :return: ``(work_coord, True)``; the first tile is always taken from the
            launch grid rather than from a CLC response.
        """
        phys_coord = cute.arch.block_idx()
        return (
            GridWorkStrategy.to_work_coord(self.template_params, phys_coord),
            Boolean(True),
        )

    @dsl_user_op
    def get_clc_barrier_storage_ptr(self, *, loc=None, ip=None):
        """SMEM pointer to the CLC mbarrier region (Int64-typed)."""
        return self.clc_mbar_ptr

    @dsl_user_op
    def get_clc_response_storage_ptr(self, *, loc=None, ip=None):
        """SMEM pointer to the CLC response region (Int128-typed)."""
        return self.clc_response_ptr

    @dsl_user_op
    def get_num_tiles_executed(self, *, loc=None, ip=None) -> Int32:
        """Return the running count of tiles this strategy has issued queries for."""
        return self.num_tiles_executed

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams):
        """SMEM workspace size in BYTES: per stage, 16 (response) + 2*8 (mbarriers)."""
        # CLC response memory (16 bytes) + CLC full and empty (2) barrier (8 bytes) memory
        return template_params.num_scheduler_stages * (16 + (2 * 8))

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ):
        """GMEM workspace size in BYTES; CLC needs none, so always 0."""
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """Populate the host workspace, which is a no-op for CLC scheduling.

        CLC scheduling owns a 0-byte GMEM workspace, so there is nothing to
        populate. Runs host-side, before upload.
        """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Flatten the dynamic state (CLC response/mbarrier ptrs, cta-in-cluster offset, counter)."""
        values, self._values_pos = [], []
        for obj in [
            self.clc_response_ptr,
            self.clc_mbar_ptr,
            self.cta_id_in_cluster,
            self.num_tiles_executed,
        ]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(self, values: list[ir.Value]):
        """Rebuild the strategy from its flattened state; static params reused as-is."""
        obj_list, values_copy = [], list(values)
        for obj, n_items in zip(
            [
                self.clc_response_ptr,
                self.clc_mbar_ptr,
                self.cta_id_in_cluster,
                self.num_tiles_executed,
            ],
            self._values_pos,
        ):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]
        return ClcDynamicPersistentWorkStrategy(
            self.template_params, self.runtime_params, *(tuple(obj_list)), loc=self._loc
        )
