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

"""Composable persistent tile scheduler.

A scheduler is assembled from three pluggable strategies -- a work strategy, a
reduction strategy, and a rasterization strategy -- that cooperate to map
persistent CTAs onto output tiles.

``TileSchedulerTemplate`` is the host-side, untraced configuration object: it
holds the static config and the strategy classes, reports workspace sizes and
the launch grid, and builds a device-side ``TileScheduler`` via ``create``.

``TileScheduler`` is the device-side, traced object that drives the per-CTA work
loop. Each request flows through the strategies as: work strategy yields a
work coordinate (x, y, z) tuple plus a validity flag, the rasterization strategy
maps that coordinate to a swizzled tile coordinate, and the reduction strategy
wraps the result into a ``WorkTileInfo``.
"""

from dataclasses import dataclass

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass import testing
from cutlass._mlir import ir
from cutlass.cute.nvgpu import cpasync
from cutlass.cutlass_dsl import (
    Boolean,
    Int32,
    Int64,
    dsl_user_op,
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.kernels.utils.tile_scheduler.base import (
    RASTERIZATION_ORDERS,
    BaseRasterizationStrategy,
    BaseReductionStrategy,
    BaseWorkStrategy,
)
from cutlass.kernels.utils.tile_scheduler.common import (
    derive_affine_divisors,
    get_swizzled_problem_layout_ncluster,
)
from cutlass.kernels.utils.tile_scheduler.params import (
    TileSchedulerPrecomputedParams,
    TileSchedulerRuntimeParams,
    TileSchedulerTemplateParams,
)


class WorkTileInfo:
    """One unit of work returned by the scheduler.

    It is carried across the persistent loop, so it implements the extract/new
    protocol below. Copied over with minor changes from the static persistent
    scheduler.

    Fields:

    - ``tile_idx``: the ``(M, N, L)`` tile coordinate (tile-unit, not
      cluster-unit) this work item targets.
    - ``is_valid_tile``: false once all tiles are exhausted; the kernel loop
      should stop consuming work once an invalid tile is seen.
    - ``acc_l_idx`` / ``k_start`` / ``k_end``: split-K index fields (the
      accumulator L slot and the K-range), defaulted to ``Int32(0)`` here; only
      carried/serialized by this class, not otherwise interpreted by the code
      in this module.
    """

    def __init__(
        self,
        tile_idx: cute.Coord,
        is_valid_tile: Boolean,
        # Split-K index fields; see class docstring.
        acc_l_idx: Int32 | None = None,
        k_start: Int32 | None = None,
        k_end: Int32 | None = None,
    ):
        self._tile_idx = tile_idx
        self._is_valid_tile = is_valid_tile
        # Create Int32(0) at call time (in traced context) so the default is a
        # proper traced value rather than a Python-int wrapper baked at
        # class-definition time.
        self._acc_l_idx = Int32(0) if acc_l_idx is None else acc_l_idx
        self._k_start = Int32(0) if k_start is None else k_start
        self._k_end = Int32(0) if k_end is None else k_end

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Flatten this work item's fields so it can be carried across the persistent loop.

        Ordering is the contract paired with ``__new_from_mlir_values__``: the
        variable-length ``tile_idx`` values come first, followed by exactly four
        trailing scalars (``is_valid_tile``, ``acc_l_idx``, ``k_start``,
        ``k_end``). Uses raw fields (``_*``), not the property accessors,
        to guarantee the same value structure both directions.
        """
        values = extract_mlir_values(self._tile_idx)
        values.extend(extract_mlir_values(self._is_valid_tile))
        values.extend(extract_mlir_values(self._acc_l_idx))
        values.extend(extract_mlir_values(self._k_start))
        values.extend(extract_mlir_values(self._k_end))
        return values

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "WorkTileInfo":
        """Rebuild a ``WorkTileInfo`` from values laid out by ``__extract_mlir_values__``.

        Relies on the same ordering: the final four entries are the scalar
        fields and everything before them reconstructs ``tile_idx``.
        """
        new_tile_idx = new_from_mlir_values(self._tile_idx, values[:-4])
        new_is_valid_tile = new_from_mlir_values(self._is_valid_tile, [values[-4]])
        new_acc_l_idx = new_from_mlir_values(self._acc_l_idx, [values[-3]])
        new_k_start = new_from_mlir_values(self._k_start, [values[-2]])
        new_k_end = new_from_mlir_values(self._k_end, [values[-1]])

        return WorkTileInfo(
            new_tile_idx,
            new_is_valid_tile,
            acc_l_idx=new_acc_l_idx,
            k_start=new_k_start,
            k_end=new_k_end,
        )

    @property
    def is_valid_tile(self) -> Boolean:
        """Check latest tile returned by the scheduler is valid or not.

        Any scheduling requests after all tasks completed will return an invalid
        tile.

        :return: The validity of the tile.
        :rtype: Boolean
        """
        return self._is_valid_tile

    @property
    def tile_idx(self) -> cute.Coord:
        """Get the index of the tile.

        :return: The index of the tile.
        :rtype: cute.Coord
        """
        return self._tile_idx

    @property
    def acc_l_idx(self) -> Int32:
        """Get the accumulator L slot index corresponding to this tile.

        For GMEM split-K this is the split-expanded L index selecting which L
        slot of the ``(M, N, L * split_k)`` accumulator view this split's
        partial is stored to.

        :return: The accumulator L slot index of the tile.
        :rtype: Int32
        """
        return self._acc_l_idx

    @property
    def k_start(self) -> Int32:
        """Get stream-K start index corresponding to this tile.

        :return: The stream-K start index of the tile.
        :rtype: Int32
        """
        return self._k_start

    @property
    def k_end(self) -> Int32:
        """Get stream-K end index corresponding to this tile.

        :return: The stream-K end index of the tile.
        :rtype: Int32
        """
        return self._k_end


def query_max_active_clusters(cluster_shape_mn, split_k, reduction_strategy):
    """Query the occupancy cap for the physical cluster this schedule launches.

    Host-side, needs a live CUDA context. Cluster split-K co-locates the
    splits along cluster-Z, so the query must see the Z-extended
    ``(M, N, split_k)`` cluster; every other schedule launches ``(M, N, 1)``.
    For kernels with preferred and fallback clusters, pass the fallback shape: it is the smallest
    cluster the launch can degrade to, so its occupancy bounds the grid.

    :param cluster_shape_mn: cluster extent in (M, N)
    :type cluster_shape_mn: tuple[int, int]
    :param split_k: number of K splits
    :type split_k: int
    :param reduction_strategy: split-K reduction strategy
    :type reduction_strategy: str
    :return: maximum number of concurrently resident clusters
    :rtype: int

    :raises testing.CantImplementError: If no cluster of the queried size can
        be resident on this device (the persistent schedulers would otherwise
        size a zero-CTA grid).
    """
    cluster_size_for_query = cluster_shape_mn[0] * cluster_shape_mn[1]
    if reduction_strategy == "cluster-splitk":
        cluster_size_for_query *= split_k
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_size_for_query
    )
    if max_active_clusters == 0:
        raise testing.CantImplementError(
            f"no cluster of size {cluster_size_for_query} "
            f"(cluster_shape_mn={tuple(cluster_shape_mn)}"
            f"{f' x split_k={split_k}' if reduction_strategy == 'cluster-splitk' else ''}) "
            "can be resident on this device: the occupancy query returned 0 "
            "active clusters, so the persistent scheduler cannot size its grid"
        )
    return max_active_clusters


def _identity(x):
    """Return ``x`` unchanged (identity epilogue for GMEM split-K kernel 1)."""
    return x


@dataclass(frozen=True)
class TileSchedulerTemplate:
    """Host-side, untraced scheduler configuration.

    Holds the static config and the three strategy classes (work, reduction,
    rasterization) that define the scheduling policy. Reports the SMEM/GMEM
    workspace sizes and the launch grid the host needs before launch, and builds
    a device-side :class:`TileScheduler` via :meth:`create`.
    """

    template_params: TileSchedulerTemplateParams
    work_strategy: type[BaseWorkStrategy]
    reduction_strategy: type[BaseReductionStrategy]
    rasterization_strategy: type[BaseRasterizationStrategy]

    @dsl_user_op
    def prepare_sched_params(
        self,
        problem_shape_mnl,
        k_tile_cnt,
        swizzle_size,
        raster_along_m,
        *,
        loc=None,
        ip=None,
    ) -> TileSchedulerPrecomputedParams:
        """Prepare grid-invariant state for static/affine/no-reduction scheduling.

        Prepare and consume with the same template, problem dimensions, K-tile
        count, swizzle, and raster direction. Both physical cluster branches use
        the preferred logical layout, built in the current tracing context.

        :param problem_shape_mnl: Problem dimensions (M, N, batch) in elements.
        :param k_tile_cnt: Full K extent in MMA tiles, rounded up by the caller.
        :param swizzle_size: Clusters per swizzle group; one disables swizzling.
        :param raster_along_m: Whether to rasterize along M rather than N.
        :param loc: Optional MLIR source location.
        :param ip: Optional MLIR insertion point.
        :return: Prepared state for grid calculation and
            device scheduler construction.
        :rtype: TileSchedulerPrecomputedParams
        :raises testing.CantImplementError: If the schedule is not
            static/affine/no-reduction.
        """
        params = self.template_params
        params.check_precompute_support()
        layout = get_swizzled_problem_layout_ncluster(
            params, problem_shape_mnl, swizzle_size, raster_along_m
        )
        major_fdd, minor_fdd = derive_affine_divisors(layout, loc=loc, ip=ip)
        return TileSchedulerPrecomputedParams(
            layout, Int32(k_tile_cnt, loc=loc, ip=ip), major_fdd, minor_fdd
        )

    @dsl_user_op
    def create(self, runtime_params: TileSchedulerRuntimeParams, *, loc=None, ip=None):
        """Build the device-side :class:`TileScheduler` for ``runtime_params``.

        Traced (creates SSAs); the host-supplied static config is bound here.
        """
        return TileScheduler.create(
            self.template_params,
            runtime_params,
            self.work_strategy,
            self.reduction_strategy,
            self.rasterization_strategy,
        )

    @property
    def is_cluster_splitk(self):
        """Return True when cluster (in-kernel DSMEM) split-K is active; forwards the template params flag."""
        return self.template_params.is_cluster_splitk

    @property
    def is_gmem_splitk(self):
        """Return True when GMEM (two-kernel) split-K is active; forwards the template params flag."""
        return self.template_params.is_gmem_splitk

    @property
    def requires_scheduler_warp(self):
        """Return True when the scheduler requires a warp."""
        return self.template_params.work_strategy in [
            "clc",
        ]

    def get_smem_workspace_size(self):
        """Total SMEM workspace, in bytes, summed across the three strategies.

        Host-side, untraced.
        """
        total_smem = self.work_strategy.get_smem_workspace_size(self.template_params)
        total_smem += self.reduction_strategy.get_smem_workspace_size(
            self.template_params
        )
        total_smem += self.rasterization_strategy.get_smem_workspace_size(
            self.template_params
        )

        return total_smem

    def get_gmem_workspace_size(self, mnl):
        """Total GMEM workspace, in bytes, for problem shape ``mnl``.

        Host-side, untraced; summed across the three strategies.
        """
        total_gmem = self.work_strategy.get_gmem_workspace_size(
            self.template_params, mnl
        )
        total_gmem += self.reduction_strategy.get_gmem_workspace_size(
            self.template_params, mnl
        )
        total_gmem += self.rasterization_strategy.get_gmem_workspace_size(
            self.template_params, mnl
        )

        return total_gmem

    def get_gmem_reduction_workspace_offset(self, mnl):
        """Byte offset of the reduction strategy's slice in the GMEM workspace.

        The combined workspace is laid out work -> reduction -> rasterization
        (see :meth:`TileScheduler.allocate_workspace`), so the reduction slice
        starts right after the work strategy's bytes. Host-side, untraced.
        """
        return self.work_strategy.get_gmem_workspace_size(self.template_params, mnl)

    def extract_gmem_splitk_acc_tensor(self, workspace, mC):
        """View the split-K partial-accumulator region of the GMEM workspace as C.

        For two-kernel split-K, kernel 1 writes each split's *full* partial
        accumulator to a dedicated GMEM region (carved out of the scheduler's
        combined workspace) instead of reducing in kernel; kernel 2 later sums the
        ``split_k`` partials into the user's C. This builds the C-like tensor over
        that region with the batch (L) extent expanded by ``split_k`` -- shape
        ``(M, N, L * split_k)`` -- so the epilogue can store each split's partial to
        its own L slot, and the host can build the TMA store descriptor for it as
        usual.

        The (M, N) majorness mirrors the user's C so the kernel's epilogue indexing
        is unchanged. The region is a freshly allocated, densely packed buffer, so
        the batch stride is the packed plane size ``M * N``.

        :param workspace: int8 base pointer of the scheduler's combined GMEM workspace
        :param mC: the user's output tensor C, shape (M, N, L)
        :return: an ``acc_dtype`` ``cute.Tensor`` of shape (M, N, L * split_k)
            over the workspace
        """
        template_params = self.template_params
        split_k = template_params.split_k
        acc_dtype = template_params.acc_dtype

        m, n, prob_l = mC.shape

        # The reduction strategy's slice follows the work strategy's in the combined
        # workspace (work -> reduction -> rasterization). The offset is in bytes;
        # advance the int8 base pointer, then reinterpret as acc_dtype -- kernel 1
        # writes the partials in full accumulation precision.
        offset = self.get_gmem_reduction_workspace_offset(mC.shape)
        gmem_acc_ptr = cute.make_ptr(
            acc_dtype,
            (workspace + offset).toint(),
            cute.AddressSpace.gmem,
            # 16 is what the workspace actually guarantees: every strategy slice
            # is rounded to a 16B multiple over a fresh 16B-aligned allocation.
            # (Do not inherit mC's alignment -- the user's C is an unrelated
            # allocation and may claim more than the workspace provides.)
            assumed_align=16,
        )
        gmem_acc_shape = (m, n, prob_l * split_k)

        # Preserve C's majorness via canonical dense strides for the packed buffer:
        # m-major (column-major) C has M contiguous; otherwise N is contiguous.
        if isinstance(m, int) and isinstance(n, int):
            m_wide, n_wide = m, n
        else:
            m_wide, n_wide = Int64(m), Int64(n)
        gmem_acc_stride = (
            (1, m_wide, m_wide * n_wide)
            if utils.LayoutEnum.from_tensor(mC).is_m_major_c()
            else (n_wide, 1, m_wide * n_wide)
        )

        gmem_acc_layout = cute.make_layout(gmem_acc_shape, stride=gmem_acc_stride)

        return cute.make_tensor(gmem_acc_ptr, gmem_acc_layout)

    def get_gmem_tma(self, use_tma_store, gmem_workspace, c, c_smem_layout, epi_tile):
        """Return ``(tma_store_atom, output_tensor)`` for the C epilogue.

        For GMEM split-K the output tensor is the partial-accumulator view over
        the workspace -- shape ``(M, N, L * split_k)`` -- so each split stores to
        its own L slot; otherwise it is the user's ``c``. When ``use_tma_store``
        is False there is no TMA atom (the atom is ``None``).
        """
        if cutlass.const_expr(self.template_params.is_gmem_splitk):
            out_tensor = self.extract_gmem_splitk_acc_tensor(gmem_workspace, c)
        else:
            out_tensor = c

        if cutlass.const_expr(use_tma_store):
            epi_smem_layout = cute.select(c_smem_layout, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), out_tensor, epi_smem_layout, epi_tile
            )
            return tma_atom_c, tma_tensor_c
        return None, out_tensor

    def swap_epilogue_for_identity_if_gmem_splitk(self, epilogue_op):
        """Return the epilogue op kernel 1 applies at its store.

        GMEM split-K stores raw partials in kernel 1 and applies
        ``epilogue_op`` once in the reduction kernel after the split sum, so
        kernel 1 gets the identity; every other mode applies ``epilogue_op``
        directly.
        """
        if self.template_params.is_gmem_splitk:
            return _identity
        return epilogue_op

    def get_effective_l_idx(self, work_tile):
        """Return the L index kernel 1's epilogue stores this work tile to.

        For GMEM split-K each split writes its partials to its own
        (split-expanded) L slot of the accumulator view, so this is
        ``work_tile.acc_l_idx``; every other mode stores to the tile's real
        batch index ``work_tile.tile_idx[2]``.
        """
        if self.template_params.is_gmem_splitk:
            return work_tile.acc_l_idx
        return work_tile.tile_idx[2]

    def get_reduction_grid_block(self, problem_shape_mnl):
        """Grid / block for the GMEM split-K reduction kernel (kernel 2).

        Thin stub: delegates to
        :func:`reduction_strategies.splitk_reduction_impl.get_reduction_grid_block`;
        a no-op unless the schedule splits the K dimension.
        """
        if cutlass.const_expr(self.template_params.is_splitk):
            # Imported here (not at module level): the reduction_strategies
            # package imports WorkTileInfo back from this module.
            from cutlass.kernels.utils.tile_scheduler.reduction_strategies import (
                splitk_reduction_impl,
            )

            return splitk_reduction_impl.get_reduction_grid_block(problem_shape_mnl)

    def reduction_kernel(
        self,
        workspace_tensor,
        c,
        num_actual_splits,
        epilogue_op,
        use_pdl=False,
        use_reduction_pdl=False,
    ):
        """Kernel 2 of GMEM split-K: sum the partial accumulators into C.

        Thin stub: delegates to
        :func:`reduction_strategies.splitk_reduction_impl.reduction_kernel` (which
        holds the implementation and its documentation), supplying this
        schedule's ``split_k``; a no-op unless the schedule splits the K
        dimension. ``num_actual_splits`` is the number of splits that own at
        least one K-tile (``min(split_k, k_tile_cnt)``); slots past it were
        never initialized by kernel 1 and are skipped. Returns the
        not-yet-launched kernel object.
        """
        if cutlass.const_expr(self.template_params.is_splitk):
            # Imported here (not at module level): the reduction_strategies
            # package imports WorkTileInfo back from this module.
            from cutlass.kernels.utils.tile_scheduler.reduction_strategies import (
                splitk_reduction_impl,
            )

            return splitk_reduction_impl.reduction_kernel(
                workspace_tensor,
                c,
                self.template_params.split_k,
                num_actual_splits,
                epilogue_op,
                use_pdl,
                use_reduction_pdl,
            )

    def splitk_reduction(
        self,
        workspace,
        c,
        k,
        epilogue_op,
        stream,
        use_pdl: bool = False,
        use_reduction_pdl: bool = False,
    ):
        """Run kernel 2 of GMEM split-K: reduce the partials into the user's C.

        One-stop launcher: builds the accumulator view over the workspace,
        derives the launch shape, and launches the reduction kernel on
        ``stream``. Call after the GEMM kernel when ``is_gmem_splitk``.
        ``k`` is the problem's K extent in elements; it bounds the actual-split
        count (``min(split_k, ceil(k / cta_k))``) so the reduction skips the
        uninitialized slots of empty splits when ``split_k`` exceeds the
        K-tile count.
        ``use_reduction_pdl`` enables intra-operator PDL: kernel 2 is
        launched with the PDL attribute and waits before its first workspace
        read. ``use_pdl`` enables inter-operator PDL: kernel 2 signals
        dependent grids at its end.
        """
        acc_tensor = self.extract_gmem_splitk_acc_tensor(workspace, c)
        red_grid, red_block = self.get_reduction_grid_block(c.shape)
        k_tile_cnt = cute.ceil_div(k, self.template_params.cta_tile_shape_mnk[2])
        num_actual_splits = cute.min(
            Int32(self.template_params.split_k), Int32(k_tile_cnt)
        )
        self.reduction_kernel(
            acc_tensor, c, num_actual_splits, epilogue_op, use_pdl, use_reduction_pdl
        ).launch(
            grid=red_grid,
            block=red_block,
            cluster=(1, 1, 1),
            stream=stream,
            use_pdl=use_reduction_pdl,
        )

    def initialize_workspace(self, host_workspace, problem_shape_mnl):
        """Host-side populate of the GMEM workspace, before it is uploaded.

        Called on the host from ``run()`` (not device-traced). Carves each
        strategy's slice out of ``host_workspace`` in the SAME work ->
        reduction -> rasterization order as
        :meth:`TileScheduler.allocate_workspace`, then hands each strategy
        exactly its own sub-buffer so strategies fill from index 0. Most
        strategies report a 0-byte slice and no-op; a strategy that needs a
        host-precomputed table is the one that actually writes.
        """
        offset = 0

        work_bytes = self.work_strategy.get_gmem_workspace_size(
            self.template_params, problem_shape_mnl
        )
        self.work_strategy.initialize_workspace(
            self.template_params,
            problem_shape_mnl,
            host_workspace[offset : offset + work_bytes],
        )
        offset += work_bytes

        reduction_bytes = self.reduction_strategy.get_gmem_workspace_size(
            self.template_params, problem_shape_mnl
        )
        self.reduction_strategy.initialize_workspace(
            self.template_params,
            problem_shape_mnl,
            host_workspace[offset : offset + reduction_bytes],
        )
        offset += reduction_bytes

        rasterization_bytes = self.rasterization_strategy.get_gmem_workspace_size(
            self.template_params, problem_shape_mnl
        )
        self.rasterization_strategy.initialize_workspace(
            self.template_params,
            problem_shape_mnl,
            host_workspace[offset : offset + rasterization_bytes],
        )

    def get_grid_shape(
        self,
        problem_shape_mnl,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        *,
        precomputed_sched_params: TileSchedulerPrecomputedParams | None = None,
    ) -> cute.Shape:
        """Derive the launch grid, reusing the prepared layout when supplied.

        :param problem_shape_mnl: Problem dimensions (M, N, batch) in elements.
        :param swizzle_size: Clusters per swizzle group; one disables swizzling.
        :param raster_along_m: Whether to rasterize along M rather than N.
        :param max_active_clusters_fallback: Occupancy cap on concurrently
            resident fallback clusters (see :func:`query_max_active_clusters`).
            A launch-time ``Int32`` like ``swizzle_size``; only the ``static``
            work strategy consumes it (its grid is one wave), the others ignore
            it.
        :param precomputed_sched_params: Prepared scheduler parameters, if supplied;
            static/affine/no-reduction only.
        :return: Three-dimensional launch grid in CTAs.
        :rtype: cute.Shape
        :raises testing.CantImplementError: If prepared values are supplied for
            an unsupported schedule.
        """
        if precomputed_sched_params is None:
            return self.work_strategy.get_grid_shape(
                self.template_params,
                problem_shape_mnl,
                swizzle_size,
                raster_along_m,
                max_active_clusters_fallback,
            )

        self.template_params.check_precompute_support()

        layout = precomputed_sched_params.swizzled_problem_layout_ncluster_mnl
        return self.work_strategy.get_grid_shape(
            self.template_params,
            problem_shape_mnl,
            swizzle_size,
            raster_along_m,
            max_active_clusters_fallback,
            swizzled_problem_layout_ncluster_mnl=layout,
        )

    def can_implement(self, problem_shape_mnkl, swizzle_size, raster_along) -> bool:
        """Host-side pre-flight: can this scheduler handle this problem and settings?

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: one of :data:`RASTERIZATION_ORDERS`
        """
        if raster_along not in RASTERIZATION_ORDERS:
            return False
        return all(
            strategy_cls.can_implement(
                self.template_params, problem_shape_mnkl, swizzle_size, raster_along
            )
            for strategy_cls in (
                self.work_strategy,
                self.reduction_strategy,
                self.rasterization_strategy,
            )
        )

    def visits_oob_tiles(self, problem_shape_mnkl, swizzle_size, raster_along) -> bool:
        """Launch-time check: does the traversal visit tiles outside the problem?

        True when the tile grid is rounded up to whole clusters along M or N
        (the padding CTAs still run, since they share cluster barriers), or
        when the swizzle leaves partially filled groups. A store without
        out-of-bounds predication writes those tiles past the problem edge.
        Cluster split-K is exempt from the cluster-padding half: its store
        already skips tiles wholly outside the problem.

        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param raster_along: ``"m"`` or ``"n"``
        """
        params = self.template_params
        if not params.is_cluster_splitk:
            cta_m, cta_n, _ = params.cta_tile_shape_mnk
            cluster_m, cluster_n, _ = params.cluster_shape
            m, n = problem_shape_mnkl[0], problem_shape_mnkl[1]
            if (
                cute.ceil_div(m, cta_m) % cluster_m != 0
                or cute.ceil_div(n, cta_n) % cluster_n != 0
            ):
                return True
        return self.rasterization_strategy.visits_oob_clusters(
            params, problem_shape_mnkl, swizzle_size, raster_along
        )

    def check_cluster_splitk_constraints(self, use_tma_store: bool) -> None:
        """Reject cluster split-K requests this schedule cannot realize.

        Kernel-side pre-flight shared by the GEMM kernels' compile checks;
        raising here surfaces an unsupported request as a
        ``CantImplementError`` before compilation rather than as a tracing
        failure. Kernel-specific constraints stay with each kernel.

        :param use_tma_store: whether the kernel stores C through TMA (the
            cluster split-K fixup requires a predicated non-TMA store)
        :type use_tma_store: bool
        :raises testing.CantImplementError: If cluster split-K is requested
            with a non-Float32 accumulator, with a TMA store, with a split
            that does not divide the 128-thread epilogue's per-thread
            elements, or with a physical cluster larger than 16 CTAs.
        """
        params = self.template_params
        if not params.is_cluster_splitk:
            return
        if params.acc_dtype != cutlass.Float32:
            raise testing.CantImplementError(
                "cluster split-K (reduction_strategy='cluster-splitk') requires "
                f"acc_dtype=Float32, got {params.acc_dtype}"
            )
        if use_tma_store:
            raise testing.CantImplementError(
                "cluster split-K (reduction_strategy='cluster-splitk') requires "
                "use_tma_store=False"
            )
        cta_m, cta_n, _ = params.cta_tile_shape_mnk
        elems_per_thread = (cta_m * cta_n) // 128
        if elems_per_thread % params.split_k != 0:
            raise testing.CantImplementError(
                f"elems_per_thread={elems_per_thread} must be divisible by "
                f"split_k={params.split_k}"
            )
        cluster_m, cluster_n, cluster_z = params.cluster_shape
        if cluster_m * cluster_n * cluster_z > 16:
            raise testing.CantImplementError(
                f"Invalid cluster shape: {params.cluster_shape_mn} with "
                f"split_k={params.split_k}"
            )

    def resolve_rasterization(
        self,
        raster_along,
        swizzle_size,
        problem_shape_mnkl,
        a_element_bytes=1,
        b_element_bytes=1,
    ):
        """Resolve requested rasterization settings to concrete launch values.

        :param raster_along: one of :data:`RASTERIZATION_ORDER_OPTIONS`
        :param swizzle_size: tiles per swizzle group (1 disables swizzling)
        :param problem_shape_mnkl: problem extents ``(M, N, K, L)`` in elements
        :param a_element_bytes: size of one element of A, in bytes
        :param b_element_bytes: size of one element of B, in bytes
        :return: ``(raster_along, swizzle_size)`` with the order concrete
        :rtype: tuple
        """
        if raster_along != "heuristic":
            return raster_along, swizzle_size
        if self.template_params.rasterization_strategy == "none":
            return "m", swizzle_size
        cta_m, cta_n, _ = self.template_params.cta_tile_shape_mnk
        tiles_m = cute.ceil_div(problem_shape_mnkl[0], cta_m)
        tiles_n = cute.ceil_div(problem_shape_mnkl[1], cta_n)
        raster_along = (
            "m" if tiles_m * a_element_bytes < tiles_n * b_element_bytes else "n"
        )
        return raster_along, swizzle_size

    @property
    def smem_alignment(self):
        """Byte alignment required for the scheduler's SMEM workspace.

        CLC response slots are 16 bytes and must be 16B-aligned; this is the max
        alignment any strategy's SMEM workspace needs today. Aggregate
        per-strategy if that changes.
        """
        return 16


class TileScheduler:
    """Device-side, traced scheduler driving the per-CTA work loop.

    Composes the three already-created strategies. The work loop calls
    :meth:`initial_work_tile_info` once, then alternates
    :meth:`advance_to_next_work` (producer side) and :meth:`fetch_next_work`
    (consumer side). Construct via :meth:`create`, not directly. Implements the
    extract/new protocol so the scheduler can be carried across the persistent loop.
    """

    @dsl_user_op
    def __init__(
        self,
        template_params: TileSchedulerTemplateParams,
        work_strategy: BaseWorkStrategy,
        reduction_strategy: BaseReductionStrategy,
        rasterization_strategy: BaseRasterizationStrategy,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ):
        self.template_params = template_params
        self.work_strategy = work_strategy
        self.reduction_strategy = reduction_strategy
        self.rasterization_strategy = rasterization_strategy
        self._loc = loc

    @staticmethod
    @dsl_user_op
    def allocate_workspace(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        work_strategy: type[BaseWorkStrategy],
        reduction_strategy: type[BaseReductionStrategy],
        rasterization_strategy: type[BaseRasterizationStrategy],
        *,
        loc=None,
        ip=None,
    ):
        """Carve the SMEM and GMEM workspace blocks among the three strategies.

        Lays out each strategy's slice back-to-back inside the runtime
        workspace base pointers and records the per-strategy start pointers on
        ``runtime_params``. Per-strategy sizes are in bytes. Returns the same
        ``runtime_params`` with the workspace pointer fields populated.
        """
        # SMEM
        runtime_params.work_smem_workspace_ptr = runtime_params.smem_workspace_ptr
        total_smem = work_strategy.get_smem_workspace_size(template_params)

        runtime_params.reduction_smem_workspace_ptr = (
            runtime_params.smem_workspace_ptr + total_smem
        )
        total_smem += reduction_strategy.get_smem_workspace_size(template_params)

        runtime_params.rasterization_smem_workspace_ptr = (
            runtime_params.smem_workspace_ptr + total_smem
        )

        # GMEM
        runtime_params.work_gmem_workspace_ptr = runtime_params.gmem_workspace_ptr
        total_gmem = work_strategy.get_gmem_workspace_size(
            template_params, runtime_params.problem_shape_mnl
        )

        runtime_params.reduction_gmem_workspace_ptr = (
            runtime_params.gmem_workspace_ptr + total_gmem
        )
        total_gmem += reduction_strategy.get_gmem_workspace_size(
            template_params, runtime_params.problem_shape_mnl
        )

        runtime_params.rasterization_gmem_workspace_ptr = (
            runtime_params.gmem_workspace_ptr + total_gmem
        )

        return runtime_params

    @staticmethod
    @dsl_user_op
    def create(
        template_params: TileSchedulerTemplateParams,
        runtime_params: TileSchedulerRuntimeParams,
        work_strategy: type[BaseWorkStrategy],
        reduction_strategy: type[BaseReductionStrategy],
        rasterization_strategy: type[BaseRasterizationStrategy],
        *,
        loc=None,
        ip=None,
    ):
        """Allocate workspace, derive problem-shape views, and build the scheduler.

        Each strategy owns its own runtime state; all three are handed the full
        static config plus the transient runtime seed. (template_params was
        previously dropped here, which broke every strategy's create().)
        Populates the swizzled cluster-linear problem layout on
        ``runtime_params`` before creating the strategies, deriving it only
        when no prepared scheduler parameters were supplied.
        """
        prepared = runtime_params.precomputed_sched_params
        if prepared is not None:
            template_params.check_precompute_support()

        runtime_params = TileScheduler.allocate_workspace(
            template_params,
            runtime_params,
            work_strategy,
            reduction_strategy,
            rasterization_strategy,
        )

        if prepared is None:
            layout = get_swizzled_problem_layout_ncluster(
                template_params,
                runtime_params.problem_shape_mnl,
                runtime_params.swizzle_size,
                runtime_params.raster_along_m,
            )
        else:
            layout = prepared.swizzled_problem_layout_ncluster_mnl

        runtime_params.swizzled_problem_layout_ncluster_mnl = layout

        return TileScheduler(
            template_params,
            work_strategy.create(template_params, runtime_params),
            reduction_strategy.create(template_params, runtime_params),
            rasterization_strategy.create(template_params, runtime_params),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def initial_work_tile_info(self, *, loc=None, ip=None) -> WorkTileInfo:
        """Return the first :class:`WorkTileInfo` for this CTA.

        Runs the full work -> rasterize -> split pipeline on the work strategy's
        initial work coordinate (x, y, z) tuple. The result's ``is_valid_tile``
        is already false if this CTA has no work.
        """
        work_coord, is_valid = self.work_strategy.initial_work()
        rasterized_info = self.rasterization_strategy.rasterize(work_coord, is_valid)
        split_info = self.reduction_strategy.split_work_tile(rasterized_info)
        return split_info

    @dsl_user_op
    def fetch_next_work(
        self,
        work_tile_info: WorkTileInfo,
        pipeline,
        consumer_state,
        *,
        loc=None,
        ip=None,
    ):
        """Consumer-side fetch of the next work item.

        Pulls the next work coordinate (x, y, z) tuple from the work strategy,
        then rasterizes and splits it. Returns ``(WorkTileInfo, consumer_state)``:
        the work strategy advances and returns the consumer state (unchanged for
        strategies without a pipeline); the caller threads it as the loop-carried
        state.
        """
        work_coord, is_valid, consumer_state = self.work_strategy.fetch_next_work(
            work_tile_info, pipeline, consumer_state
        )

        rasterized_work_tile_info = self.rasterization_strategy.rasterize(
            work_coord, is_valid
        )

        split_work_tile_info = self.reduction_strategy.split_work_tile(
            rasterized_work_tile_info
        )

        return split_work_tile_info, consumer_state

    @dsl_user_op
    def advance_to_next_work(
        self,
        work_tile_info: WorkTileInfo,
        pipeline,
        producer_state,
        *,
        loc=None,
        ip=None,
    ):
        """Producer-side advance to the next work item.

        Returns the advanced ``producer_state`` (unchanged for strategies without a
        pipeline) for the caller to thread as the loop-carried state.
        """
        producer_state = self.work_strategy.advance_to_next_work(
            work_tile_info, pipeline, producer_state
        )

        return producer_state

    @dsl_user_op
    def get_num_tiles_executed(self, *, loc=None, ip=None) -> Int32:
        """Number of valid tiles this CTA has executed; delegates to the work strategy."""
        return self.work_strategy.get_num_tiles_executed()

    @dsl_user_op
    def get_clc_response_ptr(self, *, loc=None, ip=None):
        """CLC response-storage SMEM pointer; delegates to the work strategy.

        Dynamic-persistent (``work_strategy == "clc"``) only; raises otherwise.
        """
        if cutlass.const_expr(self.template_params.work_strategy == "clc"):
            return self.work_strategy.get_clc_response_storage_ptr()
        else:
            raise ValueError(
                "Initialized TileScheduler is not a dynamic persistent tile scheduler"
            )

    @dsl_user_op
    def get_clc_mbar_ptr(self, *, loc=None, ip=None):
        """CLC mbarrier-storage SMEM pointer; delegates to the work strategy.

        Dynamic-persistent (``work_strategy == "clc"``) only; raises otherwise.
        """
        if cutlass.const_expr(self.template_params.work_strategy == "clc"):
            return self.work_strategy.get_clc_barrier_storage_ptr()
        else:
            raise ValueError(
                "Initialized TileScheduler is not a dynamic persistent tile scheduler"
            )

    def pre_fixup(self, *args, **kwargs):
        """Pre-loop split-K epilogue setup; delegates to the reduction strategy.

        A no-op unless the schedule splits the K dimension.
        """
        if cutlass.const_expr(self.template_params.split_k > 1):
            return self.reduction_strategy.pre_fixup(*args, **kwargs)

    def fixup_and_epilogue(self, *args, **kwargs):
        """Per-tile split-K reduce + epilogue; delegates to the reduction strategy.

        A no-op unless the schedule splits the K dimension.
        """
        if cutlass.const_expr(self.template_params.split_k > 1):
            return self.reduction_strategy.fixup_and_epilogue(*args, **kwargs)

    def finalize(self, *args, **kwargs):
        """End-of-kernel hook run by every CTA after the persistent loop.

        Delegates to the reduction strategy; a no-op for every strategy except
        cluster split-K, which must keep its DSMEM mailbox alive until all
        peer CTAs in the physical cluster have finished their final
        scatter/read/ack sequence.
        """
        return self.reduction_strategy.finalize(*args, **kwargs)

    def get_gmem_workspace_size(self, *args, **kwargs):
        """Always raises: GMEM workspace sizing lives on :class:`TileSchedulerTemplate`.

        Sizes are host-side (untraced) info needed before launch, so they are
        reported by the template, not the device-side scheduler.
        """
        raise NotImplementedError(
            "`get_gmem_workspace_size` is implemented in TileSchedulerTemplate"
        )

    def get_smem_workspace_size(self, *args, **kwargs):
        """Always raises: SMEM workspace sizing lives on :class:`TileSchedulerTemplate`.

        Sizes are host-side (untraced) info needed before launch, so they are
        reported by the template, not the device-side scheduler.
        """
        raise NotImplementedError(
            "`get_smem_workspace_size` is implemented in TileSchedulerTemplate"
        )

    @property
    def num_clc_response_bytes(self):
        """Size in bytes of a single CLC response slot."""
        return 16

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Flatten the three strategies' state, in strategy order.

        Records the per-strategy value count in ``self._values_pos``;
        :meth:`__new_from_mlir_values__` relies on this list (set during extract)
        to re-slice the flat value list back into the same three strategies.
        """
        values, self._values_pos = [], []
        for obj in [
            self.work_strategy,
            self.reduction_strategy,
            self.rasterization_strategy,
        ]:
            obj_values = extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))

        return values

    def __new_from_mlir_values__(self, values: list[ir.Value]):
        """Rebuild the scheduler from values laid out by :meth:`__extract_mlir_values__`.

        Re-slices ``values`` using ``self._values_pos`` (the per-strategy counts
        recorded during extract), so this must be called on an object whose
        ``_values_pos`` matches the extract that produced ``values``.
        """
        obj_list = []
        values_copy = list(values)

        for obj, n_items in zip(
            [
                self.work_strategy,
                self.reduction_strategy,
                self.rasterization_strategy,
            ],
            self._values_pos,
        ):
            obj_list.append(new_from_mlir_values(obj, values_copy[:n_items]))
            values_copy = values_copy[n_items:]

        # template_params is compile-time config, so re-supply it; the strategies
        # come from obj_list.
        new_tile_scheduler = TileScheduler(
            self.template_params, *(tuple(obj_list)), loc=self._loc
        )

        return new_tile_scheduler
