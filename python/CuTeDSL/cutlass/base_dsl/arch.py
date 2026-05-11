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
from enum import Enum, EnumMeta
import re
from typing import Any


class ArchMeta(EnumMeta):
    """
    Custom metaclass for Arch enum that supports dynamic aliases based on CUDA version.

    - If cuda_version >= 13.0: sm_101/sm_101a/sm_101f are aliases of sm_110/sm_110a/sm_110f, use sm_110 as the canonical name
    - Otherwise: sm_110/sm_110a/sm_110f are aliases of sm_101/sm_101a/sm_101f, use sm_101 as the canonical name
    """

    _arch_aliases: dict[str, str] = {}

    def __new__(
        mcs, name: str, bases: tuple[type, ...], namespace: dict[str, Any]
    ) -> "ArchMeta":
        cls = super().__new__(mcs, name, bases, namespace)  # type: ignore[arg-type]
        from .version_info import CUDA_VERSION

        if CUDA_VERSION.major >= 13:
            # sm_101 -> sm_110, use sm_110 as the canonical name
            mcs._arch_aliases = {
                "sm_101": "sm_110",
                "sm_101a": "sm_110a",
                "sm_101f": "sm_110f",
            }
        else:
            # sm_110 -> sm_101, use sm_101 as the canonical name
            mcs._arch_aliases = {
                "sm_110": "sm_101",
                "sm_110a": "sm_101a",
                "sm_110f": "sm_101f",
            }
        return cls

    def __getattribute__(cls, name: str) -> Any:
        # Use type.__getattribute__ to avoid recursion when accessing _arch_aliases
        aliases = type.__getattribute__(cls, "_arch_aliases")
        if name in aliases:
            # Redirect to the target member
            return type.__getattribute__(cls, aliases[name])
        return super().__getattribute__(name)

    def __getitem__(cls, name: str) -> "Arch":  # type: ignore[override]
        # Support Arch["sm_101"] style access
        if name in cls._arch_aliases:
            return super().__getitem__(cls._arch_aliases[name])
        return super().__getitem__(name)


class Arch(Enum, metaclass=ArchMeta):
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
    sm_101 = (10, 1, "")
    sm_101a = (10, 1, "a")
    sm_101f = (10, 1, "f")
    sm_103 = (10, 3, "")
    sm_103a = (10, 3, "a")
    sm_103f = (10, 3, "f")
    sm_110 = (11, 0, "")
    sm_110a = (11, 0, "a")
    sm_110f = (11, 0, "f")
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
        return (
            Arch.sm_100,
            Arch.sm_100a,
            Arch.sm_100f,
            Arch.sm_101,
            Arch.sm_101a,
            Arch.sm_101f,
            Arch.sm_103,
            Arch.sm_103a,
            Arch.sm_103f,
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

    def __str__(self) -> str:
        return self.name

    def __repr__(self) -> str:
        return f"Arch.{self.name}"

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
        # sm_101 is renamed to sm_110, sm_101f is family of sm_110f, but is not family of sm_100f
        if self in [Arch.sm_101a, Arch.sm_101f]:
            return arch.major == 11 and arch.minor >= 0

        return (
            self.major == arch.major
            and self.minor >= arch.minor
            and self.suffix in ["a", "f"]
        )

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
