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

"""Affine rasterization strategy for the persistent tile scheduler.

The decoding rasterizer: reads the cluster-linear index from ``work_coord[2]``
and decodes it through the swizzled cluster layout, honoring the raster
direction (M-major vs N-major), then applies the cta-in-preferred-cluster offset
(supplied by the work strategy as ``work_coord[0] / work_coord[1]``) to produce a
per-CTA tile coordinate (tile-unit space).
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
from cutlass.kernels.utils.tile_scheduler.base import (
    BaseRasterizationStrategy,
)
from cutlass.kernels.utils.tile_scheduler.common import (
    derive_affine_divisors,
    get_host_cluster_counts_mn,
)
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import WorkTileInfo


class AffineRasterizationStrategy(BaseRasterizationStrategy):
    """Decode a cluster-linear index (from ``work_coord[2]``) to a per-CTA tile coordinate."""

    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        swizzled_problem_layout_ncluster_mnl: cute.Layout,
        k_tile_cnt: Int32,
        raster_along_m: Boolean,
        swizzle_size: Int32,
        cluster_shape_major_fdd: cute.FastDivmodDivisor,
        cluster_shape_minor_fdd: cute.FastDivmodDivisor,
    ):
        """Store the decode state.

        Every dynamic member is supplied by :meth:`create` (or rebuilt by
        :meth:`__new_from_mlir_values__`) and threaded explicitly across the
        persistent loop -- nothing is re-derived on reconstruction. The two
        ``*_fdd`` divisors serve the unswizzled fast path (see
        :meth:`_transform_coord`).
        """
        self.template_params = template_params
        self.swizzled_problem_layout_ncluster_mnl = swizzled_problem_layout_ncluster_mnl
        self.k_tile_cnt = k_tile_cnt
        self.raster_along_m = raster_along_m
        self.swizzle_size = swizzle_size
        self.cluster_shape_major_fdd = cluster_shape_major_fdd
        self.cluster_shape_minor_fdd = cluster_shape_minor_fdd

    @staticmethod
    @dsl_user_op
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        *,
        loc=None,
        ip=None,
    ) -> "AffineRasterizationStrategy":
        """Build a strategy, reusing prepared divisors when supplied.

        The divisors are the swizzled layout's major and minor mode extents;
        the minor extent is exact for the ``swizzle_size == 1`` case the fast
        path serves.
        """
        prepared = runtime_params.precomputed_sched_params
        if prepared is None:
            layout = runtime_params.swizzled_problem_layout_ncluster_mnl
            k_tile_cnt = runtime_params.k_tile_cnt
            major_fdd, minor_fdd = derive_affine_divisors(layout, loc=loc, ip=ip)
        else:
            template_params.check_precompute_support()
            layout = prepared.swizzled_problem_layout_ncluster_mnl
            k_tile_cnt = prepared.k_tile_cnt
            major_fdd = prepared.cluster_shape_major_fdd
            minor_fdd = prepared.cluster_shape_minor_fdd

        return AffineRasterizationStrategy(
            template_params,
            layout,
            k_tile_cnt,
            runtime_params.raster_along_m,
            Int32(runtime_params.swizzle_size),
            major_fdd,
            minor_fdd,
        )

    @cute.jit
    def _transform_coord(
        self,
        work_coord,
        current_work_linear_idx: Int32,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> tuple[Int32, Int32, Int32]:
        """Decode a cluster-linear index to this CTA's tile coordinate.

        :param current_work_linear_idx: Cluster-linear index of the current work.
        :return: this CTA's tile coordinate ``(m, n, l)``.
        :rtype: Tuple[Int32, Int32, Int32]
        """
        cluster_major, cluster_minor, batch_l = Int32(0), Int32(0), Int32(0)
        if self.swizzle_size == Int32(1):
            cluster_minor_batch, cluster_major = divmod(
                current_work_linear_idx, self.cluster_shape_major_fdd
            )
            batch_l, cluster_minor = divmod(
                cluster_minor_batch, self.cluster_shape_minor_fdd
            )
        else:
            cluster_major, cluster_minor, batch_l = (
                self.swizzled_problem_layout_ncluster_mnl.get_flat_coord(
                    current_work_linear_idx, loc=loc, ip=ip
                )
            )

        cluster_m, cluster_n = Int32(0), Int32(0)
        if self.raster_along_m:
            cluster_m, cluster_n = cluster_major, cluster_minor
        else:
            cluster_m, cluster_n = cluster_minor, cluster_major

        return tuple(
            cute.arch.make_warp_uniform(Int32(x) * Int32(y) + Int32(z))
            for x, y, z in zip(
                (cluster_m, cluster_n, batch_l),
                self.template_params.cluster_shape,
                (work_coord[0], work_coord[1], 0),
            )
        )

    @dsl_user_op
    def rasterize(
        self,
        work_coord,
        is_valid: Boolean,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> WorkTileInfo:
        """Decoding rasterizer entry: turn ``work_coord[2]`` into this CTA's tile.

        Scales ``work_coord[2]`` down by ``cluster_shape[2]`` to recover the
        cluster-linear index, decodes this CTA's tile coordinate via
        :meth:`_transform_coord` (which applies the cta-in-cluster offset), and
        marks it warp-uniform. The returned K-range covers the whole K extent.
        """
        cluster_linear_idx = work_coord[2]

        if cutlass.const_expr(self.template_params.cluster_shape[2] > 1):
            cluster_linear_idx = (
                cluster_linear_idx // self.template_params.cluster_shape[2]
            )

        cur_tile_coord = self._transform_coord(
            work_coord, cluster_linear_idx, loc=loc, ip=ip
        )
        return WorkTileInfo(
            cur_tile_coord,
            Boolean(cute.arch.make_warp_uniform(is_valid)),
            k_start=Int32(0),
            k_end=Int32(self.k_tile_cnt),
        )

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Accept any positive swizzle no wider than the cluster extent it groups.

        The swizzle groups clusters along the minor raster axis (N when M-major,
        else M). A ``swizzle_size`` exceeding that axis' cluster count cannot
        form even one full group, so the layout would round the axis up past the
        whole problem and pad the grid with phantom clusters.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: ``"m"`` or ``"n"``
        """
        return (
            1
            <= swizzle_size
            <= AffineRasterizationStrategy._minor_cluster_extent(
                template_params, problem_shape_mnkl, raster_along
            )
        )

    @staticmethod
    def _minor_cluster_extent(template_params, problem_shape_mnkl, raster_along):
        """Cluster count along the axis the swizzle groups (N when M-major, else M)."""
        m_clusters, n_clusters = get_host_cluster_counts_mn(
            template_params, problem_shape_mnkl
        )
        return n_clusters if raster_along == "m" else m_clusters

    @staticmethod
    def visits_oob_clusters(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """True when the swizzle does not divide the axis it groups.

        Only the grouped axis is rounded up to a whole number of swizzle
        groups, so only a remainder there is visited as clusters that decode
        outside the problem. The major axis is never rounded, so its
        divisibility does not matter.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: ``"m"`` or ``"n"``
        """
        minor_extent = AffineRasterizationStrategy._minor_cluster_extent(
            template_params, problem_shape_mnkl, raster_along
        )
        return minor_extent % swizzle_size != 0

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """SMEM workspace size in bytes. Affine rasterization needs none."""
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ) -> int:
        """GMEM workspace size in bytes. Affine rasterization needs none.

        ``problem_shape_mnkl`` is part of the strategy interface and is
        intentionally ignored here.
        """
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op (host-side, before upload).

        Affine rasterization decodes coordinates on the fly and owns a 0-byte
        GMEM workspace, so there is nothing to populate.
        """

    def _carried_state(self) -> list:
        """Return the members threaded across the persistent loop, in order.

        Single source of truth for the extract/new pair below, so the two stay
        in lockstep.
        """
        return [
            self.swizzled_problem_layout_ncluster_mnl,
            self.k_tile_cnt,
            self.raster_along_m,
            self.swizzle_size,
            self.cluster_shape_major_fdd,
            self.cluster_shape_minor_fdd,
        ]

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Flatten this strategy's decode state for loop carrying."""
        values, self._values_pos = [], []
        for obj in self._carried_state():
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "AffineRasterizationStrategy":
        """Rebuild the strategy from its flattened state, in extract order."""
        obj_list, values_copy = [], list(values)
        for obj, n_items in zip(self._carried_state(), self._values_pos):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]
        return AffineRasterizationStrategy(self.template_params, *(tuple(obj_list)))
