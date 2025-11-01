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

from cutlass import cute
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import CuTeDSL

import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from ..common import OpError
from ...atom import CopyOp, Trait
from ...typing import Numeric

from .mma import CtaGroup


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
    """
    Base class for TMEM load operations in the tcgen05 instruction set.

    This abstract base class provides common functionality and validation for tensor memory (TMEM)
    load operations. It defines the fundamental parameters and architecture constraints that apply
    to all load operation variants.

    :param repeat: Number of repetitions for the load operation, defaults to Repetition.x1
    :type repeat: Repetition, optional
    :param pack: Packing pattern for TMEM to RMEM copies, defaults to Pack.NONE
    :type pack: Pack, optional
    :raises OpError: If the current architecture is not supported or if invalid parameters are provided
    """

    repeat: Repetition = Repetition.x1
    pack: Pack = Pack.NONE

    admissible_archs = Arch.filter(
        lambda arch: arch.is_family_of(Arch.sm_100f) or arch.is_family_of(Arch.sm_110f)
    )

    def __post_init__(self) -> None:
        """
        Post-initialization validation for TMEM load operations.

        Performs comprehensive validation of operation parameters and architecture compatibility.
        This method is automatically called after object creation to ensure all constraints are met.

        :raises OpError: If architecture is not supported
        :raises OpError: If repeat parameter is not a Repetition instance
        :raises OpError: If pack parameter is not a Pack instance
        """
        # Arch verification
        arch = CuTeDSL._get_dsl().get_arch_enum()
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
        """
        Generate a human-readable string representation of the load operation.

        Creates a formatted description showing the operation type, repetition count,
        and any special packing configuration.

        :return: Multi-line string describing the operation configuration
        :rtype: str
        """
        res = (
            f"tcgen05 {self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  number of repetitions = {self.repeat.value}"
        )
        if self.pack == Pack.PACK_16b_IN_32b:
            res += "\n  with 2x 16-bit to 32b packing"
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
        """
        Create a trait object for the 16x64b TMEM load operation.

        Constructs an MLIR-based trait that encapsulates the specific parameters and
        characteristics of this load operation. The trait is used by the compiler
        infrastructure to generate the appropriate low-level code.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments passed to the trait constructor
        :type kwargs: dict
        :return: A trait object that represents this specific load operation
        :rtype: Ld16x64bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            64,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x64bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        """
        Additional validation specific to 16x128b load operations.

        Extends the base class validation with operation-specific constraints.
        The 16x128b operation has limitations on the maximum repetition count due to
        hardware register and bandwidth constraints.

        :raises OpError: If x128 repetition is specified
        """
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
        """
        Create a trait object for the 16x128b TMEM load operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this load operation
        :rtype: Ld16x128bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            128,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x128bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        """
        Additional validation specific to 16x256b load operations.

        Extends the base class validation with operation-specific constraints.
        The 16x256b operation has more restrictive limitations on repetition count due to
        the larger data size per operation requiring more hardware resources.

        :raises OpError: If x64 or x128 repetition is specified
        """
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
        """
        Create a trait object for the 16x256b TMEM load operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this load operation
        :rtype: Ld16x256bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            256,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x256bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        """
        Create a trait object for the 16x32bx2 TMEM load operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this load operation
        :rtype: Ld16x32bx2Trait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            16,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld16x32bx2Trait(cute.make_atom(ty, loc=loc, ip=ip))


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
        """
        Create a trait object for the 32x32b TMEM load operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this load operation
        :rtype: Ld32x32bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemLoadType.get(
            copy_internal_type.mlir_type,
            32,
            32,
            self.repeat.value,
            ir.UnitAttr.get() if self.pack == Pack.PACK_16b_IN_32b else None,
        )
        return Ld32x32bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class Ld32x32bTrait(Trait):
    pass


@dataclass(frozen=True)
class _StBase(CopyOp):
    """
    Base class for TMEM store operations in the tcgen05 instruction set.

    This abstract base class provides common functionality and validation for tensor memory (TMEM)
    store operations. It defines the fundamental parameters and architecture constraints that apply
    to all store operation variants.

    :param repeat: Number of repetitions for the store operation (required parameter)
    :type repeat: Repetition
    :param unpack: Unpacking pattern for RMEM to TMEM copies, defaults to Unpack.NONE
    :type unpack: Unpack, optional
    :raises OpError: If the current architecture is not supported or if invalid parameters are provided
    """

    repeat: Repetition
    unpack: Unpack = Unpack.NONE

    admissible_archs = Arch.filter(
        lambda arch: arch.is_family_of(Arch.sm_100f) or arch.is_family_of(Arch.sm_110f)
    )

    def __post_init__(self) -> None:
        # Arch verification
        arch = CuTeDSL._get_dsl().get_arch_enum()
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
                "expects the 'unpack' Op parameter to be a tcgen05.Unpack instance",
            )

    def __str__(self) -> str:
        res = (
            f"tcgen05 {self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  number of repetitions = {self.repeat.value}"
        )
        if self.unpack == Unpack.UNPACK_32b_IN_16b:
            res += "\n  with 32-bit to 2x 16b unpacking"
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
        """
        Create a trait object for the 16x64b TMEM store operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this store operation
        :rtype: St16x64bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100TmemStoreType.get(
            copy_internal_type.mlir_type,
            16,
            64,
            self.repeat.value,
            ir.UnitAttr.get() if self.unpack == Unpack.UNPACK_32b_IN_16b else None,
        )
        return St16x64bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        return St16x128bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        return St16x256bTrait(cute.make_atom(ty, loc=loc, ip=ip))


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
        return St16x32bx2Trait(cute.make_atom(ty, loc=loc, ip=ip))


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
        return St32x32bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class St32x32bTrait(Trait):
    pass


@dataclass(frozen=True)
class _S2TCopyBase(CopyOp):
    """
    Base class for SMEM to TMEM copy operations in the tcgen05 instruction set.

    This abstract base class provides common functionality and validation for shared memory (SMEM)
    to tensor memory (TMEM) copy operations. These operations are used for high-throughput data
    movement between different memory hierarchies in modern GPU architectures.

    :param cta_group: Cooperative Thread Array (CTA) group configuration
    :type cta_group: CtaGroup
    :raises OpError: If the current architecture is not SM100f family or if invalid parameters are provided
    """

    cta_group: CtaGroup

    def __post_init__(self) -> None:
        # Arch verification
        arch = CuTeDSL._get_dsl().get_arch_enum()
        if not arch.is_family_of(Arch.sm_100f):
            raise OpError(
                self,
                f"expects arch to be one of {Arch.filter(lambda arch: arch.is_family_of(Arch.sm_100f))}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self,
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )

    def __str__(self) -> str:
        res = (
            f"tcgen05 {self.__class__.__name__[:-2]} Copy Operation"
            + f"\n  CTA group = {self.cta_group}"
        )

        return res


@dataclass(frozen=True)
class Cp128x256bOp(_S2TCopyBase):
    """
    128x256b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.128x256b`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp128x256bTrait":
        """
        Create a trait object for the 128x256b SMEM to TMEM copy operation.

        :param copy_internal_type: The data type for the copy operation
        :type copy_internal_type: Type[Numeric]
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        :param kwargs: Additional keyword arguments
        :type kwargs: dict
        :return: A trait object for this S2T copy operation
        :rtype: Cp128x256bTrait
        """
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            128,
            256,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.none,
        )
        return Cp128x256bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp128x256bTrait(Trait):
    pass


@dataclass(frozen=True)
class Cp128x128bOp(_S2TCopyBase):
    """
    128x128b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.128x128b`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp128x128bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            128,
            128,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.none,
        )
        return Cp128x128bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp128x128bTrait(Trait):
    pass


@dataclass(frozen=True)
class Cp4x256bOp(_S2TCopyBase):
    """
    4x256b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.4x256b`` qualifier.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp4x256bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            4,
            256,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.none,
        )
        return Cp4x256bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp4x256bTrait(Trait):
    pass


@dataclass(frozen=True)
class Cp4x32x128bOp(_S2TCopyBase):
    """
    32x128b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.32x128b`` qualifier with ``warpx4`` broadcast qualifier enabled.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp4x32x128bTrait":
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            32,
            128,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.x4,
        )
        return Cp4x32x128bTrait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp4x32x128bTrait(Trait):
    pass


@dataclass(frozen=True)
class Cp2x64x128b0213Op(_S2TCopyBase):
    """
    64x128b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.64x128b`` qualifier with ``.warpx2::02_13`` broadcast qualifier enabled.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp2x64x128b0213Trait":
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            64,
            128,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.lw_0213,
        )
        return Cp2x64x128b0213Trait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp2x64x128b0213Trait(Trait):
    pass


@dataclass(frozen=True)
class Cp2x64x128b0123Op(_S2TCopyBase):
    """
    64x128b SMEM to TMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html?highlight=tcgen05#tcgen05-instructions-tcgen05-cp>`__.
    This Operation corresponds to the ``.64x128b`` qualifier with ``.warpx2::01_23`` broadcast qualifier enabled.
    """

    def _make_trait(
        self, copy_internal_type: Type[Numeric], *, loc=None, ip=None, **kwargs
    ) -> "Cp2x64x128b0123Trait":
        ty = _cute_nvgpu_ir.CopyAtomSM100CopyS2TType.get(
            copy_internal_type.mlir_type,
            64,
            128,
            self.cta_group.value,
            _cute_nvgpu_ir.CopyS2TBroadcast.lw_0123,
        )
        return Cp2x64x128b0123Trait(cute.make_atom(ty, loc=loc, ip=ip))


class Cp2x64x128b0123Trait(Trait):
    pass
