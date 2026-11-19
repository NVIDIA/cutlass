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

"""Abstract strategy-interface layer for the tile scheduler.

Defines the three contracts every concrete scheduler strategy must honor:

- work strategy: hands out work items and advances over the strategy's linear
  work index space (see :class:`BaseWorkStrategy`).
- reduction strategy: cross-contribution fixup / work-tile splitting (see
  :class:`BaseReductionStrategy`).
- rasterization strategy: maps a work coordinate ``(x, y, z)`` to a tile
  coordinate (see :class:`BaseRasterizationStrategy`).

Each contract also declares a ``create(...)`` factory -- the real
construction entry point every concrete strategy implements (a staticmethod,
typically device-traced). Note the two-phase init pattern:
``__init__`` leaves derived fields ``None`` and ``TileScheduler.create``
populates them, so ``create`` (not ``__init__``) yields a usable instance.
"""

#: Concrete rasterization orders: which axis is the fast-varying one.
RASTERIZATION_ORDERS = ("m", "n")

RASTERIZATION_ORDER_OPTIONS = (*RASTERIZATION_ORDERS, "heuristic")


class BaseWorkStrategy:
    """Contract for a work strategy.

    A work strategy owns a work space and exposes a fetch-then-advance
    lifecycle: ``fetch_next_work`` reports the current work item together with
    its validity flag, and ``advance_to_next_work`` steps the internal cursor
    to the next item. The two are kept separate so a caller may inspect the
    current item before committing to advance past it. Each work item is a work
    coordinate ``(x, y, z)`` tuple, handed to the rasterization strategy: the
    identity rasterizer (NoRasterizationStrategy) wraps it into a
    ``WorkTileInfo`` unchanged, while the decoding rasterizer
    (AffineRasterizationStrategy) decodes a cluster-linear index from ``z``.

    The work strategy also owns the launch grid shape (``get_grid_shape``): it
    is the strategy that decides how its work space maps onto the CUDA grid.
    """

    @staticmethod
    def create(*args, **kwargs) -> "BaseWorkStrategy":
        """Factory: build a configured work strategy from the static + runtime params.

        The real construction entry point every concrete strategy implements
        (a staticmethod, typically device-traced).
        """
        raise NotImplementedError

    def __init__(self, *args, **kwargs):
        pass

    def initial_work(self, *args, **kwargs):
        """Return the strategy's initial work coordinate ``(x, y, z)`` tuple and its validity flag.

        Seeds the fetch/advance loop for the current cluster/CTA. The
        coordinate is handed to the rasterization strategy, which either wraps
        it unchanged (NoRasterizationStrategy) or decodes it
        (AffineRasterizationStrategy).
        """
        raise NotImplementedError

    def fetch_next_work(self, *args, **kwargs):
        """Return the current work item plus its validity flag, without advancing the cursor."""
        raise NotImplementedError

    def advance_to_next_work(self, *args, **kwargs):
        """Step the internal cursor to the next item in the strategy's work space."""
        raise NotImplementedError

    @staticmethod
    def get_grid_shape(*args, **kwargs):
        """Return the launch grid shape.

        Owned by the work strategy: it determines how the strategy's work space
        maps onto the grid. (Called on the class, e.g.
        ``work_strategy.get_grid_shape(...)``.) Signature shared by all
        strategies: ``(template_params, problem_shape_mnl, swizzle_size,
        raster_along_m, max_active_clusters_fallback)``; the last is a
        launch-time occupancy cap that only occupancy-bounded grids use.
        """
        raise NotImplementedError

    def get_num_tiles_executed(self, *args, **kwargs):
        """Return the number of tiles this strategy has executed (for accounting / the epilogue)."""
        raise NotImplementedError

    def get_gmem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: global-memory workspace size in BYTES."""
        raise NotImplementedError

    def get_smem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: shared-memory workspace size in BYTES."""
        raise NotImplementedError

    @staticmethod
    def can_implement(
        template_params, problem_shape_mnkl, swizzle_size, raster_along
    ) -> bool:
        """Performs feasibility checks on runtime arguments.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        return True

    def initialize_workspace(self, *args, **kwargs) -> None:
        """Initializes workspace with appropriate values specific to this strategy."""


class BaseReductionStrategy:
    """Contract for a reduction strategy.

    Combines the partial results of the work items that contribute to the same
    output tile -- only meaningful when the K dimension is split across
    clusters. ``split_work_tile`` partitions a work tile into its per-split
    sub-units; ``pre_fixup`` sets up the split-K epilogue before the reduction;
    and ``fixup_and_epilogue`` reduces one tile's per-split partials and runs
    the epilogue on the combined result. The two fixup hooks are no-ops for
    strategies that do not split K.

    Concrete strategies are constructed via their own ``create(...)`` factory
    (not declared here).
    """

    @staticmethod
    def create(*args, **kwargs) -> "BaseReductionStrategy":
        """Factory: build a configured reduction strategy from the static + runtime params.

        The construction entry point every concrete strategy implements.
        """
        raise NotImplementedError

    def __init__(self, *args, **kwargs):
        pass

    def pre_fixup(self, *args, **kwargs):
        """Set up the split-K epilogue before the per-tile reduction.

        This includes, e.g., the TMEM/register partitions the reduction reads
        back. Default no-op: strategies that do not split the K dimension have
        nothing to set up.
        """

    def fixup_and_epilogue(self, *args, **kwargs):
        """Reduce one output tile's per-split partials and run the epilogue on the combined result.

        Reduces the per-split partial accumulators across the contributing
        clusters. Default no-op: strategies that do not split the K dimension
        have no partials to combine.
        """

    def finalize(self, *args, **kwargs):
        """Run end-of-kernel synchronization after the persistent loop.

        Default no-op: only strategies with cross-CTA state that must outlive
        the epilogue (e.g. the cluster split-K DSMEM mailbox) override this.
        """

    def split_work_tile(self, *args, **kwargs):
        """Partition a work tile into the sub-units the reduction operates over."""
        raise NotImplementedError

    def get_gmem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: global-memory workspace size in BYTES."""
        raise NotImplementedError

    def get_smem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: shared-memory workspace size in BYTES."""
        raise NotImplementedError

    @staticmethod
    def can_implement(
        template_params, problem_shape_mnkl, swizzle_size, raster_along
    ) -> bool:
        """Performs feasibility checks on runtime arguments.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        return True

    def initialize_workspace(self, *args, **kwargs) -> None:
        """Initializes workspace with appropriate values specific to this strategy."""


class BaseRasterizationStrategy:
    """Contract for a rasterization strategy.

    Maps a work coordinate ``(x, y, z)`` (the tuple from the work strategy)
    onto a tile coordinate, defining the traversal order over the output (e.g.
    M-major / raster_along_m vs. N-major, swizzle). The decoding rasterizer
    (AffineRasterizationStrategy) reads a cluster-linear index from ``z`` and
    decodes it; the identity rasterizer (NoRasterizationStrategy) wraps the
    coordinate into a ``WorkTileInfo`` unchanged. ``rasterize`` performs that
    work-coord -> tile-coord mapping.

    Concrete strategies are constructed via their own ``create(...)`` factory
    (not declared here).
    """

    @staticmethod
    def create(*args, **kwargs) -> "BaseRasterizationStrategy":
        """Factory: build a configured rasterization strategy from the static + runtime params.

        The construction entry point every concrete strategy implements.
        """
        raise NotImplementedError

    def __init__(self, *args, **kwargs):
        pass

    def rasterize(self, *args, **kwargs):
        """Map a work coordinate ``(x, y, z)`` to its tile coordinate according to the configured traversal order.

        The decoding rasterizer (AffineRasterizationStrategy) decodes a
        cluster-linear index from ``z``; the identity rasterizer
        (NoRasterizationStrategy) wraps the coordinate unchanged.
        """
        raise NotImplementedError

    @staticmethod
    def visits_oob_clusters(
        template_params, problem_shape_mnkl, swizzle_size, raster_along
    ) -> bool:
        """Checks if swizzled traversal visits out-of-bounds clusters.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        return False

    def get_gmem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: global-memory workspace size in BYTES."""
        raise NotImplementedError

    def get_smem_workspace_size(self, *args, **kwargs) -> int:
        """Host-side compile-time query: shared-memory workspace size in BYTES."""
        raise NotImplementedError

    @staticmethod
    def can_implement(
        template_params, problem_shape_mnkl, swizzle_size, raster_along
    ) -> bool:
        """Performs feasibility checks on runtime arguments.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        return swizzle_size >= 1

    def initialize_workspace(self, *args, **kwargs) -> None:
        """Initializes workspace with appropriate values specific to this strategy."""
