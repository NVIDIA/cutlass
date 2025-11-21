# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from enum import Enum
import re
from typing import Callable, List, Tuple


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
    sm_101 = (10, 1, "")
    sm_101a = (10, 1, "a")
    sm_101f = (10, 1, "f")
    sm_110 = (11, 0, "")
    sm_110a = (11, 0, "a")
    sm_110f = (11, 0, "f")
    sm_120 = (12, 0, "")
    sm_120a = (12, 0, "a")
    sm_120f = (12, 0, "f")
    sm_121 = (12, 1, "")
    sm_121a = (12, 1, "a")
    sm_121f = (12, 1, "f")

    def __init__(self, major, minor, suffix):
        self.major = major
        self.minor = minor
        self.suffix = suffix

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, tuple) and len(value) == 2:
            # Support creating Arch enum from (major, minor) tuple
            # Arch(major, minor) is equivalent to Arch(major, minor, "")
            major, minor, suffix = *value, ""
            return cls((major, minor, suffix))
        else:
            raise ValueError(f"invalid arguments for Arch: {value}")
        

    # attributes to get arch list of specific families
    @classmethod
    def AmpereArchs(cls) -> Tuple["Arch"]:
        return (Arch.sm_80, Arch.sm_86, Arch.sm_87)

    @classmethod
    def AdaArchs(cls) -> Tuple["Arch"]:
        return (Arch.sm_89,)

    @classmethod
    def HopperArchs(cls) -> Tuple["Arch"]:
        return (Arch.sm_90, Arch.sm_90a)

    @classmethod
    def BlackwellArchs(cls) -> Tuple["Arch"]:
        return (
            Arch.sm_100,
            Arch.sm_100a,
            Arch.sm_100f,
            Arch.sm_101,
            Arch.sm_101a,
            Arch.sm_101f,
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

    def __repr__(self):
        return self.__str__()

    @classmethod
    def from_string(cls, arch_str):
        pattern = r"^(?:sm_?|SM_?)?(\d+)(\d)([af]?)$"
        match = re.match(pattern, arch_str)
        if not match:
            raise ValueError(f"Invalid architecture string format: {arch_str}")
        major, minor, suffix = match.groups()
        return cls((int(major), int(minor), suffix))

    @classmethod
    def filter(cls, criterion: Callable[["Arch"], bool]) -> List["Arch"]:
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
            return arch.major == 11 and arch.minor == 0

        return (
            self.major == arch.major
            and self.minor >= arch.minor
            and self.suffix in ["a", "f"]
        )

    def __lt__(self, other):
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) < (other.major, other.minor)

    def __le__(self, other):
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) <= (other.major, other.minor)

    def __gt__(self, other):
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) > (other.major, other.minor)

    def __ge__(self, other):
        if not isinstance(other, Arch):
            return NotImplemented
        return (self.major, self.minor) >= (other.major, other.minor)
