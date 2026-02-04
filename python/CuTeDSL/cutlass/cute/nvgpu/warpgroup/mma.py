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

import enum
from dataclasses import dataclass
from typing import Type, Any

from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL, T
from typing_extensions import deprecated

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from ..common import OpError, normalize_field_to_ir_name
from ...core import _pack_shape, rank, depth
from ...typing import (
    Shape,
    Tensor,
    Float16,
    BFloat16,
    Float32,
    Boolean,
    Float8E5M2,
    Float8E4M3FN,
    Int32,
    Int8,
    Uint8,
    Numeric,
    AddressSpace,
)
from ...atom import MmaOp, Trait, make_atom


####################################################################################################
#
# MMA Ops and Traits
#
####################################################################################################


class WarpGroupMmaOp(MmaOp):
    """
    Base class for all warpgroup-level MMA operations.
    """

    pass


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

    RMEM = _cute_ir.MmaFragKind.rmem
    SMEM = _cute_ir.MmaFragKind.smem_desc

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.MmaFragKind:
        return self.value


class Field(enum.Enum):
    """
    An enumeration for the fields of the MMA Atom that can be modified at runtime.
    """

    ACCUMULATE = "accum_c"

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir_field_name(self) -> str:
        return self.value


@dataclass(frozen=True)
class MmaOp(WarpGroupMmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape
    a_src: OperandSource
    a_major_mode: OperandMajorMode
    b_major_mode: OperandMajorMode

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch == Arch.sm_90a:
            raise OpError(
                self,
                f"expects arch to be {Arch.sm_90a}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # Verify that the user provided enum values
        if not isinstance(self.a_src, OperandSource):
            raise OpError(
                self,
                "expects the 'a_src' Op parameter to be a warpgroup.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, OperandMajorMode):
            raise OpError(
                self,
                "expects the 'a_major_mode' Op parameter to be a warpgroup.OperandMajorMode instance",
            )
        if not isinstance(self.b_major_mode, OperandMajorMode):
            raise OpError(
                self,
                "expects the 'b_major_mode' Op parameter to be a warpgroup.OperandMajorMode instance",
            )
        # Verify instruction shape
        if (rank(self.shape_mnk) not in [2, 3]) or (depth(self.shape_mnk) != 1):
            raise OpError(
                self,
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = self.shape_mnk[0], self.shape_mnk[1]
        if m != 64:
            raise OpError(self, f"expects the M-mode to be 64, but got {m}")
        if (n < 8) or (n > 256) or (n % 8 != 0):
            raise OpError(
                self,
                f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0. but got {n}",
            )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name  # type: ignore
            + f"\n  A data type           = {self.a_dtype}"
            + f"\n  B data type           = {self.b_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  A source location     = {self.a_src}"
            + f"\n  A major mode          = {self.a_major_mode}"
            + f"\n  B major mode          = {self.b_major_mode}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
        )

    def _verify_fragment_A(self, input: Tensor, *, loc=None, ip=None):
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise OpError(
                self,
                f"Expected affine layout for {self._make_trait()}'s operand A, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True

    def _verify_fragment_B(self, input: Tensor, *, loc=None, ip=None):
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise OpError(
                self,
                f"Expected affine layout for {self._make_trait()}'s operand B, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True


class MmaTraits(Trait):
    admissible_fields = [Field.ACCUMULATE]

    def _normalize_field_name(self, field: Any) -> str:
        """
        Normalize a field specifier (enum or string) into the IR logical field name.
        Accepted inputs:
          - Field.ACCUMULATE
          - "accum_c"
        """
        return normalize_field_to_ir_name(field, self.admissible_fields)

    def set(self, field, value, *, loc=None, ip=None) -> None:
        field_ir_name = self._normalize_field_name(field)
        # Prefer the newer builder that accepts a logical field name, but keep
        # a fallback for legacy attribute-based construction to avoid breaking changes.
        bool_val = Boolean(value).ir_value(loc=loc, ip=ip)
        try:
            self.value = _cute_nvgpu_ir.atom_set_value(
                self.value, field_ir_name, bool_val, loc=loc, ip=ip
            )
        except (TypeError, AttributeError):
            # Legacy path: construct the per-arch field attribute explicitly
            attr_asm = f"#cute_nvgpu.atom_mma_field_sm90<{field_ir_name}>"
            attr = ir.Attribute.parse(attr_asm)
            self.value = _cute_nvgpu_ir.atom_set_value(
                self.value, attr, bool_val, loc=loc, ip=ip
            )

    def get(self, field, *, loc=None, ip=None) -> Any:
        field_ir_name = self._normalize_field_name(field)
        try:
            return _cute_nvgpu_ir.atom_get_value(
                Boolean.mlir_type, self.value, field_ir_name, loc=loc, ip=ip
            )
        except (TypeError, AttributeError):
            attr_asm = f"#cute_nvgpu.atom_mma_field_sm90<{field_ir_name}>"
            attr = ir.Attribute.parse(attr_asm)
            return _cute_nvgpu_ir.atom_get_value(
                Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
            )


@dataclass(frozen=True)
class MmaF16BF16Op(MmaOp):
    """
    F16/BF16 warpgroup MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#asynchronous-warpgroup-level-matrix-instructions-wgmma-mma>`__.
    This Operation covers the instructions using the ``.f16`` or ``.bf16`` qualifiers for the input operands.
    """

    descriptive_name = "warpgroup F16/BF16 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            ab_dtype,
            ab_dtype,
            acc_dtype,
            instruction_shape,
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
        if (self.a_dtype == BFloat16) and (self.acc_dtype != Float32):
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32 when 'ab_dtype' is BFloat16",
            )
        # Verify the instruction shape
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
        ty = _cute_nvgpu_ir.MmaAtomSM90Type.get(
            shape_mnk.type.attribute,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
        )
        return MmaF16BF16Trait(
            make_atom(ty, (Boolean(False).ir_value(loc=loc, ip=ip),), loc=loc, ip=ip)
        )


class MmaF16BF16Trait(MmaTraits):
    pass


@dataclass(frozen=True)
class MmaF8Op(MmaOp):
    """
    F16/BF16 warpgroup MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#asynchronous-warpgroup-level-matrix-instructions-wgmma-mma>`__.
    This Operation covers the instructions using the ``.e4m3`` or ``.e5m2`` qualifiers for the input operands.
    """

    descriptive_name = "warpgroup F8 MMA Operation"

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            a_dtype,
            b_dtype,
            acc_dtype,
            instruction_shape,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self):
        # Input data type verification
        if self.a_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise OpError(
                self,
                "expects the 'a_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        if self.b_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise OpError(
                self,
                "expects the 'b_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Verify the instruction shape
        instruction_k = 32
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaF8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM90Type.get(
            shape_mnk.type.attribute,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
        )
        return MmaF8Trait(
            make_atom(ty, (Boolean(False).ir_value(loc=loc, ip=ip),), loc=loc, ip=ip)
        )


class MmaF8Trait(MmaTraits):
    pass


@dataclass(frozen=True)
class MmaI8Op(MmaOp):
    """
    I8 warpgroup MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#asynchronous-warpgroup-level-matrix-instructions-wgmma-mma>`__.
    This Operation covers the instructions using the ``.s8`` or ``.u8`` qualifiers for the input operands.
    """

    descriptive_name = "warpgroup I8 MMA Operation"

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        a_src: OperandSource,
        a_major_mode: OperandMajorMode,
        b_major_mode: OperandMajorMode,
    ) -> None:
        super().__init__(
            a_dtype,
            b_dtype,
            acc_dtype,
            instruction_shape,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self):
        # Input data type verification
        if self.a_dtype not in [Int8, Uint8]:
            raise OpError(
                self,
                "expects the 'a_dtype' Op parameter to be one of Int8 or Uint8",
            )
        if self.b_dtype not in [Int8, Uint8]:
            raise OpError(
                self,
                "expects the 'b_dtype' Op parameter to be one of Int8 or Uint8",
            )
        # Accumulator data type verification
        if self.acc_dtype != Int32:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter must be Int32",
            )

        # Verify the instruction shape
        instruction_k = 32
        if rank(self.shape_mnk) == 2:
            object.__setattr__(self, "shape_mnk", (*self.shape_mnk, instruction_k))
        if self.shape_mnk[2] != instruction_k:
            raise OpError(
                self,
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {self.shape_mnk[2]}",
            )

        n = self.shape_mnk[1]
        if not (n >= 8 and n <= 256 and (n == 8 or n == 24 or n % 16 == 0)):
            raise OpError(
                self,
                "expects the N-mode to satisfy N=8*i where i={1,2,3,4} ",
                f"or N=16*i where i={{3,4,...,15,16}}. But got {n}",
            )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaI8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM90Type.get(
            shape_mnk.type.attribute,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            (T.si8() if self.a_dtype.signed else T.ui8()),
            (T.si8() if self.b_dtype.signed else T.ui8()),
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
        )
        return MmaI8Trait(
            make_atom(ty, (Boolean(False).ir_value(loc=loc, ip=ip),), loc=loc, ip=ip)
        )


class MmaI8Trait(MmaTraits):
    pass


####################################################################################################
#
# SMEM layout atoms
#
####################################################################################################


class SmemLayoutAtomKind(enum.Enum):
    """
    Enum class for the kinds of SMEM layout atoms for SM90.

    Given a swizzle kind, an SMEM layout atom is the compact layout of smallest size that can
    be used to construct an SMEM layout using blocked product for operand A or B such that the
    resulting layout is legal for both TMA and UMMA.

    Note that there are other ways of creating legal layouts for operand A and B.
    """

    MN_INTER = enum.auto()
    MN_SW32 = enum.auto()
    MN_SW64 = enum.auto()
    MN_SW128 = enum.auto()
    K_INTER = enum.auto()
    K_SW32 = enum.auto()
    K_SW64 = enum.auto()
    K_SW128 = enum.auto()
