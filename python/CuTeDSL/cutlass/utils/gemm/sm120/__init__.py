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

"""Narrow SM120 MXF4/NVFP4 GEMM helper API."""

from .constants import (
    MXF4NVF4_CTA_SHAPE_MNK,
    MXF4NVF4_MMA_SHAPE_MNK,
    MXF4NVF4_SCALE_TMA_BYTES,
    MXF4NVF4_SCALE_VEC_SIZE,
    mxf4nvf4_ab_tma_bytes,
    mxf4nvf4_full_tma_bytes,
)
from .layouts import (
    make_mxf4nvf4_a_gmem_layout,
    make_mxf4nvf4_ab_tma_physical_layout_staged,
    make_mxf4nvf4_b_gmem_layout,
    make_mxf4nvf4_native_tma_smem_views,
    make_mxf4nvf4_scale_interleaved_gmem_layout,
    make_mxf4nvf4_scale_interleaved_tma_layout_staged,
    make_mxf4nvf4_tiled_mma,
)
from .tma import make_mxf4nvf4_native_tma_atoms
from .validation import mxf4nvf4_can_implement, validate_mxf4nvf4_gemm_config

__all__ = [
    "MXF4NVF4_CTA_SHAPE_MNK",
    "MXF4NVF4_MMA_SHAPE_MNK",
    "MXF4NVF4_SCALE_TMA_BYTES",
    "MXF4NVF4_SCALE_VEC_SIZE",
    "make_mxf4nvf4_native_tma_atoms",
    "make_mxf4nvf4_native_tma_smem_views",
    "make_mxf4nvf4_a_gmem_layout",
    "make_mxf4nvf4_ab_tma_physical_layout_staged",
    "make_mxf4nvf4_b_gmem_layout",
    "make_mxf4nvf4_scale_interleaved_gmem_layout",
    "make_mxf4nvf4_scale_interleaved_tma_layout_staged",
    "make_mxf4nvf4_tiled_mma",
    "mxf4nvf4_ab_tma_bytes",
    "mxf4nvf4_can_implement",
    "mxf4nvf4_full_tma_bytes",
    "validate_mxf4nvf4_gemm_config",
]
