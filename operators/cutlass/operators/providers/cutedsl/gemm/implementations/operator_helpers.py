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

"""Shared helpers for CuTeDSL GEMM kernel implementations.

This module hosts small, dependency-light utilities that are reused across
the persistent / preferred-cluster / EFC / etc. kernel implementations but
do not exist in the CuteDSL API, as well as associated mapper functions.
"""

from __future__ import annotations

import enum

from cutlass.operators.metadata.design.tile_scheduler import (
    CLCDynamicPersistentTileSchedulerMetadata,
    StaticPersistentTileSchedulerMetadata,
    TileSchedulerMetadata,
)


class PersistentTileSchedulerType(enum.Enum):
    """Identifies which persistent tile-scheduler dispatch the kernel uses.

    Members:
        CLC: Cluster Launch Control dynamic persistent scheduler.
        STATIC_PERSISTENT: Static persistent scheduler. Each SM in the
            launch grid iterates over a fixed slice of tiles known at
            launch time.
    """

    CLC = enum.auto()
    STATIC_PERSISTENT = enum.auto()


def scheduler_metadata_to_enum(
    metadata: TileSchedulerMetadata | None,
) -> PersistentTileSchedulerType:
    """Map tile-scheduler metadata to its kernel-side dispatch tag."""
    if isinstance(metadata, CLCDynamicPersistentTileSchedulerMetadata):
        return PersistentTileSchedulerType.CLC
    if isinstance(metadata, StaticPersistentTileSchedulerMetadata):
        return PersistentTileSchedulerType.STATIC_PERSISTENT
    raise ValueError(
        f"Unsupported tile-scheduler metadata: {metadata!r}. Expected an "
        f"instance of {CLCDynamicPersistentTileSchedulerMetadata.__name__} or "
        f"{StaticPersistentTileSchedulerMetadata.__name__}."
    )
