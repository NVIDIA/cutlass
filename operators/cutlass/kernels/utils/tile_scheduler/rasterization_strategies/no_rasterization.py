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

"""No-rasterization (identity) strategy for the tile scheduler.

The work strategy already returns this CTA's own per-CTA tile coordinate, so this
strategy wraps it into a ``WorkTileInfo`` unchanged -- no decode, no offset, no
swizzle, no raster reorder.
"""

import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    Boolean,
    Int32,
    dsl_user_op,
)
from cutlass.kernels.utils.tile_scheduler.base import BaseRasterizationStrategy
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)
from cutlass.kernels.utils.tile_scheduler.tile_scheduler import WorkTileInfo


class NoRasterizationStrategy(BaseRasterizationStrategy):
    """Identity rasterizer: wrap the per-CTA work coordinate unchanged.

    The work strategy already returns this CTA's own per-CTA tile coordinate, so
    this strategy only attaches the validity flag and the full ``[0, k_tile_cnt)``
    K-range. No decode, no offset, no swizzle, no raster reorder -- contrast
    ``AffineRasterizationStrategy``, which decodes a cluster-linear index.
    """

    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
    ):
        """Stash params. Reused by ``__new_from_mlir_values__``.

        ``runtime_params.k_tile_cnt`` supplies the full K-range attached to each
        wrapped tile.

        :param template_params: compile-time scheduler config.
        :type template_params: TileSchedulerTemplateParams
        :param runtime_params: runtime scheduler parameters.
        :type runtime_params: TileSchedulerRuntimeParams
        """
        # Field stash; reused by __new_from_mlir_values__.
        self.template_params = template_params
        self.runtime_params = runtime_params

    @staticmethod
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
    ) -> "NoRasterizationStrategy":
        """Build a strategy from the scheduler params (no precomputation needed).

        :param template_params: compile-time scheduler config.
        :type template_params: TileSchedulerTemplateParams
        :param runtime_params: runtime scheduler parameters.
        :type runtime_params: TileSchedulerRuntimeParams
        :return: the constructed strategy.
        :rtype: NoRasterizationStrategy
        """
        return NoRasterizationStrategy(template_params, runtime_params)

    @dsl_user_op
    def rasterize(
        self,
        work_coord,
        is_valid: Boolean,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> WorkTileInfo:
        """Wrap the per-CTA work coordinate into a WorkTileInfo, unchanged.

        The work strategy already returns this CTA's own per-CTA tile coordinate, so
        this strategy only attaches the validity flag and the full [0, k_tile_cnt)
        K-range. No decode, no offset, no swizzle / raster reorder.
        """
        return WorkTileInfo(
            work_coord,
            Boolean(is_valid),
            k_start=Int32(0),
            k_end=Int32(self.runtime_params.k_tile_cnt),
        )

    @staticmethod
    def can_implement(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl,
        swizzle_size,
        raster_along,
    ) -> bool:
        """Accept only the trivial traversal, which is all this rasterizer expresses.

        It wraps the work strategy's coordinate unchanged, applying no swizzle
        and no raster reorder, so honoring anything else is impossible for
        every problem -- the request would be silently dropped.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        return raster_along == "m" and swizzle_size == 1

    @staticmethod
    def get_smem_workspace_size(template_params: TileSchedulerTemplateParams) -> int:
        """Shared-memory workspace required, in bytes. This strategy needs none.

        :param template_params: compile-time scheduler config.
        :type template_params: TileSchedulerTemplateParams
        :return: workspace size in bytes (always 0).
        :rtype: int
        """
        return 0

    @staticmethod
    def get_gmem_workspace_size(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnkl: cute.Shape,
    ) -> int:
        """Global-memory workspace required, in bytes. This strategy needs none.

        ``problem_shape_mnkl`` is part of the strategy interface but is ignored
        here since the size is unconditionally 0.

        :param template_params: compile-time scheduler config.
        :type template_params: TileSchedulerTemplateParams
        :param problem_shape_mnkl: full problem shape (ignored).
        :type problem_shape_mnkl: cute.Shape
        :return: workspace size in bytes (always 0).
        :rtype: int
        """
        return 0

    @staticmethod
    def initialize_workspace(
        template_params: TileSchedulerTemplateParams,
        problem_shape_mnl: cute.Shape,
        host_workspace,
    ) -> None:
        """No-op host-side workspace initialization (runs before upload).

        Identity rasterization owns a 0-byte GMEM workspace, so there is nothing
        to populate.
        """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        # No loop-carried state to serialize.
        return []

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "NoRasterizationStrategy":
        # Nothing was serialized; rebuild from the stored config.
        return NoRasterizationStrategy(self.template_params, self.runtime_params)
