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

from cutlass.cutlass_dsl import CuTeDSL, T

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from ..common import OpError
from ...core import MmaOp, Trait, _pack_shape, rank, depth
from ...typing import (
    Shape,
    Float8E5M2,
    Float8E4M3FN,
    Float16,
    BFloat16,
    Float32,
    TFloat32,
    Boolean,
    Int8,
    Uint8,
    Int32,
    Numeric,
)


####################################################################################################
#
# MMA Ops and Traits
#
####################################################################################################


class OperandMajorMode(enum.Enum):
    """
    An enumeration for the majorness of the input operands of the MMA.
    """

    MN = _cute_ir.MajorMode.mn
    K = _cute_ir.MajorMode.k

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            value = value.upper()
            if value == "MN":
                return OperandMajorMode.MN
            elif value == "K":
                return OperandMajorMode.K

    def _to_ir(self) -> _cute_ir.MajorMode:
        return self.value


class OperandSource(enum.Enum):
    """
    An enumeration for the source memory location of the A input operand of the MMA.
    """

    TMEM = _cute_ir.MmaFragKind.tmem
    SMEM = _cute_ir.MmaFragKind.smem_desc

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.MmaFragKind:
        return self.value


class CtaGroup(enum.Enum):
    """
    An enumeration for the ``cta_group``  qualifier of the MMA.
    """

    ONE = 1
    TWO = 2

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"


class Field(enum.Enum):
    """
    An enumeration for the fields of the MMA Atom that can be modified at runtime.
    """

    NEGATE_A = "neg_a"
    NEGATE_B = "neg_b"
    ACCUMULATE = "accum_c"

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir_field_name(self) -> str:
        return self.value


# Base class for all tcgen05 MMA Ops used to factor out some internal code
@dataclass(frozen=True)
class MmaOp(MmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape
    cta_group: CtaGroup
    a_src: OperandSource
    a_major_mode: OperandMajorMode
    b_major_mode: OperandMajorMode

    admissible_archs = ["sm_100a"]

    def __post_init__(self) -> None:
        # Verify arch
        arch = CuTeDSL._get_dsl().envar.arch
        if arch not in self.admissible_archs:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self,
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )
        if not isinstance(self.a_src, OperandSource):
            raise OpError(
                self,
                "expects the 'a_src' Op parameter to be a tcgen05.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, OperandMajorMode):
            raise OpError(
                self,
                "expects the 'a_major_mode' Op parameter to be a tcgen05.OperandMajorMode instance",
            )
        if not isinstance(self.b_major_mode, OperandMajorMode):
            raise OpError(
                self,
                "expects the 'b_major_mode' Op parameter to be a tcgen05.OperandMajorMode instance",
            )
        # Verify the instruction shape
        if (rank(self.shape_mnk) not in [2, 3]) or (depth(self.shape_mnk) != 1):
            raise OpError(
                self,
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = self.shape_mnk[0], self.shape_mnk[1]
        if self.cta_group == CtaGroup.ONE:
            if m not in [64, 128]:
                raise OpError(self, f"expects the M-mode to be 64 or 128, but got {m}")
            if m == 64:
                if (n < 8) or (n > 256) or (n % 8 != 0):
                    raise OpError(
                        self,
                        f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0, but got {n}",
                    )
            elif m == 128:
                if (n < 16) or (n > 256) or (n % 16 != 0):
                    raise OpError(
                        self,
                        f"expects the N-mode to satisfy 8 <= N <= 256 and N % 16 == 0, but got {n}",
                    )
        else:
            if m not in [128, 256]:
                raise OpError(self, f"expects the M-mode to be 128 or 256, but got {m}")
            if (n < 32) or (n > 256) or (n % 32 != 0):
                raise OpError(
                    self,
                    f"expects the N-mode to satisfy 32 <= N <= 256 and N % 32 == 0, but got {n}",
                )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name  # type: ignore
            + f"\n  A data type           = {self.a_dtype}"
            + f"\n  B data type           = {self.b_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  CTA group             = {self.cta_group}"
            + f"\n  A source location     = {self.a_src}"
            + f"\n  A major mode          = {self.a_major_mode}"
            + f"\n  B major mode          = {self.b_major_mode}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
        )


class MmaTrait(Trait):
    admissible_fields = [Field.ACCUMULATE, Field.NEGATE_A, Field.NEGATE_B]

    def set(self, field, value, *, loc=None, ip=None) -> None:
        if field not in self.admissible_fields:
            raise ValueError(
                f"expects field to be one of {self.admissible_fields}, but got {field}"
            )
        field_name = f"#cute_nvgpu.atom_mma_field_sm100<{field._to_ir_field_name()}>"
        attr = ir.Attribute.parse(field_name)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, Boolean(value).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )


#
# TF32 MMA
#


@dataclass(frozen=True)
class MmaTF32Op(MmaOp):
    """
    TF32 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::tf32`` qualifier.
    """

    descriptive_name = "tcgen05 TF32 MMA Operation"

    def __init__(
        self,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            TFloat32,
            TFloat32,
            Float32,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self) -> None:
        # Verify the instruction shape
        instruction_k = 8
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaTF32Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMAType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            0,
        )
        return MmaTF32Trait(
            _cute_nvgpu_ir.make_sm100_mma(
                ty,
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


class MmaTF32Trait(MmaTrait):
    pass


#
# F16/BF16 MMA
#


@dataclass(frozen=True)
class MmaF16BF16Op(MmaOp):
    """
    F16/BF16 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::f16`` qualifier.
    """

    descriptive_name = "tcgen05 F16/BF16 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            ab_dtype,
            ab_dtype,
            acc_dtype,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in [Float16, BFloat16]:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be one of Float16 or BFloat16",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 16
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaF16BF16Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMAType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            0,
        )
        return MmaF16BF16Trait(
            _cute_nvgpu_ir.make_sm100_mma(
                ty,
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


class MmaF16BF16Trait(MmaTrait):
    pass


#
# I8 MMA
#


@dataclass(frozen=True)
class MmaI8Op(MmaOp):
    """
    I8 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::i8`` qualifier.
    """

    descriptive_name = "tcgen05 I8 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            ab_dtype,
            ab_dtype,
            Int32,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in [Int8, Uint8]:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be one of Int8 or Uint8",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Instruction shape verification
        instruction_k = 32
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaI8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMAType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            (T.si8() if self.a_dtype.signed else T.ui8()),
            (T.si8() if self.b_dtype.signed else T.ui8()),
            T.si32(),
            self.a_src._to_ir(),
            0,
        )
        return MmaI8Trait(
            _cute_nvgpu_ir.make_sm100_mma(
                ty,
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


class MmaI8Trait(MmaTrait):
    pass


#
# F8F6F4 MMA
#


@dataclass(frozen=True)
class MmaFP8Op(MmaOp):
    """
    F8 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    """

    descriptive_name = "tcgen05 F8 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:

        super().__init__(
            ab_dtype,
            ab_dtype,
            acc_dtype,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 32
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaFP8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMAType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            0,
        )
        return MmaFP8Trait(
            _cute_nvgpu_ir.make_sm100_mma(
                ty,
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                Boolean(False).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


class MmaFP8Trait(MmaTrait):
    pass


####################################################################################################
#
# SMEM layout atoms
#
####################################################################################################


class SmemLayoutAtomKind(enum.Enum):
    """
    Enum class for the kinds of SMEM layout atoms for SM100.

    Given a swizzle kind, an SMEM layout atom is the compact layout of smallest size that can be
    used to construct an SMEM layout using blocked product for operand A or B such that the
    resulting layout is legal for both TMA and UMMA.

    Note that there are other ways of creating legal layouts for operand A and B.
    """

    MN_INTER = enum.auto()
    MN_SW32 = enum.auto()
    MN_SW64 = enum.auto()
    MN_SW128 = enum.auto()
    MN_SW128_32B = enum.auto()
    K_INTER = enum.auto()
    K_SW32 = enum.auto()
    K_SW64 = enum.auto()
    K_SW128 = enum.auto()
