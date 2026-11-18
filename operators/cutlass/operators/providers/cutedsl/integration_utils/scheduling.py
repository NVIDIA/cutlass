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

"""Operator-side scheduling shared by every kernel on the composable tile scheduler.

Utility functions frequently used for a CuTe DSL GEMM operator whose kernel is
built on the composable tile scheduler (``cutlass.kernels.utils.tile_scheduler``).

1. **Enumerate the strategy triples to generate operators for, and reject the
   ones no kernel can realize.** See :func:`enumerate_tile_schedulers` and
   :func:`reduction_fits`.

2. **Resolve performance settings.** Performance settings can either be wholly
  determined by the design metadata, partially determined by both design
  metadata and by performance arguments, or resolved by the operator itself.
  See :func:`resolve_launch_rasterization` and :func:`resolve_split_count`.
"""

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

from cutlass.kernels.utils.tile_scheduler.common import get_host_cluster_counts_mn
from cutlass.operators.arguments.performance import (
    GemmPerformanceControls,
    TileSchedulerControls,
)
from cutlass.operators.arguments.tile_scheduler_settings import RasterOrder
from cutlass.operators.metadata.design.tile_scheduler import (
    CLCDynamicPersistentMetadata,
    ClusterSplitKReductionMetadata,
    NonPersistentMetadata,
    NoRasterizationMetadata,
    NoReductionMetadata,
    SplitKReductionMetadata,
    StaticPersistentMetadata,
    TileSchedulerMetadata,
    TileSwizzleRasterizationMetadata,
)

if TYPE_CHECKING:
    from cutlass.operators.arguments.base import RuntimeArguments
    from cutlass.operators.device_properties import DeviceProperties
    from cutlass.operators.metadata.design.tile_scheduler import (
        RasterizationMetadata,
        ReductionMetadata,
    )

#: Raster orders as the kernels spell them.
_RASTER_ORDER_ARGS = {
    RasterOrder.ALONG_M: "m",
    RasterOrder.ALONG_N: "n",
    RasterOrder.HEURISTIC: "heuristic",
}


def reduction_fits(
    reduction: ReductionMetadata,
    *,
    cta_tile_mn: tuple[int, int],
    cluster_shape_mn: tuple[int, int],
    use_tma_store: bool,
) -> bool:
    """Return whether a kernel of this shape can realize this reduction strategy.

    Checks that the reduction strategy is compatible with the given shapes
    and the epilogue store type.

    :param reduction: The reduction strategy the design advertises.
    :type reduction: ReductionMetadata
    :param cta_tile_mn: The ``(M, N)`` tile one CTA computes, after the 2CTA
        MMA halving where that applies.
    :type cta_tile_mn: tuple[int, int]
    :param cluster_shape_mn: The cluster the kernel launches, without the
        cluster-Z extent the splits occupy.
    :type cluster_shape_mn: tuple[int, int]
    :param use_tma_store: Whether the epilogue stores C through TMA.
    :type use_tma_store: bool
    :return: True if a kernel can be built for this strategy.
    :rtype: bool
    """

    # other strategies do not have extra conditions
    if not isinstance(
        reduction, (SplitKReductionMetadata, ClusterSplitKReductionMetadata)
    ):
        return True

    is_cluster_splitk = isinstance(reduction, ClusterSplitKReductionMetadata)

    if not use_tma_store and not is_cluster_splitk:
        return False

    # Split-K and cluster split-K only support a single compile-time split
    # count; neither takes the split count at runtime.
    domain = reduction.split_count
    if isinstance(domain, tuple) and len(domain) == 1:
        split_count = domain[0]
        if split_count <= 1:
            return False
    else:
        return False

    # no other split-k conditions
    if not is_cluster_splitk:
        return True

    # Cluster split-K reduces through DSMEM and stores the per-split shards
    # from registers, which the TMA store cannot express.
    if use_tma_store:
        return False

    cta_tile_m, cta_tile_n = cta_tile_mn
    cluster_m, cluster_n = cluster_shape_mn
    # The cluster split-K fixup only shards a 64- or 128-row CTA tile.
    if cta_tile_m not in (64, 128):
        return False
    # The 128-thread epilogue splits each thread's accumulators evenly.
    if (cta_tile_m * cta_tile_n // 128) % split_count != 0:
        return False
    # The splits occupy cluster-Z, so they count against the cluster budget.
    if cluster_m * cluster_n * split_count > 16:
        return False
    return True


def enumerate_tile_schedulers(
    split_counts: tuple[int, ...] = (2,),
    swizzle_sizes: tuple[int, ...] = (1, 2, 4, 8),
) -> tuple[TileSchedulerMetadata, ...]:
    """Enumerate every strategy triple the tile scheduler can be built for.

    The swizzle size and raster order are launch arguments rather than
    specializations, so the rasterizing designs advertise the whole domain from
    a single operator instead of one operator per fixed
    (swizzle size, raster order) tuple.
    Two-kernel (GMEM) split-K advertises one design per count.

    :param split_counts: The split counts to generate split-K designs for.
    :type split_counts: tuple[int, ...]
    :param swizzle_sizes: The swizzle sizes the rasterizing designs accept.
    :type swizzle_sizes: tuple[int, ...]
    :return: One :class:`TileSchedulerMetadata` per supported triple.
    :rtype: tuple[TileSchedulerMetadata, ...]
    """
    persistences = (
        NonPersistentMetadata(),
        CLCDynamicPersistentMetadata(),
        StaticPersistentMetadata(),
    )
    reductions = (
        NoReductionMetadata(),
        *(SplitKReductionMetadata(split_count=(count,)) for count in split_counts),
    )
    rasterizations = (
        TileSwizzleRasterizationMetadata(
            swizzle_size=swizzle_sizes,
            raster_order=tuple(RasterOrder),
        ),
        NoRasterizationMetadata(),
    )

    return tuple(
        TileSchedulerMetadata(
            persistence=persistence,
            reduction=reduction,
            rasterization=rasterization,
        )
        for persistence, reduction, rasterization in itertools.product(
            persistences, reductions, rasterizations
        )
        if not (
            isinstance(persistence, StaticPersistentMetadata)
            and isinstance(rasterization, NoRasterizationMetadata)
        )
    )


def resolve_launch_rasterization(
    args: RuntimeArguments,
    rasterization: RasterizationMetadata | None,
    template,
    problem_shape_mnkl: tuple[int, int, int, int],
    a_element_bytes: int,
    b_element_bytes: int,
    predicated_store: bool = True,
) -> tuple[int, str]:
    """Settle this launch's swizzle size and raster order, and check them.

    Resolves the caller's request against the domain the design advertises,
    against defaults, or lets the scheduler's heuristic pick a raster order if
    asked to. Narrows a swizzle wider than the problem (see :func:`_fit_swizzle_size`),
    and then validates the settled pair against the problem shape.

    :param args: The arguments this launch was called with; its
        ``performance`` field carries the requested settings.
    :type args: RuntimeArguments
    :param rasterization: The rasterization strategy the design advertises.
    :type rasterization: RasterizationMetadata | None
    :param template: The kernel's ``TileSchedulerTemplate``.
    :param problem_shape_mnkl: Problem extents ``(M, N, K, L)`` in elements.
    :type problem_shape_mnkl: tuple[int, int, int, int]
    :param a_element_bytes: Size of one A element, for the raster heuristic.
    :type a_element_bytes: int
    :param b_element_bytes: Size of one B element, for the raster heuristic.
    :type b_element_bytes: int
    :param predicated_store: Whether the epilogue predicates out-of-bounds
        tiles. A store that does not (the non-TMA path) must not be given a
        traversal that leaves the problem.
    :type predicated_store: bool
    :return: The swizzle size, and the raster order as ``"m"`` or ``"n"``.
    :rtype: tuple[int, str]
    :raises ValueError: If the settled settings cannot be honored for this problem.
    """
    controls = _get_tile_scheduler_controls(args)

    # With no performance controls, the kernel's defaults are used:
    # no swizzle, M-major traversal or the compile-time set value of the design
    requested_swizzle_size = ... if controls is None else controls.swizzle_size
    requested_raster_order = ... if controls is None else controls.raster_order
    # default_raster_order can be None if controls is set to wildcard
    default_raster_order = RasterOrder.ALONG_M if controls is None else None

    swizzle_size = _resolve_setting(
        getattr(rasterization, "swizzle_size", None),
        requested_swizzle_size,
        1,
    )
    order = _resolve_setting(
        getattr(rasterization, "raster_order", None),
        requested_raster_order,
        default_raster_order,
    )
    raster_along = "heuristic" if order is None else _RASTER_ORDER_ARGS[order]

    # calls heuristic to resolve to fixed settings if using heuristic mode
    raster_along, swizzle_size = template.resolve_rasterization(
        raster_along,
        swizzle_size,
        problem_shape_mnkl,
        a_element_bytes=a_element_bytes,
        b_element_bytes=b_element_bytes,
    )
    swizzle_size = _fit_swizzle_size(
        template, problem_shape_mnkl, swizzle_size, raster_along
    )

    if not template.can_implement(problem_shape_mnkl, swizzle_size, raster_along):
        raise ValueError(
            f"the tile scheduler cannot schedule problem {problem_shape_mnkl} "
            f"with swizzle_size={swizzle_size}, raster_order={raster_along!r}"
        )

    if not predicated_store and template.visits_oob_tiles(
        problem_shape_mnkl, swizzle_size, raster_along
    ):
        raise ValueError(
            f"problem {problem_shape_mnkl} with swizzle_size={swizzle_size} leaves "
            "out-of-bounds tiles that a non-TMA store cannot predicate away"
        )
    return swizzle_size, raster_along


def _fit_swizzle_size(
    template,
    problem_shape_mnkl: tuple[int, int, int, int],
    swizzle_size: int,
    raster_along: str,
) -> int:
    """Narrow a swizzle wider than the cluster extent it groups to that extent.

    The affine swizzle groups clusters along N when rasterizing along M, and
    along M otherwise. A group at least as wide as that axis visits the
    problem's clusters in the same order as one exactly as wide, but pads the
    grid with clusters outside the problem, which the scheduler rejects.

    :param template: The kernel's ``TileSchedulerTemplate``.
    :param problem_shape_mnkl: Problem extents ``(M, N, K, L)`` in elements.
    :type problem_shape_mnkl: tuple[int, int, int, int]
    :param swizzle_size: The resolved swizzle size.
    :type swizzle_size: int
    :param raster_along: The resolved raster order, ``"m"`` or ``"n"``.
    :type raster_along: str
    :return: ``swizzle_size``, capped at the grouped axis' cluster count.
    :rtype: int
    """
    if template.template_params.rasterization_strategy != "affine":
        return swizzle_size
    m_clusters, n_clusters = get_host_cluster_counts_mn(
        template.template_params, problem_shape_mnkl
    )
    grouped_clusters = n_clusters if raster_along == "m" else m_clusters
    return min(swizzle_size, grouped_clusters)


def resolve_split_count(reduction: ReductionMetadata) -> int:
    """Return the compile-time split count of a design's reduction strategy.

    :param reduction: The reduction strategy the design advertises.
    :type reduction: ReductionMetadata
    :return: 1 for a strategy without a ``split_count`` (``NoReductionMetadata``),
        otherwise the single split count it advertises.
    :rtype: int
    :raises ValueError: If ``split_count`` is not a single fixed count, since
        the kernel specializes on it at compile time.
    """
    if not hasattr(reduction, "split_count"):
        return 1
    split_count = reduction.split_count
    if not (
        isinstance(split_count, tuple)
        and len(split_count) == 1
        and isinstance(split_count[0], int)
    ):
        raise ValueError(
            f"{reduction!r} must fix a single compile-time split count, got "
            f"split_count={split_count!r}"
        )
    return split_count[0]


def resolve_max_active_clusters(
    device_properties: DeviceProperties,
    fallback_cluster_shape_mn: tuple[int, int],
    split_k: int,
    reduction_strategy: str,
    work_strategy: str,
) -> int:
    """Query and validate the occupancy cap for a universal-kernel launch.

    Non-static strategies cover the whole problem and ignore the occupancy
    argument, so they receive zero without querying the device.

    Cluster split-K places its splits in the physical cluster's Z dimension.
    ``DeviceProperties`` multiplies the two dimensions it receives, so fold
    fallback M and N together and pass Z separately.

    :param device_properties: Properties of the launch device.
    :type device_properties: DeviceProperties
    :param fallback_cluster_shape_mn: Fallback cluster shape in M and N.
    :type fallback_cluster_shape_mn: tuple[int, int]
    :param split_k: Compile-time split count.
    :type split_k: int
    :param reduction_strategy: Kernel reduction strategy.
    :type reduction_strategy: str
    :param work_strategy: Kernel work-distribution strategy.
    :type work_strategy: str
    :return: Maximum concurrently resident fallback clusters.
    :rtype: int
    :raises RuntimeError: If the fallback cluster cannot reside on the device.
    """
    if work_strategy != "static":
        return 0

    fallback_m, fallback_n = fallback_cluster_shape_mn
    cluster_z = split_k if reduction_strategy == "cluster-splitk" else 1
    max_active_clusters = device_properties.max_active_clusters(
        (fallback_m * fallback_n, cluster_z)
    )
    if max_active_clusters == 0:
        raise RuntimeError(
            f"no fallback cluster of shape "
            f"({fallback_m}, {fallback_n}, {cluster_z}) "
            f"can be resident on device {device_properties.device_id}"
        )
    return max_active_clusters


def _get_tile_scheduler_controls(args: RuntimeArguments | None):
    """Return the tile-scheduler settings a caller requested, if any.

    :param args: The arguments of the launch being resolved, or ``None``.
    :type args: RuntimeArguments | None
    :return: The requested controls, or ``None`` if the caller made no request.
    :rtype: TileSchedulerControls | None
    """
    if args is None or not isinstance(args.performance, GemmPerformanceControls):
        return None
    controls = args.performance.tile_scheduler_controls
    return controls if isinstance(controls, TileSchedulerControls) else None


def _resolve_setting(domain, requested, default):
    """Resolve one scheduler setting against the domain the design offers.

    :param domain: The values this design offers: a tuple, an
        :class:`~cutlass.operators.typing.AnyValue` wildcard, or ``None`` when
        the setting is not offered.
    :param requested: The caller's request, or ``...`` / ``None`` for none.
    :param default: The value to use when neither the domain nor the caller decides.
    :return: The resolved setting value.
    """
    # A request outside ``domain`` is not checked here; it must already have
    # been rejected by ``TileSchedulerMetadata.supports(args)``.
    addressed = requested is not ... and requested is not None

    # compile-time set parameter, or only one option offered
    if isinstance(domain, tuple) and len(domain) == 1:
        return domain[0]

    # runtime set parameter
    return requested if addressed else default
