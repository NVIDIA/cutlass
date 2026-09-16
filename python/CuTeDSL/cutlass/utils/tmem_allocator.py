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
from typing import Any

from typing_extensions import deprecated

from cutlass.memory import TmemAllocator as _TmemAllocator
from cutlass.memory import TmemBufferPool as _TmemBufferPool
from cutlass.memory import (
    compute_tmem_cols_from_layout as _compute_tmem_cols_from_layout,
)
from cutlass.memory import (
    get_num_tmem_alloc_cols as _get_num_tmem_alloc_cols,
)


@deprecated(
    "cutlass.utils.tmem_allocator.TmemAllocator is deprecated; use "
    "cutlass.memory.TmemAllocator instead. It will be removed in a future release."
)
class TmemAllocator(_TmemAllocator):
    """Deprecated alias for `cutlass.memory.tmem.TmemAllocator`."""


@deprecated(
    "cutlass.utils.tmem_allocator.TmemBufferPool is deprecated; use "
    "cutlass.memory.TmemBufferPool instead. It will be removed in a future release."
)
class TmemBufferPool(_TmemBufferPool):
    """Deprecated alias for `cutlass.memory.tmem.TmemBufferPool`."""


@deprecated(
    "cutlass.utils.tmem_allocator.compute_tmem_cols_from_layout is deprecated; use "
    "cutlass.memory.compute_tmem_cols_from_layout instead. It will be removed in a "
    "future release."
)
@functools.wraps(_compute_tmem_cols_from_layout)
def compute_tmem_cols_from_layout(*args: Any, **kwargs: Any) -> Any:
    return _compute_tmem_cols_from_layout(*args, **kwargs)


@deprecated(
    "cutlass.utils.tmem_allocator.get_num_tmem_alloc_cols is deprecated; use "
    "cutlass.memory.get_num_tmem_alloc_cols instead. It will be removed in a future "
    "release."
)
@functools.wraps(_get_num_tmem_alloc_cols)
def get_num_tmem_alloc_cols(*args: Any, **kwargs: Any) -> Any:
    return _get_num_tmem_alloc_cols(*args, **kwargs)


__all__ = [
    "TmemAllocator",
    "TmemBufferPool",
    "compute_tmem_cols_from_layout",
    "get_num_tmem_alloc_cols",
]
