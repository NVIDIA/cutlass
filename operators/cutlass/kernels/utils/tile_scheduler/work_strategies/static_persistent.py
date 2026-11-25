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

"""Static persistent work strategy for the tile scheduler.

Provides a fixed assignment of output tiles to persistent CTAs. The launched
grid holds at most one wave of CTAs -- sized at launch from the occupancy cap
passed to :meth:`StaticPersistentWorkStrategy.get_grid_shape` -- and each
persistent CTA strides through the CTA-linear index space by
``num_persistent_ctas`` (read from ``grid_dim().z``) per iteration. There is no
runtime work stealing or atomic counter, hence "static".

The index handled here is CTA-linear (``block_idx().z``, combined over clusters
and split-K); the rasterizer scales it down to the cluster-linear index and adds
the cta-in-cluster offset.
"""

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    Boolean,
    Int32,
    dsl_user_op,
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseWorkStrategy
from cutlass.kernels.utils.tile_scheduler.common import (
    get_host_num_clusters,
    get_swizzled_problem_layout_ncluster,
)
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)


class StaticPersistentWorkStrategy(BaseWorkStrategy):
    """Static persistent scheduling over the cluster grid in CTA-linear space.

    Each persistent CTA starts at its own CTA-linear index (``block_idx().z``,
    combined over clusters and split-K) and advances by ``num_persistent_ctas``
    per wave until the index runs past the total CTA-linear extent
    (``cluster_shape[2]`` times the number of clusters in the problem). The
    affine rasterizer scales the index down, adds the cta-in-cluster offset, and
    applies the runtime swizzle / raster reorder at decode time.

    Instances are constructed via :meth:`create` on device; ``__init__`` may
    also be re-invoked by :meth:`__new_from_mlir_values__` to rebuild the
    strategy from its flattened state.
    """

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        cta_work_linear_idx: Int32,
        cta_in_preferred_cluster: cute.Coord,
        num_persistent_ctas: Int32,
        num_tiles_executed: Int32 = 0,
        *,
        loc=None,
        ip=None,
    ):
        """Store per-CTA scheduling state.

        :param cta_work_linear_idx: this CTA's current CTA-linear index (combined
            over clusters and split-K, as in the launch grid's z dimension).
        :param cta_in_preferred_cluster: this CTA's ``(x, y, z)`` offset within a
            preferred cluster, sampled once at construction.
        :param num_persistent_ctas: per-wave stride in CTA-linear space.
        :param num_tiles_executed: initial value of the owned counter (0 for a
            fresh strategy; non-zero when rebuilt from its flattened state).
        """
        self.template_params = template_params
        self.runtime_params = runtime_params
        self.cta_work_linear_idx = cta_work_linear_idx
        self.cta_in_preferred_cluster = cta_in_preferred_cluster
        self.num_persistent_ctas = num_persistent_ctas
        self.num_tiles_executed = num_tiles_executed

        self.swizzled_problem_layout_ncluster_mnl = (
            runtime_params.swizzled_problem_layout_ncluster_mnl
        )

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
        """Construct a strategy for the current CTA from the launch grid.

        The block's ``block_idx().z`` is its starting CTA-linear index (combined
        over clusters and split-K) and ``grid_dim().z`` is the per-wave stride in
        CTA-linear space.
        """
        _, _, bidz = cute.arch.block_idx()
        _, _, num_persistent_ctas = cute.arch.grid_dim()

        if cutlass.const_expr(
            template_params.cluster_shape == template_params.fallback_cluster_shape
        ):
            cta_in_preferred_cluster = cute.arch.block_in_cluster_idx()
        else:
            cta_in_preferred_cluster = tuple(
                Int32(x) % template_params.cluster_shape[i]
                for i, x in enumerate(cute.arch.block_idx())
            )

        return StaticPersistentWorkStrategy(
            template_params,
            runtime_params,
            Int32(bidz),
            cta_in_preferred_cluster,
            Int32(num_persistent_ctas),
            Int32(0),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def _work_coord_and_valid(self, cta_work_linear_idx, *, loc=None, ip=None):
        """Return ``((cta_x, cta_y, cta_work_linear_idx), valid)`` for a CTA-linear index.

        The CTA-linear index is carried in z, with x/y the
        cta-in-preferred-cluster offset; the rasterizer scales z down and
        applies that offset.
        """
        num_clusters = cute.size(self.swizzled_problem_layout_ncluster_mnl.shape)
        cta_extent = self.template_params.cluster_shape[2] * num_clusters
        is_valid = cta_work_linear_idx < cta_extent

        return (
            self.cta_in_preferred_cluster[0],
            self.cta_in_preferred_cluster[1],
            cta_work_linear_idx,
        ), Boolean(is_valid)

    @dsl_user_op
    def initial_work(self, *, loc=None, ip=None):
        """Return ``(work_coord, valid)`` for this CTA's first work item."""
        return self._work_coord_and_valid(self.cta_work_linear_idx)

    @dsl_user_op
    def fetch_next_work(
        self, work_tile_info, pipeline, consumer_state, *, loc=None, ip=None
    ):
        """Advance one wave and return ``(work_coord, valid, consumer_state)``.

        Strides the CTA-linear index by ``num_persistent_ctas`` and re-evaluates
        validity. There is no pipeline in static mode, so ``consumer_state`` is
        returned unchanged (for caller-thread uniformity). ``work_tile_info``,
        ``pipeline`` and ``consumer_state`` are otherwise ignored; they exist only
        for interface compatibility with dynamic strategies.
        """
        self.cta_work_linear_idx += self.num_persistent_ctas
        work_coord, is_valid = self._work_coord_and_valid(self.cta_work_linear_idx)
        self.num_tiles_executed += Int32(1)
        return work_coord, is_valid, consumer_state

    @dsl_user_op
    def advance_to_next_work(
        self, work_tile_info, pipeline, producer_state, *, loc=None, ip=None
    ):
        """No-op in static mode; returns ``producer_state`` unchanged.

        ``work_tile_info``, ``pipeline`` and ``producer_state`` are ignored and
        exist only for interface compatibility with dynamic strategies.
        """
        return producer_state

    @staticmethod
    def get_grid_shape(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        *,
        swizzled_problem_layout_ncluster_mnl: cute.Layout | None = None,
    ) -> cute.Shape:
        """Derive the CTA grid, capped by fallback-cluster occupancy.

        X/Y enumerate CTAs within a preferred cluster; Z is the persistent
        wave stride: one wave's worth of clusters, i.e. the clusters in the
        swizzled problem capped by ``max_active_clusters_fallback``.

        :param template_params: Static scheduler configuration.
        :param problem_shape_mnl: Problem dimensions (M, N, batch).
        :param swizzle_size: Clusters per swizzle group; one disables swizzling.
        :param raster_along_m: Whether to rasterize along M rather than N.
        :param max_active_clusters_fallback: Occupancy cap on concurrently
            resident *fallback* clusters (``fallback_cluster_shape``), as
            returned by the driver occupancy query. A launch-time value
            (``Int32``, like ``swizzle_size``): one compiled kernel serves any
            device or MPS partition. Must be > 0; the caller validates.
        :param swizzled_problem_layout_ncluster_mnl: Optional layout prepared
            from the same template and launch inputs.
        :return: Three-dimensional launch grid in CTAs.
        :rtype: cute.Shape
        """
        if swizzled_problem_layout_ncluster_mnl is None:
            swizzled_problem_layout_ncluster_mnl = get_swizzled_problem_layout_ncluster(
                template_params, problem_shape_mnl, swizzle_size, raster_along_m
            )
        num_ctas_per_cluster = cute.size(template_params.cluster_shape)
        num_ctas_in_problem = (
            cute.size(swizzled_problem_layout_ncluster_mnl.shape) * num_ctas_per_cluster
        )
        num_ctas_per_fallback_cluster = cute.size(
            template_params.fallback_cluster_shape
        )

        # Total ctas that can run in one wave, accounting for the additional fallback clusters.
        fallback_ctas_per_wave = (
            max_active_clusters_fallback * num_ctas_per_fallback_cluster
        )
        preferred_clusters_per_wave_with_fallback = (
            fallback_ctas_per_wave // num_ctas_per_cluster
        )

        num_ctas_per_wave = (
            preferred_clusters_per_wave_with_fallback * num_ctas_per_cluster
        )

        num_persistent_ctas = cutlass.cutlass_dsl.min(
            num_ctas_in_problem, num_ctas_per_wave
        )
        num_persistent_clusters = num_persistent_ctas // num_ctas_per_cluster

        return (
            *template_params.cluster_shape[:2],
            template_params.cluster_shape[2] * num_persistent_clusters,
        )

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Bound the CTA-linear work index this strategy strides over.

        The launch grid itself is occupancy-bounded (one wave), so only the
        work index -- ``cluster_z`` times the cluster count over the swizzled
        raster -- is bounded.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        num_clusters = get_host_num_clusters(
            template_params, problem_shape_mnkl, swizzle_size, raster_along
        )
        return template_params.cluster_shape[2] * num_clusters <= 2**31 - 1

    @dsl_user_op
    def get_num_tiles_executed(self, *, loc=None, ip=None) -> Int32:
        """Number of work items this cluster has fetched since construction."""
        return self.num_tiles_executed

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """Shared-memory workspace in BYTES; static scheduling needs none."""
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ) -> int:
        """Global-memory workspace in BYTES; static scheduling needs none."""
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op (host-side, before upload): static scheduling owns a 0-byte GMEM workspace, so there is nothing to populate."""

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Flatten the carried Int32 fields for loop carrying."""
        values, self._values_pos = [], []
        for obj in [
            self.cta_work_linear_idx,
            self.cta_in_preferred_cluster,
            self.num_persistent_ctas,
            self.num_tiles_executed,
        ]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(self, values: list[ir.Value]):
        """Rebuild a strategy from the values produced by __extract_mlir_values__."""
        obj_list, values_copy = [], list(values)
        for obj, n_items in zip(
            [
                self.cta_work_linear_idx,
                self.cta_in_preferred_cluster,
                self.num_persistent_ctas,
                self.num_tiles_executed,
            ],
            self._values_pos,
        ):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]
        return StaticPersistentWorkStrategy(
            self.template_params, self.runtime_params, *(tuple(obj_list)), loc=self._loc
        )
