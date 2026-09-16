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

"""Compatibility exports for leaf utilities moved to ``base_dsl.utils``."""

from .utils.leaf_utils import (  # noqa: F401
    LeafInfo,
    TraversableLeafMixin,
    _flatten_to_ir_values,
    _get_all_attrs,
    _is_assignable_leaf,
    _is_dynamic_expression,
    _unflatten_ir_values,
    _unwrap_ir_value,
    gather_leaves,
    inject_leaves,
    is_frozen_dataclass,
    print_leaves_debug,
)

__all__ = [
    "LeafInfo",
    "TraversableLeafMixin",
    "gather_leaves",
    "inject_leaves",
    "is_frozen_dataclass",
    "print_leaves_debug",
]
