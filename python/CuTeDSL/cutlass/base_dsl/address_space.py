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

from enum import IntEnum


class AddressSpace(IntEnum):
    """Public CUTLASS address-space enum.

    Values match the CuTe MLIR dialect address-space encoding, but this enum is
    intentionally defined in Python so public APIs do not depend on a dialect
    binding object.
    """

    generic = 0
    gmem = 1
    smem = 3
    rmem = 5
    tmem = 6
    dsmem = 7
    cmem = 4
    def __str__(self) -> str:
        return self.name
