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

"""Performance-control requests shared by operator implementations."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import TYPE_CHECKING

from cutlass.operators.arguments.base import PerformanceControls
from cutlass.operators.arguments.data_driven_sync import DataDrivenSyncControls
from cutlass.operators.arguments.pdl import ProgrammaticDependentLaunchControl
from cutlass.operators.arguments.tile_scheduler_settings import (
    RasterizationStrategy,
    RasterOrder,
    ReductionStrategy,
)

if TYPE_CHECKING:
    from types import EllipsisType


def is_ellipses_or_none(value: object) -> bool:
    """Check if a value is an ellipsis or None."""
    return value is ... or value is None


@dataclass(frozen=True, kw_only=True)
class TileSchedulerControls:
    """Describe performance settings related to the tile scheduler.

    Every field distinguishes the following states:

    * ``...`` (the default) -- the caller expressed no opinion. Every operator
      matches and the operator's own default is used at launch.
    * A concrete value -- only operators whose design accepts that value match.
    * ``None`` -- the caller asks not to use the setting. ``reduction`` and
      ``rasterization`` are axes that every tile scheduler has, so ``None`` is
      canonicalized to their do-nothing value; for the other settings it selects
      operators whose design does not expose the setting at all.

    Attributes:
        reduction (ReductionStrategy | None | EllipsisType): How partial results
            along the K dimension are combined. ``NO_REDUCTION`` computes each
            output tile from the full K extent, ``SPLIT_K`` reduces partials
            through global memory, and ``CLUSTER_SPLIT_K`` reduces them inside a
            cluster over distributed shared memory.
        split_count (int | None | EllipsisType): How many K slices the
            reduction splits an output tile into. Must be greater than 1 for
            ``SPLIT_K`` and ``CLUSTER_SPLIT_K``.
        rasterization (RasterizationStrategy | None | EllipsisType): The order in
            which the scheduler walks output tiles. ``NO_RASTERIZATION`` visits
            them in the scheduler's natural linear order, while
            ``TILE_SWIZZLE`` groups them so that neighboring tiles run close
            together in time.
        raster_order (RasterOrder | None | EllipsisType): The dimension walked
            first within a swizzle group, ``ALONG_M`` or ``ALONG_N``, or
            ``HEURISTIC`` to let the scheduler pick from the problem shape.
        swizzle_size (int | None | EllipsisType): How many tiles a swizzle
            group spans along a swizzle group dimension.
    """

    reduction: ReductionStrategy | None | EllipsisType = ...
    split_count: int | None | EllipsisType = ...

    rasterization: RasterizationStrategy | None | EllipsisType = ...
    raster_order: RasterOrder | None | EllipsisType = ...
    swizzle_size: int | None | EllipsisType = ...

    def __post_init__(self) -> None:
        """Canonicalize ``None`` strategies and validate requested control values.

        Raises:
            ValueError: If a control has the wrong type, or if the requested
                values contradict each other.
        """
        # A strategy axis is always present in a tile scheduler, so asking not to
        # use one means asking for its do-nothing value. Canonicalize before the
        # checks below.
        if self.reduction is None:
            object.__setattr__(self, "reduction", ReductionStrategy.NO_REDUCTION)
        if self.rasterization is None:
            object.__setattr__(
                self, "rasterization", RasterizationStrategy.NO_RASTERIZATION
            )

        # Validate input types
        enum_controls = (
            ("reduction", self.reduction, ReductionStrategy),
            ("rasterization", self.rasterization, RasterizationStrategy),
            ("raster_order", self.raster_order, RasterOrder),
        )
        for name, value, expected_type in enum_controls:
            if not is_ellipses_or_none(value) and not isinstance(value, expected_type):
                raise ValueError(
                    f"{name} must be a {expected_type.__name__}, got {value!r}"
                )
        for name, value in (
            ("split_count", self.split_count),
            ("swizzle_size", self.swizzle_size),
        ):
            if not is_ellipses_or_none(value) and (
                not isinstance(value, int) or isinstance(value, bool) or value < 1
            ):
                raise ValueError(f"{name} must be a positive int, got {value!r}")

        # Check that combination of inputs is cross-compatible.
        # Information on valid combinations of inputs is found in
        # the tile scheduler metadata documentation.
        #
        # This does not check that the controls is valid for the operator.
        # Call additional checks with supports() in the tile scheduler metadata.
        # Changing performance controls may require changing the operator if
        # features are unsupported.

        # A do-nothing strategy should fail if it tries to set any parameters.
        if self.reduction is ReductionStrategy.NO_REDUCTION and not is_ellipses_or_none(
            self.split_count
        ):
            raise ValueError(
                "split_count must be unset (...) or None when reduction is "
                f"NO_REDUCTION, got {self.split_count!r}"
            )

        if self.rasterization is RasterizationStrategy.NO_RASTERIZATION:
            if not is_ellipses_or_none(self.swizzle_size):
                raise ValueError(
                    "swizzle_size must be unset (...) or None when rasterization is "
                    f"NO_RASTERIZATION, got {self.swizzle_size!r}"
                )
            if not is_ellipses_or_none(self.raster_order):
                raise ValueError(
                    "raster_order must be unset (...) or None when rasterization is "
                    f"NO_RASTERIZATION, got {self.raster_order!r}"
                )

        if self.split_count == 1 and self.reduction in (
            ReductionStrategy.SPLIT_K,
            ReductionStrategy.CLUSTER_SPLIT_K,
        ):
            raise ValueError(
                f"split_count must be greater than 1 when reduction is {self.reduction}"
            )

    def requested_values(self) -> dict[str, object]:
        """Return the controls the caller addressed, keyed by control name.

        Fields left as ``...`` (the unset default) are omitted.

        Returns:
            dict[str, object]: Control names mapped to their requested values.
                Fields left unset (``...``) are omitted.
        """
        return {name: value for name, value in asdict(self).items() if value is not ...}


@dataclass(kw_only=True)
class GemmPerformanceControls(PerformanceControls):
    """Describe independent, optional GEMM performance settings.

    Individual controls (e.g. :attr:`pdl`) are standalone dataclasses composed
    as fields here, rather than each being its own
    :class:`~cutlass.operators.PerformanceControls` subclass. This lets a GEMM
    request combine multiple independent performance controls at once.

    For :attr:`tile_scheduler_controls`, ``...`` (the default) means the caller
    expressed no opinion, and ``None`` means the caller explicitly asked for no
    tile-scheduler request.
    """

    tile_scheduler_controls: TileSchedulerControls | None | EllipsisType = ...

    pdl: ProgrammaticDependentLaunchControl = field(
        default_factory=ProgrammaticDependentLaunchControl
    )
    """Query and control Programmatic Dependent Launch (PDL) controls."""

    data_driven_sync: DataDrivenSyncControls = field(
        default_factory=DataDrivenSyncControls
    )
    """Query and control data-driven synchronization controls."""

    def __post_init__(self) -> None:
        """Validate the tile-scheduler control request at construction.

        Raises:
            ValueError: If ``tile_scheduler_controls`` is not a
                :class:`TileSchedulerControls`, ``None``, or ``...``.
        """
        if not is_ellipses_or_none(self.tile_scheduler_controls) and not isinstance(
            self.tile_scheduler_controls, TileSchedulerControls
        ):
            raise ValueError(
                "tile_scheduler_controls must be a TileSchedulerControls, None, "
                f"or ..., got {self.tile_scheduler_controls!r}"
            )
