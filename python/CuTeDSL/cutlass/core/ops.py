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


from typing import Optional, Union

from cutlass._mlir import ir
from cutlass._mlir.dialects import core as _core_ir
from cutlass.cute.core import _pack_coord
from cutlass.cute.tensor import _Tensor
from cutlass.cute.typing import Coord, Tensor as CuteTensor
from cutlass.cutlass_dsl import dsl_user_op

from .tensor import Tensor
__all__ = [
    "domain_offset",
]


@dsl_user_op
def domain_offset(
    tensor: Union[Tensor, CuteTensor],
    coord: Coord,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Tensor, CuteTensor]:
    """Shift a view's logical domain by ``coord``, keeping the same layout:
    reading the result at coord ``c`` refers to ``tensor`` at ``coord + c``.
    ``tensor`` may be a ``core.Tensor`` or a cute tensor over a ``cute.memref``;
    the returned wrapper matches the input kind.

    :param tensor: Source view (``core.Tensor`` or cute tensor).
    :param coord: Rank-matching coord describing the per-mode domain shift.
    """
    coord_value = _pack_coord(coord, loc=loc, ip=ip)
    result = _core_ir.DomainOffsetOp(tensor.value, coord_value, loc=loc, ip=ip).result
    # core.Tensor
    if isinstance(tensor, Tensor):
        return Tensor(result)
    # Rewrap preserving the element type for the cute tensor case.
    return _Tensor(result, dtype=tensor.element_type, loc=loc, ip=ip)


