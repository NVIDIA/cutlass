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

import functools
import warnings
from typing import Any

from typing_extensions import deprecated

from cutlass.memory import SmemAllocator as _SmemAllocator
from cutlass.memory import get_kernel_smem_size as _get_kernel_smem_size
from cutlass.memory import (
    get_smem_capacity_in_bytes as _get_smem_capacity_in_bytes,
)


@deprecated(
    "cutlass.utils.smem_allocator.SmemAllocator is deprecated; use "
    "cutlass.memory.SmemAllocator instead. It will be removed in a future release."
)
class SmemAllocator(_SmemAllocator):
    """Deprecated alias for `cutlass.memory.smem.SmemAllocator`."""

    @staticmethod
    @functools.wraps(_SmemAllocator.capacity_in_bytes)
    def capacity_in_bytes(*args: Any, **kwargs: Any) -> Any:
        warnings.warn(
            "cutlass.utils.smem_allocator.SmemAllocator.capacity_in_bytes is "
            "deprecated; use cutlass.memory.SmemAllocator.capacity_in_bytes "
            "instead. It will be removed in a future release.",
            DeprecationWarning,
            stacklevel=2,
        )
        return _SmemAllocator.capacity_in_bytes(*args, **kwargs)


@deprecated(
    "cutlass.utils.smem_allocator.get_kernel_smem_size is deprecated; use "
    "cutlass.memory.get_kernel_smem_size instead. It will be removed in a future "
    "release."
)
@functools.wraps(_get_kernel_smem_size)
def get_kernel_smem_size(*args: Any, **kwargs: Any) -> Any:
    return _get_kernel_smem_size(*args, **kwargs)


@deprecated(
    "cutlass.utils.smem_allocator.get_smem_capacity_in_bytes is deprecated; use "
    "cutlass.memory.get_smem_capacity_in_bytes instead. It will be removed in a "
    "future release."
)
@functools.wraps(_get_smem_capacity_in_bytes)
def get_smem_capacity_in_bytes(*args: Any, **kwargs: Any) -> Any:
    return _get_smem_capacity_in_bytes(*args, **kwargs)


# SmemPartition members compare by object identity and SMEM_CAPACITY_MAP is a
# plain dict, so neither can be handed out as a @deprecated wrapper copy. A
# module-level __getattr__ (PEP 562) adds the deprecation warning instead.
def __getattr__(name: str) -> Any:
    if name == "SmemPartition":
        warnings.warn(
            "cutlass.utils.smem_allocator.SmemPartition is deprecated; use "
            "cutlass.memory.SmemPartition instead. It will be removed in a future "
            "release.",
            DeprecationWarning,
            stacklevel=2,
        )
        from cutlass.memory import SmemPartition

        return SmemPartition
    if name == "SMEM_CAPACITY_MAP":
        warnings.warn(
            "cutlass.utils.smem_allocator.SMEM_CAPACITY_MAP is deprecated; use "
            "cutlass.memory.get_smem_capacity_in_bytes instead. It will be removed "
            "in a future release.",
            DeprecationWarning,
            stacklevel=2,
        )
        from cutlass.cutlass_dsl import SMEM_CAPACITY_MAP

        return SMEM_CAPACITY_MAP
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "SMEM_CAPACITY_MAP",  # noqa: F822  # provided by module __getattr__
    "SmemAllocator",
    "SmemPartition",  # noqa: F822  # provided by module __getattr__
    "get_kernel_smem_size",
    "get_smem_capacity_in_bytes",
]
