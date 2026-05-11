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

from typing import Optional

from cutlass import cute
from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import lir as cutlass_lir


@dsl_user_op
def dot_block_scaled(
    mma_atom: cute.MmaAtom,
    a: cute.Tensor,
    sfa: cute.Tensor,
    b: cute.Tensor,
    sfb: cute.Tensor,
    c: cute.Tensor,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    cutlass_lir.DotBlockScaledOp(
        mma_atom._unpack(),
        a.value,
        sfa.value,
        b.value,
        sfb.value,
        c.value,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def dot(
    mma_atom: cute.MmaAtom,
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    cutlass_lir.DotOp(
        mma_atom._unpack(),
        a.value,
        b.value,
        c.value,
        loc=loc,
        ip=ip,
    )


