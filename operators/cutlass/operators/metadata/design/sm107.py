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

from dataclasses import dataclass, field
from typing import ClassVar

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments.base import RuntimeArguments
from cutlass.operators.arguments.performance import (
    GemmPerformanceControls,
    TileSchedulerControls,
)
from cutlass.operators.metadata.design.data_driven_sync import (
    DataDrivenSyncMetadata,
)
from cutlass.operators.metadata.design.sm100 import Sm100DesignMetadata
from cutlass.operators.status import Status


@dataclass(slots=True)
class Sm107DesignMetadata(Sm100DesignMetadata):
    """Design metadata for operators in the SM107 architecture family."""

    enable_breuse: bool = False
    """Whether the kernel retains each B tile for a second MMA along M."""

    max_cluster_size: ClassVar[int] = 30
    """Maximum non-portable cluster size allowed by sm107 architecture."""

    data_driven_sync: DataDrivenSyncMetadata = field(
        default_factory=DataDrivenSyncMetadata
    )
    """Data-driven synchronization metadata about whether Operator is producer/consumer.

    Typically paired with PDL.
    """

    def supports(
        self, args: RuntimeArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Ensures runtime arguments satisfy the design metadata.

        Args:
            args (RuntimeArguments): The arguments to check support for.
            target_sm (TargetSm | None): The target SM to check support for. If None, skips arch-specific checks.

        Returns:
            Status: Status indicating whether the provided args satisfy the design metadata.
        """
        performance = args.performance
        if isinstance(performance, GemmPerformanceControls):
            status = Status.success()
            data_driven_sync_supported = self.data_driven_sync.supports(
                performance.data_driven_sync, target_sm
            )
            status = status.combine(data_driven_sync_supported)
            pdl_supported = self.pdl.supports(performance.pdl)
            if self.tile_scheduler is not None:
                scheduler_supported = self.tile_scheduler.supports(args)
            elif isinstance(performance.tile_scheduler_controls, TileSchedulerControls):
                scheduler_supported = Status.fail(
                    "This operator does not support user-controlled tile scheduling"
                )
            else:
                scheduler_supported = Status.success()
            return status.combine([pdl_supported, scheduler_supported])

        status = super(Sm107DesignMetadata, self).supports(args, target_sm)
        if self.data_driven_sync.is_enabled():
            status = status.combine(
                Status.fail(
                    "Operator uses data-driven synchronization but it was not requested. "
                    "Operator cannot safely support disabling data-driven synchronization."
                )
            )
        if self.pdl.is_enabled():
            status = status.combine(
                Status.fail(
                    "Operator uses PDL but it was not requested. "
                    "PDL operator cannot safely support disabling PDL."
                )
            )
        return status

    def __post_init__(self) -> None:
        # Zero-arg super() breaks with slots=True on parent+child,
        # so use explicit two-arg super() instead.
        super(Sm107DesignMetadata, self).__post_init__()
