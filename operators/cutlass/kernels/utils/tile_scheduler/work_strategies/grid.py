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

"""Non-persistent work strategy.

Maps one output tile to one CTA: the kernel grid itself enumerates the tiles, so
no on-device scheduling loop is needed. The strategy yields exactly one valid
tile per CTA and reports ``valid=False`` thereafter, so the caller's work loop
runs a single iteration.

Two compile-time configurations (selected by
``template_params.rasterization_strategy``):

* ``'none'``: a grid proportional to the tile shape; the per-CTA ``(m, n, l)``
  tile coordinate is returned directly. Paired with ``NoRasterizationStrategy``
  -- the identity rasterizer that adds the cta-in-cluster offset.
* ``'affine'``: the cluster-linear grid ``(cluster_m * num_clusters, cluster_n,
  cluster_z)``. The physical launch coordinate is mapped by
  :meth:`GridWorkStrategy.to_work_coord` to the work coordinate
  ``AffineRasterizationStrategy`` (the decoding rasterizer) decodes, applying
  the runtime swizzle / raster reorder.
"""

from typing import Any

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    Boolean,
    Int32,
    dsl_user_op,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseWorkStrategy
from cutlass.kernels.utils.tile_scheduler.common import (
    get_host_cluster_counts_mn,
    get_host_num_clusters,
    get_problem_shape_ntile,
    get_swizzled_problem_layout_ncluster,
)
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)


class GridWorkStrategy(BaseWorkStrategy):
    """Non-persistent work strategy: one output tile per CTA.

    The grid enumerates all tiles, so this strategy never schedules across tiles.
    It returns this CTA's work coordinate; with a tile-proportional grid this is
    the per-CTA ``(m, n, l)`` tile coordinate, and with the cluster-linear grid
    it is the physical coordinate mapped by :meth:`to_work_coord` for the
    rasterizer to decode. Either way the first ``fetch_next_work`` reports the
    tile invalid and the work loop ends after one iteration.
    ``template_params``/``runtime_params`` are stored but unused by the (trivial)
    scheduling logic.
    """

    @staticmethod
    def to_work_coord(template_params: TileSchedulerTemplateParams, phys_coord):
        """Map a physical launch-grid coordinate to the rasterizer's work coordinate.

        :param phys_coord: ``(x, y, z)`` coordinate in the launched grid
        :return: the ``(x, y, z)`` work coordinate for the rasterizer
        """
        if cutlass.const_expr(template_params.rasterization_strategy == "none"):
            return phys_coord
        cluster_m, _, cluster_z = template_params.cluster_shape
        x, y, z = phys_coord
        return (x % cluster_m, y, (x // cluster_m) * cluster_z + z)

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ):
        """Store params; ``num_tiles_executed`` starts at 0 (one tile per CTA)."""
        self.template_params = template_params
        self.runtime_params = runtime_params
        self.num_tiles_executed = Int32(0)

        self._loc = loc

    @staticmethod
    @dsl_user_op
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ):
        """Build a non-persistent grid work strategy for the current CTA."""
        return GridWorkStrategy(template_params, runtime_params, loc=loc, ip=ip)

    @dsl_user_op
    def initial_work(self, *, loc: Any = None, ip: Any = None):
        """Seed this CTA's first work coordinate from its own ``block_idx()``.

        The rasterizer maps it to a tile. Always valid for the launched grid.

        :return: ``((Coord x, y, z), Boolean valid)``
        """
        phys_coord = cute.arch.block_idx()
        return self.to_work_coord(self.template_params, phys_coord), Boolean(True)

    @dsl_user_op
    def fetch_next_work(
        self, work_tile_info, grid_pipeline, grid_consumer_state, *, loc=None, ip=None
    ):
        """Mark the current tile done; report that no further tile exists.

        Each CTA owns exactly one tile, so the "next" tile is always invalid.
        Returns ``(work_coord, valid, grid_consumer_state)`` with ``valid=False``;
        there is no pipeline, so the state is returned unchanged.
        """
        # The full grid is enumerated one CTA at a time, so the next tile is invalid.
        self.num_tiles_executed += Int32(1)

        # Invalid tile -> the coordinate is unused; return this CTA's own work
        # coordinate for shape/type consistency with initial_work.
        phys_coord = cute.arch.block_idx()
        return (
            self.to_work_coord(self.template_params, phys_coord),
            Boolean(False),
            grid_consumer_state,
        )

    @dsl_user_op
    def advance_to_next_work(
        self, work_tile_info, clc_pipeline, clc_producer_state, *, loc=None, ip=None
    ):
        """No-op advance (there is never a next tile to advance to).

        ``clc_pipeline`` and ``clc_producer_state`` are accepted only to match the
        work-strategy interface and are ignored here; the state is returned unchanged.
        """
        return clc_producer_state

    @staticmethod
    def get_grid_shape(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback=None,
    ) -> cute.Shape:
        """Launch grid (in CTAs) that enumerates every tile, one per CTA.

        ``max_active_clusters_fallback`` is accepted for signature parity with
        the static strategy (whose grid is occupancy-bounded) and ignored: this
        grid covers the whole problem regardless of occupancy.

        When ``rasterization_strategy == "none"``, returns a grid
        proportional to the tile shape ``(tiles_m, tiles_n, batch_l *
        cluster_shape[2])`` (paired with the identity rasterizer). Otherwise
        returns the cluster-linear grid ``(cluster_m * num_clusters, cluster_n,
        cluster_z)``, with the cluster count on ``grid.x`` to avoid overflowing
        the grid dimensions; :meth:`to_work_coord` maps the physical coordinate
        back for the affine rasterizer to decode. The swizzled cluster raster
        is rounded up to whole swizzle groups, so the count may cover
        out-of-bounds clusters (dropped by the epilogue) and does not depend on
        which axis is major.
        """
        # Tile-proportional grid: each CTA reads its tile straight from blockIdx
        # (paired with NoRasterizationStrategy, the identity rasterizer).
        if template_params.rasterization_strategy == "none":
            return get_problem_shape_ntile(template_params, problem_shape_mnl)
        swizzled_problem_layout_ncluster_mnl = get_swizzled_problem_layout_ncluster(
            template_params, problem_shape_mnl, swizzle_size, raster_along_m
        )
        num_clusters = cute.size(swizzled_problem_layout_ncluster_mnl.shape)
        cluster_m, cluster_n, cluster_z = template_params.cluster_shape
        return (cluster_m * num_clusters, cluster_n, cluster_z)

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Bound the launch grid this strategy emits for the problem.

        The identity-rasterizer grid is tile-proportional (N tiles on ``grid.y``,
        split-expanded batch on ``grid.z``); the affine grid puts the cluster
        count on ``grid.x`` and the CTA-linear index in the work coordinate.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        cluster_m, cluster_n, cluster_z = template_params.cluster_shape
        if template_params.rasterization_strategy == "none":
            _, n_clusters = get_host_cluster_counts_mn(
                template_params, problem_shape_mnkl
            )
            tiles_l = cute.round_up(
                problem_shape_mnkl[3] * template_params.split_k, cluster_z
            )
            return n_clusters * cluster_n <= 65535 and tiles_l <= 65535
        num_clusters = get_host_num_clusters(
            template_params, problem_shape_mnkl, swizzle_size, raster_along
        )
        return max(cluster_m, cluster_z) * num_clusters <= 2**31 - 1

    @dsl_user_op
    def get_num_tiles_executed(self, *, loc=None, ip=None) -> Int32:
        """Return the per-CTA tile counter (reaches 1 after the single tile)."""
        return self.num_tiles_executed

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams):
        """SMEM workspace in BYTES; grid scheduling needs none, so always 0."""
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ):
        """GMEM workspace in BYTES; grid scheduling needs none, so always 0."""
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op host-side initializer, called before upload.

        Grid scheduling owns a 0-byte GMEM workspace, so there is nothing to
        populate.
        """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """No dynamic state to carry; return an empty list."""
        return []

    def __new_from_mlir_values__(self, values: list[ir.Value]):
        """Rebuild a stateless strategy; carried ``values`` are unused."""
        return GridWorkStrategy(self.template_params, self.runtime_params)
