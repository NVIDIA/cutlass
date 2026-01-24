# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from cutlass.base_dsl.common import DSLRuntimeError


def version_checker(version: str) -> bool:
    """Check the version of the object file is compatible with the current dsl version or not."""
    if version not in ["1.0", "1.1"]:
        raise DSLRuntimeError("Incompatible version: " + version)
    return True
