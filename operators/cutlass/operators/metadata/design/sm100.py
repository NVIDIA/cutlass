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

from __future__ import annotations

from dataclasses import dataclass
from math import prod
from typing import TYPE_CHECKING, ClassVar

from cutlass.operators.metadata.design.base import BLASDesignMetadata
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.metadata.design.tile_scheduler import TileSchedulerMetadata


@dataclass
class Sm100DesignMetadata(BLASDesignMetadata):
    """Design metadata for operators in the SM100 architecture family."""

    use_2cta_mma: bool
    """Whether to use a 2CTA MMA instruction"""

    use_tma_store: bool
    """Whether to use TMA to store the results of the operation"""

    tile_scheduler: TileSchedulerMetadata | None = None
    """Describes the tile scheduling strategy used by the Operator"""

    fallback_cluster_shape: tuple[int, ...] | None = None
    """Fallback cluster shape for preferred cluster mode.

    When ``None`` (default), the Operator uses a single fixed cluster shape
    (``BLASDesignMetadata.cluster_shape``). When set:

    * the Operator uses two cluster shapes: ``cluster_shape`` as the
      preferred (larger) shape and ``fallback_cluster_shape`` as the smaller
      fallback for tiles that cannot fill a full preferred cluster.
    * Preferred cluster depth (Z dimension) must be the same as that of fallback cluster.
    * Fallback cluster shape must evenly divide the preferred cluster shape.
    """

    max_cluster_size: ClassVar[int] = 16
    """Maximum non-portable cluster size allowed by sm100f architecture."""

    def use_fallback_cluster(self) -> bool:
        """Return True when this design uses a preferred (larger) and fallback (smaller) cluster shape."""
        return self.fallback_cluster_shape is not None

    def __post_init__(self):

        super().__post_init__()

        if prod(self.cluster_shape) > self.max_cluster_size:
            raise ValueError(
                f"cluster_shape {self.cluster_shape} is too large, must have size <= {self.max_cluster_size}"
            )

        if self.fallback_cluster_shape is None:
            return

        # Enforce the preferred/fallback cluster size invariant.
        if not (
            status := self.is_valid_fallback_cluster(
                self.cluster_shape, self.fallback_cluster_shape
            )
        ):
            status.raise_on_error()

    @classmethod
    def is_valid_fallback_cluster(
        cls,
        cluster_shape: tuple[int, int, int],
        fallback_cluster_shape: tuple[int, int, int],
    ) -> Status:
        """Check if the fallback_cluster_shape is valid for the given cluster_shape."""
        if len(fallback_cluster_shape) != 3:
            return Status.fail(
                f"fallback_cluster_shape must have rank 3, got {fallback_cluster_shape}"
            )
        if any(dim <= 0 for dim in fallback_cluster_shape):
            return Status.fail(
                f"fallback_cluster_shape dimensions must be positive, got {fallback_cluster_shape}"
            )

        # Both shapes must have the same rank.
        if len(fallback_cluster_shape) != len(cluster_shape):
            return Status.fail(
                f"fallback_cluster_shape {fallback_cluster_shape} must have "
                f"the same rank as cluster_shape {cluster_shape}"
            )


        # A fallback shape equal to preferred shape is not strictly incorrect, but
        # defeats the purpose of specifying fallback cluster and so is likely unintended.
        if fallback_cluster_shape == cluster_shape:
            return Status.fail(
                "fallback_cluster_shape should differ from cluster_shape "
                "(use fallback_cluster_shape=None to express no preferred-cluster "
                f"mode instead); got both = {cluster_shape}"
            )

        # Depth of both cluster shapes should match
        if fallback_cluster_shape[-1] != cluster_shape[-1]:
            return Status.fail(
                "fallback_cluster_shape and cluster_shape must agree on the "
                "trailing (batch) dim; got "
                f"fallback_cluster_shape={fallback_cluster_shape}, "
                f"cluster_shape={cluster_shape}"
            )

        # fallback cluster shape should evenly divide preferred cluster shape, and be smaller
        for dim, (fallback, preferred) in enumerate(
            zip(fallback_cluster_shape[:-1], cluster_shape[:-1])
        ):
            if preferred % fallback != 0:
                return Status.fail(
                    "fallback_cluster_shape must evenly divide cluster_shape "
                    "in every non-batch dim; got "
                    f"fallback_cluster_shape={fallback_cluster_shape}, "
                    f"cluster_shape={cluster_shape} "
                    f"(dim {dim}: {preferred} % {fallback} != 0)"
                )

        return Status.success()
