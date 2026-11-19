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

from cutlass import base_dsl



def supports_report_valid(arch: base_dsl.Arch) -> bool:
    res = arch.is_family_of(base_dsl.Arch.sm_107f)
    return res



def supports_pzo_convert(arch: base_dsl.Arch) -> bool:
    res = arch.is_family_of(base_dsl.Arch.sm_107f)
    return res
