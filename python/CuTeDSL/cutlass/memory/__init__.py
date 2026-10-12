# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""On-chip memory allocation building blocks for kernel authoring:
shared memory (SMEM) and tensor memory (TMEM) allocators.
"""

from .smem import (
    SmemAllocator,
    SmemPartition,
    get_kernel_smem_size,
    get_smem_capacity_in_bytes,
)
from .tmem import (
    TmemAllocator,
    TmemBufferPool,
    compute_tmem_cols_from_layout,
    get_num_tmem_alloc_cols,
)

__all__ = [
    "SmemAllocator",
    "SmemPartition",
    "get_kernel_smem_size",
    "get_smem_capacity_in_bytes",
    "TmemAllocator",
    "TmemBufferPool",
    "compute_tmem_cols_from_layout",
    "get_num_tmem_alloc_cols",
]
