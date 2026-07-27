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


# MMA operands passed to `dot` / `dot_block_scaled` / ... must follow
# the CuTe fragment contract `(MMA, REST_M, REST_K)` (rank >= 3), same as
# the underlying `cute.gemm`. Partitioning an MMA tile often yields rank-2
# A/B slices, so callers historically had to sprinkle
# `cute.append_ones(..., up_to_rank=3)` at every call site. We do that here
# so the user doesn't have to. Already-rank-3 (or higher) tensors pass
# through unchanged.
def _ensure_rank3(
    t: cute.Tensor,
    loc: Optional[ir.Location],
    ip: Optional[ir.InsertionPoint],
) -> cute.Tensor:
    if cute.rank(t) < 3:
        t = cute.append_ones(t, up_to_rank=3, loc=loc, ip=ip)
    return t


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
    a = _ensure_rank3(a, loc, ip)
    b = _ensure_rank3(b, loc, ip)
    sfa = _ensure_rank3(sfa, loc, ip)
    sfb = _ensure_rank3(sfb, loc, ip)
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
    a = _ensure_rank3(a, loc, ip)
    b = _ensure_rank3(b, loc, ip)
    cutlass_lir.DotOp(
        mma_atom._unpack(),
        a.value,
        b.value,
        c.value,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def dot_sparse(
    mma_atom: cute.MmaAtom,
    a: cute.Tensor,
    e: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Emit a sparse MMA operation.

    :param mma_atom: Regular sparse MMA atom. The op derives the metadata
        operand expected by the atom from ``e`` during lowering.
    :param a: Sparse A operand partitioned as rank-3 ``(V, Rest, K)``.
    :param e: Sparse metadata operand partitioned as rank-3 ``(V, Rest, K)``.
    :param b: Dense B operand partitioned as rank-3 ``(V, Rest, K)``.
    :param c: Accumulator/result operand.
    :param loc: Optional MLIR location.
    :param ip: Optional MLIR insertion point.
    """
    a = _ensure_rank3(a, loc, ip)
    e = _ensure_rank3(e, loc, ip)
    b = _ensure_rank3(b, loc, ip)
    cutlass_lir.DotSparseOp(
        mma_atom._unpack(),
        a.value,
        e.value,
        b.value,
        c.value,
        loc=loc,
        ip=ip,
    )


