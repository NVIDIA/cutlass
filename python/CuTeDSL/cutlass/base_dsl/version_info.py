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


from .common import (
    DSLCudaVersion,
    DSLVersion,
    DSLRuntimeError,
    _get_cuda_version,
    _get_dsl_version,
)

try:
    CUDA_VERSION = DSLCudaVersion(_get_cuda_version())
except Exception as e:
    raise DSLRuntimeError(
        "💥💥💥 Failed to get CUDA version 💥💥💥",
        cause=e,
        suggestion="Consider re-installing the package.",
    ) from e

try:
    DSL_VERSION = DSLVersion(_get_dsl_version())
except Exception as e:
    raise DSLRuntimeError(
        "💥💥💥 Failed to get DSL version 💥💥💥",
        cause=e,
        suggestion="Consider re-installing the package.",
    ) from e
