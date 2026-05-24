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

"""Constants for SM120 MXF4/NVFP4 GEMM helpers."""

from typing import Literal

AbSmemFormat = Literal["packed", "unpack"]

MXF4NVF4_CTA_SHAPE_MNK = (128, 128, 128)
MXF4NVF4_MMA_SHAPE_MNK = (16, 8, 64)
MXF4NVF4_SCALE_VEC_SIZE = 16
MXF4NVF4_SCALE_K = MXF4NVF4_CTA_SHAPE_MNK[2] // MXF4NVF4_SCALE_VEC_SIZE
MXF4NVF4_SCALE_TMA_MIN_L = 2

# Packed-path fixed CTA transaction sizes. Use mxf4nvf4_*_tma_bytes()
# when the A/B SMEM format is configurable.
MXF4NVF4_AB_TMA_BYTES = (
    MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_CTA_SHAPE_MNK[2] // 2
)
MXF4NVF4_SCALE_TMA_BYTES = MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_SCALE_K
MXF4NVF4_FULL_TMA_BYTES = 2 * MXF4NVF4_AB_TMA_BYTES + 2 * MXF4NVF4_SCALE_TMA_BYTES


def mxf4nvf4_ab_tma_bytes(ab_smem_format: AbSmemFormat = "packed") -> int:
    """Return one SM120 MXF4/NVFP4 A or B TMA transaction size in bytes."""
    major_extent = MXF4NVF4_CTA_SHAPE_MNK[0]
    tile_k = MXF4NVF4_CTA_SHAPE_MNK[2]
    if ab_smem_format == "packed":
        return major_extent * tile_k // 2
    if ab_smem_format == "unpack":
        return major_extent * tile_k
    raise ValueError(f"unsupported ab_smem_format: {ab_smem_format!r}")


def mxf4nvf4_full_tma_bytes(ab_smem_format: AbSmemFormat = "packed") -> int:
    """Return the total fixed microtile TMA transaction size in bytes."""
    return 2 * mxf4nvf4_ab_tma_bytes(ab_smem_format) + 2 * MXF4NVF4_SCALE_TMA_BYTES


__all__ = [
    "AbSmemFormat",
    "MXF4NVF4_CTA_SHAPE_MNK",
    "MXF4NVF4_FULL_TMA_BYTES",
    "MXF4NVF4_MMA_SHAPE_MNK",
    "MXF4NVF4_SCALE_K",
    "MXF4NVF4_SCALE_TMA_MIN_L",
    "MXF4NVF4_SCALE_TMA_BYTES",
    "MXF4NVF4_SCALE_VEC_SIZE",
    "mxf4nvf4_ab_tma_bytes",
    "mxf4nvf4_full_tma_bytes",
]
