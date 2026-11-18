# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Shared mixed-cluster fallback machinery for tile-scheduler params classes."""

from typing import Callable, Optional, Tuple

import cutlass.cute as cute
from cutlass.cute.typing import Int32

from cutlass._mlir import ir


class MixedClusterParamsMixin:
    """Mixin providing fallback-cluster support to tile-scheduler params.

    Subclass contract:

    1. Constructor accepts ``fallback_cluster_shape_mnk: Optional[cute.Shape]``
       and calls ``self._init_fallback(fallback_cluster_shape_mnk, factory)``
       once, where ``factory`` builds a sibling instance (passing
       ``fallback_cluster_shape_mnk=None`` to itself to avoid recursion).

    2. After selecting active params, physical-cluster-dependent math must derive from
       ``self.runtime_cluster_dims()``, NOT from ``self.cluster_shape_mn``:
       the pytree reconstruction restores Python fields from the prototype,
       so the static tuple always reflects the preferred shape even on the
       fallback clone.

       This does not apply to logical-grid scheduling: the static persistent
       scheduler retains primary params and the preferred-shaped grid's tile
       ownership regardless of the physical cluster shape.

    Subclasses implement ``_extract_primary_mlir_values``,
    ``_new_primary_from_mlir_values``, and ``_primary_values_count``.
    """

    _fallback: "MixedClusterParamsMixin"
    _has_distinct_fallback: bool
    # Provided by the concrete subclass; declared here so mypy can see it.
    # Runtime value is always a length-3 tuple of ints (cluster_m, cluster_n, 1).
    _cluster_shape_mnk: Tuple[int, int, int]

    # Abstract — subclasses must implement these.
    def _extract_primary_mlir_values(self) -> list[ir.Value]:
        raise NotImplementedError

    def _new_primary_from_mlir_values(
        self, mlir_values: list[ir.Value]
    ) -> "MixedClusterParamsMixin":
        raise NotImplementedError

    @property
    def _primary_values_count(self) -> int:
        raise NotImplementedError

    def _init_fallback(
        self,
        fallback_cluster_shape_mnk: Optional[Tuple[int, int, int]],
        factory: Callable[[Tuple[int, int, int]], "MixedClusterParamsMixin"],
    ) -> None:
        if fallback_cluster_shape_mnk is not None and (
            tuple(fallback_cluster_shape_mnk) != tuple(self._cluster_shape_mnk)
        ):
            self._has_distinct_fallback = True
            self._fallback = factory(fallback_cluster_shape_mnk)
        else:
            self._has_distinct_fallback = False
            self._fallback = self

    def __extract_mlir_values__(self) -> list[ir.Value]:
        primary = self._extract_primary_mlir_values()
        fallback = self._fallback._extract_primary_mlir_values()
        return primary + fallback

    def __new_from_mlir_values__(
        self, mlir_values: list[ir.Value]
    ) -> "MixedClusterParamsMixin":
        n = self._primary_values_count
        new_primary = self._new_primary_from_mlir_values(list(mlir_values[:n]))
        new_primary._fallback = self._fallback._new_primary_from_mlir_values(
            list(mlir_values[n:])
        )
        new_primary._has_distinct_fallback = self._has_distinct_fallback
        return new_primary

    @staticmethod
    @cute.jit
    def _select_active_params(
        params: "MixedClusterParamsMixin",
    ) -> "MixedClusterParamsMixin":
        """Return ``params`` on the preferred cluster, else ``params._fallback``.

        Inside the body-clone, ``is_preferred_cluster`` folds to a constant per
        clone, so the ``scf.if`` collapses to a single arm.
        """
        from cutlass.cute import experimental as cute_ext

        active = params
        if cute_ext.is_preferred_cluster(params._cluster_shape_mnk):
            active = params
        else:
            active = params._fallback
        return active

    def runtime_cluster_dims(self) -> Tuple[Int32, Int32, Int32]:
        """Return ``(cdx, cdy, cdz)`` Int32 SSA values for the active cluster.

        Reads ``cute.arch.block_in_cluster_dim()`` directly. Inside a
        mixed-cluster expansion clone these reads fold to that branch's static
        shape; in the outer dispatch and in unspecialized kernels they remain
        runtime values.
        """
        return cute.arch.block_in_cluster_dim()


def max_active_preferred_clusters(
    cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    max_active_clusters: int,
    max_active_fallback_clusters: Optional[int],
) -> int:
    """Resident preferred-cluster slots for a mixed launch.

    Worst case every slot falls back, so the residency budget is the
    fallback wave's CTA capacity (fallback occupancy x fallback size);
    floor it into whole preferred-cluster slots.

    Returns 0 when that budget cannot fit one preferred slot: a mixed
    launch is infeasible, and the empty grid fails at launch instead of
    running a cluster shape the caller did not request.

    Returns ``max_active_clusters`` unchanged when there is no distinct
    fallback shape or no fallback occupancy.
    """
    if max_active_fallback_clusters is None or tuple(
        fallback_cluster_shape_mn
    ) == tuple(cluster_shape_mn):
        return max_active_clusters
    max_ctas_for_fallback_cluster = (
        max_active_fallback_clusters
        * fallback_cluster_shape_mn[0]
        * fallback_cluster_shape_mn[1]
    )
    preferred_cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
    return max_ctas_for_fallback_cluster // preferred_cluster_size
