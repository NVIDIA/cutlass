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

from dataclasses import dataclass
from typing import Type

import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from ..common import OpError
from ...core import _pack_shape
from ...typing import Numeric, Optional
from ...atom import CopyOp, Trait, make_atom


@dataclass(frozen=True)
class BaseOp(CopyOp):
    transpose: bool = False
    num_matrices: int = 1
    unpack_bits: Optional[int] = None

    def __post_init__(self) -> None:
        if not isinstance(self.transpose, bool):
            raise OpError(
                self,
                "expects the 'transpose' Op parameter to be a bool instance",
            )

    def __str__(self) -> str:
        res = (
            f"{self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  number of matrices = {self.num_matrices}"
        )
        if self.transpose:
            res += "\n  transposed"
        if self.unpack_bits is not None:
            res += f"\n  unpack {self.unpack_bits}b to 8b"
        return res


@dataclass(frozen=True)
class LdMatrix8x8x16bOp(BaseOp):
    """
    8x8 ``ldmatrix`` Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-load-instruction-ldmatrix>`__.
    This operation corresponds to the ``.m8n8`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.num_matrices not in [1, 2, 4]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [1,2,4]",
            )
        if self.unpack_bits is not None:
            raise OpError(self, "Op doesn't support unpacking")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "LdMatrix8x8x16bTrait":
        mode = _pack_shape((8, 8), loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.CopyAtomLdsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            _cute_nvgpu_ir.LdsmSzPattern.u16,
            self.num_matrices,
            ir.UnitAttr.get() if self.transpose else None,
        )
        return LdMatrix8x8x16bTrait(make_atom(ty, loc=loc, ip=ip))


class LdMatrix8x8x16bTrait(Trait):
    pass


@dataclass(frozen=True)
class LdMatrix8x16x8bOp(BaseOp):
    """
    8x16 ``ldmatrix`` Operation with unpacking to 8b container.
    Packed source container is 16x4b elements with 64b padding
    or 16x6b elements with 32b padding (total 128b per 16 elements)

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-load-instruction-ldmatrix>`__.
    This operation corresponds to the ``.m8n16`` and the ``.b4x16_p64``, ``.b6x16_p32`` qualifiers.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.transpose:
            raise OpError(self, "Op doesn't support transpose")
        if self.num_matrices not in [1, 2, 4]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [1,2,4]",
            )
        if self.unpack_bits not in [None, 4, 6]:
            raise OpError(self, "Op unpack bits must be 4 or 6 or None")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "LdMatrix8x16x8bTrait":
        # LdMatrix8x16x8b without unpacking doesn't exist
        # but is equivalent to LdMatrix8x8x16b
        mode_n = 8 if self.unpack_bits is None else 16
        mode = _pack_shape((8, mode_n), loc=loc, ip=ip)
        sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u16
        if self.unpack_bits == 4:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u4x16p64to8
        elif self.unpack_bits == 6:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u6x16p32to8
        ty = _cute_nvgpu_ir.CopyAtomLdsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            sz_pattern,
            self.num_matrices,
            None,
        )
        return LdMatrix8x16x8bTrait(make_atom(ty, loc=loc, ip=ip))


class LdMatrix8x16x8bTrait(Trait):
    pass


@dataclass(frozen=True)
class LdMatrix16x8x8bOp(BaseOp):
    """
    16x8 8b ``ldmatrix`` Operation with transpose

    There is no direct PTX correspondance to this Op.
    This actually lowers to ldmatrix with the ``.m16n16`` qualifier and
    additional address and value permutations to match stmatrix.m16n8.trans.
    Useful for vectorizing with Ampere-style 8x8 matrix thread-value layouts
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if not self.transpose:
            raise OpError(self, "Op only supports transpose")
        if self.num_matrices not in [2, 4]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [2,4]",
            )
        if self.unpack_bits not in [None, 4, 6]:
            raise OpError(self, "Op unpack bits must be 4 or 6 or None")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "LdMatrix16x8x8bTrait":
        mode = _pack_shape((16, 8), loc=loc, ip=ip)
        sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u8
        if self.unpack_bits == 4:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u4x16p64to8
        elif self.unpack_bits == 6:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u6x16p32to8
        ty = _cute_nvgpu_ir.CopyAtomLdsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            sz_pattern,
            self.num_matrices,
            ir.UnitAttr.get(),
        )
        return LdMatrix16x8x8bTrait(make_atom(ty, loc=loc, ip=ip))


class LdMatrix16x8x8bTrait(Trait):
    pass


@dataclass(frozen=True)
class LdMatrix16x16x8bOp(BaseOp):
    """
    16x16 ``ldmatrix`` Operation with transpose and optional unpacking to 8b container.
    Packed source container is 16x4b elements with 64b padding
    or 16x6b elements with 32b padding (total 128b per 16 elements)

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-load-instruction-ldmatrix>`__.
    This operation corresponds to the ``.m16n16`` and the ``.b4x16_p64``,``.b6x16_p32``,``.b8`` qualifiers.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if not self.transpose:
            raise OpError(self, "Op only supports transpose")
        if self.num_matrices not in [1, 2]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [1,2]",
            )
        if self.unpack_bits not in [None, 4, 6]:
            raise OpError(self, "Op unpack bits must be 4 or 6 or None")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "LdMatrix16x16x8bTrait":
        mode = _pack_shape((16, 16), loc=loc, ip=ip)
        sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u8
        if self.unpack_bits == 4:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u4x16p64to8
        elif self.unpack_bits == 6:
            sz_pattern = _cute_nvgpu_ir.LdsmSzPattern.u6x16p32to8
        ty = _cute_nvgpu_ir.CopyAtomLdsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            sz_pattern,
            self.num_matrices,
            ir.UnitAttr.get(),
        )
        return LdMatrix16x16x8bTrait(make_atom(ty, loc=loc, ip=ip))


class LdMatrix16x16x8bTrait(Trait):
    pass


@dataclass(frozen=True)
class StMatrix8x8x16bOp(BaseOp):
    """
    8x8 ``stmatrix`` Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-stmatrix>`__.
    This operation corresponds to the ``m8n8`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.num_matrices not in [1, 2, 4]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [1,2,4]",
            )
        if self.unpack_bits is not None:
            raise OpError(self, "Op doesn't support unpacking")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "StMatrix8x8x16bTrait":
        mode = _pack_shape((8, 8), loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.CopyAtomStsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            self.num_matrices,
            ir.UnitAttr.get() if self.transpose else None,
        )
        return StMatrix8x8x16bTrait(make_atom(ty, loc=loc, ip=ip))


class StMatrix8x8x16bTrait(Trait):
    pass


@dataclass(frozen=True)
class StMatrix16x8x8bOp(BaseOp):
    """
    16x8 ``stmatrix`` Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-stmatrix>`__.
    This operation corresponds to the ``m16n8`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if not self.transpose:
            raise OpError(self, "Op only supports transpose")
        if self.num_matrices not in [1, 2, 4]:
            raise OpError(
                self,
                "expects the 'num_matrices' Op parameter to be one of [1,2,4]",
            )
        if self.unpack_bits is not None:
            raise OpError(self, "Op doesn't support unpacking")

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "StMatrix16x8x8bTrait":
        mode = _pack_shape((16, 8), loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.CopyAtomStsmType.get(
            copy_internal_type.mlir_type,
            mode.type.attribute,
            self.num_matrices,
            ir.UnitAttr.get(),
        )
        return StMatrix16x8x8bTrait(make_atom(ty, loc=loc, ip=ip))


class StMatrix16x8x8bTrait(Trait):
    pass
