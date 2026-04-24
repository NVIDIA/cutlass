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
from typing import Type, Any, List, Tuple, Union

import enum
from cutlass import cute
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.cutlass_dsl import BaseDSL


from ..common import OpError
from ...typing import (
    Shape,
    Float4E2M1FN,
    Float8E8M0FNU,
    Float8E4M3FN,
    Float16,
    BFloat16,
    Float32,
    Boolean,
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

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaF16BF16Trait":
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

    def _verify_fragment_A(self, input: Tensor, *, loc=None, ip=None):
        pass

    def _verify_fragment_B(self, input: Tensor, *, loc=None, ip=None):
        pass


class MmaF16BF16Trait(Trait):
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
        "sm_120a",
    ]

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch == Arch.sm_120a:
            raise OpError(
                self,
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
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

    def _verify_fragment_A(self, input: Tensor, *, loc=None, ip=None):
        pass

    def _verify_fragment_B(self, input: Tensor, *, loc=None, ip=None):
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
        Field.ACCUMULATE,
        Field.SFA,
        Field.SFB,
    ]

    def set(self, field, value, *, loc=None, ip=None) -> None:
        if field not in self.admissible_fields:
            raise ValueError(
                f"expects field to be one of {self.admissible_fields}, but got {field}"
            )
        if field == Field.ACCUMULATE:
            value = Boolean(value).ir_value(loc=loc, ip=ip)
        elif field in [Field.SFA, Field.SFB]:
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

    def get(self, field, *, loc=None, ip=None) -> Any:
        if field not in [Field.ACCUMULATE]:
            raise ValueError(f"the get method for {field} is not supported")
        field_name = f"#cute_nvgpu.atom_mma_field_sm120_block_scaled<{field._to_ir_field_name()}>"
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

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaMXF4Trait":
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

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaMXF4NVF4Trait":
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


def _normalize_scaled_operand(
    operand: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
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


def _require_static_size(actual, expected: int, name: str) -> None:
    if actual != expected:
        raise ValueError(f"`{name}` must have static size {expected}, but got {actual}")


def _validate_scale_fragment(
    scale: Tensor,
    name: str,
    dtype: Type[Numeric],
    logical_k: int,
    physical_count: int,
    *,
    loc=None,
    ip=None,
) -> Tensor:
    _require_rmem(scale, name)
    if scale.element_type != dtype:
        raise TypeError(f"`{name}` must have element type {dtype}")
    _require_static_size(cute.size(scale, loc=loc, ip=ip), logical_k, name)

    compact = cute.filter_zeros(scale, loc=loc, ip=ip)
    _require_static_size(
        cute.cosize(compact.layout, loc=loc, ip=ip),
        physical_count,
        f"compact `{name}`",
    )
    return compact


def _validate_sm120_block_scaled_atom(atom: cute.MmaAtom) -> MmaSM120BlockScaledOp:
    op = getattr(atom, "op", None)
    if not isinstance(op, MmaSM120BlockScaledOp):
        raise TypeError("`mma_unpack` expects an SM120 warp block-scaled MMA atom")

    if op.shape_mnk != (16, 8, 64):
        raise ValueError(
            f"SM120 block-scaled MMA shape must be (16, 8, 64), got {op.shape_mnk}"
        )

    if op.sf_vec_size == 16 and op.sf_type != Float8E4M3FN:
        raise ValueError("NVFP4 scale vector size 16 requires Float8E4M3FN scales")
    if op.sf_vec_size == 32 and op.sf_type != Float8E8M0FNU:
        raise ValueError("MXF4 scale vector size 32 requires Float8E8M0FNU scales")

    return op


@dsl_user_op
def make_mxf4nvf4_sfa_layout(*, loc=None, ip=None) -> cute.Layout:
    """
    Return the per-thread SM120 MXF4NVF4 SFA register-fragment layout.

    The layout models 64 logical K scale entries and compacts them to four
    physical E4M3 scale elements with zero strides, matching vector size 16.
    """
    return cute.make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_sfb_layout(*, loc=None, ip=None) -> cute.Layout:
    """
    Return the per-thread SM120 MXF4NVF4 SFB register-fragment layout.

    The layout models 64 logical K scale entries and compacts them to four
    physical E4M3 scale elements with zero strides, matching vector size 16.
    """
    return cute.make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_sfa_fragment(
    dtype: Type[Numeric] = Float8E4M3FN, *, loc=None, ip=None
) -> Tensor:
    if dtype != Float8E4M3FN:
        raise TypeError("SM120 MXF4NVF4 SFA fragments require Float8E4M3FN")
    return cute.make_rmem_tensor(
        make_mxf4nvf4_sfa_layout(loc=loc, ip=ip), dtype, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_sfb_fragment(
    dtype: Type[Numeric] = Float8E4M3FN, *, loc=None, ip=None
) -> Tensor:
    if dtype != Float8E4M3FN:
        raise TypeError("SM120 MXF4NVF4 SFB fragments require Float8E4M3FN")
    return cute.make_rmem_tensor(
        make_mxf4nvf4_sfb_layout(loc=loc, ip=ip), dtype, loc=loc, ip=ip
    )


@dsl_user_op
def mma_unpack(
    atom: cute.MmaAtom,
    d: Tensor,
    a: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    b: Union[Tensor, List[Tensor], Tuple[Tensor, ...]],
    c: Tensor,
    *,
    loc=None,
    ip=None,
) -> None:
    """
    SM120 warp block-scaled MMA helper mirroring C++ ``mma_unpack``.

    ``a`` and ``b`` must be ``(fragment, scale_fragment)`` pairs. Scale
    fragments are logical K-size tensors in register memory whose zero-stride
    filtered layouts compact to ``K / sf_vec_size`` physical scale elements.
    """
    op = _validate_sm120_block_scaled_atom(atom)
    a_fragment, sfa = _normalize_scaled_operand(a, "a")
    b_fragment, sfb = _normalize_scaled_operand(b, "b")

    _require_rmem(d, "d")
    _require_rmem(a_fragment, "a fragment")
    _require_rmem(b_fragment, "b fragment")
    _require_rmem(c, "c")

    logical_k = op.shape_mnk[2]
    physical_count = logical_k // op.sf_vec_size
    compact_sfa = _validate_scale_fragment(
        sfa, "sfa", op.sf_type, logical_k, physical_count, loc=loc, ip=ip
    )
    compact_sfb = _validate_scale_fragment(
        sfb, "sfb", op.sf_type, logical_k, physical_count, loc=loc, ip=ip
    )

    atom.set(Field.SFA, compact_sfa.iterator, loc=loc, ip=ip)
    atom.set(Field.SFB, compact_sfb.iterator, loc=loc, ip=ip)

    return _cute_ir.gemm(
        atom._unpack(loc=loc, ip=ip),
        d.value,
        [a_fragment.value],
        [b_fragment.value],
        c.value,
        loc=loc,
        ip=ip,
    )
