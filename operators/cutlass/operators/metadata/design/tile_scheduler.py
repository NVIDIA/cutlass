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

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.arch import TargetSm

if TYPE_CHECKING:
    from cutlass.operators.metadata import DesignMetadata, OperandsMetadata


@dataclass(kw_only=True, frozen=True, slots=True)
class TileSchedulerMetadata(ABC):
    """Models an abstract tile scheduler."""

    @classmethod
    @abstractmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns all the supported targets for the tile scheduler.

        Considers optional design and operands metadata when determining
        which targets are supported.
        """
        raise NotImplementedError("Subclasses must implement this method")


@dataclass(kw_only=True, frozen=True, slots=True)
class CLCDynamicPersistentTileSchedulerMetadata(TileSchedulerMetadata):
    """Metadata for the CLC dynamic persistent tile scheduler."""

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns supported targets for CLC dynamic persistent tile scheduler."""
        return [TargetSm("100f"), TargetSm("110f"), TargetSm("120")]


@dataclass(kw_only=True, frozen=True, slots=True)
class StaticPersistentTileSchedulerMetadata(TileSchedulerMetadata):
    """Metadata for the static persistent tile scheduler."""

    @classmethod
    def supported_targets(
        cls,
        design: DesignMetadata | None = None,
        operands: OperandsMetadata | None = None,
    ) -> list[TargetSm]:
        """Returns supported targets for static persistent tile scheduler."""
        return [
            TargetSm("80"),
            TargetSm("90"),
            TargetSm("100f"),
            TargetSm("110f"),
            TargetSm("120"),
        ]
