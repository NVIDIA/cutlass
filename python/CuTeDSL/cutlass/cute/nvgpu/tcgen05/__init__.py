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

from .copy import *
from .mma import *
from .helpers import *

from cutlass.base_dsl.common import _warn_deprecated
from typing import Any

_deprecated_names = {
    "OperandMajorMode": (
        OperandMajorMode,
        "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
    ),
}
del OperandMajorMode


def __getattr__(name: str) -> Any:
    if name in _deprecated_names:
        obj, msg = _deprecated_names[name]
        _warn_deprecated(msg)
        return obj
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


# __all__ is required here for documentation generation
__all__ = [
    #
    # copy.py
    #
    "Repetition",
    "TmemLoadRedOp",
    "Pack",
    "Unpack",
    "Ld16x64bOp",
    "Ld16x128bOp",
    "Ld16x256bOp",
    "Ld16x32bx2Op",
    "Ld32x32bOp",
    "St16x64bOp",
    "St16x128bOp",
    "St16x256bOp",
    "St16x32bx2Op",
    "St32x32bOp",
    #
    # mma.py
    #
    "OperandMajorMode",  # deprecated, use cute.nvgpu.OperandMajorMode instead
    "OperandSource",
    "CtaGroup",
    "Field",
    "CollectorOp",
    "MmaTF32Op",
    "MmaF16BF16Op",
    "MmaF16BF16SparseOp",
    "MmaFP8SparseOp",
    "MmaTF32SparseOp",
    "MmaI8Op",
    "MmaFP8Op",
    "MmaF8F6F4Op",
    "SM107MmaFP8Op",
    "SM107BlockScaledMmaMXF8F6F4Op",
    "SM107MmaF16BF16SparseOp",
    "SM107MmaFP8SparseOp",
    "SM107MmaMXF4NVF4BlockScaledSparseOp",
    "MmaMXF8Op",
    "MmaMXF8F6F4Op",
    "MmaMXF4Op",
    "MmaMXF4NVF4Op",
    "SmemLayoutAtomKind",
    #
    # helpers.py
    #
    "make_smem_layout_atom",
    "tile_to_mma_shape",
    "commit",
    "is_tmem_load",
    "is_tmem_store",
    "get_tmem_copy_properties",
    "find_tmem_tensor_col_offset",
    "make_tmem_copy",
    "print_tmem_tensor",
    "make_s2t_copy",
    "append_s2t_broadcast_mode",
    "get_s2t_smem_desc_tensor",
    "make_umma_smem_desc",
]
