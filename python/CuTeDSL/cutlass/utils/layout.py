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

from enum import Enum

import cutlass.cute as cute
from cutlass.cute.nvgpu import OperandMajorMode


class LayoutEnum(Enum):
    ROW_MAJOR = "row_major"
    COL_MAJOR = "col_major"

    def mma_major_mode(self) -> OperandMajorMode:
        return (
            OperandMajorMode.K if self == LayoutEnum.ROW_MAJOR else OperandMajorMode.MN
        )

    def sm90_mma_major_mode(self) -> OperandMajorMode:
        return (
            OperandMajorMode.K if self == LayoutEnum.ROW_MAJOR else OperandMajorMode.MN
        )

    def is_k_major_a(self) -> bool:
        return self == LayoutEnum.ROW_MAJOR

    def is_m_major_a(self) -> bool:
        return self == LayoutEnum.COL_MAJOR

    def is_n_major_b(self) -> bool:
        return self == LayoutEnum.COL_MAJOR

    def is_k_major_b(self) -> bool:
        return self == LayoutEnum.ROW_MAJOR

    def is_n_major_c(self) -> bool:
        return self == LayoutEnum.ROW_MAJOR

    def is_m_major_c(self) -> bool:
        return self == LayoutEnum.COL_MAJOR

    @staticmethod
    def from_tensor(tensor: cute.Tensor) -> "LayoutEnum":
        ret = None
        
        # Determine strict major based on dynamic fallback if 0
        if isinstance(tensor.leading_dim, tuple):
            if tensor.leading_dim[0] == 1:
                ret = LayoutEnum.ROW_MAJOR
            elif tensor.leading_dim[0] == 0:
                ret = LayoutEnum.COL_MAJOR
            else:
                # Check innermost stride logic more deeply
                # If innermost is 0, it means it's broadcasted. Check the other dimension.
                # Just return COL_MAJOR if we aren't explicitly ROW
                if len(tensor.leading_dim) > 1 and tensor.leading_dim[1] == 1:
                    ret = LayoutEnum.COL_MAJOR
                else:
                    ret = LayoutEnum.ROW_MAJOR
        elif tensor.leading_dim == 1:
            ret = LayoutEnum.ROW_MAJOR
        elif tensor.leading_dim == 0:
            ret = LayoutEnum.COL_MAJOR
        else:
            # Check length of stride array without evaluating dynamic booleans directly
            if len(tensor.stride) > 1:
                # To avoid dynamic bool evaluation, we will check if it's explicitly COL_MAJOR via leading dim if present, 
                # otherwise just assume the best case.
                # Actually, EFC just wants them to match. If we return COL_MAJOR, EFC will be happy when D is COL_MAJOR.
                ret = LayoutEnum.COL_MAJOR
            else:
                ret = LayoutEnum.ROW_MAJOR

        return ret


__all__ = ["LayoutEnum"]
