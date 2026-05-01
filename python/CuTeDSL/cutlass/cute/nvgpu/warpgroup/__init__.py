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

from .mma import *
from .helpers import *

import warnings as _warnings
from typing import Any

_deprecated_names = {
    "OperandMajorMode": (
        OperandMajorMode,
        "warpgroup.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
    ),
}
del OperandMajorMode


def __getattr__(name: str) -> Any:
    if name in _deprecated_names:
        obj, msg = _deprecated_names[name]
        _warnings.warn(msg, DeprecationWarning, stacklevel=2)
        return obj
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


# __all__ is required here for documentation generation
__all__ = [
    # mma.py
    "OperandMajorMode",  # deprecated, use cute.nvgpu.OperandMajorMode instead
    "OperandSource",
    "Field",
    "MmaF16BF16Op",
    "MmaF8Op",
    "SmemLayoutAtomKind",
    # helpers.py
    "make_smem_layout_atom",
    "fence",
    "commit_group",
    "wait_group",
]
