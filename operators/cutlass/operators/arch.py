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

import enum
from dataclasses import dataclass
from enum import auto as enum_auto
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Iterable

    from cutlass.operators.metadata import DesignMetadata, OperandsMetadata


@dataclass(init=False)
class TargetSm:
    """Target compute capability & portability to compile for."""

    cc: int
    portability: ArchPortability

    def __init__(
        self,
        sm_str: str | None = None,
        *,
        cc: int | None = None,
        portability: ArchPortability | None = None,
    ):
        """Create a ``TargetSm``.

        Args:
            sm_str (str | None): String like "100", "100a", or "100f".
            cc (int | None): Compute capability as integer (e.g., 100).
            portability (ArchPortability | None): Architecture portability. If not
                provided, defaults to ArchConditional if cc >= 90, else Portable.

        Note:
            Must use either sm_str or cc/portability, not both.

        Example:
            >>> TargetSm("100a")
            >>> TargetSm(cc=100)
            >>> TargetSm(cc=100, portability=ArchPortability.ArchConditional)

        Raises:
            ValueError: If both sm_str and cc/portability are provided, or neither.
            ValueError: If portability is not valid for the given cc.
        """
        if sm_str is not None:
            if cc is not None or portability is not None:
                raise ValueError("Cannot specify sm_str with cc/portability")
            self.cc, self.portability = self._parse_str(sm_str)
        elif cc is not None:
            self.cc = cc
            self.portability = portability or (
                ArchPortability.ArchConditional
                if cc >= 90
                else ArchPortability.Portable
            )
        else:
            raise ValueError("Must specify either sm_str or cc/portability")

        if self.portability == ArchPortability.ArchConditional and self.cc < 90:
            raise ValueError(
                f"TargetSm {self.__str__()} is invalid. ArchConditional targets must be Hopper (sm90) or newer"
            )
        if self.portability == ArchPortability.FamilyPortable and self.cc < 100:
            raise ValueError(
                f"TargetSm {self.__str__()} is invalid. FamilyPortable targets must be Blackwell (sm100) or newer"
            )

    @classmethod
    def ensure(cls, value: TargetSm | str | None) -> TargetSm | None:
        """Coerce a string to ``TargetSm``, or return as-is if already one."""
        if value is None or isinstance(value, cls):
            return value
        if isinstance(value, str):
            return cls(value)
        raise TypeError(f"Expected TargetSm or str. Got {value} of type {type(value)}")

    @staticmethod
    def get_supported_targets(
        design: DesignMetadata, operands: OperandsMetadata
    ) -> list[TargetSm]:
        """Get the supported targets for a given design and operands.

        Raises:
            ValueError: If ``design`` does not have a ``mma_instruction_type`` field.
        """
        # For now, just return the supported instruction.
        # It can be extended to any other rules that are introduced.
        metadata_to_check = []

        if not hasattr(design, "mma_instruction_type"):
            raise ValueError(
                "Cannot determine supported targets with missing mma_instruction_type field in "
                f"design metadata: {design}"
            )
        mma_supported_targets = design.mma_instruction_type.supported_targets(
            design, operands
        )

        metadata_to_check.append(mma_supported_targets)

        # check against tile scheduler supported targets
        if hasattr(design, "tile_scheduler") and design.tile_scheduler:
            tile_scheduler_supported_targets = design.tile_scheduler.supported_targets(
                design, operands
            )
            metadata_to_check.append(tile_scheduler_supported_targets)
        return list(set.intersection(*map(set, metadata_to_check)))

    def is_portable_to(self, other: TargetSm | str) -> bool:
        """Check if this target can compile/run on architecture described by `other` TargetSm."""
        other = TargetSm.ensure(other)
        match self.portability:
            case ArchPortability.Portable:
                return self.cc <= other.cc
            case ArchPortability.FamilyPortable:
                return self.major == other.major and self.cc <= other.cc
            case ArchPortability.ArchConditional:
                return self == other
            case _:
                raise NotImplementedError

    def supports_operators_from(
        self, operator_targets: Iterable[TargetSm | str]
    ) -> bool:
        """Check if this target can compile/run operators designed for any of the given targets."""
        return any(
            TargetSm.ensure(target).is_portable_to(self) for target in operator_targets
        )

    @property
    def major(self) -> int:
        """Get the major version of the target SM."""
        return self.cc // 10

    @property
    def minor(self) -> int:
        """Get the minor version of the target SM."""
        return self.cc % 10

    @staticmethod
    def _parse_str(s: str) -> tuple[int, ArchPortability]:
        """Parse a compile target string (e.g., "100", "100a", "100f")."""
        portability_map = {
            "a": ArchPortability.ArchConditional,
            "f": ArchPortability.FamilyPortable,
        }

        suffix = s[-1]
        try:
            if suffix.isdigit():
                return (int(s), ArchPortability.Portable)
            return (int(s[:-1]), portability_map[suffix])
        except (ValueError, KeyError):
            raise ValueError(
                f"Invalid TargetSm: '{s}'. Expected form: '100', '100a', '100f'"
            ) from None

    def __str__(self) -> str:
        suffix = (
            self.portability.name[0].lower()
            if self.portability != ArchPortability.Portable
            else ""
        )
        return f"{self.cc}{suffix}"

    def __hash__(self) -> int:
        return hash((self.cc, self.portability))


class ArchPortability(enum.Enum):
    """Portability of a compiled Operator to other architectures/compute capabilities.

    See:
        https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html#feature-set-compiler-targets
    """

    Portable = enum_auto()
    """Portable to future architectures (e.g. sm_100 without "a" or "f")."""

    FamilyPortable = enum_auto()
    """Portable to future architectures within the same family (e.g. sm_100f).
    Only applicable to Blackwell and newer architectures (cc >= 100).
    """

    ArchConditional = enum_auto()
    """Not portable to any other architecture (e.g. sm_100a).
    Only applicable to Hopper and newer architectures (cc >= 90).
    """
