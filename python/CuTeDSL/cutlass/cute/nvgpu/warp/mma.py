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

from dataclasses import dataclass
from typing import Any, Optional, Type

import enum
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL


from ..common import OpError
from ...typing import (
    Shape,
    Float4E2M1FN,
    Float8E8M0FNU,
    Float8E4M3FN,
    Float8E5M2,
    Float16,
    BFloat16,
    Float32,
    Numeric,
    Pointer,
)
from ...core import _pack_shape
from ...typing import Tensor
from ...atom import MmaOp, Trait, make_atom

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir


####################################################################################################
#
# MMA Ops and Traits
#
####################################################################################################


class WarpMmaOp(MmaOp):
    """
    Base class for all warp-level MMA operations.
    """

    pass


@dataclass(frozen=True)
class MmaF16BF16Op(WarpMmaOp):
    """
    F16/BF16 warp-level MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-mma>`__.
    This Operation covers the instructions using the ``.f16`` or ``.bf16`` qualifiers for the input operands.
    """

    ab_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape

    def __post_init__(self) -> None:
        if self.ab_dtype not in [Float16, BFloat16]:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be one of Float16 or BFloat16",
            )
        if self.acc_dtype not in [Float16, Float32]:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        if (self.ab_dtype == BFloat16) and (self.acc_dtype != Float32):
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32 when 'ab_dtype' is BFloat16",
            )
        if self.shape_mnk not in [(16, 8, 8), (16, 8, 16)]:
            raise OpError(
                self,
                "expects the 'shape_mnk' Op parameter to be one of (16,8,8) or (16,8,16)",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaF16BF16Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM80Type.get(
            shape_mnk.type.attribute,
            self.ab_dtype.mlir_type,
            self.ab_dtype.mlir_type,
            self.acc_dtype.mlir_type,
        )
        return MmaF16BF16Trait(make_atom(ty, loc=loc, ip=ip))

    def __str__(self) -> str:
        return (
            "warp-level F16/BF16 MMA Operation"
            + f"\n  A/B data type         = {self.ab_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        return True

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        return True


class MmaF16BF16Trait(Trait):
    pass


@dataclass(frozen=True)
class MmaFP8Op(WarpMmaOp):
    """
    FP8 warp-level MMA Operation (SM89).

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-mma>`__.
    This Operation covers the instructions using the ``.e4m3`` or ``.e5m2`` qualifiers for the input operands.
    """

    ab_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape

    def __post_init__(self) -> None:
        if self.ab_dtype not in [Float8E4M3FN, Float8E5M2]:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be one of Float8E4M3FN or Float8E5M2",
            )
        if self.acc_dtype not in [Float16, Float32]:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32 or Float16",
            )
        if self.shape_mnk not in [(16, 8, 32), (16, 8, 16)]:
            raise OpError(
                self,
                "expects the 'shape_mnk' Op parameter to be (16,8,32) or (16,8,16)",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaFP8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM89Type.get(
            shape_mnk.type.attribute,
            self.ab_dtype.mlir_type,
            self.ab_dtype.mlir_type,
            self.acc_dtype.mlir_type,
        )
        return MmaFP8Trait(make_atom(ty, loc=loc, ip=ip))

    def __str__(self) -> str:
        return (
            "warp-level FP8 MMA Operation (SM89)"
            + f"\n  A/B data type         = {self.ab_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass


class MmaFP8Trait(Trait):
    pass


# Base class for SM120 Blockscaled MMA Ops
@dataclass(frozen=True)
class MmaSM120BlockScaledOp(MmaOp):
    ab_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape
    sf_type: Type[Numeric]
    sf_vec_size: int
    use_sf_layout_TV: bool = False

    admissible_archs = [
        Arch.sm_120a,
        Arch.sm_120f,
        Arch.sm_121a,
        Arch.sm_121f,
    ]

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}"
                " - Note: sm_120f is currently not supported, "
                " please compile for your local GPU architecture instead with env "
                "CUTE_DSL_ARCH set to sm_120a or sm_121a",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # (ab_dtype, shape_mnk) consistency: FP4 uses (16,8,64); FP8 uses (16,8,32).
        if self.ab_dtype == Float4E2M1FN:
            if self.shape_mnk != (16, 8, 64):
                raise OpError(
                    self,
                    "expects the 'shape_mnk' Op parameter to be (16,8,64) for Float4E2M1FN",
                )
        elif self.ab_dtype in (Float8E4M3FN, Float8E5M2):
            if self.shape_mnk != (16, 8, 32):
                raise OpError(
                    self,
                    "expects the 'shape_mnk' Op parameter to be (16,8,32) for Float8E4M3FN/Float8E5M2",
                )
        else:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be Float4E2M1FN, Float8E4M3FN, or Float8E5M2",
            )
        if self.acc_dtype != Float32:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32",
            )

        if self.sf_vec_size == 16:
            # vec_size=16 is only valid for FP4 (NVFP4) with E4M3 scale.
            if self.ab_dtype != Float4E2M1FN:
                raise OpError(
                    self,
                    "expects the 'sf_vec_size' Op parameter to be 32 for Float8E4M3FN/Float8E5M2",
                )
            if self.sf_type != Float8E4M3FN:
                raise OpError(
                    self,
                    "expects the 'sf_type' Op parameter to be Float8E4M3FN",
                )
        elif self.sf_vec_size == 32:
            # vec_size=32 path uses UE8M0 scale for both FP4 (MXF4) and FP8 (MXF8).
            if self.sf_type != Float8E8M0FNU:
                raise OpError(
                    self,
                    "expects the 'sf_type' Op parameter to be Float8E8M0FNU",
                )
        else:
            raise OpError(
                self,
                "expects the 'sf_vec_size' Op parameter to be 16 or 32",
            )

    def __str__(self) -> str:
        return (
            "warp-level MXF4/MXF4NVF4/MXF8 MMA Operation"
            + f"\n  A/B data type         = {self.ab_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
            + f"\n  Vector size           = {self.sf_vec_size}"
            + f"\n  SF data type          = {self.sf_type}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass


class Field(enum.Enum):
    """
    An enumeration for the fields of the MMA Atom that can be modified at runtime.
    """

    ACCUMULATE = "accum_c"
    SFA = "sf_a"
    SFB = "sf_b"

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir_field_name(self) -> str:
        return self.value


class MmaBlockScaledTrait(Trait):
    admissible_fields = [
        Field.SFA,
        Field.SFB,
    ]

    def set(
        self,
        field: Any,
        value: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if field not in self.admissible_fields:
            raise ValueError(
                f"expects field to be one of {self.admissible_fields}, but got {field}"
            )
        if field in [Field.SFA, Field.SFB]:
            if not isinstance(value, Pointer):
                raise ValueError(
                    f"expects value to be a pointer for {field}, but got {type(value).__name__}"
                )
            value = value.value

        field_name = f"#cute_nvgpu.atom_mma_field_sm120_block_scaled<{field._to_ir_field_name()}>"
        attr = ir.Attribute.parse(field_name)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, value, loc=loc, ip=ip
        )

    def get(
        self,
        field: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        raise ValueError(f"the get method for {field} is not supported")


#
# MXF4 MMA
#


@dataclass(frozen=True)
class MmaMXF4Op(MmaSM120BlockScaledOp):
    """
    MXF4 warp-level MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-mma>`__.
    This Operation covers the instructions using the ``.e2m1`` qualifiers for the input operands.
    .kind           = {.kind::mxf4};
    .scale_vec_size = {.scale_vec::2X};
    .stype          = {.ue8m0};
    """

    descriptive_name = "warp-level MXF4 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        sf_type: Type[Numeric],
    ) -> None:
        super().__init__(
            ab_dtype,
            acc_dtype,
            (16, 8, 64),
            sf_type,
            32,
        )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM120BlockScaledType.get(
            shape_mnk.type.attribute,
            32,
            False,
            self.ab_dtype.mlir_type,
            self.ab_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_type.mlir_type,
        )
        return MmaMXF4Trait(make_atom(ty, loc=loc, ip=ip))


class MmaMXF4Trait(MmaBlockScaledTrait):
    pass


#
# MXF4NVF4 MMA
#


@dataclass(frozen=True)
class MmaMXF4NVF4Op(MmaSM120BlockScaledOp):
    """
    MXF4NVF4 warp-level MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-mma>`__.
    This Operation covers the instructions using the ``.e2m1`` qualifiers for the input operands.
    .kind           = {.kind::mxf4nvf4};
    .scale_vec_size = {.scale_vec::2X, .scale_vec::4X};
    .stype          = {.ue8m0, .ue4m3};
    """

    descriptive_name = "warp-level MXF4NVF4 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        sf_type: Type[Numeric],
    ) -> None:
        super().__init__(
            ab_dtype,
            acc_dtype,
            (16, 8, 64),
            sf_type,
            16,
        )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4NVF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM120BlockScaledType.get(
            shape_mnk.type.attribute,
            16,
            False,
            self.ab_dtype.mlir_type,
            self.ab_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_type.mlir_type,
        )
        return MmaMXF4NVF4Trait(make_atom(ty, loc=loc, ip=ip))


class MmaMXF4NVF4Trait(MmaBlockScaledTrait):
    pass


#
# MXF8 MMA
#


@dataclass(frozen=True)
class MmaMXF8Op(MmaSM120BlockScaledOp):
    """
    MXF8 warp-level MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#warp-level-matrix-instructions-mma>`__.
    This Operation covers the instructions using the ``.e4m3`` / ``.e5m2`` qualifiers for the input operands.
    .kind           = {.kind::mxf8};
    .scale_vec_size = {.scale_vec::1X};
    .stype          = {.ue8m0};
    """

    descriptive_name = "warp-level MXF8 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        sf_type: Type[Numeric],
    ) -> None:
        super().__init__(
            ab_dtype,
            acc_dtype,
            (16, 8, 32),
            sf_type,
            32,
        )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM120BlockScaledType.get(
            shape_mnk.type.attribute,
            32,
            False,
            self.ab_dtype.mlir_type,
            self.ab_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_type.mlir_type,
        )
        return MmaMXF8Trait(make_atom(ty, loc=loc, ip=ip))


class MmaMXF8Trait(MmaBlockScaledTrait):
    pass


#
# MXF8F6F4 mixed-precision MMA (independent A/B dtypes)
#


MXF8F6F4_SUPPORTED_PAIRS = frozenset(
    {
        (Float4E2M1FN, Float8E4M3FN),
        (Float4E2M1FN, Float8E5M2),
        (Float8E4M3FN, Float4E2M1FN),
        (Float8E5M2, Float4E2M1FN),
    }
)


@dataclass(frozen=True)
class MmaMXF8F6F4Op(MmaOp):
    """
    SM120 MXF8F6F4 mixed-precision warp-level block-scaled MMA Operation.

    Covers the PTX instructions using independent ``.<a_type>.<b_type>``
    qualifiers (one of e2m1.e4m3, e2m1.e5m2, e4m3.e2m1, e5m2.e2m1):

    .kind           = {.kind::mxf8f6f4};
    .scale_vec_size = {.scale_vec::1X};
    .stype          = {.ue8m0};

    A and B operand dtypes are independent. Same-dtype FP4/FP4 and FP8/FP8
    paths remain on ``MmaMXF4Op`` / ``MmaMXF4NVF4Op`` / ``MmaMXF8Op``
    respectively. Same-width mixed-FP8 (E4M3 + E5M2) and FP6 mixed pairs
    are not supported.
    """

    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    sf_type: Type[Numeric]

    descriptive_name = "warp-level MXF8F6F4 mixed-precision MMA Operation"

    shape_mnk = (16, 8, 32)
    sf_vec_size = 32
    use_sf_layout_TV = False

    admissible_archs = [
        Arch.sm_120a,
        Arch.sm_121a,
    ]

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        if self.acc_dtype != Float32:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32",
            )
        if self.sf_type != Float8E8M0FNU:
            raise OpError(
                self,
                "expects the 'sf_type' Op parameter to be Float8E8M0FNU",
            )
        # Reject same-dtype pairs explicitly (route to dedicated ops).
        if self.a_dtype == self.b_dtype:
            if self.a_dtype == Float4E2M1FN:
                raise OpError(
                    self,
                    "same-dtype Float4E2M1FN/Float4E2M1FN is not supported by MmaMXF8F6F4Op; "
                    "use MmaMXF4Op (sf_vec_size=32) or MmaMXF4NVF4Op (sf_vec_size=16) instead",
                )
            if self.a_dtype in (Float8E4M3FN, Float8E5M2):
                raise OpError(
                    self,
                    "same-dtype FP8/FP8 is not supported by MmaMXF8F6F4Op; "
                    "use MmaMXF8Op instead",
                )
        # Reject same-width mixed-FP8 (E4M3 + E5M2) explicitly.
        fp8_dtypes = (Float8E4M3FN, Float8E5M2)
        if self.a_dtype in fp8_dtypes and self.b_dtype in fp8_dtypes:
            raise OpError(
                self,
                "same-width mixed-FP8 (Float8E4M3FN + Float8E5M2) is not supported; "
                "supported MXF8F6F4 pairs are (Float4E2M1FN x Float8E4M3FN/Float8E5M2) "
                "and the reverse",
            )
        # Final allow-list check (catches FP6 and any other unsupported dtype).
        if (self.a_dtype, self.b_dtype) not in MXF8F6F4_SUPPORTED_PAIRS:
            raise OpError(
                self,
                f"unsupported (a_dtype, b_dtype) = ({self.a_dtype}, {self.b_dtype}) "
                f"for MmaMXF8F6F4Op; supported pairs are "
                f"{sorted(repr(p) for p in MXF8F6F4_SUPPORTED_PAIRS)}. "
                f"FP6 mixed pairs are not supported.",
            )

    def __str__(self) -> str:
        return (
            "warp-level MXF8F6F4 mixed-precision MMA Operation"
            + f"\n  A data type           = {self.a_dtype}"
            + f"\n  B data type           = {self.b_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
            + f"\n  Vector size           = {self.sf_vec_size}"
            + f"\n  SF data type          = {self.sf_type}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        pass

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF8F6F4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM120BlockScaledType.get(
            shape_mnk.type.attribute,
            self.sf_vec_size,
            self.use_sf_layout_TV,
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_type.mlir_type,
        )
        return MmaMXF8F6F4Trait(make_atom(ty, loc=loc, ip=ip))


class MmaMXF8F6F4Trait(MmaBlockScaledTrait):
    pass
