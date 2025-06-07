# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import enum
from dataclasses import dataclass
from typing import Type

from cutlass.cutlass_dsl import CuTeDSL

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from ..common import OpError
from ...core import CopyOp, Trait
from ...typing import Numeric


class Repetition(enum.Enum):
    """
    An enumeration for the number of repetitions of a given TMEM copy within the instruction.
    """

    x1 = 1
    x2 = 2
    x4 = 4
    x8 = 8
    x16 = 16
    x32 = 32
    x64 = 64
    x128 = 128

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, int):
            if value == 1:
                return Repetition.x1
            elif value == 2:
                return Repetition.x2
            elif value == 8:
                return Repetition.x8
            elif value == 16:
                return Repetition.x16
            elif value == 32:
                return Repetition.x32
            elif value == 64:
                return Repetition.x64
            elif value == 128:
                return Repetition.x128


class Pack(enum.Enum):
    """
    An enumeration for the possible packing patterns for TMEM to RMEM copies.
    """

    NONE = enum.auto()
    PACK_16b_IN_32b = enum.auto()

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"


class Unpack(enum.Enum):
    """
    An enumeration for the possible unpacking patterns for RMEM to TMEM copies.
    """

    NONE = enum.auto()
    UNPACK_32b_IN_16b = enum.auto()

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"


@dataclass(frozen=True)
class _LdBase(CopyOp):
    repeat: Repetition = Repetition.x1
    pack: Pack = Pack.NONE

    admissible_archs = ["sm_100a"]

    def __post_init__(self) -> None:
        # Arch verification
        arch = CuTeDSL._get_dsl().envar.arch
        if arch not in self.admissible_archs:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

        if not isinstance(self.repeat, Repetition):
            raise OpError(
                self,
                "expects the 'repeat' Op parameter to be a tcgen05.Repetition instance",
            )
        if not isinstance(self.pack, Pack):
            raise OpError(
                self,
                "expects the 'pack' Op parameter to be a tcgen05.Pack instance",
            )

    def __str__(self) -> str:
        res = (
            f"tcgen05 {self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  number of repetitions = {self.repeat.value}"
        )
        if self.pack == Pack.PACK_16b_IN_32b:
            res += f"\n  with 2x 16-bit to 32b packing"
        return res


@dataclass(frozen=True)
class Ld16x64bOp(_LdBase):
    """
    16x64b TMEM load Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-ld>`__.
    This Operation corresponds to the ``.16x64b`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Ld16x64bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            64,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x64bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class Ld16x64bTrait(Trait):
    pass


@dataclass(frozen=True)
class Ld16x128bOp(_LdBase):
    """
    16x128b TMEM load Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-ld>`__.
    This Operation corresponds to the ``.16x128b`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.repeat == Repetition.x128:
            raise OpError(
                self,
                "x128 repetition is not supported",
                suggestion="choose one of x1, x2, x4, x8, x16, x32, x64",
            )

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Ld16x128bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            128,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x128bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class Ld16x128bTrait(Trait):
    pass


@dataclass(frozen=True)
class Ld16x256bOp(_LdBase):
    """
    16x256b TMEM load Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-ld>`__.
    This Operation corresponds to the ``.16x256b`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.repeat in (Repetition.x128, Repetition.x64):
            raise OpError(
                self,
                "x64 and x128 repetition is not supported",
                suggestion="choose one of x1, x2, x4, x8, x16, x32",
            )

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Ld16x256bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            256,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x256bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class Ld16x256bTrait(Trait):
    pass


@dataclass(frozen=True)
class Ld16x32bx2Op(_LdBase):
    """
    16x32bx2 TMEM load Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-ld>`__.
    This Operation corresponds to the ``.16x32bx2`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Ld16x32bx2Trait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x32bx2Trait(_cute_ir.atom(ty, loc=loc, ip=ip))


class Ld16x32bx2Trait(Trait):
    pass


@dataclass(frozen=True)
class Ld32x32bOp(_LdBase):
    """
    32x32b TMEM load Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-ld>`__.
    This Operation corresponds to the ``.32x32`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Ld32x32bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            32,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld32x32bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class Ld32x32bTrait(Trait):
    pass


@dataclass(frozen=True)
class _StBase(CopyOp):
    repeat: Repetition
    unpack: Unpack = Unpack.NONE

    admissible_archs = ["sm_100a"]

    def __post_init__(self) -> None:
        # Arch verification
        arch = CuTeDSL._get_dsl().envar.arch
        if arch not in self.admissible_archs:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

        if not isinstance(self.repeat, Repetition):
            raise OpError(
                self,
                "expects the 'repeat' Op parameter to be a tcgen05.Repetition instance",
            )
        if not isinstance(self.unpack, Unpack):
            raise OpError(
                self,
                "expects the 'pack' Op parameter to be a tcgen05.Unpack instance",
            )

    def __str__(self) -> str:
        res = (
            f"tcgen05 {self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  number of repetitions = {self.repeat.value}"
        )
        if self.unpack == Unpack.UNPACK_32b_IN_16b:
            res += f"\n  with 32-bit to 2x 16b unpacking"
        return res


@dataclass(frozen=True)
class St16x64bOp(_StBase):
    """
    16x64b TMEM store Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-st>`__.
    This Operation corresponds to the ``.16x64`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "St16x64bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            16,
            64,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St16x64bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class St16x64bTrait(Trait):
    pass


@dataclass(frozen=True)
class St16x128bOp(_StBase):
    """
    16x128b TMEM store Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-st>`__.
    This Operation corresponds to the ``.16x128`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.repeat == Repetition.x128:
            raise OpError(
                self,
                "x128 repetition is not supported",
                suggestion="choose one of x1, x2, x4, x8, x16, x32, x64",
            )

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "St16x128bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            16,
            128,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St16x128bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class St16x128bTrait(Trait):
    pass


@dataclass(frozen=True)
class St16x256bOp(_StBase):
    """
    16x256b TMEM store Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-st>`__.
    This Operation corresponds to the ``.16x256`` qualifier.
    """

    def __post_init__(self) -> None:
        super().__post_init__()
        if self.repeat in (Repetition.x128, Repetition.x64):
            raise OpError(
                self,
                "x64 and x128 repetition is not supported",
                suggestion="choose one of x1, x2, x4, x8, x16, x32",
            )

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "St16x256bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            16,
            256,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St16x256bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class St16x256bTrait(Trait):
    pass


@dataclass(frozen=True)
class St16x32bx2Op(_StBase):
    """
    16x32x2b TMEM store Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-st>`__.
    This Operation corresponds to the ``.16x32x2`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "St16x32bx2Trait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            16,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St16x32bx2Trait(_cute_ir.atom(ty, loc=loc, ip=ip))


class St16x32bx2Trait(Trait):
    pass


@dataclass(frozen=True)
class St32x32bOp(_StBase):
    """
    32x32b TMEM store Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-instructions-tcgen05-st>`__.
    This Operation corresponds to the ``.32x32`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "St32x32bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            32,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St32x32bTrait(_cute_ir.atom(ty, loc=loc, ip=ip))


class St32x32bTrait(Trait):
    pass
