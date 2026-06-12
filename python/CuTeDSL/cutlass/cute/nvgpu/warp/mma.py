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
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL, dsl_user_op


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
    Int8,
    Int32,
    Numeric,
    Pointer,
    Uint8,
    AddressSpace,
    Layout,
)
from ...core import _pack_shape, cosize, filter_zeros, make_layout, rank, size
from ...tensor import TensorSSA, make_rmem_tensor, recast_tensor
from ...typing import Tensor
from ...atom import MmaAtom, MmaOp, Trait, make_atom

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
import cutlass._mlir.dialects.vector as vector


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

    def is_mxf4nvf4_sm120(self) -> bool:
        return (
            self.shape_mnk == (16, 8, 64)
            and self.ab_dtype == Float4E2M1FN
            and self.acc_dtype == Float32
            and self.sf_type == Float8E4M3FN
            and self.sf_vec_size == 16
        )


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
    if tensor.memspace != AddressSpace.rmem:
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
    if fragment.element_type == Float4E2M1FN:
        _require_static_size(
            size(fragment, loc=loc, ip=ip), expected_logical_size, name
        )
        compact = filter_zeros(fragment, loc=loc, ip=ip)
    elif fragment.element_type in (Int8, Uint8):
        _require_static_size(
            size(fragment, loc=loc, ip=ip),
            expected_i32_size * 4,
            name,
        )
        compact = filter_zeros(fragment, loc=loc, ip=ip)
    else:
        raise TypeError(
            f"`{name}` must have element type {Float4E2M1FN}, {Int8}, or {Uint8}"
        )

    i32_fragment = recast_tensor(compact, Int32, loc=loc, ip=ip)
    _require_static_size(
        size(i32_fragment, loc=loc, ip=ip),
        expected_i32_size,
        f"packed `{name}`",
    )
    return i32_fragment


def _mxf4nvf4_fragment_atom_size(fragment: Tensor, fp4_size: int) -> int:
    return fp4_size // 2 if fragment.element_type in (Int8, Uint8) else fp4_size


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
    _require_static_size(size(accumulator, loc=loc, ip=ip), 4, name)


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
    _require_static_size(size(scale, loc=loc, ip=ip), 64, name)

    compact = filter_zeros(scale, loc=loc, ip=ip)
    _require_static_size(
        cosize(compact.layout, loc=loc, ip=ip),
        4,
        f"compact `{name}`",
    )
    return compact


def _validate_mxf4nvf4_atom(atom: MmaAtom) -> None:
    op = getattr(atom, "op", None)
    if not isinstance(op, MmaSM120BlockScaledOp):
        raise TypeError("`mma_mxf4nvf4` expects an SM120 warp blockscaled MMA atom")
    if not op.is_mxf4nvf4_sm120():
        raise ValueError(
            "SM120 NVFP4 MMA requires Float4E2M1FN A/B, Float32 accumulators, "
            "Float8E4M3FN scales, shape (16, 8, 64), and scale_vec::4X"
        )


def _is_mxf4nvf4_full_k_tiled_fragment(
    d: Tensor,
    a_fragment: Tensor,
    b_fragment: Tensor,
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> bool:
    if (
        rank(a_fragment) < 3
        or rank(b_fragment) < 3
        or rank(d) < 3
        or rank(c) < 3
    ):
        return False
    a_atom_size = _mxf4nvf4_fragment_atom_size(a_fragment, 32)
    b_atom_size = _mxf4nvf4_fragment_atom_size(b_fragment, 16)
    if size(a_fragment, mode=[0], loc=loc, ip=ip) != a_atom_size:
        return False
    if size(b_fragment, mode=[0], loc=loc, ip=ip) != b_atom_size:
        return False
    if size(d, mode=[0], loc=loc, ip=ip) != 4:
        return False
    if size(c, mode=[0], loc=loc, ip=ip) != 4:
        return False
    m_tiles = size(a_fragment, mode=[1], loc=loc, ip=ip)
    n_tiles = size(b_fragment, mode=[1], loc=loc, ip=ip)
    k_tiles = size(a_fragment, mode=[2], loc=loc, ip=ip)
    if size(b_fragment, mode=[2], loc=loc, ip=ip) != k_tiles:
        return False
    return (
        size(d, mode=[1], loc=loc, ip=ip) == m_tiles
        and size(d, mode=[2], loc=loc, ip=ip) == n_tiles
        and size(c, mode=[1], loc=loc, ip=ip) == m_tiles
        and size(c, mode=[2], loc=loc, ip=ip) == n_tiles
    )


def _is_mxf4nvf4_tiled_fragment(
    d: Tensor,
    a_fragment: Tensor,
    b_fragment: Tensor,
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> bool:
    a_size = size(a_fragment, loc=loc, ip=ip)
    b_size = size(b_fragment, loc=loc, ip=ip)
    d_size = size(d, loc=loc, ip=ip)
    c_size = size(c, loc=loc, ip=ip)
    a_atom_size = _mxf4nvf4_fragment_atom_size(a_fragment, 32)
    b_atom_size = _mxf4nvf4_fragment_atom_size(b_fragment, 16)
    if (
        a_size == a_atom_size
        and b_size == b_atom_size
        and d_size == 4
        and c_size == 4
    ):
        return False
    if _is_mxf4nvf4_full_k_tiled_fragment(
        d, a_fragment, b_fragment, c, loc=loc, ip=ip
    ):
        return True
    if a_size % a_atom_size != 0 or b_size % b_atom_size != 0:
        return False
    a_tiles = a_size // a_atom_size
    b_tiles = b_size // b_atom_size
    return d_size == 4 * a_tiles * b_tiles and c_size == d_size


def _select_mxf4nvf4_scale_fragment(
    scale: Tensor,
    tile_idx: int,
    tile_count: int,
    name: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    scale_size = size(scale, loc=loc, ip=ip)
    if scale_size == 64:
        return scale
    if scale_size == 64 * tile_count and rank(scale) >= 2:
        return scale[(None, tile_idx)]
    raise ValueError(
        f"`{name}` must be a canonical scale fragment or one scale fragment per tile"
    )


def _select_mxf4nvf4_full_k_scale_fragment(
    scale: Tensor,
    major_idx: int,
    k_idx: int,
    major_tiles: int,
    k_tiles: int,
    name: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tensor:
    scale_size = size(scale, loc=loc, ip=ip)
    if scale_size == 64:
        return scale
    scale_rank = rank(scale)
    mode_0_size = size(scale, mode=[0], loc=loc, ip=ip) if scale_rank >= 1 else 0
    mode_1_size = size(scale, mode=[1], loc=loc, ip=ip) if scale_rank >= 2 else 0
    mode_2_size = size(scale, mode=[2], loc=loc, ip=ip) if scale_rank >= 3 else 0
    if (
        scale_rank >= 3
        and mode_0_size == 64
        and mode_1_size == major_tiles
        and mode_2_size == k_tiles
    ):
        return scale[(None, major_idx, k_idx)]
    raise ValueError(
        f"`{name}` must be a canonical scale fragment or one scale fragment per "
        "major/K tile; got "
        f"rank={scale_rank}, size={scale_size}, "
        f"modes=({mode_0_size}, {mode_1_size}, {mode_2_size}), "
        f"expected=(64, {major_tiles}, {k_tiles})"
    )


def _mxf4nvf4_tiled_gemm_indices(m_tiles: int, n_tiles: int):
    for m_idx in range(m_tiles):
        for n_idx in range(n_tiles):
            yield m_idx, n_idx


def _mma_mxf4nvf4_full_k_tiled(
    atom: MmaAtom,
    d: Tensor,
    a_fragment: Tensor,
    sfa: Tensor,
    b_fragment: Tensor,
    sfb: Tensor,
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    m_tiles = size(a_fragment, mode=[1], loc=loc, ip=ip)
    n_tiles = size(b_fragment, mode=[1], loc=loc, ip=ip)
    k_tiles = size(a_fragment, mode=[2], loc=loc, ip=ip)
    for k_idx in range(k_tiles):
        for m_idx, n_idx in _mxf4nvf4_tiled_gemm_indices(m_tiles, n_tiles):
            sfa_tile = _select_mxf4nvf4_full_k_scale_fragment(
                sfa, m_idx, k_idx, m_tiles, k_tiles, "sfa", loc=loc, ip=ip
            )
            sfb_tile = _select_mxf4nvf4_full_k_scale_fragment(
                sfb, n_idx, k_idx, n_tiles, k_tiles, "sfb", loc=loc, ip=ip
            )
            c_tile = (
                c[(None, m_idx, n_idx)]
                if k_idx == 0
                else d[(None, m_idx, n_idx)]
            )
            mma_mxf4nvf4(
                atom,
                d[(None, m_idx, n_idx)],
                (a_fragment[(None, m_idx, k_idx)], sfa_tile),
                (b_fragment[(None, n_idx, k_idx)], sfb_tile),
                c_tile,
                loc=loc,
                ip=ip,
            )


def _mma_mxf4nvf4_tiled(
    atom: MmaAtom,
    d: Tensor,
    a_fragment: Tensor,
    sfa: Tensor,
    b_fragment: Tensor,
    sfb: Tensor,
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    if _is_mxf4nvf4_full_k_tiled_fragment(
        d, a_fragment, b_fragment, c, loc=loc, ip=ip
    ):
        return _mma_mxf4nvf4_full_k_tiled(
            atom, d, a_fragment, sfa, b_fragment, sfb, c, loc=loc, ip=ip
        )
    a_atom_size = _mxf4nvf4_fragment_atom_size(a_fragment, 32)
    b_atom_size = _mxf4nvf4_fragment_atom_size(b_fragment, 16)
    a_tiles = size(a_fragment, loc=loc, ip=ip) // a_atom_size
    b_tiles = size(b_fragment, loc=loc, ip=ip) // b_atom_size
    if rank(a_fragment) < 2 or rank(b_fragment) < 2:
        raise ValueError("tiled SM120 MXF4NVF4 fragments must expose tile modes")
    if rank(d) < 3 or rank(c) < 3:
        raise ValueError("tiled SM120 MXF4NVF4 accumulators must expose M/N tile modes")
    for m_idx, n_idx in _mxf4nvf4_tiled_gemm_indices(a_tiles, b_tiles):
        sfa_tile = _select_mxf4nvf4_scale_fragment(
            sfa, m_idx, a_tiles, "sfa", loc=loc, ip=ip
        )
        sfb_tile = _select_mxf4nvf4_scale_fragment(
            sfb, n_idx, b_tiles, "sfb", loc=loc, ip=ip
        )
        mma_mxf4nvf4(
            atom,
            d[(None, m_idx, n_idx)],
            (a_fragment[(None, m_idx)], sfa_tile),
            (b_fragment[(None, n_idx)], sfb_tile),
            c[(None, m_idx, n_idx)],
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def make_mxf4nvf4_sfa_layout(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Layout:
    """Return the SM120 MXF4NVF4 SFA register scale-fragment layout."""
    return make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_sfb_layout(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Layout:
    """Return the SM120 MXF4NVF4 SFB register scale-fragment layout."""
    return make_layout(((16, 4),), stride=((0, 1),), loc=loc, ip=ip)


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
    return make_rmem_tensor(
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
    return make_rmem_tensor(
        make_mxf4nvf4_sfb_layout(loc=loc, ip=ip), dtype, loc=loc, ip=ip
    )


@dsl_user_op
def mma_mxf4nvf4(
    atom: MmaAtom,
    d: Tensor,
    a: Union[List[Tensor], Tuple[Tensor, ...]],
    b: Union[List[Tensor], Tuple[Tensor, ...]],
    c: Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Issue SM120 MXF4NVF4 warp MMA with bundled FP4 and E4M3 scale fragments.

    This helper consumes already-partitioned register fragments. SMEM scale
    partitioning remains in the Blackwell block-scaled helper path
    (``partition_fragment_SFA`` / ``partition_fragment_SFB``).
    """
    _validate_mxf4nvf4_atom(atom)
    a_fragment, sfa = _normalize_mxf4nvf4_operand(a, "a")
    b_fragment, sfb = _normalize_mxf4nvf4_operand(b, "b")

    if _is_mxf4nvf4_tiled_fragment(
        d, a_fragment, b_fragment, c, loc=loc, ip=ip
    ):
        return _mma_mxf4nvf4_tiled(
            atom, d, a_fragment, sfa, b_fragment, sfb, c, loc=loc, ip=ip
        )

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

    sfa_i32 = recast_tensor(compact_sfa, Int32, loc=loc, ip=ip)
    sfb_i32 = recast_tensor(compact_sfb, Int32, loc=loc, ip=ip)

    a_vec = a_i32.load(loc=loc, ip=ip)
    b_vec = b_i32.load(loc=loc, ip=ip)
    c_vec = c.load(loc=loc, ip=ip)
    a_regs = [a_vec[i].ir_value(loc=loc, ip=ip) for i in range(4)]
    b_regs = [b_vec[i].ir_value(loc=loc, ip=ip) for i in range(2)]
    c_regs = [c_vec[i].ir_value(loc=loc, ip=ip) for i in range(4)]
    shape_mnk = _pack_shape((16, 8, 64), loc=loc, ip=ip)
    result = _cute_nvgpu_ir.arch_mma_SM120_block_scaled(
        [Float32.mlir_type] * 4,
        shape_mnk.type.attribute,
        16,
        ir.TypeAttr.get(Float4E2M1FN.mlir_type),
        ir.TypeAttr.get(Float4E2M1FN.mlir_type),
        ir.TypeAttr.get(Float8E4M3FN.mlir_type),
        a_regs,
        b_regs,
        c_regs,
        Int32(sfa_i32[0]).ir_value(loc=loc, ip=ip),
        Int32(sfb_i32[0]).ir_value(loc=loc, ip=ip),
        thread_id_a=0,
        thread_id_b=0,
        loc=loc,
        ip=ip,
    )
    result_vec = vector.from_elements(
        ir.VectorType.get([4], Float32.mlir_type), result, loc=loc, ip=ip
    )
    d.store(
        TensorSSA(result_vec, d.shape, Float32, loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )


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
