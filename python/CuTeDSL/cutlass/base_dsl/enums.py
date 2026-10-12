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

from collections.abc import Callable
from enum import Enum, IntEnum


class Arch(Enum):
    # sm_arch = (major, minor, suffix)
    # Ampere
    sm_80 = (8, 0, "")
    sm_86 = (8, 6, "")
    sm_87 = (8, 7, "")
    # Ada
    sm_89 = (8, 9, "")
    # Hopper
    sm_90 = (9, 0, "")
    sm_90a = (9, 0, "a")
    # Blackwell
    sm_100 = (10, 0, "")
    sm_100a = (10, 0, "a")
    sm_100f = (10, 0, "f")
    sm_110 = (11, 0, "")
    sm_110a = (11, 0, "a")
    sm_110f = (11, 0, "f")
    sm_101 = sm_110
    sm_101a = sm_110a
    sm_101f = sm_110f
    sm_103 = (10, 3, "")
    sm_103a = (10, 3, "a")
    sm_103f = (10, 3, "f")
    sm_107 = (10, 7, "")
    sm_107a = (10, 7, "a")
    sm_107f = (10, 7, "f")
    sm_120 = (12, 0, "")
    sm_120a = (12, 0, "a")
    sm_120f = (12, 0, "f")
    sm_121 = (12, 1, "")
    sm_121a = (12, 1, "a")
    sm_121f = (12, 1, "f")
    def __init__(self, major: int, minor: int, suffix: str) -> None:
        self.major = major
        self.minor = minor
        self.suffix = suffix

    # attributes to get arch list of specific families
    @classmethod
    def AmpereArchs(cls) -> tuple["Arch", ...]:
        return (Arch.sm_80, Arch.sm_86, Arch.sm_87)

    @classmethod
    def AdaArchs(cls) -> tuple["Arch", ...]:
        return (Arch.sm_89,)

    @classmethod
    def HopperArchs(cls) -> tuple["Arch", ...]:
        return (Arch.sm_90, Arch.sm_90a)

    @classmethod
    def BlackwellArchs(cls) -> tuple["Arch", ...]:
        archs = (
            Arch.sm_100,
            Arch.sm_100a,
            Arch.sm_100f,
            Arch.sm_101,
            Arch.sm_101a,
            Arch.sm_101f,
            Arch.sm_103,
            Arch.sm_103a,
            Arch.sm_103f,
            Arch.sm_107,
            Arch.sm_107a,
            Arch.sm_107f,
            Arch.sm_110,
            Arch.sm_110a,
            Arch.sm_110f,
            Arch.sm_120,
            Arch.sm_120a,
            Arch.sm_120f,
            Arch.sm_121,
            Arch.sm_121a,
            Arch.sm_121f,
        )
        return tuple(dict.fromkeys(archs))

    @classmethod
    def RubinArchs(cls) -> tuple["Arch", ...]:
        return (
            Arch.sm_107,
            Arch.sm_107a,
            Arch.sm_107f,
        )

    def __str__(self) -> str:
        return self.name

    def __repr__(self) -> str:
        return f"base_dsl.Arch.{self.name}"

    @classmethod
    def from_string(cls, arch_str: str) -> "Arch":
        return cls[arch_str]

    def to_string(self) -> str:
        return self.name

    @classmethod
    def filter(cls, criterion: Callable[["Arch"], bool]) -> list["Arch"]:
        """
        Filter the archs by the given criterion.
        """
        return [arch for arch in cls if criterion(arch)]

    def is_family_of(self, arch: "Arch") -> bool:
        """
        Check if this arch is equal or higher in the same family than the given arch, so that the family-specific features can be used.

        Example:

        .. code-block:: python

            >>> arch = Arch.sm_103f
            >>> arch.is_family_of(Arch.sm_100f)
            True

        """

        return (
            self.major == arch.major
            and self.minor >= arch.minor
            and self.suffix in ["a", "f"]
        )

    def can_run_binary_built_for(self, target: "Arch") -> bool:
        """Whether hardware of this (runtime) arch can execute a cubin built for ``target``.

        Arch-conditional targets (``a`` suffix, e.g. ``sm_100a``) run only on their exact
        arch. Family-portable (``f``) and baseline (no suffix) targets run on any hardware
        in the same major family whose minor is at least the target's minor (e.g. an
        ``sm_100f`` binary runs on ``sm_100a`` and ``sm_103a``).
        """
        if self == target:
            return True
        if self.major != target.major:
            return False
        if target.suffix == "a":
            return self == target
        return self.minor >= target.minor

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) < (other.major, other.minor)

    def __le__(self, other: object) -> bool:
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) <= (other.major, other.minor)

    def __gt__(self, other: object) -> bool:
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) > (other.major, other.minor)

    def __ge__(self, other: object) -> bool:
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) >= (other.major, other.minor)


class AddressSpace(IntEnum):
    """Public CUTLASS address-space enum.

    Values match the CuTe MLIR dialect address-space encoding, but this enum is
    intentionally defined in Python so public APIs do not depend on a dialect
    binding object.
    """

    generic = 0
    gmem = 1
    smem = 3
    rmem = 5
    tmem = 6
    dsmem = 7
    cmem = 4
    def __str__(self) -> str:
        return self.name


__all__ = ["AddressSpace", "Arch"]
