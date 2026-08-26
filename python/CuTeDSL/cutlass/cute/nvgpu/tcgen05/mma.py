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

import enum
import warnings
from dataclasses import dataclass
from typing import Any, Optional, Tuple, Type, Union, cast

from cutlass import base_dsl
from cutlass.cutlass_dsl import DSLUserCodeError, BaseDSL, T, DSLRuntimeError

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
import cutlass._mlir.dialects.vector as vector_d
from typing_extensions import deprecated

from ..common import normalize_field_to_ir_name
from ..common import OperandMajorMode as _OperandMajorMode
from ... import core, atom
from ...core import _pack_shape, rank, depth
from ...typing import (
    Shape,
    Tensor,
    Float4E2M1FN,
    Float8E8M0FNU,
    Float8E5M2,
    Float8E4M3FN,
    Float6E3M2FN,
    Float6E2M3FN,
    FloatNV8E5M3FNU,
    Float16,
    BFloat16,
    Float32,
    TFloat32,
    Boolean,
    Int8,
    Uint8,
    Int32,
    Integer,
    Numeric,
    AddressSpace,
    Pointer,
)
from ...atom import Trait, make_atom

from ..warp.mma import SparseMetadataFormat


# ============================================================================================
# tcgen05 MMA -- PTX Instruction Support Matrix
# ============================================================================================
#
# PTX Ref: https://docs.nvidia.com/cuda/parallel-thread-execution/
#          #tensor-core-5th-generation-instructions
#
# Y = Supported    N = Not supported    [I] = Internal release only
#
# Dense (tcgen05.mma):
#
#   | Kind    | A/B Types               | Acc      | base_dsl.Arch     | PTX Instruction                                  | NVVM Op          | IR Type    | DSL | DSL Class              |
#   |---------|-------------------------|----------|----------|--------------------------------------------------|------------------|------------|-----|------------------------|
#   | tf32    | TF32                    | F32      | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::tf32           | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaTF32Op              |
#   | f16     | F16                     | F16      | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaF16BF16Op           |
#   | f16     | F16                     | F32      | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaF16BF16Op           |
#   | f16     | BF16                    | F32      | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaF16BF16Op           |
#   | i8      | I8, U8                  | I32      | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::i8             | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaI8Op                |
#   | f8f6f4  | E4M3, E5M2              | F16, F32 | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::f8f6f4         | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaFP8Op               |
#   | f8f6f4  | E4M3, E5M2, NV8E5M3     | F16, F32 | sm_107a  | tcgen05.mma.cta_group::{cg}.kind::f8f6f4         | nvvm.tcgen05.mma | sm107.mma  |  Y  | SM107MmaFP8Op          |
#   | f8f6f4  | E2M3, E3M2, E2M1        | F16, F32 | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::f8f6f4         | nvvm.tcgen05.mma | sm100.mma  |  Y  | MmaF8F6F4Op            |
#   | f8f6f4  | all (weight-stationary) | F16, F32 | sm_100a+ | tcgen05.mma.ws.cta_group::{cg}.kind::f8f6f4      | nvvm.tcgen05.mma |            |  N  |                        |
#
#
# Structured sparse (tcgen05.mma.sp):
#
#   | Kind    | A/B Types              | Acc      | base_dsl.Arch     | PTX Instruction                                     | NVVM Op             | IR Type       | DSL | DSL Class                    |
#   |---------|------------------------|----------|----------|-----------------------------------------------------|---------------------|---------------|-----|------------------------------|
#   | f16     | F16                    | F16      | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  Y  | MmaF16BF16SparseOp           |
#   | f16     | F16                    | F32      | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  Y  | MmaF16BF16SparseOp           |
#   | f16     | BF16                   | F32      | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  Y  | MmaF16BF16SparseOp           |
#   | f16     | F16, BF16              | F32      | sm_107a  | tcgen05.mma.sp.cta_group::{cg}.kind::f16            | nvvm.tcgen05.mma.sp | sm107.mma_sp  |  Y  | SM107MmaF16BF16SparseOp      |
#   | tf32    | TF32                   | F32      | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::tf32           | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  N  |                              |
#   | i8      | I8, U8                 | I32      | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::i8             | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  N  |                              |
#   | f8f6f4  | E4M3, E5M2 etc         | F16, F32 | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::f8f6f4         | nvvm.tcgen05.mma.sp | sm100.mma_sp  |  N  |                              |
#
# Block-scaled (tcgen05.mma, block_scale):
#
#   | Kind     | A/B Types               | SF Type       | Acc  | base_dsl.Arch     | PTX Instruction                                                 | NVVM Op                                   | IR Type           | DSL | DSL Class                         |
#   |----------|-------------------------|---------------|------|----------|-----------------------------------------------------------------|-------------------------------------------|-------------------|-----|-----------------------------------|
#   | mxf8f6f4 | E4M3, E5M2              | UE8M0         | F32  | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::mxf8f6f4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | MmaMXF8Op                         |
#   | mxf4     | E2M1                    | UE8M0         | F32  | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::mxf4.block_scale              | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | MmaMXF4Op                         |
#   | mxf4     | E2M1                    | UE8M0         | F32  | sm_103a  | tcgen05.mma.cta_group::{cg}.kind::mxf4.block_scale              | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | SM103MmaMXF4Op                    |
#   | mxf4nvf4 | E2M1, NVF4              | UE8M0, UE4M3  | F32  | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::mxf4nvf4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | MmaMXF4NVF4Op                     |
#   | mxf4nvf4 | E2M1, NVF4              | UE8M0, UE4M3  | F32  | sm_103a  | tcgen05.mma.cta_group::{cg}.kind::mxf4nvf4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | SM103MmaMXF4NVF4Op                |
#   | mxf4nvf4 | E2M1, NVF4              | UE8M0,NV8E5M3 | F32  | sm_107a  | tcgen05.mma.cta_group::{cg}.kind::mxf4nvf4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm107.mma_bs      |  Y  | SM107MmaMXF4NVF4Op                |
#   | mxf8f6f4 | E4M3, E5M2              | UE8M0         | F32  | sm_107a  | tcgen05.mma.cta_group::{cg}.kind::mxf8f6f4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm107.mma_bs      |  Y  | SM107BlockScaledMmaMXF8F6F4Op     |
#   | mxf8f6f4 | E2M3, E3M2, E2M1        | UE8M0         | F32  | sm_100a+ | tcgen05.mma.cta_group::{cg}.kind::mxf8f6f4.block_scale          | nvvm.tcgen05.mma.block_scale              | sm100.mma_bs      |  Y  | MmaMXF8F6F4Op                     |
#   | mxf8f6f4 | all (weight-stationary) | UE8M0         | F32  | sm_100a+ | tcgen05.mma.ws.cta_group::{cg}.kind::mxf8f6f4.block_scale       | nvvm.tcgen05.mma.block_scale              |                   |  N  |                                   |
#
# Block-scaled sparse (tcgen05.mma.sp, block_scale):
#
#   | Kind     | A/B Types              | SF Type       | Acc  | base_dsl.Arch     | PTX Instruction                                                    | NVVM Op                              | IR Type           | DSL | DSL Class                                  |
#   |----------|------------------------|---------------|------|----------|--------------------------------------------------------------------|--------------------------------------|-------------------|-----|--------------------------------------------|
#   | mxf4nvf4 | E2M1, NVF4             | UE8M0, UE4M3  | F32  | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::mxf4nvf4.block_scale          | nvvm.tcgen05.mma.sp.block_scale      | sm100.mma_bs_sp   |  N  |                                            |
#   | mxf8f6f4 | (various)              | UE8M0         | F32  | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::mxf8f6f4.block_scale          | nvvm.tcgen05.mma.sp.block_scale      | sm100.mma_bs_sp   |  N  |                                            |
#   | mxf4     | E2M1                   | UE8M0         | F32  | sm_100a+ | tcgen05.mma.sp.cta_group::{cg}.kind::mxf4.block_scale              | nvvm.tcgen05.mma.sp.block_scale      | sm100.mma_bs_sp   |  N  |                                            |
#
# ============================================================================================

_F8F6F4_TYPES = [
    Float8E5M2,
    Float8E4M3FN,
    Float6E3M2FN,
    Float6E2M3FN,
    Float4E2M1FN,
]

####################################################################################################
#
# MMA Ops and Traits
#
####################################################################################################


def _tcgen05_arch_suggestion(arch: base_dsl.Arch, warp_op_hint: str) -> str:
    """tcgen05 (TMEM / UMMA / tcgen05.alloc) is datacenter-Blackwell-only hardware;
    consumer Blackwell (sm_120 / sm_121) lacks it, so redirect those users to the
    warp-level mma.sync equivalents instead of the generic CUTE_DSL_ARCH hint."""
    if arch.is_family_of(base_dsl.Arch.sm_120f) or arch.is_family_of(
        base_dsl.Arch.sm_121f
    ):
        return (
            f"tcgen05 MMA requires datacenter Blackwell (sm_100 / sm_103). On consumer "
            f"Blackwell (sm_120 / sm_121) use the warp-level {warp_op_hint}; see the "
            f"blackwell_geforce dense_gemm / blockscaled_gemm examples."
        )
    return "Ensure env CUTE_DSL_ARCH matches your GPU architecture"


class Tcgen05MmaOp(atom.MmaOp):
    """
    Base class for all tcgen05 MMA operations.
    """

    pass


@deprecated(
    "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead"
)
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

    def __eq__(self, other: object) -> bool:
        if hasattr(other, "_to_ir") and type(other._to_ir()) is type(self._to_ir()):
            return self._to_ir() == other._to_ir()
        raise DSLRuntimeError(
            f"{self.__module__}.{self.__class__.__qualname__} cannot be compared with {other.__module__}.{other.__class__.__qualname__}"
        )

    def __ne__(self, other: object) -> bool:
        return not self.__eq__(other)

    def __hash__(self) -> int:
        return hash(self.value)

    @classmethod
    def _missing_(cls, value: Any) -> Optional["OperandMajorMode"]:
        if isinstance(value, str):
            value = value.upper()
            if value == "MN":
                return OperandMajorMode.MN
            elif value == "K":
                return OperandMajorMode.K
        return None

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
    SFA = "sf_a"
    SFB = "sf_b"
    METADATA = "e"
    DISABLE_OUTPUT_LANE = "disable_output_lane"

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir_field_name(self) -> str:
        return self.value


def _make_disable_output_lane_default(
    cta_group: CtaGroup,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    num_elts = 4 if cta_group == CtaGroup.ONE else 8
    vec_ty = ir.VectorType.get([num_elts], Int32.mlir_type)
    c0 = Int32(0).ir_value(loc=loc, ip=ip)
    return vector_d.from_elements(vec_ty, [c0] * num_elts, loc=loc, ip=ip)


def _coerce_disable_output_lane_value(
    value: Any,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    if isinstance(value, ir.Value):
        return value
    wrapped_val = getattr(value, "value", None)
    if isinstance(wrapped_val, ir.Value):
        return wrapped_val
    if isinstance(value, (tuple, list)):
        if len(value) not in (4, 8):
            raise ValueError(
                "disable_output_lane expects a list/tuple of 4 (CTA_1) or 8 (CTA_2) i32 lanes"
            )
        vec_ty = ir.VectorType.get([len(value)], Int32.mlir_type)
        elems = [Int32(v).ir_value(loc=loc, ip=ip) for v in value]
        return vector_d.from_elements(vec_ty, elems, loc=loc, ip=ip)
    raise ValueError(
        "disable_output_lane expects an mlir value, a DSL value wrapping mlir value, "
        "or a list/tuple of integers"
    )


def _extract_disable_output_lane_kwarg(kwargs: dict[str, Any]) -> Any:
    return kwargs.pop("disable_output_lane", None)


def _reject_block_scaled_disable_output_lane_kwargs(
    kwargs: dict[str, Any],
    kind: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    disable_output_lane = _extract_disable_output_lane_kwarg(kwargs)
    if kwargs:
        unsupported = ", ".join(sorted(kwargs.keys()))
        raise ValueError(f"unsupported tcgen05 {kind} runtime kwargs: {unsupported}")
    if disable_output_lane is not None:
        _coerce_disable_output_lane_value(disable_output_lane, loc=loc, ip=ip)
        raise ValueError(
            "disable-output-lane/disable_output_lane is not supported for tcgen05 block-scaled MMA"
        )


def _supports_disable_output_lane_field(atom: ir.Value) -> bool:
    try:
        _cute_nvgpu_ir.resolve_atom_field_attr(
            atom, Field.DISABLE_OUTPUT_LANE._to_ir_field_name()
        )
        return True
    except ValueError:
        return False


class CollectorOp(enum.Enum):
    """
    An enumeration for the collector operation qualifier of the MMA for SM107.

    Collector operations control accumulator behavior in SM107 MMA instructions:
    - DISCARD: Discard the accumulator value
    - LASTUSE: Mark this as the last use of the accumulator
    - FILL: Fill the accumulator
    - USE: Use the accumulator normally
    """

    DISCARD = 0
    LASTUSE = 1
    FILL = 2
    USE = 3

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> int:
        return self.value

    @classmethod
    def _missing_(cls, value: Any) -> "CollectorOp":
        """
        Called when the default enum lookup by value fails.
        Enables string-based lookup for user convenience.
        """
        if isinstance(value, str):
            # Remove class prefix if present (e.g., "CollectorOp.DISCARD" -> "DISCARD")
            if "." in value:
                value = value.split(".")[-1]

            # Convert to uppercase for case-insensitive matching
            value_upper = value.upper()

            try:
                return cls[value_upper]
            except KeyError:
                pass

        # If we get here, the value is invalid
        valid_values = ", ".join([f"{member.name} ({member.value})" for member in cls])
        raise ValueError(
            f"Invalid CollectorOp value: {value!r}. Valid values are: {valid_values}"
        )


def _make_sm10x_umma_atom_type(
    shape_attr: Any,
    cta_group: int,
    a_major_ir: Any,
    b_major_ir: Any,
    a_type_ir: Any,
    b_type_ir: Any,
    c_type_ir: Any,
    a_src_ir: Any,
    use_packed_c_format: bool = False,
) -> Any:
    """Construct the appropriate tcgen05 dense UMMA MLIR atom type for the
    current compilation target architecture.

    """
    arch = BaseDSL._get_dsl().get_arch_enum()
    if arch.is_family_of(base_dsl.Arch.sm_107):
        return _cute_nvgpu_ir.MmaAtomSM107UMMAType.get(
            shape_attr,
            cta_group,
            a_major_ir,
            b_major_ir,
            a_type_ir,
            b_type_ir,
            c_type_ir,
            a_src_ir,
            0,  # c_scale_exp
            CollectorOp.DISCARD._to_ir(),
            CollectorOp.DISCARD._to_ir(),
        )
    return _cute_nvgpu_ir.MmaAtomSM100UMMAType.get(
        shape_attr,
        cta_group,
        a_major_ir,
        b_major_ir,
        a_type_ir,
        b_type_ir,
        c_type_ir,
        a_src_ir,
        0,  # c_scale_exp
    )


# Base class for all tcgen05 MMA Ops with syntax `tcgen05.mma.cta_group.kind` used to factor out some internal code
@dataclass(frozen=True)
class MmaOp(Tcgen05MmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape
    cta_group: CtaGroup
    a_src: OperandSource
    a_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    b_major_mode: Union[_OperandMajorMode, OperandMajorMode]

    admissible_archs = base_dsl.Arch.filter(
        lambda arch: (
            arch.is_family_of(base_dsl.Arch.sm_100f)
            or arch.is_family_of(base_dsl.Arch.sm_110f)
        )
    )

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise DSLUserCodeError(
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion=_tcgen05_arch_suggestion(
                    arch, "cute.nvgpu.warp.MmaF16BF16Op"
                ),
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise DSLUserCodeError(
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )
        if not isinstance(self.a_src, OperandSource):
            raise DSLUserCodeError(
                "expects the 'a_src' Op parameter to be a tcgen05.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, _OperandMajorMode) and not isinstance(
            self.a_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'a_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if not isinstance(self.b_major_mode, _OperandMajorMode) and not isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'b_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if isinstance(self.a_major_mode, OperandMajorMode) or isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            warnings.warn(
                "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
                DeprecationWarning,
                stacklevel=2,
            )
            # Normalize the major modes to the new enum type
            # Since this is a frozen dataclass, we need to use the object.__setattr__ method to set the attributes
            object.__setattr__(
                self, "a_major_mode", _OperandMajorMode(self.a_major_mode.value)
            )
            object.__setattr__(
                self, "b_major_mode", _OperandMajorMode(self.b_major_mode.value)
            )
        # Verify the instruction shape
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if (rank(shape_mnk_tuple) not in [2, 3]) or (depth(shape_mnk_tuple) != 1):
            raise DSLUserCodeError(
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = shape_mnk_tuple[0], shape_mnk_tuple[1]
        if self.cta_group == CtaGroup.ONE:
            if m not in [64, 128]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 64 or 128, but got {m}"
                )
            if self.b_dtype.width == 8 and (self.b_major_mode == _OperandMajorMode.MN):
                if (n < 16) or (n > 256) or (n % 16 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 16 <= N <= 256 and N % 16 == 0, but got {n}",
                    )
            else:
                if (n < 8) or (n > 256) or (n % 8 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0, but got {n}",
                    )
        else:
            if m not in [128, 256]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 128 or 256, but got {m}"
                )
            if self.b_dtype.width == 8 and (self.b_major_mode == _OperandMajorMode.MN):
                if (n < 32) or (n > 256) or (n % 32 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 32 <= N <= 256 and N % 32 == 0, but got {n}",
                    )
            else:
                if (n < 16) or (n > 256) or (n % 16 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 16 <= N <= 256 and N % 16 == 0, but got {n}",
                    )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name
            + f"\n  A data type           = {self.a_dtype}"
            + f"\n  B data type           = {self.b_dtype}"
            + f"\n  Accumulator data type = {self.acc_dtype}"
            + f"\n  CTA group             = {self.cta_group}"
            + f"\n  A source location     = {self.a_src}"
            + f"\n  A major mode          = {self.a_major_mode}"
            + f"\n  B major mode          = {self.b_major_mode}"
            + f"\n  Instruction shape MNK = {self.shape_mnk}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand A, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand B, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True


class Sm100MmaTraits(Trait):
    admissible_fields = [
        Field.ACCUMULATE,
        Field.NEGATE_A,
        Field.NEGATE_B,
        Field.DISABLE_OUTPUT_LANE,
    ]

    def set(
        self,
        field: Any,
        value: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        field_ir = normalize_field_to_ir_name(field, self.admissible_fields)
        if field_ir == Field.DISABLE_OUTPUT_LANE._to_ir_field_name():
            val = _coerce_disable_output_lane_value(value, loc=loc, ip=ip)
            if not _supports_disable_output_lane_field(self.value):
                return
        else:
            val = Boolean(value).ir_value(loc=loc, ip=ip)
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, val, loc=loc, ip=ip
        )

    def get(
        self,
        field: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        field_ir = normalize_field_to_ir_name(field, self.admissible_fields)
        if field_ir == Field.DISABLE_OUTPUT_LANE._to_ir_field_name():
            raise ValueError(
                "get(disable_output_lane) is not supported; set it via "
                "cute.nvgpu.tcgen05.Field.DISABLE_OUTPUT_LANE and pass through cute.gemm/mma_atom_call"
            )
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        return _cute_nvgpu_ir.atom_get_value(
            Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
        )

    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> ir.Value:
        disable_output_lane = _extract_disable_output_lane_kwarg(kwargs)
        if kwargs:
            unsupported = ", ".join(sorted(kwargs.keys()))
            raise ValueError(f"unsupported tcgen05 MMA runtime kwargs: {unsupported}")
        if disable_output_lane is None:
            return self.value
        if not _supports_disable_output_lane_field(self.value):
            _coerce_disable_output_lane_value(disable_output_lane, loc=loc, ip=ip)
            return self.value
        field_ir = Field.DISABLE_OUTPUT_LANE._to_ir_field_name()
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        mask_val = _coerce_disable_output_lane_value(
            disable_output_lane, loc=loc, ip=ip
        )
        return _cute_nvgpu_ir.atom_set_value(self.value, attr, mask_val, loc=loc, ip=ip)


# Base class for all tcgen05 BlockScaled MMA Ops with syntax `tcgen05.mma.cta_group.kind.block_scale` used to factor out some internal code
@dataclass(frozen=True)
class BlockScaledMmaOp(Tcgen05MmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    sf_dtype: Type[Numeric]
    sf_vec_size: int
    shape_mnk: Shape
    cta_group: CtaGroup
    a_src: OperandSource
    a_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    b_major_mode: Union[_OperandMajorMode, OperandMajorMode]

    admissible_archs = [
        base_dsl.Arch.sm_100a,
        base_dsl.Arch.sm_100f,
        base_dsl.Arch.sm_103a,
        base_dsl.Arch.sm_107a,
        base_dsl.Arch.sm_110a,
    ]

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise DSLUserCodeError(
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion=_tcgen05_arch_suggestion(
                    arch, "cute.nvgpu.warp.MmaMXF4Op / MmaMXF4NVF4Op / MmaMXF8Op"
                ),
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise DSLUserCodeError(
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )
        if not isinstance(self.a_src, OperandSource):
            raise DSLUserCodeError(
                "expects the 'a_src' Op parameter to be a tcgen05.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, _OperandMajorMode) and not isinstance(
            self.a_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'a_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if not isinstance(self.b_major_mode, _OperandMajorMode) and not isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'b_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if isinstance(self.a_major_mode, OperandMajorMode) or isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            warnings.warn(
                "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
                DeprecationWarning,
                stacklevel=2,
            )
        # Verify the instruction shape
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if (rank(shape_mnk_tuple) not in [2, 3]) or (depth(shape_mnk_tuple) != 1):
            raise DSLUserCodeError(
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = shape_mnk_tuple[0], shape_mnk_tuple[1]
        if self.cta_group == CtaGroup.ONE:
            if m != 128:
                raise DSLUserCodeError(f"expects the M-mode to be 128, but got {m}")

            if (n < 8) or (n > 256) or (n % 8 != 0):
                raise DSLUserCodeError(
                    f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0, but got {n}",
                )
        else:
            if m not in [128, 256]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 128 or 256, but got {m}"
                )
            if (n < 16) or (n > 256) or (n % 16 != 0):
                raise DSLUserCodeError(
                    f"expects the N-mode to satisfy 16 <= N <= 256 and N % 16 == 0, but got {n}",
                )
        if self.sf_vec_size not in [16, 32]:
            raise DSLUserCodeError(
                f"expects the scale factor vector size to be 16 or 32, but got {self.sf_vec_size}",
            )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name
            + f"\n  A data type               = {self.a_dtype}"
            + f"\n  B data type               = {self.b_dtype}"
            + f"\n  Accumulator data type     = {self.acc_dtype}"
            + f"\n  Scale factor data type    = {self.sf_dtype}"
            + f"\n  Scale factor vector size  = {self.sf_vec_size}"
            + f"\n  CTA group                 = {self.cta_group}"
            + f"\n  A source location         = {self.a_src}"
            + f"\n  A major mode              = {self.a_major_mode}"
            + f"\n  B major mode              = {self.b_major_mode}"
            + f"\n  Instruction shape MNK     = {self.shape_mnk}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand A, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand B, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True


class BlockScaledMmaTraits(Trait):
    admissible_fields = [
        Field.ACCUMULATE,
        Field.NEGATE_A,
        Field.NEGATE_B,
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
        field_ir = normalize_field_to_ir_name(field, self.admissible_fields)
        # Derive boolean/pointer IR names from enum values, no hard-coded strings.
        bool_field_ir = {
            f._to_ir_field_name()
            for f in self.admissible_fields
            if f in (Field.ACCUMULATE, Field.NEGATE_A, Field.NEGATE_B)
        }
        ptr_field_ir = {
            f._to_ir_field_name()
            for f in self.admissible_fields
            if f in (Field.SFA, Field.SFB)
        }
        # Coerce value based on field kind
        if field_ir in bool_field_ir:
            val = Boolean(value).ir_value(loc=loc, ip=ip)
        elif field_ir in ptr_field_ir:
            if not isinstance(value, Pointer):
                raise ValueError(
                    f"expects value to be a pointer for {field_ir}, but got {type(value).__name__}"
                )
            val = cast(Any, value).value
        else:
            raise ValueError(f"unsupported field: {field_ir}")
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, val, loc=loc, ip=ip
        )

    def get(
        self,
        field: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        # Only boolean-returning fields supported for get. Derive from admissible_fields.
        gettable_fields = [
            f for f in self.admissible_fields if f not in (Field.SFA, Field.SFB)
        ]
        field_ir = normalize_field_to_ir_name(field, gettable_fields)
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        return _cute_nvgpu_ir.atom_get_value(
            Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
        )

    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> ir.Value:
        _reject_block_scaled_disable_output_lane_kwargs(
            kwargs, "block-scaled MMA", loc=loc, ip=ip
        )
        return self.value


# Base class for all tcgen05 Sparse MMA Ops with syntax `tcgen05.mma.cta_group.kind.sparse` used to factor out some internal code
@dataclass(frozen=True)
class SparseMmaOp(Tcgen05MmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    shape_mnk: Shape
    cta_group: CtaGroup
    a_src: OperandSource
    a_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    b_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    sparse_metadata_format: SparseMetadataFormat

    admissible_archs = base_dsl.Arch.filter(
        lambda arch: (
            arch.is_family_of(base_dsl.Arch.sm_100f)
            or arch.is_family_of(base_dsl.Arch.sm_110f)
        )
    )

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise DSLUserCodeError(
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise DSLUserCodeError(
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )
        if not isinstance(self.a_src, OperandSource):
            raise DSLUserCodeError(
                "expects the 'a_src' Op parameter to be a tcgen05.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, _OperandMajorMode) and not isinstance(
            self.a_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'a_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if not isinstance(self.b_major_mode, _OperandMajorMode) and not isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'b_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )

        if isinstance(self.a_major_mode, OperandMajorMode) or isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            warnings.warn(
                "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
                DeprecationWarning,
                stacklevel=2,
            )

        if not isinstance(self.sparse_metadata_format, SparseMetadataFormat):
            raise DSLUserCodeError(
                "expects the 'sparse_metadata_format' Op parameter to be a tcgen05.SparseMetadataFormat instance",
            )
        # Verify the instruction shape
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if (rank(shape_mnk_tuple) not in [2, 3]) or (depth(shape_mnk_tuple) != 1):
            raise DSLUserCodeError(
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = shape_mnk_tuple[0], shape_mnk_tuple[1]
        # For sparse MMA, the shape validation follows the same rules as dense MMA
        # but the K dimension is typically doubled in the derived classes
        if self.cta_group == CtaGroup.ONE:
            if m not in [64, 128]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 64 or 128, but got {m}"
                )
            if m == 64:
                if (n < 8) or (n > 256) or (n % 8 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0, but got {n}",
                    )
            elif m == 128:
                if (n < 16) or (n > 256) or (n % 16 != 0):
                    raise DSLUserCodeError(
                        f"expects the N-mode to satisfy 16 <= N <= 256 and N % 16 == 0, but got {n}",
                    )
        else:
            if m not in [128, 256]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 128 or 256, but got {m}"
                )
            if (n < 32) or (n > 256) or (n % 32 != 0):
                raise DSLUserCodeError(
                    f"expects the N-mode to satisfy 32 <= N <= 256 and N % 32 == 0, but got {n}",
                )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name
            + f"\n  A data type               = {self.a_dtype}"
            + f"\n  B data type               = {self.b_dtype}"
            + f"\n  Accumulator data type     = {self.acc_dtype}"
            + f"\n  CTA group                 = {self.cta_group}"
            + f"\n  A source location         = {self.a_src}"
            + f"\n  A major mode              = {self.a_major_mode}"
            + f"\n  B major mode              = {self.b_major_mode}"
            + f"\n  Instruction shape MNK     = {self.shape_mnk}"
            + f"\n  Sparse metadata format    = {self.sparse_metadata_format}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand A, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand B, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True


class SparseMmaTraits(Trait):
    admissible_fields = [
        Field.ACCUMULATE,
        Field.NEGATE_A,
        Field.NEGATE_B,
        Field.METADATA,
    ]

    def set(
        self,
        field: Any,
        value: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        field_ir = normalize_field_to_ir_name(field, self.admissible_fields)
        # Derive boolean/pointer IR names from enum values, no hard-coded strings.
        bool_field_ir = {
            f._to_ir_field_name()
            for f in self.admissible_fields
            if f in (Field.ACCUMULATE, Field.NEGATE_A, Field.NEGATE_B)
        }
        ptr_field_ir = {
            f._to_ir_field_name() for f in self.admissible_fields if f is Field.METADATA
        }
        # Coerce value based on field kind
        if field_ir in bool_field_ir:
            val = Boolean(value).ir_value(loc=loc, ip=ip)
        elif field_ir in ptr_field_ir:
            if not isinstance(value, Pointer):
                raise ValueError(
                    f"expects value to be a pointer for {field_ir}, but got {type(value).__name__}"
                )
            val = cast(Any, value).value
        else:
            raise ValueError(f"unsupported field: {field_ir}")
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, val, loc=loc, ip=ip
        )

    def get(
        self,
        field: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        # Only boolean-returning fields supported for get. Derive from admissible_fields.
        gettable_fields = [f for f in self.admissible_fields if f is not Field.METADATA]
        field_ir = normalize_field_to_ir_name(field, gettable_fields)
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        return _cute_nvgpu_ir.atom_get_value(
            Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
        )


# Base class for all tcgen05 BlockScaled Sparse MMA Ops used to factor out some internal code
@dataclass(frozen=True)
class BlockScaledSparseMmaOp(Tcgen05MmaOp):
    a_dtype: Type[Numeric]
    b_dtype: Type[Numeric]
    acc_dtype: Type[Numeric]
    sf_dtype: Type[Numeric]
    sf_vec_size: int
    shape_mnk: Shape
    cta_group: CtaGroup
    a_src: OperandSource
    a_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    b_major_mode: Union[_OperandMajorMode, OperandMajorMode]
    sparse_metadata_format: SparseMetadataFormat

    admissible_archs = [
        base_dsl.Arch.sm_100a,
        base_dsl.Arch.sm_103a,
        base_dsl.Arch.sm_107a,
    ]

    def __post_init__(self) -> None:
        # Verify arch
        arch = BaseDSL._get_dsl().get_arch_enum()
        if arch not in self.admissible_archs:
            raise DSLUserCodeError(
                f"expects arch to be one of {self.admissible_archs}, but got {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        # Verify that the user provided enum values
        if not isinstance(self.cta_group, CtaGroup):
            raise DSLUserCodeError(
                "expects the 'cta_group' Op parameter to be a tcgen05.CtaGroup instance",
            )
        if not isinstance(self.a_src, OperandSource):
            raise DSLUserCodeError(
                "expects the 'a_src' Op parameter to be a tcgen05.OperandSource instance",
            )
        if not isinstance(self.a_major_mode, _OperandMajorMode) and not isinstance(
            self.a_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'a_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if not isinstance(self.b_major_mode, _OperandMajorMode) and not isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            raise DSLUserCodeError(
                "expects the 'b_major_mode' Op parameter to be a cute.nvgpu.OperandMajorMode or tcgen05.OperandMajorMode (deprecated) instance",
            )
        if isinstance(self.a_major_mode, OperandMajorMode) or isinstance(
            self.b_major_mode, OperandMajorMode
        ):
            warnings.warn(
                "tcgen05.OperandMajorMode is deprecated, use cute.nvgpu.OperandMajorMode instead",
                DeprecationWarning,
                stacklevel=2,
            )
        if not isinstance(self.sparse_metadata_format, SparseMetadataFormat):
            raise DSLUserCodeError(
                "expects the 'sparse_metadata_format' Op parameter to be a tcgen05.SparseMetadataFormat instance",
            )
        # Verify the instruction shape
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if (rank(shape_mnk_tuple) not in [2, 3]) or (depth(shape_mnk_tuple) != 1):
            raise DSLUserCodeError(
                f"expected a flat rank 2 or 3 tuple for the 'shape_mnk' Op parameter, "
                f"but got {self.shape_mnk}",
            )
        m, n = shape_mnk_tuple[0], shape_mnk_tuple[1]
        if self.cta_group == CtaGroup.ONE:
            if m != 128:
                raise DSLUserCodeError(f"expects the M-mode to be 128, but got {m}")

            if (n < 8) or (n > 256) or (n % 8 != 0):
                raise DSLUserCodeError(
                    f"expects the N-mode to satisfy 8 <= N <= 256 and N % 8 == 0, but got {n}",
                )
        else:
            if m not in [128, 256]:
                raise DSLUserCodeError(
                    f"expects the M-mode to be 128 or 256, but got {m}"
                )
            if (n < 16) or (n > 256) or (n % 16 != 0):
                raise DSLUserCodeError(
                    f"expects the N-mode to satisfy 16 <= N <= 256 and N % 16 == 0, but got {n}",
                )

    def __str__(self) -> str:
        return (
            self.__class__.descriptive_name
            + f"\n  A data type               = {self.a_dtype}"
            + f"\n  B data type               = {self.b_dtype}"
            + f"\n  Accumulator data type     = {self.acc_dtype}"
            + f"\n  Scale factor data type    = {self.sf_dtype}"
            + f"\n  Scale factor vector size  = {self.sf_vec_size}"
            + f"\n  CTA group                 = {self.cta_group}"
            + f"\n  A source location         = {self.a_src}"
            + f"\n  A major mode              = {self.a_major_mode}"
            + f"\n  B major mode              = {self.b_major_mode}"
            + f"\n  Instruction shape MNK     = {self.shape_mnk}"
            + f"\n  Sparse metadata format    = {self.sparse_metadata_format}"
        )

    def _verify_fragment_A(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand A, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True

    def _verify_fragment_B(
        self,
        input: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool:
        if input.memspace == AddressSpace.smem and isinstance(
            input.layout.type, _cute_ir.ComposedLayoutType
        ):
            raise DSLUserCodeError(
                f"Expected affine layout for {self._make_trait()}'s operand B, "
                f"but got composed layout instead: {input.layout}"
                f"\nPlease use recast_ptr(ptr, {input.layout.inner}, element_type) operation to move swizzle to the ptr",
            )
        return True


class BlockScaledSparseMmaTraits(Trait):
    admissible_fields = [
        Field.ACCUMULATE,
        Field.NEGATE_A,
        Field.NEGATE_B,
        Field.SFA,
        Field.SFB,
        Field.METADATA,
    ]

    def set(
        self,
        field: Any,
        value: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        field_ir = normalize_field_to_ir_name(field, self.admissible_fields)
        # Derive boolean/pointer IR names from enum values, no hard-coded strings.
        bool_field_ir = {
            f._to_ir_field_name()
            for f in self.admissible_fields
            if f in (Field.ACCUMULATE, Field.NEGATE_A, Field.NEGATE_B)
        }
        ptr_field_ir = {
            f._to_ir_field_name()
            for f in self.admissible_fields
            if f in (Field.SFA, Field.SFB, Field.METADATA)
        }
        # Coerce value based on field kind
        if field_ir in bool_field_ir:
            val = Boolean(value).ir_value(loc=loc, ip=ip)
        elif field_ir in ptr_field_ir:
            if not isinstance(value, Pointer):
                raise ValueError(
                    f"expects value to be a pointer for {field_ir}, but got {type(value).__name__}"
                )
            val = cast(Any, value).value
        else:
            raise ValueError(f"unsupported field: {field_ir}")
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        self.value = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, val, loc=loc, ip=ip
        )

    def get(
        self,
        field: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        # Only boolean-returning fields supported for get. Derive from admissible_fields.
        gettable_fields = [
            f
            for f in self.admissible_fields
            if f not in (Field.SFA, Field.SFB, Field.METADATA)
        ]
        field_ir = normalize_field_to_ir_name(field, gettable_fields)
        attr = _cute_nvgpu_ir.resolve_atom_field_attr(self.value, field_ir)
        return _cute_nvgpu_ir.atom_get_value(
            Boolean.mlir_type, self.value, attr, loc=loc, ip=ip
        )

    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> ir.Value:
        _reject_block_scaled_disable_output_lane_kwargs(
            kwargs, "block-scaled sparse MMA", loc=loc, ip=ip
        )
        return self.value


#
# TF32 MMA
#


@dataclass(frozen=True)
class MmaTF32Op(MmaOp):
    """
    TF32 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::tf32`` qualifier.

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | TF32        | TF32        | F32      | 8     |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), but only with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.
    * For completion of tcgen05 TMEM load/store operations, use
      ``tcgen05.wait::ld`` / ``tcgen05.wait::st`` (PTX waits).
    * For ordering tcgen05 operations across threads, use
      ``tcgen05.fence::before_thread_sync`` / ``tcgen05.fence::after_thread_sync``
      (PTX fences) together with an execution-order synchronization mechanism.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 TF32 MMA Operation"

    def __init__(
        self,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
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
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaTF32Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _make_sm10x_umma_atom_type(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
        )
        operands = [
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
        ]
        return MmaTF32Trait(
            make_atom(
                ty,
                operands,
                loc=loc,
                ip=ip,
            )
        )


class MmaTF32Trait(Sm100MmaTraits):
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

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | F16         | F16         | F16, F32 | 16    |
    +-------------+-------------+----------+-------+
    | BF16        | BF16        | F32      | 16    |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 F16/BF16 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
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
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Float16 or BFloat16",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 16
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaF16BF16Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _make_sm10x_umma_atom_type(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            use_packed_c_format=(
                self.acc_dtype is Float16
                and self.a_dtype is Float16
                and self.b_dtype is Float16
            ),
        )
        operands = [
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
        ]
        return MmaF16BF16Trait(
            make_atom(
                ty,
                operands,
                loc=loc,
                ip=ip,
            )
        )


class MmaF16BF16Trait(Sm100MmaTraits):
    pass


@dataclass(frozen=True)
class MmaF16BF16SparseOp(SparseMmaOp):
    """
    F16/BF16 tcgen05 Sparse MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma-sp>`__.
    This Operation corresponds to the ``.kind::f16`` qualifier with sparse support.

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | F16         | F16         | F16, F32 | 32    |
    +-------------+-------------+----------+-------+
    | BF16        | BF16        | F32      | 32    |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * Sparse MMA takes A with its metadata: pass it in ``cute.gemm(...)`` as ``[a, e]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 sparse MMA
        cute.gemm(mma_atom, d, [a, e], b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 F16/BF16 Sparse MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        sparse_metadata_format: SparseMetadataFormat,
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
            sparse_metadata_format,
        )
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in [Float16, BFloat16]:
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Float16 or BFloat16",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 32  # For sparse, K is doubled compared to dense F16/BF16
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaF16BF16SparseTrait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMASparseType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            T.ui8(),
            self.sparse_metadata_format._to_ir(),
            self.a_src._to_ir(),
            0,  # cScaleExp
        )

        return MmaF16BF16SparseTrait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        Uint8,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaF16BF16SparseTrait(SparseMmaTraits):
    pass


@dataclass(frozen=True)
class MmaFP8SparseOp(SparseMmaOp):
    """
    FP8 tcgen05 Sparse MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma-sp>`__.
    This Operation corresponds to the ``.kind::f8f6f4`` qualifier with sparse support.

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | E4M3, E5M2  | E4M3, E5M2  | F16, F32 | 64    |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * A and B data types must be the same
    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * With B-major=MN: Mma-N step doubles (16 for CG1, 32 for CG2)
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * Sparse MMA takes A with its metadata: pass it in ``cute.gemm(...)`` as ``[a, e]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 sparse MMA
        cute.gemm(mma_atom, d, [a, e], b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 FP8 Sparse MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        sparse_metadata_format: SparseMetadataFormat,
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
            sparse_metadata_format,
        )
        self._verify()

    def _verify(self) -> None:
        if self.a_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        instruction_k = 64
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaFP8SparseTrait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMASparseType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            T.ui8(),
            self.sparse_metadata_format._to_ir(),
            self.a_src._to_ir(),
            0,  # cScaleExp
        )

        return MmaFP8SparseTrait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        Uint8,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaFP8SparseTrait(SparseMmaTraits):
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

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | Int8, Uint8 | Int8, Uint8 | Int32    | 32    |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * CtaGroup.ONE: Mma-M in {64, 128}; Mma-N in {8, 16, 24, 32, 48, 64, 80, ..., 256}
      (step 8 for Mma-N <= 32, then step 16 for Mma-N > 32; values like 40, 56 are invalid)
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B signedness are independent (mixed signed/unsigned allowed)
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With B MN-major (8-bit B transpose): Mma-N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 I8 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
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
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Int8 or Uint8",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Instruction shape verification
        instruction_k = 32
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaI8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        # MmaI8 only operates on integer dtypes.
        assert issubclass(self.a_dtype, Integer) and issubclass(self.b_dtype, Integer)
        ty = _make_sm10x_umma_atom_type(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            (T.si8() if self.a_dtype.signed else T.ui8()),
            (T.si8() if self.b_dtype.signed else T.ui8()),
            T.si32(),
            self.a_src._to_ir(),
        )
        operands = [
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
        ]
        return MmaI8Trait(
            make_atom(
                ty,
                operands,
                loc=loc,
                ip=ip,
            )
        )


class MmaI8Trait(Sm100MmaTraits):
    pass


#
# F8F6F4 MMA
#


@deprecated("MmaFP8Op is deprecated, use MmaF8F6F4Op instead")
@dataclass(frozen=True)
class MmaFP8Op(MmaOp):
    """
    F8 tcgen05 MMA Operation.

    .. deprecated::
        Use :class:`MmaF8F6F4Op` instead.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.

    **Supported data type combinations:**

    +-------------+-------------+----------+-------+
    | A Data Type | B Data Type | Acc Type | Mma-K |
    +=============+=============+==========+=======+
    | E4M3, E5M2  | E4M3, E5M2  | F16, F32 | 32    |
    +-------------+-------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * A and B data types must be the same
    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * With B-major=MN: Mma-N step doubles (16 for CG1, 32 for CG2)
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 F8 MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
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
        if self.a_dtype not in [
            Float8E5M2,
            Float8E4M3FN,
        ]:
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Float8E5M2, Float8E4M3FN"
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 32
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaFP8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _make_sm10x_umma_atom_type(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            use_packed_c_format=(self.acc_dtype is Float16),
        )
        operands = [
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
        ]
        return MmaFP8Trait(
            make_atom(
                ty,
                operands,
                loc=loc,
                ip=ip,
            )
        )


class MmaFP8Trait(Sm100MmaTraits):
    pass


@dataclass(frozen=True)
class MmaF8F6F4Op(MmaOp):
    """
    F8F6F4 tcgen05 MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.

    **Supported data type combinations:**

    +------------------------------+------------------------------+----------+-------+
    | A Data Type                  | B Data Type                  | Acc Type | Mma-K |
    +==============================+==============================+==========+=======+
    | E4M3, E5M2, E3M2, E2M3, E2M1 | E4M3, E5M2, E3M2, E2M3, E2M1 | F16, F32 | 32    |
    +------------------------------+------------------------------+----------+-------+

    **Supported architectures:** sm_100a, sm_100f, sm_103a, sm_103f, sm_110a, sm_110f

    **Constraints:**

    * A and B data types are independent (mixed F8/F6/F4 allowed)
    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * With B-major=MN: Mma-N step doubles (16 for CG1, 32 for CG2)
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 F8F6F4 MMA Operation"

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
    ) -> None:
        super().__init__(
            a_dtype,
            b_dtype,
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
        if self.a_dtype not in _F8F6F4_TYPES:
            raise DSLUserCodeError(
                "expects the 'a_dtype' Op parameter to be one of "
                "Float8E5M2, Float8E4M3FN, Float6E3M2FN, Float6E2M3FN, or Float4E2M1FN",
            )
        if self.b_dtype not in _F8F6F4_TYPES:
            raise DSLUserCodeError(
                "expects the 'b_dtype' Op parameter to be one of "
                "Float8E5M2, Float8E4M3FN, Float6E3M2FN, Float6E2M3FN, or Float4E2M1FN",
            )
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Instruction shape verification
        instruction_k = 32
        shape_mnk_tuple = cast(Tuple[Any, ...], self.shape_mnk)
        if rank(self.shape_mnk) == 2:
            shape_mnk_tuple = (*shape_mnk_tuple, instruction_k)
            object.__setattr__(self, "shape_mnk", shape_mnk_tuple)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaF8F6F4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _make_sm10x_umma_atom_type(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            use_packed_c_format=(self.acc_dtype is Float16),
        )
        operands = [
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            Boolean(False).ir_value(loc=loc, ip=ip),
            _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
        ]
        return MmaF8F6F4Trait(
            make_atom(
                ty,
                operands,
                loc=loc,
                ip=ip,
            )
        )


class MmaF8F6F4Trait(Sm100MmaTraits):
    pass


#
# SM107 (Rubin) MMA
#


@dataclass(frozen=True)
class SM107MmaFP8Op(MmaOp):
    """
    F8 SM107 (Rubin) MMA Operation.

    This MMA operation is specifically designed for SM107 architecture (Rubin),
    with support for collector operations and extended K dimension (64).

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.

    **Supported data type combinations:**

    +-------------+-------------+----------+--------+
    | A Data Type | B Data Type | Acc Type | Mma-K  |
    +=============+=============+==========+========+
    | E4M3, E5M2  | E4M3, E5M2  | F16, F32 | 32, 64 |
    +-------------+-------------+----------+--------+

    **Supported architectures:** sm_107a

    **Constraints:**

    * A and B data types are independent (mixed FP8 allowed)
    * CtaGroup.ONE: Mma-M in {64, 128}; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * With B-major=MN: Mma-N step doubles (16 for CG1, 32 for CG2)
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, a, b, c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 SM107 F8 MMA Operation"

    # Dataclass fields must have default values when parent fields don't
    a_collector_op: CollectorOp = CollectorOp.DISCARD
    b_collector_op: CollectorOp = CollectorOp.DISCARD

    admissible_archs = [
        base_dsl.Arch.sm_107,
        base_dsl.Arch.sm_107a,
        base_dsl.Arch.sm_107f,
    ]

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        a_collector_op: CollectorOp | str = CollectorOp.DISCARD,
        b_collector_op: CollectorOp | str = CollectorOp.DISCARD,
    ) -> None:
        # Convert string collector ops to CollectorOp enums
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)

        # Initialize parent class fields first
        super().__init__(
            a_dtype,
            b_dtype,
            acc_dtype,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        # Set collector ops after parent initialization (required for frozen dataclass)
        object.__setattr__(self, "a_collector_op", a_collector_op)
        object.__setattr__(self, "b_collector_op", b_collector_op)

        # Additional SM107-specific verification
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise DSLUserCodeError(
                "expects the 'a_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        if self.b_dtype not in [Float8E5M2, Float8E4M3FN]:
            raise DSLUserCodeError(
                "expects the 'b_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        # Accumulator data type verification
        if self.acc_dtype not in [Float16, Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be one of Float16 or Float32",
            )
        # Verify collector ops
        if not isinstance(self.a_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'a_collector_op' Op parameter to be a CollectorOp instance",
            )
        if not isinstance(self.b_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'b_collector_op' Op parameter to be a CollectorOp instance",
            )
        # Instruction shape verification - SM107 primarily uses K=64
        # Note: K=32 is also supported for compatibility, but K=64 is the recommended default for SM107
        instruction_k_list = [32, 64]
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            # Default to 64 (SM107's native K dimension)
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, 64))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] not in instruction_k_list:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be one of {instruction_k_list}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "SM107MmaFP8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM107UMMAType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.a_src._to_ir(),
            0,  # c_scale_exp
            self.a_collector_op._to_ir(),
            self.b_collector_op._to_ir(),
        )
        return SM107MmaFP8Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    _make_disable_output_lane_default(self.cta_group, loc=loc, ip=ip),
                ],
                loc=loc,
                ip=ip,
            )
        )


class SM107MmaFP8Trait(Sm100MmaTraits):
    pass


#
# MXF8F6F4 MMA
#


@deprecated("MmaMXF8Op is deprecated, use MmaMXF8F6F4Op instead")
@dataclass(frozen=True)
class MmaMXF8Op(BlockScaledMmaOp):
    """
    MXF8 tcgen05 BlockScaled MMA Operation.

    .. deprecated::
        Use :class:`MmaMXF8F6F4Op` instead.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf8f6f4`` qualifier.

    **Supported data type combinations:**

    +-------------+-------------+--------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+==============+==========+=======+=============+
    | E4M3, E5M2  | E4M3, E5M2  | UE8M0        | F32      | 32    | 32          |
    +-------------+-------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a

    **Constraints:**

    * A and B data types must be the same
    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CtaGroup.ONE, 32 for CtaGroup.TWO.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 MXF8 BlockScaled MMA Operation"

    def __init__(
        self,
        ab_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
    ) -> None:
        super().__init__(
            ab_dtype,
            ab_dtype,
            Float32,
            Float8E8M0FNU,
            32,
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
            raise DSLUserCodeError(
                "expects the 'ab_dtype' Op parameter to be one of Float8E5M2 or Float8E4M3FN",
            )
        assert self.b_dtype == self.a_dtype, "a_dtype and b_dtype must be the same"
        # Instruction shape verification
        instruction_k = 32
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF8Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
        )
        return MmaMXF8Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaMXF8Trait(BlockScaledMmaTraits):
    pass


@dataclass(frozen=True)
class MmaMXF8F6F4Op(BlockScaledMmaOp):
    """
    MXF8F6F4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf8f6f4`` qualifier.

    **Supported data type combinations:**

    +------------------------------+------------------------------+--------------+----------+-------+-------------+
    | A Data Type                  | B Data Type                  | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +==============================+==============================+==============+==========+=======+=============+
    | E4M3, E5M2, E3M2, E2M3, E2M1 | E4M3, E5M2, E3M2, E2M3, E2M1 | UE8M0        | F32      | 32    | 32          |
    +------------------------------+------------------------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a

    **Constraints:**

    * A and B data types are independent (mixed F8/F6/F4 allowed)
    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CtaGroup.ONE, 32 for CtaGroup.TWO.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 MXF8F6F4 BlockScaled MMA Operation"

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: Union[_OperandMajorMode, OperandMajorMode],
        b_major_mode: Union[_OperandMajorMode, OperandMajorMode],
    ) -> None:
        super().__init__(
            a_dtype,
            b_dtype,
            Float32,
            Float8E8M0FNU,
            32,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.a_dtype not in _F8F6F4_TYPES:
            raise DSLUserCodeError(
                "expects the 'a_dtype' Op parameter to be one of "
                "Float8E5M2, Float8E4M3FN, Float6E3M2FN, Float6E2M3FN, or Float4E2M1FN",
            )
        if self.b_dtype not in _F8F6F4_TYPES:
            raise DSLUserCodeError(
                "expects the 'b_dtype' Op parameter to be one of "
                "Float8E5M2, Float8E4M3FN, Float6E3M2FN, Float6E2M3FN, or Float4E2M1FN",
            )

        # Instruction shape verification
        instruction_k = 32
        shape_mnk_tuple = cast(Tuple[Any, ...], self.shape_mnk)
        if rank(self.shape_mnk) == 2:
            shape_mnk_tuple = (*shape_mnk_tuple, instruction_k)
            object.__setattr__(self, "shape_mnk", shape_mnk_tuple)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF8F6F4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
        )
        return MmaMXF8F6F4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaMXF8F6F4Trait(BlockScaledMmaTraits):
    pass


#
# MXF4 MMA
#


@dataclass(frozen=True)
class MmaMXF4Op(BlockScaledMmaOp):
    """
    MXF4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf4`` qualifier.

    **Supported data type combinations:**

    +-------------+-------------+--------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+==============+==========+=======+=============+
    | E2M1        | E2M1        | UE8M0        | F32      | 64    | 32          |
    +-------------+-------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a

    **Constraints:**

    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * Transpose (MN-major) is not supported. Both A and B must be K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 MXF4 BlockScaled MMA Operation"

    def __init__(
        self,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
    ) -> None:
        super().__init__(
            Float4E2M1FN,
            Float4E2M1FN,
            Float32,
            Float8E8M0FNU,
            32,
            instruction_shape,
            cta_group,
            a_src,
            _OperandMajorMode.K,
            _OperandMajorMode.K,
        )
        self._verify()

    def _verify(self) -> None:
        # Instruction shape verification
        instruction_k = 64
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
        )
        return MmaMXF4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaMXF4Trait(BlockScaledMmaTraits):
    pass


#
# MXF4NVF4 MMA
#


@dataclass(frozen=True)
class MmaMXF4NVF4Op(BlockScaledMmaOp):
    """
    MXF4NVF4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf4nvf4`` qualifier.

    **Supported data type combinations:**

    +-------------+-------------+--------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+==============+==========+=======+=============+
    | E2M1        | E2M1        | UE8M0, UE4M3 | F32      | 64    | 16          |
    +-------------+-------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a

    **Constraints:**

    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * Transpose (MN-major) is not supported. Both A and B must be K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 MXF4NVF4 BlockScaled MMA Operation"

    def __init__(
        self,
        sf_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
    ) -> None:
        super().__init__(
            Float4E2M1FN,
            Float4E2M1FN,
            Float32,
            sf_dtype,
            16,
            instruction_shape,
            cta_group,
            a_src,
            _OperandMajorMode.K,
            _OperandMajorMode.K,
        )
        self._verify()

    def _verify(self) -> None:
        # Scale Factor data type verification
        if self.sf_dtype not in [Float8E8M0FNU, Float8E4M3FN]:
            raise DSLUserCodeError(
                "expects the 'sf_dtype' Op parameter to be one of Float8E8M0FNU",
            )
        # Instruction shape verification
        instruction_k = 64
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4NVF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
        )
        return MmaMXF4NVF4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class MmaMXF4NVF4Trait(BlockScaledMmaTraits):
    pass


#
# SM103 MXF4 MMA
#


@dataclass(frozen=True)
class SM103MmaMXF4Op(BlockScaledMmaOp):
    """
    SM103 MXF4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf4`` qualifier.
    This Operation is for SM103.

    **Supported data type combinations:**

    +-------------+-------------+--------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+==============+==========+=======+=============+
    | E2M1        | E2M1        | UE8M0        | F32      | 96    | 32          |
    +-------------+-------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a (K=96 requires sm_103a+)

    **Constraints:**

    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * Transpose (MN-major) is not supported. Both A and B must be K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 SM103 MXF4 BlockScaled MMA Operation"

    def __init__(
        self,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
    ) -> None:
        super().__init__(
            Float4E2M1FN,
            Float4E2M1FN,
            Float32,
            Float8E8M0FNU,
            32,
            instruction_shape,
            cta_group,
            a_src,
            _OperandMajorMode.K,
            _OperandMajorMode.K,
        )
        self._verify()

    def _verify(self) -> None:
        # Instruction shape verification
        instruction_k = 96
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
            1030,
        )
        return MmaMXF4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


#
# SM103 MXF4NVF4 MMA
#


@dataclass(frozen=True)
class SM103MmaMXF4NVF4Op(BlockScaledMmaOp):
    """
    SM103 MXF4NVF4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf4nvf4`` qualifier.
    This Operation is for SM103.

    **Supported data type combinations:**

    +-------------+-------------+--------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+==============+==========+=======+=============+
    | E2M1        | E2M1        | UE8M0, UE4M3 | F32      | 96    | 16          |
    +-------------+-------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_100a, sm_103a (K=96 requires sm_103a+)

    **Constraints:**

    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M in {128, 256}; 16 <= Mma-N <= 256, step 16
    * Transpose (MN-major) is not supported. Both A and B must be K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 SM103 MXF4NVF4 BlockScaled MMA Operation"

    def __init__(
        self,
        sf_dtype: Type[Numeric],
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
    ) -> None:
        super().__init__(
            Float4E2M1FN,
            Float4E2M1FN,
            Float32,
            sf_dtype,
            16,
            instruction_shape,
            cta_group,
            a_src,
            _OperandMajorMode.K,
            _OperandMajorMode.K,
        )
        self._verify()

    def _verify(self) -> None:
        # Scale Factor data type verification
        if self.sf_dtype not in [Float8E8M0FNU, Float8E4M3FN]:
            raise DSLUserCodeError(
                "expects the 'sf_dtype' Op parameter to be one of Float8E8M0FNU",
            )
        # Instruction shape verification
        instruction_k = 96
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaMXF4NVF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM100UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
            1030,
        )
        return MmaMXF4NVF4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                    core.make_ptr(
                        self.sf_dtype, 0, AddressSpace.tmem, loc=loc, ip=ip
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


#
# SM107 MXF4NVF4 MMA
#


@dataclass(frozen=True)
class SM107MmaMXF4NVF4Op(BlockScaledMmaOp):
    """
    SM107 MXF4NVF4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf4nvf4`` qualifier.
    This Operation is for SM107.

    **Supported data type combinations:**

    +-------------+-------------+-----------------------+----------+-------+-------------+
    | A Data Type | B Data Type | SF Data Type          | Acc Type | Mma-K | SF Vec Size |
    +=============+=============+=======================+==========+=======+=============+
    | E2M1        | E2M1        | UE8M0, UE4M3, NV8E5M3 | F32      | 128   | 16, 32      |
    +-------------+-------------+-----------------------+----------+-------+-------------+

    **Supported architectures:** sm_107a

    **Constraints:**

    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M = 256; 16 <= Mma-N <= 256, step 16
    * Transpose (MN-major) is not supported. Both A and B must be K-major.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 SM107 MXF4NVF4 BlockScaled MMA Operation"

    # Dataclass fields must have default values when parent fields don't
    a_collector_op: CollectorOp = CollectorOp.DISCARD
    b_collector_op: CollectorOp = CollectorOp.DISCARD

    admissible_archs = base_dsl.Arch.filter(
        lambda arch: arch.is_family_of(base_dsl.Arch.sm_107)
    )

    def __init__(
        self,
        sf_dtype: Type[Numeric],
        sf_vec_size: int,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_collector_op: CollectorOp | str = CollectorOp.DISCARD,
        b_collector_op: CollectorOp | str = CollectorOp.DISCARD,
    ) -> None:
        # Convert string collector ops to CollectorOp enums
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)

        super().__init__(
            Float4E2M1FN,
            Float4E2M1FN,
            Float32,
            sf_dtype,
            sf_vec_size,
            instruction_shape,
            cta_group,
            a_src,
            _OperandMajorMode.K,
            _OperandMajorMode.K,
        )
        # Set collector ops after parent initialization (required for frozen dataclass)
        object.__setattr__(self, "a_collector_op", a_collector_op)
        object.__setattr__(self, "b_collector_op", b_collector_op)

        self._verify()

    def _verify(self) -> None:
        # Scale Factor data type verification
        if self.sf_dtype not in [
            Float8E8M0FNU,
            Float8E4M3FN,
            FloatNV8E5M3FNU,
        ]:
            raise DSLUserCodeError(
                "expects the 'sf_dtype' Op parameter to be one of Float8E8M0FNU, Float8E4M3FN",
            )

        # Verify collector ops
        if not isinstance(self.a_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'a_collector_op' Op parameter to be a CollectorOp instance",
            )
        if not isinstance(self.b_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'b_collector_op' Op parameter to be a CollectorOp instance",
            )

        # Instruction shape verification
        instruction_k = 128
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "SM107MmaMXF4NVF4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM107UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
            self.a_collector_op._to_ir(),
            self.b_collector_op._to_ir(),
        )
        return SM107MmaMXF4NVF4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                    core.make_ptr(
                        self.sf_dtype,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class SM107MmaMXF4NVF4Trait(BlockScaledMmaTraits):
    pass



@dataclass(frozen=True)
class SM107BlockScaledMmaMXF8F6F4Op(BlockScaledMmaOp):
    """
    SM107 MXF8F6F4 tcgen05 BlockScaled MMA Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-instructions-mma>`__.
    This Operation corresponds to the ``.kind::mxf8f6f4`` qualifier.
    This Operation is for SM107.

    **Supported data type combinations:**

    +---------------------+---------------------+--------------+----------+-------+-------------+
    | A Data Type         | B Data Type         | SF Data Type | Acc Type | Mma-K | SF Vec Size |
    +=====================+=====================+==============+==========+=======+=============+
    | E4M3, E5M2, E2M3,   | E4M3, E5M2, E2M3,   | UE8M0        | F32      | 64    | 32          |
    +---------------------+---------------------+--------------+----------+-------+-------------+
    | E3M2, E2M1, NV8E5M3 | E3M2, E2M1, NV8E5M3 |              |          |       |             |
    +---------------------+---------------------+--------------+----------+-------+-------------+

    **Supported architectures:** sm_107a

    **Constraints:**

    * A and B data types are independent (mixed types allowed)
    * CtaGroup.ONE: Mma-M = 128; 8 <= Mma-N <= 256, step 8
    * CtaGroup.TWO: Mma-M = 256; 16 <= Mma-N <= 256, step 16
    * A and B support both K-major and MN-major (transpose), except with
      128B swizzling with 32B swizzle-atomicity. Transpose A requires
      a_src=SMEM. When a_src=TMEM, A is always K-major.
    * With 8-bit B transpose (MN-major): N step changes to 16 for CG1, 32 for CG2.

    **Execution Model:**

    * ``cute.gemm(...)`` (PTX: ``tcgen05.mma``) is asynchronous. Issue granularity is
      single-thread (for ``.cta_group::1``) or single-thread in a CTA pair
      (for ``.cta_group::2``), per PTX issue rules.
    * In user code, issue ``cute.gemm(...)`` as warp-uniform and do not wrap it in
      ``elect_one()``, as ``elect_one()`` insertion is handled by the compiler.
    * For block-scaled MMA, pass A and B as paired operands in ``cute.gemm(...)``:
      ``[a, sfa]`` and ``[b, sfb]``.
    * To observe/sequence MMA completion for dependent non-pipelined operations, call
      ``cute.nvgpu.tcgen05.commit(...)`` (PTX: ``tcgen05.commit``) and follow the
      corresponding completion wait/synchronization path.

    .. code-block:: python

        # CORRECT: warp-uniform tcgen05 MMA
        cute.gemm(mma_atom, d, [a, sfa], [b, sfb], c)

        # Signal completion of prior tcgen05 MMA operations
        with cute.arch.elect_one():
            cute.nvgpu.tcgen05.commit(mbar_ptr, None, cta_group)

    """

    descriptive_name = "tcgen05 SM107 MXF8F6F4 BlockScaled MMA Operation"

    # Dataclass fields must have default values when parent fields don't
    a_collector_op: CollectorOp = CollectorOp.DISCARD
    b_collector_op: CollectorOp = CollectorOp.DISCARD

    admissible_archs = base_dsl.Arch.filter(
        lambda arch: arch.is_family_of(base_dsl.Arch.sm_107)
    )

    def __init__(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        sf_dtype: Type[Numeric],
        sf_vec_size: int,
        instruction_shape: Shape,
        cta_group: CtaGroup,
        a_src: OperandSource,
        a_major_mode: _OperandMajorMode,
        b_major_mode: _OperandMajorMode,
        a_collector_op: CollectorOp | str = CollectorOp.DISCARD,
        b_collector_op: CollectorOp | str = CollectorOp.DISCARD,
    ) -> None:
        # Convert string collector ops to CollectorOp enums
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)

        super().__init__(
            a_dtype,
            b_dtype,
            Float32,
            sf_dtype,
            sf_vec_size,
            instruction_shape,
            cta_group,
            a_src,
            a_major_mode,
            b_major_mode,
        )
        # Set collector ops after parent initialization (required for frozen dataclass)
        object.__setattr__(self, "a_collector_op", a_collector_op)
        object.__setattr__(self, "b_collector_op", b_collector_op)

        # Additional SM107-specific verification
        self._verify()

    def _verify(self) -> None:
        # Input data type verification
        if self.sf_dtype not in [Float8E8M0FNU]:
            raise DSLUserCodeError(
                "expects the 'sf_dtype' Op parameter to be Float8E8M0FNU",
            )
        if self.acc_dtype not in [Float32]:
            raise DSLUserCodeError(
                "expects the 'acc_dtype' Op parameter to be Float32",
            )
        # Verify collector ops
        if not isinstance(self.a_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'a_collector_op' Op parameter to be a CollectorOp instance",
            )
        if not isinstance(self.b_collector_op, CollectorOp):
            raise DSLUserCodeError(
                "expects the 'b_collector_op' Op parameter to be a CollectorOp instance",
            )
        # Verify scaling factor vector size
        if self.sf_vec_size not in [32]:
            raise DSLUserCodeError(
                "expects the 'sf_vec_size' Op parameter to be 32",
            )
        # Instruction shape verification
        instruction_k = 64
        shape_mnk_tuple: Any = cast(Any, self.shape_mnk)
        if rank(shape_mnk_tuple) == 2:
            object.__setattr__(self, "shape_mnk", (*shape_mnk_tuple, instruction_k))
            shape_mnk_tuple = cast(Any, self.shape_mnk)
        if shape_mnk_tuple[2] != instruction_k:
            raise DSLUserCodeError(
                f"expects the instruction extent in the K-mode to be {instruction_k}, "
                f"but got {shape_mnk_tuple[2]}",
            )

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "SM107BlockScaledMmaMXF8F6F4Trait":
        shape_mnk = _pack_shape(self.shape_mnk, loc=loc, ip=ip)
        ty = _cute_nvgpu_ir.MmaAtomSM107UMMABlockScaledType.get(
            shape_mnk.type.attribute,
            self.cta_group.value,
            self.a_major_mode._to_ir(),
            self.b_major_mode._to_ir(),
            self.a_dtype.mlir_type,
            self.b_dtype.mlir_type,
            self.acc_dtype.mlir_type,
            self.sf_dtype.mlir_type,
            self.a_src._to_ir(),
            self.sf_vec_size,
            self.a_collector_op._to_ir(),
            self.b_collector_op._to_ir(),
        )
        return SM107BlockScaledMmaMXF8F6F4Trait(
            make_atom(
                ty,
                [
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    Boolean(False).ir_value(loc=loc, ip=ip),
                    core.make_ptr(
                        self.sf_dtype,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                    core.make_ptr(
                        self.sf_dtype,
                        0,
                        AddressSpace.tmem,
                        assumed_align=8,
                        loc=loc,
                        ip=ip,
                    ).value,
                ],
                loc=loc,
                ip=ip,
            )
        )


class SM107BlockScaledMmaMXF8F6F4Trait(BlockScaledMmaTraits):
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
