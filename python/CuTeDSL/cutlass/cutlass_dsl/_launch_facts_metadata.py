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

"""Shared IR metadata contract for private CuTe launch-fact providers.

The launch backend and provider-facing CuTe API both consume this attribute.
Keeping its wire names and schema version here prevents the producer and
consumer from drifting without introducing a ``cutlass_dsl``/``cutlass.cute``
import cycle.
"""

from cutlass._mlir import ir


# CUDA launch dimensions occupy unsigned 32-bit fields.
CUDA_LAUNCH_DIM_MAX = (1 << 32) - 1

LAUNCH_FACTS_SCHEMA_VERSION = 1
LAUNCH_FACTS_SCHEMA_VERSION_FIELD = "schema_version"

LAUNCH_FACTS_ATTR = "cutlass_launch_facts"
EXACT_BLOCK_DIM_FIELD = "exact_block_dim"
EXACT_GRID_DIM_FIELD = "exact_grid_dim"
EXACT_CLUSTER_DIM_FIELD = "exact_cluster_dim"
COOPERATIVE_LAUNCH_FIELD = "cooperative_launch"
CLUSTER_LAUNCH_FIELD = "cluster_launch"


def int64_attr(value: int) -> ir.IntegerAttr:
    """Build the signed-width-neutral integer attribute used by the contract."""

    return ir.IntegerAttr.get(ir.IntegerType.get_signless(64), value)
