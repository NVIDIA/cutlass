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

from __future__ import annotations

import functools
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments.performance import (
    GemmPerformanceControls,
    TileSchedulerControls,
)
from cutlass.operators.arguments.tile_scheduler_settings import (
    RasterizationStrategy,
    RasterOrder,
    ReductionStrategy,
)
from cutlass.operators.status import Status
from cutlass.operators.typing import AnyValue

if TYPE_CHECKING:
    from cutlass.operators.arguments.base import RuntimeArguments
    from cutlass.operators.metadata import DesignMetadata, OperandsMetadata


def _format_parameter_domain(domain: tuple | AnyValue | None) -> str:
    """Format a parameter domain compactly for operator-name style encoding.

    Multiple accepted values are joined with ``"+"``.

    Args:
        domain: A tuple of concrete values, an :class:`AnyValue` wildcard, or
            ``None`` when the parameter is not offered.

    Returns:
        str: ``"+"``-joined values (e.g. ``"1+2+4"`` or ``"AlongN"``), the
            wildcard's own spelling (e.g. ``"AnyValue[int]"``), or ``"Off"``
            when the parameter is disabled.
    """
    if domain is None:
        return "Off"
    if isinstance(domain, AnyValue):
        return repr(domain)
    return "+".join(str(value) for value in domain)


@dataclass(frozen=True, slots=True)
class TileSchedulerMetadata:
    """A tile scheduler fully described by three strategy axes.

    * :class:`PersistenceMetadata` -- whether the kernel is persistent and how
      that persistence is driven.
    * :class:`ReductionMetadata` -- whether (and how) the GEMM's K reduction is
      split across tiles.
    * :class:`RasterizationMetadata` -- the order in which tiles are scheduled.
    """

    persistence: PersistenceMetadata
    reduction: ReductionMetadata
    rasterization: RasterizationMetadata

    def __post_init__(self) -> None:
        """Validate cross-strategy compatibility between the three axes.

        Raises:
            ValueError: If ``persistence`` is static persistent while
                ``rasterization`` is :class:`NoRasterizationMetadata`.
        """
        if (
            self.persistence is None
            or self.reduction is None
            or self.rasterization is None
        ):
            raise ValueError("persistence, reduction, and rasterization must be set")
        if isinstance(self.persistence, StaticPersistentMetadata) and isinstance(
            self.rasterization, NoRasterizationMetadata
        ):
            raise ValueError(
                "StaticPersistentMetadata is not supported with NoRasterizationMetadata"
            )

    def supported_targets(
        self: TileSchedulerMetadata,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the tile scheduler.

        Considers optional design and operands metadata when determining
        which targets are supported.
        """
        return list(
            _by_axis_supported_targets(
                self.persistence, self.reduction, self.rasterization
            )
        )

    def __repr__(self) -> str:
        """Return a compact operator-name style encoding of this scheduler."""
        return f"{self.persistence}_{self.reduction}_{self.rasterization}"

    def supports(self, args: RuntimeArguments) -> Status:
        """Checks whether arguments are supported by the tile scheduler metadata.

        An unspecified ``args.performance``, and the ``...`` default for
        ``tile_scheduler_controls``, both express no opinion and are accepted.
        ``args.performance=None`` asks for an operator without performance
        controls, and ``tile_scheduler_controls=None`` asks for one without a
        tile scheduler; this metadata satisfies neither. Otherwise every
        requested setting must fall inside the domain this scheduler offers.

        Args:
            args (RuntimeArguments): The arguments to check support for.

        Returns:
            Status: Success, or a failure naming the unsupported control.
        """
        performance = args.performance
        if performance is ...:
            return Status.success()
        if performance is None:
            return Status.fail(
                "performance=None requests an operator without performance "
                f"controls, but this operator schedules tiles with {self}"
            )
        if not isinstance(performance, GemmPerformanceControls):
            return Status.fail(
                f"expected GemmPerformanceControls, got {type(performance).__name__}"
            )
        controls = performance.tile_scheduler_controls
        if controls is Ellipsis:
            return Status.success()
        if controls is None:
            return Status.fail(
                "tile_scheduler_controls=None requests an operator without a tile "
                f"scheduler metadata features, but this operator schedules tiles with {self}"
            )
        if not isinstance(controls, TileSchedulerControls):
            return Status.fail(f"expected TileSchedulerControls, got {controls!r}")

        if controls.reduction is not ...:
            accepted_reduction = {
                NoReductionMetadata: ReductionStrategy.NO_REDUCTION,
                SplitKReductionMetadata: ReductionStrategy.SPLIT_K,
                ClusterSplitKReductionMetadata: ReductionStrategy.CLUSTER_SPLIT_K,
            }
            if controls.reduction != accepted_reduction.get(type(self.reduction)):
                return Status.fail(
                    f"reduction={controls.reduction} is not supported by this operator"
                )

        if controls.rasterization is not ...:
            accepted_rasterization = {
                NoRasterizationMetadata: RasterizationStrategy.NO_RASTERIZATION,
                TileSwizzleRasterizationMetadata: RasterizationStrategy.TILE_SWIZZLE,
            }
            if controls.rasterization != accepted_rasterization.get(
                type(self.rasterization)
            ):
                return Status.fail(
                    f"rasterization={controls.rasterization} is not supported by "
                    "this operator"
                )

        for control, strategy in (
            ("split_count", self.reduction),
            ("raster_order", self.rasterization),
            ("swizzle_size", self.rasterization),
        ):
            requested = getattr(controls, control)
            if requested is ...:
                continue
            accepted = getattr(strategy, control, None)
            is_accepted = (
                requested in accepted
                if hasattr(accepted, "__contains__")
                else requested == accepted
            )
            if not is_accepted:
                return Status.fail(
                    f"{control}={requested} is not supported by this operator; "
                    f"it accepts {accepted}"
                )
        return Status.success()


@dataclass(frozen=True, slots=True)
class PersistenceMetadata(ABC):
    """Base class for tile-scheduler persistence strategies."""

    @classmethod
    @abstractmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the persistence strategy.

        Considers optional design and operands metadata when determining
        which targets are supported.
        """
        raise NotImplementedError("Subclasses must implement this method")


@dataclass(frozen=True, slots=True)
class NonPersistentMetadata(PersistenceMetadata):
    """A non-persistent tile scheduler that launches one CTA per tile."""

    def __repr__(self) -> str:
        return "NonPersistent"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this persistence strategy for kernel arguments."""
        return "grid"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the non-persistent mode."""
        return _ALL_TARGETS


@dataclass(frozen=True, slots=True)
class StaticPersistentMetadata(PersistenceMetadata):
    """A statically persistent scheduler that reuses CTAs across tiles."""

    def __repr__(self) -> str:
        return "StaticPersistent"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this persistence strategy for kernel arguments."""
        return "static"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the static persistent mode."""
        return _ALL_TARGETS


@dataclass(frozen=True, slots=True)
class CLCDynamicPersistentMetadata(PersistenceMetadata):
    """A CLC-driven dynamically persistent tile scheduler."""

    def __repr__(self) -> str:
        return "CLC"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this persistence strategy for kernel arguments."""
        return "clc"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the CLC dynamic persistent mode."""
        return _CLC_PERSISTENT_TARGETS


@dataclass(frozen=True, slots=True)
class ReductionMetadata(ABC):
    """Determines how the K dimension is split into tiles."""

    @classmethod
    @abstractmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the reduction strategy.

        Considers optional design and operands metadata when determining
        which targets are supported.
        """
        raise NotImplementedError("Subclasses must implement this method")


@dataclass(frozen=True, slots=True)
class NoReductionMetadata(ReductionMetadata):
    """A reduction strategy that does not split the K dimension."""

    def __repr__(self) -> str:
        return "noReduction"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this reduction strategy for kernel arguments."""
        return "none"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the no-reduction strategy."""
        return _ALL_TARGETS


@dataclass(frozen=True, slots=True)
class SplitKReductionMetadata(ReductionMetadata):
    """A reduction strategy that splits the K dimension into multiple tiles."""

    # Omitting the setting leaves it unset, meaning the design does not offer
    # this parameter at all.
    split_count: tuple[int, ...] | AnyValue[int] | None = None

    def __post_init__(self) -> None:
        """Type-check an explicit ``split_count``.

        Raises:
            ValueError: If ``split_count`` is neither a tuple of :class:`int`,
                nor ``AnyValue(int)``.
        """
        if self.split_count is None:
            return
        is_int_wildcard = (
            isinstance(self.split_count, AnyValue)
            and self.split_count.value_type is int
        )
        is_int_tuple = isinstance(self.split_count, tuple) and all(
            isinstance(value, int) for value in self.split_count
        )
        if not (is_int_wildcard or is_int_tuple):
            raise ValueError(f"Unrecognized type for split_count: {self.split_count!r}")

    def __repr__(self) -> str:
        return f"splitK{_format_parameter_domain(self.split_count)}"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this reduction strategy for kernel arguments."""
        return "gmem-splitk"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the split-K reduction strategy."""
        return _ALL_TARGETS


@dataclass(frozen=True, slots=True)
class ClusterSplitKReductionMetadata(ReductionMetadata):
    """A reduction strategy that splits K with cluster awareness.

    Contains a compile-time setting for split_count.
    """

    # Omitting the setting leaves it unset, meaning the design does not offer
    # this parameter at all.
    split_count: tuple[int] | None = None

    def __post_init__(self) -> None:
        if self.split_count is not None:
            if not isinstance(self.split_count, tuple) or not all(
                isinstance(value, int) for value in self.split_count
            ):
                raise ValueError(
                    f"Unrecognized type for split_count: {self.split_count!r}"
                )
            if len(self.split_count) != 1:
                raise ValueError(
                    f"compile time parameters must be a tuple of length 1, but got {self.split_count!r}"
                )

    def __repr__(self) -> str:
        return f"clusterSplitK{_format_parameter_domain(self.split_count)}"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this reduction strategy for kernel arguments."""
        return "cluster-splitk"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the cluster split-K reduction strategy."""
        return _CLUSTER_SPLITK_TARGETS


@dataclass(frozen=True, slots=True)
class RasterizationMetadata(ABC):
    """Determines how the tile order is rasterized."""

    @classmethod
    @abstractmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the rasterization strategy.

        Considers optional design and operands metadata when determining
        which targets are supported.
        """
        raise NotImplementedError("Subclasses must implement this method")


@dataclass(frozen=True, slots=True)
class NoRasterizationMetadata(RasterizationMetadata):
    """A rasterization strategy that does not rasterize the tiles."""

    def __repr__(self) -> str:
        return "noRasterization"

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this rasterization strategy for kernel arguments."""
        return "none"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the no-rasterization strategy."""
        return _ALL_TARGETS


@dataclass(frozen=True, slots=True)
class TileSwizzleRasterizationMetadata(RasterizationMetadata):
    """A rasterization strategy using a raster-order + swizzle pattern."""

    # Omitting the setting leaves it unset, meaning the design does not offer
    # this parameter at all.
    raster_order: tuple[RasterOrder, ...] | None = None
    swizzle_size: tuple[int, ...] | AnyValue[int] | None = None

    def __post_init__(self) -> None:
        """Type-check an explicit ``raster_order`` and ``swizzle_size``.

        Raises:
            ValueError: If ``raster_order`` is not a tuple of :class:`RasterOrder`,
                or if ``swizzle_size`` is neither a tuple of :class:`int`, nor
                ``AnyValue(int)``.
        """
        if self.raster_order is not None and not (
            isinstance(self.raster_order, tuple)
            and all(isinstance(value, RasterOrder) for value in self.raster_order)
        ):
            raise ValueError(
                f"Unrecognized type for raster_order: {self.raster_order!r}"
            )
        if self.swizzle_size is None:
            return
        is_int_wildcard = (
            isinstance(self.swizzle_size, AnyValue)
            and self.swizzle_size.value_type is int
        )
        is_int_tuple = isinstance(self.swizzle_size, tuple) and all(
            isinstance(value, int) for value in self.swizzle_size
        )
        if not (is_int_wildcard or is_int_tuple):
            raise ValueError(
                f"Unrecognized type for swizzle_size: {self.swizzle_size!r}"
            )

    def __repr__(self) -> str:
        return (
            f"swizzle{_format_parameter_domain(self.swizzle_size)}"
            f"-{_format_parameter_domain(self.raster_order)}"
        )

    @classmethod
    def arg_name(cls) -> str:
        """Returns the commonly used name for this rasterization strategy for kernel arguments."""
        return "affine"

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the raster-order + swizzle strategy."""
        return _ALL_TARGETS


_ALL_TARGETS = [
    TargetSm("80"),
    TargetSm("90"),
    TargetSm("100f"),
    TargetSm("110f"),
    TargetSm("120f"),
]

_CLC_PERSISTENT_TARGETS = [
    TargetSm("100f"),
    TargetSm("110f"),
    TargetSm("120f"),
]

_CLUSTER_SPLITK_TARGETS = [
    TargetSm("90"),
    TargetSm("100f"),
    TargetSm("110f"),
    TargetSm("120f"),
]


@functools.cache
def _by_axis_supported_targets(
    persistence: PersistenceMetadata,
    reduction: ReductionMetadata,
    rasterization: RasterizationMetadata,
) -> tuple[TargetSm, ...]:
    """Cache the supported targets for a tile scheduler.

    The strategies are frozen dataclasses, so equal strategy values share one
    cache entry regardless of instance identity. The result keeps the
    persistence axis's ordering so it is deterministic.

    Args:
        persistence (PersistenceMetadata): The persistence strategy.
        reduction (ReductionMetadata): The reduction strategy.
        rasterization (RasterizationMetadata): The rasterization strategy.

    Returns:
        tuple[TargetSm, ...]: The targets supported by all three strategies.
    """
    persistence_targets = persistence.supported_targets()
    common = set(persistence_targets).intersection(
        reduction.supported_targets(), rasterization.supported_targets()
    )
    return tuple(t for t in persistence_targets if t in common)
