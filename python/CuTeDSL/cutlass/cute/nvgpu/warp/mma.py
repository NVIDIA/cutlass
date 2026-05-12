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
from typing import Any, List, Optional, Tuple, Type, Union

import enum
from cutlass import cute
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL, dsl_user_op


from ..common import OpError, normalize_field_to_ir_name
from ...typing import (
    Shape,
    Float4E2M1FN,
    Float8E8M0FNU,
    Float8E4M3FN,
    Float8E5M2,
    Float16,
    BFloat16,
    Float32,
    Boolean,
    Int32,
    Numeric,
    Pointer,
)
from ...core import _pack_shape
from ...typing import Tensor
from ...atom import MmaOp, Trait, make_atom

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
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
        Arch.sm_121a,
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
        if self.ab_dtype != Float4E2M1FN:
            raise OpError(
                self,
                "expects the 'ab_dtype' Op parameter to be Float4E2M1FN",
            )
        if self.acc_dtype != Float32:
            raise OpError(
                self,
                "expects the 'acc_dtype' Op parameter to be Float32",
            )
        if self.shape_mnk != (16, 8, 64):
            raise OpError(
                self,
                "expects the 'shape_mnk' Op parameter to be (16,8,64)",
            )

        if self.sf_vec_size == 16:
            if self.sf_type != Float8E4M3FN:
                raise OpError(
                    self,
                    "expects the 'sf_type' Op parameter to be Float8E4M3FN",
                )
        elif self.sf_vec_size == 32:
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
            "warp-level MXF4/MXF4NVF4 MMA Operation"
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

    def supports_operand_bundle(self, a: List[Tensor], b: List[Tensor]) -> bool:
        return (
            len(a) == 2
            and len(b) == 2
            and self.shape_mnk == (16, 8, 64)
            and self.ab_dtype == Float4E2M1FN
            and self.acc_dtype == Float32
            and self.sf_type == Float8E4M3FN
            and self.sf_vec_size == 16
        )

    def gemm_with_operand_bundle(
        self,
        atom: cute.MmaAtom,
        d: Tensor,
        a: List[Tensor],
        b: List[Tensor],
        c: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if not self.supports_operand_bundle(a, b):
            raise TypeError(f"{self} does not support GEMM operand bundles")
        return mma_unpack(atom, d, a, b, c, loc=loc, ip=ip)


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
        Field.ACCUMULATE,
        Field.SFA,
        Field.SFB,
    ]

    def _normalize_field_name(self, field: Any) -> str:
        return normalize_field_to_ir_name(field, self.admissible_fields)

    def set(
        self,
        field: Any,
        value: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        field_ir_name = self._normalize_field_name(field)
        if field_ir_name == Field.ACCUMULATE.value:
            value = Boolean(value).ir_value(loc=loc, ip=ip)
        elif field_ir_name in [Field.SFA.value, Field.SFB.value]:
            if not isinstance(value, Pointer):
                raise ValueError(
                    f"expects value to be a pointer for {field}, but got {type(value).__name__}"
                )
            value = value.value

        try:
            self.value = _cute_nvgpu_ir.atom_set_value(
                self.value, field_ir_name, value, loc=loc, ip=ip
            )
        except (TypeError, AttributeError):
            field_name = (
                f"#cute_nvgpu.atom_mma_field_sm120_block_scaled<{field_ir_name}>"
            )
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
        field_ir_name = self._normalize_field_name(field)
        if field_ir_name != Field.ACCUMULATE.value:
            raise ValueError(f"the get method for {field} is not supported")
        try:
            return _cute_nvgpu_ir.atom_get_value(
                Boolean.mlir_type, self.value, field_ir_name, loc=loc, ip=ip
            )
        except (TypeError, AttributeError):
            field_name = (
                f"#cute_nvgpu.atom_mma_field_sm120_block_scaled<{field_ir_name}>"
            )
            attr = ir.Attribute.parse(field_name)
            return _cute_nvgpu_ir.atom_get_value(
                Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
            )


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


def _normalize_mxf4nvf4_operand(
    operand: Union[List[Tensor], Tuple[Tensor, ...]],
    name: str,
) -> Tuple[Tensor, Tensor]:
    if not isinstance(operand, (list, tuple)) or len(operand) != 2:
        raise TypeError(f"`{name}` must be a two-tensor sequence `(fragment, scale)`")
    fragment, scale = operand
    if not isinstance(fragment, Tensor) or not isinstance(scale, Tensor):
        raise TypeError(f"`{name}` must contain only Tensor operands")
    return fragment, scale


def _require_rmem(tensor: Tensor, name: str) -> None:
    if tensor.memspace != cute.AddressSpace.rmem:
        raise ValueError(f"`{name}` must be register-resident")


def _require_static_size(actual: Any, expected: int, name: str) -> None:
    if actual != expected:
        raise ValueError(f"`{name}` must have static size {expected}, but got {actual}")


def _validate_mxf4nvf4_packed_fragment_layout(
    fragment: Tensor,
    name: str,
    *,
    expected_logical_size: int,
    expected_i32_size: int,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    _require_rmem(fragment, name)
    if fragment.element_type != Float4E2M1FN:
        raise TypeError(f"`{name}` must have element type {Float4E2M1FN}")
    _require_static_size(
        cute.size(fragment, loc=loc, ip=ip), expected_logical_size, name
    )

    compact = cute.filter_zeros(fragment, loc=loc, ip=ip)
    i32_fragment = cute.recast_tensor(compact, Int32, loc=loc, ip=ip)
    _require_static_size(
        cute.size(i32_fragment, loc=loc, ip=ip),
        expected_i32_size,
        f"packed `{name}`",
    )
    return i32_fragment


def _validate_mxf4nvf4_accumulator_layout(
    accumulator: Tensor,
    name: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    _require_rmem(accumulator, name)
    if accumulator.element_type != Float32:
        raise TypeError(f"`{name}` must have element type {Float32}")
    _require_static_size(cute.size(accumulator, loc=loc, ip=ip), 4, name)


def _validate_mxf4nvf4_scale_fragment_layout(
    scale: Tensor,
    name: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    _require_rmem(scale, name)
    if scale.element_type != Float8E4M3FN:
        raise TypeError(f"`{name}` must have element type {Float8E4M3FN}")
    _require_static_size(cute.size(scale, loc=loc, ip=ip), 64, name)

    compact = cute.filter_zeros(scale, loc=loc, ip=ip)
    _require_static_size(
        cute.cosize(compact.layout, loc=loc, ip=ip),
        4,
        f"compact `{name}`",
    )
    i32_scale = cute.recast_tensor(compact, Int32, loc=loc, ip=ip)
    _require_static_size(
        cute.size(i32_scale, loc=loc, ip=ip),
        1,
        f"packed `{name}`",
    )
    return compact


def _validate_mxf4nvf4_atom(atom: cute.MmaAtom) -> MmaSM120BlockScaledOp:
    op = getattr(atom, "op", None)
    if not isinstance(op, MmaSM120BlockScaledOp):
        raise TypeError("`mma_unpack` expects an SM120 warp blockscaled MMA atom")
    if not op.supports_operand_bundle([None, None], [None, None]):  # type: ignore[list-item]
        raise ValueError(
            "SM120 NVFP4 MMA requires Float4E2M1FN A/B, Float32 accumulators, "
            "Float8E4M3FN scales, shape (16, 8, 64), and scale_vec::4X"
        )
    return op


@dsl_user_op
def make_mxf4nvf4_sfa_layout(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the SM120 MXF4NVF4 SFA register scale-fragment layout."""
    return cute.make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_sfb_layout(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the SM120 MXF4NVF4 SFB register scale-fragment layout."""
    return cute.make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_sfa_fragment(
    dtype: Type[Numeric] = Float8E4M3FN,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    """Return an SM120 MXF4NVF4 SFA register scale fragment."""
    if dtype != Float8E4M3FN:
        raise TypeError("SM120 MXF4NVF4 SFA fragments require Float8E4M3FN")
    return cute.make_rmem_tensor(
        make_mxf4nvf4_sfa_layout(loc=loc, ip=ip), dtype, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_sfb_fragment(
    dtype: Type[Numeric] = Float8E4M3FN,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    """Return an SM120 MXF4NVF4 SFB register scale fragment."""
    if dtype != Float8E4M3FN:
        raise TypeError("SM120 MXF4NVF4 SFB fragments require Float8E4M3FN")
    return cute.make_rmem_tensor(
        make_mxf4nvf4_sfb_layout(loc=loc, ip=ip), dtype, loc=loc, ip=ip
    )


@dsl_user_op
def mma_unpack(
    atom: cute.MmaAtom,
    d: Tensor,
    a: Union[List[Tensor], Tuple[Tensor, ...]],
    b: Union[List[Tensor], Tuple[Tensor, ...]],
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Issue SM120 MXF4NVF4 warp MMA with bundled FP4 and E4M3 scale fragments."""
    _validate_mxf4nvf4_atom(atom)
    a_fragment, sfa = _normalize_mxf4nvf4_operand(a, "a")
    b_fragment, sfb = _normalize_mxf4nvf4_operand(b, "b")

    a_i32 = _validate_mxf4nvf4_packed_fragment_layout(
        a_fragment,
        "a fragment",
        expected_logical_size=32,
        expected_i32_size=4,
        loc=loc,
        ip=ip,
    )
    b_i32 = _validate_mxf4nvf4_packed_fragment_layout(
        b_fragment,
        "b fragment",
        expected_logical_size=16,
        expected_i32_size=2,
        loc=loc,
        ip=ip,
    )
    _validate_mxf4nvf4_accumulator_layout(d, "d", loc=loc, ip=ip)
    _validate_mxf4nvf4_accumulator_layout(c, "c", loc=loc, ip=ip)

    compact_sfa = _validate_mxf4nvf4_scale_fragment_layout(
        sfa, "sfa", loc=loc, ip=ip
    )
    compact_sfb = _validate_mxf4nvf4_scale_fragment_layout(
        sfb, "sfb", loc=loc, ip=ip
    )

    sfa_i32 = cute.recast_tensor(compact_sfa, Int32, loc=loc, ip=ip)
    sfb_i32 = cute.recast_tensor(compact_sfb, Int32, loc=loc, ip=ip)

    a_vec = a_i32.load(loc=loc, ip=ip)
    b_vec = b_i32.load(loc=loc, ip=ip)
    c_vec = c.load(loc=loc, ip=ip)
    shape_mnk = _pack_shape((16, 8, 64), loc=loc, ip=ip)
    result = _cute_nvgpu_ir.arch_mma_SM120_block_scaled(
        c_vec.type,
        shape_mnk.type.attribute,
        16,
        ir.TypeAttr.get(Float4E2M1FN.mlir_type),
        ir.TypeAttr.get(Float4E2M1FN.mlir_type),
        ir.TypeAttr.get(Float8E4M3FN.mlir_type),
        a_vec,
        b_vec,
        c_vec,
        Int32(sfa_i32[0]).ir_value(loc=loc, ip=ip),
        Int32(sfb_i32[0]).ir_value(loc=loc, ip=ip),
        # This helper accepts only the canonical register fragments produced by
        # partition_shape_A/B for the single-instruction SM120 MXF4NVF4 form.
        # Their physical layout carries the lane/byte mapping, so the
        # instruction's immediate byte/thread selectors stay at the canonical
        # zero values.
        byte_id_a=0,
        byte_id_b=0,
        thread_id_a=0,
        thread_id_b=0,
        loc=loc,
        ip=ip,
    )
    d.store(cute.TensorSSA(result, d.shape, Float32, loc=loc, ip=ip), loc=loc, ip=ip)
