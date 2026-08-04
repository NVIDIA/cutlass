# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.


"""CUDA tensor map data structure and related APIs."""

import cutlass

from dataclasses import dataclass, field
from enum import Enum, IntEnum, auto
from typing import Any, Sequence, Tuple, Type, cast

from cutlass.base_dsl import dsl_user_op, lru_cache_ir
from cutlass.base_dsl.dsl import is_dynamic_expression
from cutlass.base_dsl.typing import (
    Numeric,
    Constexpr,
    Pointer,
    Integer,
    Int8,
    Int16,
    Int32,
    Int64,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Float16,
    Float32,
    Float64,
    BFloat16,
    TFloat32,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Float4E2M1FN,
    Float6E3M2FN,
    Float6E2M3FN,
    Float4E2M1FNx2,
    Float6E3M2FNx4,
    Float6E2M3FNx4,
)
import cutlass.cute as cute
from cutlass.cute.core import ScaledBasis, depth, leading_dim
from cutlass.base_dsl.common import DSLUserCodeError

import cutlass._mlir.ir as ir
from cutlass._mlir.dialects import cuda as cuda_dialect
from cutlass._mlir.dialects import llvm


def _stride_to_tma_units(
    stride: Integer | int, element_type: Type[Numeric]
) -> Integer | int:
    """Convert a tensor-element stride to the 16-byte units used by TMA.

    Element units here mean units of ``element_type`` itself. For
    packed dtypes such as ``Float4E2M1FNx2`` / ``Float6E{3M2,2M3}FNx4``,
    one tensor element is already one packed storage unit.
    """

    return stride * element_type.width // 128


def _product(values: Sequence[Int8 | int]) -> Int32 | int:
    result = 1
    for value in values:
        result *= value
    return result


def _canonicalize_tensor_element_type_for_tma(
    element_type: Type[Numeric],
) -> Type[Numeric]:
    """Normalize narrow-byte aliases to the canonical base-dsl classes.

    ``create_tensor_map_tiled_from_view()`` forwards
    ``tensor.element_type`` verbatim. Some byte-addressed tensors surface
    equivalent ``Int8`` / ``Uint8`` classes from different import paths,
    but the TensorMap default-format tables are keyed by the canonical classes.
    Keep the fix local to the from-view convenience path.
    """

    if (
        getattr(element_type, "__name__", None) == "Uint8"
        and getattr(element_type, "width", None) == 8
    ):
        return Uint8
    if (
        getattr(element_type, "__name__", None) == "Int8"
        and getattr(element_type, "width", None) == 8
    ):
        return Int8
    return element_type


class TensorMapDataType(IntEnum):
    """Enumerated type describing tensor map data types"""

    uint8 = 0
    uint16 = 1
    uint32 = 2
    int32 = 3
    uint64 = 4
    int64 = 5
    float16 = 6
    float32 = 7
    float64 = 8
    bfloat16 = 9
    float32_ftz = 10
    tfloat32 = 11
    tfloat32_ftz = 12
    f416u4_align8b = 13
    f416u4_align16b = 14
    f416u6_align16b = 15

    def __str__(self) -> str:
        if self is TensorMapDataType.uint8:
            return "uint8"
        if self is TensorMapDataType.uint16:
            return "uint16"
        if self is TensorMapDataType.uint32:
            return "uint32"
        if self is TensorMapDataType.int32:
            return "int32"
        if self is TensorMapDataType.uint64:
            return "uint64"
        if self is TensorMapDataType.int64:
            return "int64"
        if self is TensorMapDataType.float16:
            return "float16"
        if self is TensorMapDataType.float32:
            return "float32"
        if self is TensorMapDataType.float64:
            return "float64"
        if self is TensorMapDataType.bfloat16:
            return "bfloat16"
        if self is TensorMapDataType.float32_ftz:
            return "float32_ftz"
        if self is TensorMapDataType.tfloat32:
            return "tfloat32"
        if self is TensorMapDataType.tfloat32_ftz:
            return "tfloat32_ftz"
        if self is TensorMapDataType.f416u4_align8b:
            return "f416u4_align8b"
        if self is TensorMapDataType.f416u4_align16b:
            return "f416u4_align16b"
        if self is TensorMapDataType.f416u6_align16b:
            return "f416u6_align16b"
        raise ValueError("Unknown TensorMapDataType enum entry.")

    @property
    def bit_width(self) -> int:
        """Return the element bit-width for this TMA data type."""
        return {
            TensorMapDataType.uint8: 8,
            TensorMapDataType.uint16: 16,
            TensorMapDataType.uint32: 32,
            TensorMapDataType.int32: 32,
            TensorMapDataType.uint64: 64,
            TensorMapDataType.int64: 64,
            TensorMapDataType.float16: 16,
            TensorMapDataType.float32: 32,
            TensorMapDataType.float64: 64,
            TensorMapDataType.bfloat16: 16,
            TensorMapDataType.float32_ftz: 32,
            TensorMapDataType.tfloat32: 32,
            TensorMapDataType.tfloat32_ftz: 32,
            TensorMapDataType.f416u4_align8b: 4,
            TensorMapDataType.f416u4_align16b: 4,
            TensorMapDataType.f416u6_align16b: 6,
        }[self]


class TensorMapDataFormat(Enum):
    """Consumer-facing tensor-map data format.

    Most entries describe the transfer/container layout that downstream
    consumers such as ``ldmatrix`` or ``tcgen05.cp`` care about. The FTZ
    entries select tensor-map data-type variants used by tensor reduce
    operations. Exact CUDA driver encodings are derived internally from the
    logical dtype plus this format when needed.

    ``DEFAULT`` is the ordinary resolved format for dtypes that do not require
    a special transfer layout.
    """

    DEFAULT = auto()
    BYTE = auto()
    F32_FTZ = auto()
    TF32_FTZ = auto()
    B4X16 = auto()
    B4X16_P64 = auto()
    B6X16_P32 = auto()

    def __str__(self) -> str:
        return self.name.lower()


class _TensorMapEncoding(IntEnum):
    """Internal CUDA tensor-map encoding values.

    Keep these numeric values aligned with the CUDA driver enum.
    """

    UINT8 = 0
    UINT16 = 1
    UINT32 = 2
    INT32 = 3
    UINT64 = 4
    INT64 = 5
    FLOAT16 = 6
    FLOAT32 = 7
    FLOAT64 = 8
    BFLOAT16 = 9
    F32_FTZ = 10
    TFLOAT32 = 11
    TF32_FTZ = 12
    B4X16 = 13
    B4X16_P64 = 14
    B6X16_P32 = 15


_DEFAULT_TENSORMAP_FORMAT_BY_ENCODING: dict[_TensorMapEncoding, TensorMapDataFormat] = {
    _TensorMapEncoding.UINT8: TensorMapDataFormat.BYTE,
    _TensorMapEncoding.B4X16_P64: TensorMapDataFormat.B4X16_P64,
    _TensorMapEncoding.B6X16_P32: TensorMapDataFormat.B6X16_P32,
}

_TENSORMAP_ENCODING_FORMAT_OVERRIDES: dict[
    tuple[Type[Numeric], TensorMapDataFormat], _TensorMapEncoding
] = {
    (Float32, TensorMapDataFormat.F32_FTZ): _TensorMapEncoding.F32_FTZ,
    (TFloat32, TensorMapDataFormat.TF32_FTZ): _TensorMapEncoding.TF32_FTZ,
    (Float4E2M1FN, TensorMapDataFormat.B4X16): _TensorMapEncoding.B4X16,
    (Float4E2M1FNx2, TensorMapDataFormat.B4X16): _TensorMapEncoding.B4X16,
    (Float4E2M1FNx2, TensorMapDataFormat.B4X16_P64): _TensorMapEncoding.B4X16_P64,
}

_LEGACY_TENSORMAP_TYPE_TO_FORMAT: dict[TensorMapDataType, TensorMapDataFormat] = {
    TensorMapDataType.uint8: TensorMapDataFormat.BYTE,
    TensorMapDataType.uint16: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.uint32: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.int32: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.uint64: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.int64: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.float16: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.float32: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.float64: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.bfloat16: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.float32_ftz: TensorMapDataFormat.F32_FTZ,
    TensorMapDataType.tfloat32: TensorMapDataFormat.DEFAULT,
    TensorMapDataType.tfloat32_ftz: TensorMapDataFormat.TF32_FTZ,
    TensorMapDataType.f416u4_align8b: TensorMapDataFormat.B4X16,
    TensorMapDataType.f416u4_align16b: TensorMapDataFormat.B4X16_P64,
    TensorMapDataType.f416u6_align16b: TensorMapDataFormat.B6X16_P32,
}


def _infer_default_tensormap_format(
    encoding: _TensorMapEncoding,
) -> TensorMapDataFormat:
    return _DEFAULT_TENSORMAP_FORMAT_BY_ENCODING.get(
        encoding, TensorMapDataFormat.DEFAULT
    )


def _infer_default_tensormap_encoding(dtype: Type[Numeric]) -> _TensorMapEncoding:
    return _TensorMapEncoding(int(get_dsl_type_to_tensormap_type(dtype)))


class TensorMapFloatOOBFill(IntEnum):
    """Enumerated type describing tensor map out-of-bound fill modes"""

    none = 0
    nan_request_zero_fma = 1

    def __str__(self) -> str:
        return self.name


class TensorMapInterleave(IntEnum):
    """Enumerated type describing tensor map interleave modes"""

    none = 0
    i16b = 1
    i32b = 2

    def __str__(self) -> str:
        return self.name


class TensorMapL2Promotion(IntEnum):
    """Enumerated type describing tensor map L2 promotion sizes"""

    none = 0
    l2_64b = 1
    l2_128b = 2
    l2_256b = 3

    def __str__(self) -> str:
        return self.name


class TensorMapSwizzle(IntEnum):
    """Swizzle pattern applied by the TMA hardware during ``cp.async.bulk`` transfers.

    Passed as the ``swizzle`` argument to the TensorMap creation helpers.  The hardware
    automatically applies the XOR permutation to the SMEM physical addresses as it
    writes each element — no manual address calculation is needed on the TMA path.

    .. list-table::
       :header-rows: 1

       * - Member
         - Value
         - Effect
       * - ``none``
         - 0
         - No swizzle — linear SMEM layout
       * - ``s32b``
         - 1
         - 32-byte XOR swizzle
       * - ``s64b``
         - 2
         - 64-byte XOR swizzle
       * - ``s128b``
         - 3
         - 128-byte XOR swizzle — **required** for
           ``tcgen05.mma kind::f16`` on SM100
       * - ``s128b_atom_32b``
         - 4
         - 128B XOR with 32B atomic sub-partition
       * - ``s128b_atom_32b_flip_8b``
         - 5
         - 128B XOR + 32B atom + 8B flip
       * - ``s128b_atom_64b``
         - 6
         - 128B XOR with 64B atomic sub-partition

    Generic swizzle descriptor classes with a ``from_name()`` constructor can
    be used as conversion targets for the common ``none`` / ``s32b`` /
    ``s64b`` / ``s128b`` presets.
    """

    none = 0
    s32b = 1
    s64b = 2
    s128b = 3
    s128b_atom_32b = 4
    s128b_atom_32b_flip_8b = 5
    s128b_atom_64b = 6

    def __str__(self) -> str:
        return self.name

    @classmethod
    def from_name(cls, name: str) -> "TensorMapSwizzle":
        try:
            return cls[name]
        except KeyError as exc:
            raise ValueError(f"Unsupported TensorMapSwizzle name {name!r}.") from exc

    def to(self, target_type: type[object]) -> object:
        """Convert this TensorMap swizzle to another swizzle representation.

        Atom-specific variants (``s128b_atom_32b`` etc.) have no
        ``Swizzle`` counterpart, so converting them via the
        ``Swizzle.from_name`` round-trip would raise.  ``s128b_atom_32b``
        has a direct :class:`Tcgen05SmemSwizzle` mapping
        (``SWIZZLE_128B_ATOM_32B``) which we hand off here without going
        through ``Swizzle``.
        """
        if target_type is TensorMapSwizzle:
            return self

        from cutlass.base_dsl.swizzle import Swizzle  # noqa: PLC0415

        from cutlass.experimental.primitives import Tcgen05SmemSwizzle  # noqa: PLC0415

        if target_type is Tcgen05SmemSwizzle:
            atom_map = {
                TensorMapSwizzle.s128b_atom_32b: (
                    Tcgen05SmemSwizzle.SWIZZLE_128B_ATOM_32B  # type: ignore[attr-defined]
                ),
            }
            if self in atom_map:
                return atom_map[self]
            if self in (
                TensorMapSwizzle.s128b_atom_32b_flip_8b,
                TensorMapSwizzle.s128b_atom_64b,
            ):
                raise ValueError(f"{self!s} has no Tcgen05SmemSwizzle equivalent")
            return self.to(Swizzle).to(Tcgen05SmemSwizzle)  # type: ignore[attr-defined]
        if target_type is Swizzle:
            return Swizzle.from_name(str(self))  # type: ignore[attr-defined]
        raise TypeError(f"Unsupported swizzle conversion target: {target_type!r}")


def _derive_tensormap_encoding(
    dtype: Type[Numeric],
    tma_format: TensorMapDataFormat | TensorMapDataType | None = None,
) -> tuple[TensorMapDataFormat, _TensorMapEncoding]:
    """Resolve the public TensorMap format and private CUDA encoding."""
    if isinstance(tma_format, TensorMapDataType):
        return (
            _LEGACY_TENSORMAP_TYPE_TO_FORMAT[tma_format],
            _TensorMapEncoding(int(tma_format)),
        )

    try:
        default_encoding = _infer_default_tensormap_encoding(dtype)
    except ValueError as exc:
        raise ValueError(f"Unsupported type for TensorMap: {dtype}") from exc

    default_tma_format = _infer_default_tensormap_format(default_encoding)
    resolved_tma_format = (
        TensorMapDataFormat(tma_format)
        if tma_format is not None
        else default_tma_format
    )
    if resolved_tma_format == default_tma_format:
        return resolved_tma_format, default_encoding

    override_encoding = _TENSORMAP_ENCODING_FORMAT_OVERRIDES.get(
        (dtype, resolved_tma_format)
    )
    if override_encoding is not None:
        return resolved_tma_format, override_encoding

    raise ValueError(
        "Unsupported TensorMap dtype/format combination: "
        f"dtype={dtype}, tma_format={resolved_tma_format}"
    )


def _derive_tensormap_shared_storage_dtype(
    dtype: Type[Numeric],
    tma_format: TensorMapDataFormat,
) -> Type[Numeric]:
    """Return the dtype that sizes the TMA destination shared storage."""
    if tma_format in {
        TensorMapDataFormat.BYTE,
        TensorMapDataFormat.B4X16_P64,
        TensorMapDataFormat.B6X16_P32,
    }:
        return Uint8
    if tma_format == TensorMapDataFormat.B4X16:
        return Float4E2M1FN
    return dtype


def _derive_tensormap_global_tx_dtype(
    dtype: Type[Numeric],
    tma_format: TensorMapDataFormat,
) -> Type[Numeric]:
    """Return the dtype used to count TMA global transaction bytes."""
    return _derive_tensormap_stride_dtype(dtype, tma_format)


def _derive_tensormap_stride_dtype(
    dtype: Type[Numeric],
    tma_format: TensorMapDataFormat,
) -> Type[Numeric]:
    """Return the element dtype used to convert tensor strides for TMA."""
    if tma_format in {TensorMapDataFormat.B4X16, TensorMapDataFormat.B4X16_P64}:
        if dtype is Float4E2M1FNx2:
            return Float4E2M1FN
    if tma_format == TensorMapDataFormat.B6X16_P32:
        if dtype is Float6E3M2FNx4:
            return Float6E3M2FN
        if dtype is Float6E2M3FNx4:
            return Float6E2M3FN
    return dtype


_SUBBYTE_TENSORMAP_FORMATS = {
    TensorMapDataFormat.B4X16,
    TensorMapDataFormat.B4X16_P64,
    TensorMapDataFormat.B6X16_P32,
}

_PADDED_SUBBYTE_BOX_BYTES = {
    TensorMapDataFormat.B4X16_P64: 64,
    TensorMapDataFormat.B6X16_P32: 96,
}

_PADDED_SUBBYTE_SWIZZLES = {
    TensorMapSwizzle.none,
    TensorMapSwizzle.s128b,
    TensorMapSwizzle.s128b_atom_32b,
    TensorMapSwizzle.s128b_atom_64b,
}


def _static_int(value: object) -> int | None:
    """Return a Python int for statically known values; otherwise None."""
    if is_dynamic_expression(value):
        return None
    try:
        return int(value)  # type: ignore[call-overload]
    except (TypeError, ValueError):
        return None


def _format_byte_count(bits: int) -> str:
    if bits % 8 == 0:
        return f"{bits // 8}B"
    return f"{bits}/8B"


def _validate_tensormap_constraints(
    *,
    dtype: Type[Numeric],
    tma_format: TensorMapDataFormat,
    global_address: Int64 | int,
    global_dims: Sequence[Int32 | int],
    global_strides: Sequence[Int64 | int],
    box_dims: Sequence[Int8 | int],
    swizzle: TensorMapSwizzle,
    oob_fill: TensorMapFloatOOBFill,
) -> None:
    """Reject statically visible TensorMap configurations disallowed by PTX.

    See PTX ISA 9.7.9.26.5.1, "Restriction on Tensor Copy instructions".
    Runtime TMA coordinates and copy direction are validated by the caller,
    but descriptor fields known at construction time can fail early here.
    """

    if (
        tma_format in _SUBBYTE_TENSORMAP_FORMATS
        and oob_fill == TensorMapFloatOOBFill.nan_request_zero_fma
    ):
        raise ValueError(f"TensorMap format {tma_format} does not support OOB-NaN fill")

    required_box_bytes = _PADDED_SUBBYTE_BOX_BYTES.get(tma_format)
    if required_box_bytes is None:
        return

    lane_dtype = _derive_tensormap_global_tx_dtype(dtype, tma_format)
    format_name = str(tma_format)
    required_bits = required_box_bytes * 8

    box_dim0 = _static_int(box_dims[0])
    if box_dim0 is not None:
        box_bits = box_dim0 * lane_dtype.width
        if box_bits != required_bits:
            raise ValueError(
                f"TensorMap format {format_name} requires Box-Size[0] to be "
                f"exactly {required_box_bytes}B, got "
                f"{_format_byte_count(box_bits)}"
            )

    tensor_dim0 = _static_int(global_dims[0])
    if tensor_dim0 is not None:
        tensor_bits = tensor_dim0 * lane_dtype.width
        if tensor_bits % required_bits != 0:
            raise ValueError(
                f"TensorMap format {format_name} requires Tensor-Size[0] to "
                f"be a multiple of {required_box_bytes}B, got "
                f"{_format_byte_count(tensor_bits)}"
            )

    base_address = _static_int(global_address)
    if base_address is not None and base_address % 32 != 0:
        raise ValueError(
            f"TensorMap format {format_name} requires global_address to be "
            f"32B aligned, got {base_address}"
        )

    for dim, stride in enumerate(global_strides, start=1):
        stride_16b = _static_int(stride)
        if stride_16b is not None and stride_16b % 2 != 0:
            raise ValueError(
                f"TensorMap format {format_name} requires tensor stride for "
                f"dimension {dim} to be 32B aligned, got "
                f"{stride_16b * 16}B"
            )

    if swizzle not in _PADDED_SUBBYTE_SWIZZLES:
        allowed = ", ".join(str(mode) for mode in sorted(_PADDED_SUBBYTE_SWIZZLES))
        raise ValueError(
            f"TensorMap format {format_name} supports only none or 128B "
            f"swizzle modes, got {swizzle}; allowed: {allowed}"
        )


def get_dsl_type_to_tensormap_type(dsl_type: Type[Numeric]) -> TensorMapDataType:
    # Some call paths surface byte-addressed storage dtypes through the base-dsl
    # module, so match on canonical narrow-byte names as well as class identity.
    if (
        getattr(dsl_type, "__name__", None) in {"Int8", "Uint8"}
        and getattr(dsl_type, "width", None) == 8
    ):
        return TensorMapDataType.uint8
    if dsl_type == Float16:
        return TensorMapDataType.float16
    elif dsl_type == Float32:
        return TensorMapDataType.float32
    elif dsl_type == Float64:
        return TensorMapDataType.float64
    elif dsl_type == BFloat16:
        return TensorMapDataType.bfloat16
    elif dsl_type == TFloat32:
        return TensorMapDataType.tfloat32
    elif dsl_type == Int16:
        # TMA has no signed-16-bit encoding; use the 16-bit storage container.
        return TensorMapDataType.uint16
    elif dsl_type == Int32:
        return TensorMapDataType.int32
    elif dsl_type == Int64:
        return TensorMapDataType.int64
    elif dsl_type == Uint8:
        return TensorMapDataType.uint8
    elif dsl_type == Int8:
        # TMA has no signed-8-bit encoding; byte-addressed payloads use the
        # uint8 descriptor and consumers interpret signedness themselves.
        return TensorMapDataType.uint8
    elif dsl_type == Uint16:
        return TensorMapDataType.uint16
    elif dsl_type == Uint32:
        return TensorMapDataType.uint32
    elif dsl_type == Uint64:
        return TensorMapDataType.uint64
    elif dsl_type in {Float8E4M3FN, Float8E5M2, Float8E8M0FNU}:
        # FP8 is byte-addressed by TMA; tcgen05 interprets the bytes by dtype.
        return TensorMapDataType.uint8
    elif dsl_type is Float4E2M1FN:
        # 4-bit FP4 defaults to the f4-aligned-to-16B encoding used by
        # the 16-byte-aligned MMA path. The alternate 8-byte-aligned encoding
        # cannot be derived from dtype alone; pass tma_format explicitly.
        return TensorMapDataType.f416u4_align16b
    elif dsl_type is Float4E2M1FNx2:
        # Packed fp4x2 tensors are naturally byte-addressed in host layouts:
        # one tensor element is one byte holding two FP4 lanes.
        return TensorMapDataType.uint8
    elif dsl_type in {Float6E3M2FN, Float6E2M3FN}:
        # 6-bit FP6 — same alignment story as FP4.
        return TensorMapDataType.f416u6_align16b
    elif dsl_type in {Float6E3M2FNx4, Float6E2M3FNx4}:
        return TensorMapDataType.f416u6_align16b
    raise ValueError(f"Unsupported type for TensorMap: {dsl_type}")


def get_tensormap_type_to_dsl_type(
    tma_format: TensorMapDataType,
) -> Type[Numeric] | None:
    """Return the closest CUTLASS dtype for a tensor-map data format.

    Some tensor-map encodings are storage formats rather than precise logical
    element types.  For example, FP8 tensor maps are encoded as ``uint8``; use
    :func:`create_tensor_map_tiled_from_view` or pass the logical dtype to
    preserve the exact FP8 element type. Likewise, the FP4 / FP6 tensor-map
    enums describe scalar-lane unpacking encodings; packed host dtypes such as
    ``Float4E2M1FNx2`` are preserved only when the logical dtype is available.
    """
    mapping: dict[TensorMapDataType, Type[Numeric] | None] = {
        TensorMapDataType.uint8: Uint8,
        TensorMapDataType.uint16: Uint16,
        TensorMapDataType.uint32: Uint32,
        TensorMapDataType.int32: Int32,
        TensorMapDataType.uint64: Uint64,
        TensorMapDataType.int64: Int64,
        TensorMapDataType.float16: Float16,
        TensorMapDataType.float32: Float32,
        TensorMapDataType.float64: Float64,
        TensorMapDataType.bfloat16: BFloat16,
        TensorMapDataType.float32_ftz: Float32,
        TensorMapDataType.tfloat32: TFloat32,
        TensorMapDataType.tfloat32_ftz: TFloat32,
        TensorMapDataType.f416u4_align8b: Float4E2M1FN,
        TensorMapDataType.f416u4_align16b: Float4E2M1FN,
        TensorMapDataType.f416u6_align16b: Float6E3M2FN,
    }
    return mapping[TensorMapDataType(tma_format)]


@dataclass(frozen=True, eq=False)
class TensorMap:
    """Abstract TMA descriptor handle reflecting a CUDA tensor map.

    Wraps an MLIR ``!cuda.tensor_map`` value.  Call :meth:`get_ptr` inside a
    ``@cute.kernel`` to obtain a pointer suitable for TMA intrinsics.  The
    host-side wrapper also retains static metadata chosen at descriptor
    construction time: the logical CUTLASS element ``dtype`` when known, the
    consumer-facing :class:`TensorMapDataFormat`, the TMA-order ``box_dims``,
    and the :class:`TensorMapSwizzle` mode. For descriptors built from a
    ``cute.Tensor``, ``box_dims`` are stored after the builder's TMA-order
    reordering; use the stored metadata inside kernels rather than passing a
    second copy of the box or byte count.

    The shared-memory storage dtype, shared storage byte count, and TMA global
    transaction byte count for one TMA box are derived from that metadata.
    Derive downstream kernel settings from the same source of truth:
    ``box_volume`` for logical element count, ``shared_storage_bytes`` for SMEM
    staging size, and :meth:`global_tx_bytes` for
    ``mbarrier_arrive_expect_tx``. This avoids drift between the TensorMap
    descriptor and separately passed tile constants while the raw CUDA encoding
    stays internal to descriptor construction.

    Use ``GridConstant[TensorMap]`` for kernel parameters that carry TMA
    descriptors. This marks the argument as ``__grid_constant__`` so that the
    descriptor lives in constant memory:

    .. code-block:: python

        @cute.kernel
        def kernel(desc: GridConstant[TensorMap], smem: cute.Tensor, ...):
            mbar_ptr = ...
            nvvm.cp_async_bulk_tensor_shared_cta_global(
                smem, desc.get_ptr(), (coord_k, coord_m), mbar_ptr
            )

        @cute.jit
        def host(a: cute.Tensor, ...):
            desc = create_tensor_map_tiled_from_view(
                a, box_dims=(128, 64), swizzle=TensorMapSwizzle.s128b
            )
            kernel(desc, ...).launch(...)
    """

    value: ir.Value = field(repr=False)
    swizzle: Constexpr[TensorMapSwizzle] = TensorMapSwizzle.none
    dtype: Constexpr = None
    tma_format: Constexpr[TensorMapDataFormat] = TensorMapDataFormat.DEFAULT
    box_dims: Constexpr[Tuple[Int8 | int, ...]] = ()

    @property
    def element_type(self) -> Type[Numeric] | None:
        """Alias for :attr:`dtype`, matching ``cute.Tensor.element_type``."""
        return self.dtype

    @property
    def box_volume(self) -> Int32 | int:
        """Number of logical TMA elements in one descriptor box.

        The product is computed from the descriptor's stored TMA-order
        ``box_dims``. Use this instead of passing duplicate physical box
        dimensions when sizing per-box loops or logical staging arrays.
        """
        return _product(self.box_dims)

    @property
    def shared_storage_dtype(self) -> Type[Numeric] | None:
        """Dtype that sizes the shared-memory side of one TMA box."""
        if self.dtype is None:
            return None
        return _derive_tensormap_shared_storage_dtype(self.dtype, self.tma_format)

    @property
    def shared_storage_bytes(self) -> Int32 | int:
        """Shared-memory bytes needed for one descriptor box.

        Use this value when allocating byte-addressed SMEM staging for a TMA
        box. It can differ from :meth:`global_tx_bytes` for formats whose SMEM
        representation expands or pads the global representation.

        :raises ValueError: If the TensorMap does not carry enough metadata to
            derive a shared-memory storage dtype.
        """
        storage_dtype = self.shared_storage_dtype
        if storage_dtype is None:
            raise ValueError(
                "shared_storage_dtype is not available; create TensorMap through "
                "create_tensor_map_tiled or create_tensor_map_tiled_from_view"
            )
        return self.box_volume * storage_dtype.width // 8

    def global_tx_bytes(self) -> Int32 | int:
        """Global-memory bytes completed by one TMA copy of this descriptor box.

        This value is the per-copy byte count to pass to
        ``mbarrier_arrive_expect_tx`` for one TMA completion. It intentionally
        does not account for multicast fanout or multiple TMA producers sharing
        one mbarrier; callers should sum those completions explicitly.

        :raises ValueError: If the TensorMap does not carry enough metadata to
            derive a global transaction dtype.
        """
        if self.dtype is None:
            raise ValueError(
                "global transaction dtype is not available; create TensorMap "
                "through create_tensor_map_tiled or "
                "create_tensor_map_tiled_from_view"
            )
        tx_dtype = _derive_tensormap_global_tx_dtype(self.dtype, self.tma_format)
        return self.box_volume * tx_dtype.width // 8

    @staticmethod
    def _get_mlir_type() -> ir.Type:
        """Return the MLIR dialect type for a CUDA tensor map.

        :return: MLIR type for tiled TMA descriptor (``!cuda.tensor_map``).
        :rtype: ir.Type
        """
        return ir.Type.parse("!cuda.tensor_map")

    @dsl_user_op
    @lru_cache_ir()
    def get_ptr(
        self, *, loc: ir.Location | None = None, ip: ir.InsertionPoint | None = None
    ) -> Pointer:
        """Return a pointer to the tensor map.

        :return: Pointer to the tensor map.
        :rtype: :class:`cutlass.Pointer`
        """
        llvm_ptr = cuda_dialect.cast(llvm.PointerType.get(), self.value, loc=loc, ip=ip)
        return Pointer._from_raw_ptr(llvm_ptr)


@dsl_user_op
def create_tensor_map_tiled(
    global_address: Int64 | int,
    dtype: Type[Numeric],
    global_dims: Sequence[Int32 | int],
    global_strides: Sequence[Int64 | int],
    box_dims: Sequence[Int8 | int],
    *,
    traversal_strides: Sequence[Int8 | int] | None = None,
    interleave: TensorMapInterleave | None = None,
    swizzle: TensorMapSwizzle | None = None,
    l2_promotion: TensorMapL2Promotion | None = None,
    oob_fill: TensorMapFloatOOBFill | None = None,
    tma_format: TensorMapDataFormat | TensorMapDataType | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> TensorMap:
    """Build a tiled TMA descriptor from explicit parameters.

    TMA uses **column-major** dimension ordering: ``global_dims[0]`` is the
    fastest-varying (innermost, contiguous) axis.  For a C-order (row-major)
    ``(M, K)`` fp16 array whose rows are contiguous, pass ``global_dims=[K, M]``
    and ``global_strides=[K * 2 // 16]`` (row stride in 16-byte units).

    Pass the logical CUTLASS ``Numeric`` type explicitly via *dtype*.
    The descriptor builder maps that logical dtype to both a consumer-facing
    :class:`TensorMapDataFormat` and the required CUDA-driver encoding
    internally when the mapping is unambiguous.

    Use ``TensorMapDataFormat`` when you need to describe the *transfer
    container layout* in the same terms a TMA consumer sees, or when a tensor
    reduce path needs an FTZ-specific data-type variant:

    * ``BYTE`` → byte-addressed payload (the consumer interprets the bytes)
    * ``F32_FTZ`` → ``Float32`` tensor-map format with FTZ semantics for
      tensor reduce operations
    * ``TF32_FTZ`` → ``TFloat32`` tensor-map format with FTZ semantics for
      tensor reduce operations
    * ``B4X16`` → PTX ``.b4x16`` / CUDA packed-FP4 8-byte layout
    * ``B4X16_P64`` → PTX ``.b4x16_p64`` / CUDA packed-FP4 16-byte layout
    * ``B6X16_P32`` → PTX ``.b6x16_p32`` for loads and ``.b6p2x16`` for
      stores, both backed by CUDA's packed-FP6 descriptor encoding

    Example — 2-D fp16 ``(M=1024, K=64)`` row-major tensor, 128×64 tile,
    128-byte swizzle:

    .. code-block:: python

        desc = create_tensor_map_tiled(
            global_address=a.iterator.toint(),   # Int64 device pointer
            dtype=cutlass.Float16,
            global_dims=[64, 1024],              # [K, M] — K is innermost
            global_strides=[64 * 2 // 16],       # row stride in 16-B units: 8
            box_dims=[64, 128],                  # box: 64 in K, 128 in M
            swizzle=TensorMapSwizzle.s128b,
        )

    Example — FP8 tile.  No explicit ``TensorMapDataFormat.BYTE`` is needed;
    the logical FP8 dtype is retained while TMA uses byte storage:

    .. code-block:: python

        desc = create_tensor_map_tiled(
            global_address=a_fp8.iterator.toint(),
            dtype=cutlass.Float8E4M3FN,
            global_dims=[128, 128],
            global_strides=[128 * 1 // 16],
            box_dims=[128, 128],
            swizzle=TensorMapSwizzle.s128b,
        )

    Example — packed FP4 tile.  ``cutlass.Float4E2M1FNx2`` names the packed
    global-memory storage type, while ``B4X16_P64`` selects the logical scalar
    FP4 lane format consumed by TMA. Dimensions, strides, and boxes are still
    expressed in logical scalar FP4 lanes. Per PTX, ``B4X16_P64`` requires
    ``Box-Size[0] == 64B`` (128 FP4 lanes); larger K tiles must be issued as
    multiple TMA copies with different coordinates.

    .. code-block:: python

        desc = create_tensor_map_tiled(
            global_address=b_packed.iterator.toint(),
            dtype=cutlass.Float4E2M1FNx2,
            tma_format=TensorMapDataFormat.B4X16_P64,
            global_dims=[k, n],
            global_strides=[k * 4 // 128],
            box_dims=[128, n_tile],
            swizzle=TensorMapSwizzle.s128b,
        )

    :param global_address: Device pointer (as ``Int64`` or integer) to the
        first element of the global tensor.
    :type global_address: Int64 or int
    :param dtype: Logical CUTLASS element dtype such as ``cutlass.Float16`` or
        ``cutlass.Float8E4M3FN``. The descriptor retains this logical dtype even
        when the backing TMA encoding uses a different storage container.
    :type dtype: CUTLASS dtype
    :param global_dims: Shape of the global tensor in TMA (column-major) order:
        ``global_dims[0]`` is the contiguous dimension.
        Rank must be between 1 and 5.

        Sub-byte / packed dtypes — this raw-args helper takes
        ``global_dims`` verbatim in the units expected by the selected
        tensor-map format. For ``BYTE`` over ``Float4E2M1FNx2``, one element is
        one packed fp4x2 storage byte. For ``B4X16`` / ``B4X16_P64``, one
        element is one scalar FP4 lane.
    :type global_dims: Sequence[Int32 or int]
    :param global_strides: Inter-dimension strides in **16-byte units**,
        length ``rank - 1`` (the innermost stride is implicit/unused).
        For a C-order tensor with element size ``E`` bytes and inner-dim size
        ``D``, the stride value is ``D * E // 16``.

        Sub-byte / packed dtypes — this raw-args helper takes the value
        verbatim. For ``BYTE`` over ``Float4E2M1FNx2`` the stride is in fp4x2
        storage-byte units, so an FP4 row of ``K`` scalar values uses
        ``(K // 2) * 8 // 128`` (= ``K // 32``). For ``B4X16`` /
        ``B4X16_P64`` the same logical row uses scalar-lane units:
        ``K * 4 // 128``.
    :type global_strides: Sequence[Int64 or int]
    :param box_dims: Tile (box) dimensions for TMA, one per dimension,
        in the same column-major order as *global_dims*.
    :type box_dims: Sequence[Int8 or int]
    :param traversal_strides: Element strides within each box dimension,
        defaults to None (all-ones).
    :type traversal_strides: Sequence[Int8 or int], optional
    :param interleave: Interleave mode, defaults to None (``none``).
    :type interleave: TensorMapInterleave, optional
    :param swizzle: Shared-memory swizzle mode, defaults to None (``none``).
        Accepts :class:`TensorMapSwizzle` or a canonical swizzle descriptor that
        can be converted to a tensor-map encoding.
        For ordinary element formats, ``s128b`` requires
        ``box_dims[0] * sizeof(elem) == 128``. Padded sub-byte formats have
        stricter PTX requirements validated at construction: ``B4X16_P64``
        requires ``Box-Size[0] == 64B`` and ``B6X16_P32`` requires
        ``Box-Size[0] == 96B``.
    :type swizzle: TensorMapSwizzle or compatible swizzle descriptor, optional
    :param l2_promotion: L2 promotion hint, defaults to None (``none``).
    :type l2_promotion: TensorMapL2Promotion, optional
    :param oob_fill: Out-of-bounds fill mode, defaults to None (``none``).
    :type oob_fill: TensorMapFloatOOBFill, optional
    :param tma_format: Optional consumer-facing transfer-layout override or
        FTZ variant. Leave as None to derive the default layout from *dtype*.
        Legacy ``TensorMapDataType`` values are accepted for compatibility and
        are converted to the corresponding public ``TensorMapDataFormat``.
    :type tma_format: TensorMapDataFormat, optional
    :raises ValueError: If tensor rank is not between 1 and 5, or if
        *box_dims*, *global_strides*, or *traversal_strides* have
        inconsistent lengths.
    :return: A :class:`TensorMap` wrapping the created ``!cuda.tensor_map`` and
        retaining the selected static *dtype*, *tma_format*, *box_dims*, and
        *swizzle* metadata on the Python object. The shared-memory storage dtype
        and per-box byte count are derived from those fields.
    :rtype: TensorMap
    """

    rank = len(global_dims)
    if rank < 1 or rank > 5:
        raise ValueError(f"Expected tensor rank to be between 1 and 5, got {rank}")
    if len(box_dims) != rank:
        raise ValueError(
            f"Expected box_dims rank to match rank(global_dims) (={rank}), got "
            f"{len(box_dims)}"
        )
    if len(global_strides) != rank - 1:
        raise ValueError(
            f"Expected rank(global_strides) to match rank(global_dims) - 1"
            f"(={rank - 1}), got {len(global_strides)}"
        )
    if traversal_strides is not None and len(traversal_strides) != rank:
        raise ValueError(
            f"Expected rank(traversal_strides) to match rank(global_dims)"
            f" (={rank}), got {len(traversal_strides)}"
        )

    # Resolve both the consumer-facing transfer format and the CUDA-driver
    # encoding while retaining logical dtype metadata. Passing a CUTLASS dtype
    # preserves logical types such as FP8 even when TMA stores them as uint8.
    resolved_tma_format, tma_format_encoding = _derive_tensormap_encoding(
        dtype, tma_format
    )
    if swizzle is not None and hasattr(swizzle, "to"):
        swizzle = swizzle.to(TensorMapSwizzle)  # type: ignore[assignment]
    interleave = interleave if interleave is not None else TensorMapInterleave.none
    swizzle = swizzle if swizzle is not None else TensorMapSwizzle.none
    l2_promotion = (
        l2_promotion if l2_promotion is not None else TensorMapL2Promotion.none
    )
    oob_fill = oob_fill if oob_fill is not None else TensorMapFloatOOBFill.none
    _validate_tensormap_constraints(
        dtype=dtype,
        tma_format=resolved_tma_format,
        global_address=global_address,
        global_dims=global_dims,
        global_strides=global_strides,
        box_dims=box_dims,
        swizzle=swizzle,
        oob_fill=oob_fill,
    )

    # Convert global_address to !ptr.ptr<#ptr.generic_space>
    addr_i64 = Int64(global_address).ir_value()
    ptr_ptr_type = ir.Type.parse("!ptr.ptr<#ptr.generic_space>")
    global_address_ptr = cuda_dialect.cast(ptr_ptr_type, addr_i64)

    global_dims_arr: cutlass.Array = cutlass.Array(
        Int64, rank, space=cutlass.AddressSpace.rmem
    )
    for i, global_dim in enumerate(global_dims):
        global_dims_arr[i] = global_dim

    # Convert strides from 16-byte units to bytes
    strides_size = len(global_strides)
    global_strides_arr: cutlass.Array = cutlass.Array(
        Int64, max(strides_size, 1), space=cutlass.AddressSpace.rmem
    )
    for i, global_stride in enumerate(global_strides):
        global_strides_arr[i] = Int64(global_stride) * Int64(16)

    box_dims_arr: cutlass.Array = cutlass.Array(
        Int32, rank, space=cutlass.AddressSpace.rmem
    )
    for i, box_dim in enumerate(box_dims):
        box_dims_arr[i] = Int32(box_dim)

    element_strides_arr: cutlass.Array = cutlass.Array(
        Int32, rank, space=cutlass.AddressSpace.rmem
    )
    if traversal_strides is None:
        for i in range(rank):
            element_strides_arr[i] = 1
    else:
        for i, traversal_stride in enumerate(traversal_strides):
            element_strides_arr[i] = traversal_stride

    cuda_result_ty = cuda_dialect.ResultType.get()
    tensor_map_ty = TensorMap._get_mlir_type()
    results = cuda_dialect.tensor_map_encode_tiled(
        cuda_result_ty,
        tensor_map_ty,
        Int32(int(tma_format_encoding)).ir_value(),
        Int32(rank).ir_value(),
        global_address_ptr,
        global_dims_arr.ir_value(),
        global_strides_arr.ir_value(),
        box_dims_arr.ir_value(),
        element_strides_arr.ir_value(),
        Int32(interleave).ir_value(),
        Int32(swizzle).ir_value(),
        Int32(l2_promotion).ir_value(),
        Int32(oob_fill).ir_value(),
        loc=loc,
        ip=ip,
    )
    cuda_result, tensor_map = results
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)
    return TensorMap(
        tensor_map,
        swizzle=swizzle,
        dtype=dtype,
        tma_format=resolved_tma_format,
        box_dims=tuple(box_dims),
    )


@dsl_user_op
def create_tensor_map_tiled_from_view(
    tensor: cute.Tensor,
    box_dims: Tuple[Int8 | int, ...],
    *,
    stride_order: Tuple[int, ...] | None = None,
    interleave: TensorMapInterleave | None = None,
    swizzle: TensorMapSwizzle | None = None,
    l2_promotion: TensorMapL2Promotion | None = None,
    oob_fill: TensorMapFloatOOBFill | None = None,
    dtype: Type[Numeric] | None = None,
    tma_format: TensorMapDataFormat | TensorMapDataType | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> TensorMap:
    """Build a tiled TMA descriptor from a ``cute.Tensor`` or ``cutlass.Array`` view.

    Convenience wrapper around :func:`create_tensor_map_tiled` that
    auto-detects the global address, data type, dimensions, and strides
    from *tensor*, which may be either a layout-carrying ``cute.Tensor`` or a
    bare-metal ``cutlass.Array`` view over the same memory.

    Prefer leaving *dtype* and *tma_format* as ``None`` so the descriptor uses
    the tensor's element type and its default transfer layout. If a logical
    dtype override is required, pass a CUTLASS ``Numeric`` type via *dtype*.
    Use ``TensorMapDataFormat`` when the descriptor must express a
    consumer-facing packed layout, for example ``B4X16_P64`` to request PTX
    ``.b4x16_p64`` for FP4 TMA, or when a tensor reduce path requires
    ``F32_FTZ`` / ``TF32_FTZ``.

    *box_dims* must be given in the **tensor's original mode order**, not
    in TMA column-major order.  For a row-major ``(M, K)`` tensor where K
    is contiguous, pass ``box_dims=(M_tile, K_tile)``.

    When *stride_order* is provided, the tensor map dimensions are builtin from
    the tensor in the order specified by *stride_order*, otherwise the function
    will compute the dimensions in the **stride ascending order** from the
    tensor's strides. TMA coordinates later used in the kernel must follow the
    same order. For example, without *stride_order*, for a row-major ``(B, S, H, D)``
    tensor, the tensor map dimensions used are ``(D, H, S, B)`` and the TMA
    coordinates should be ``(d_off, head, seq, batch)``.

    Example — fp16 ``A`` matrix ``(M, K)`` row-major, 128-row × 64-col tile,
    128-byte swizzle (requires ``K_tile * 2 == 128``, i.e. ``K_tile = 64``):

    .. code-block:: python

        # a.shape = (M, K), a is row-major (K is the contiguous axis)
        desc_a = create_tensor_map_tiled_from_view(
            a,
            box_dims=(128, 64),              # (M_tile, K_tile) — tensor order
            swizzle=TensorMapSwizzle.s128b,  # needs box_dims[K] * 2 == 128
        )

    Example — fp16 ``B`` matrix ``(N, K)`` row-major, 128×64 tile:

    .. code-block:: python

        desc_b = create_tensor_map_tiled_from_view(
            b,
            box_dims=(128, 64),              # (N_tile, K_tile)
            swizzle=TensorMapSwizzle.s128b,
        )

    Swizzle constraints (fp16, 2 bytes/elem):

    * ``s128b``: contiguous box dimension must be exactly 64 elements (128 B)
    * ``s64b``: contiguous box dimension must be exactly 32 elements (64 B)
    * ``s32b``: contiguous box dimension must be exactly 16 elements (32 B)
    * ``none``: no constraint; layout in SMEM is purely linear

    **Sub-byte dtype shape / stride convention** — the input tensor's shape,
    *box_dims*, and TMA coordinates are in logical element units. For default
    packed storage formats such as ``Float4E2M1FNx2`` with ``BYTE`` TMA format,
    one logical element is one packed fp4x2 storage byte. When explicitly
    selecting scalar-lane formats such as ``B4X16`` or ``B4X16_P64`` over a
    packed tensor, one logical element is one scalar FP4 lane; the helper keeps
    the packed pointer dtype but converts tensor strides using the scalar lane
    bit width. ``B4X16_P64`` descriptors must still satisfy the PTX padded
    sub-byte restrictions, including ``Box-Size[0] == 64B``.

    :param tensor: A ``cute.Tensor`` with a flattened (depth-1) layout, or a
        ``cutlass.Array`` view over the same memory. Both expose the shape /
        stride / element-type / base-pointer facts the TMA builder needs.
    :type tensor: cute.Tensor or cutlass.Array
    :param box_dims: Tile dimensions, one per tensor mode, in **tensor mode
        order** (not TMA column-major order).
    :type box_dims: tuple[Int8 or int, ...]
    :param stride_order: Explicit dimension order from innermost to
        outermost.  When provided the automatic stride sort is skipped.
        E.g. ``(0, 1, 2, 3)`` means mode 0 is innermost.
    :type stride_order: tuple[int, ...], optional
    :param interleave: Interleave mode, defaults to None (``none``).
    :type interleave: TensorMapInterleave, optional
    :param swizzle: Shared-memory swizzle mode, defaults to None (``none``).
    :type swizzle: TensorMapSwizzle, optional
    :param l2_promotion: L2 promotion hint, defaults to None (``none``).
    :type l2_promotion: TensorMapL2Promotion, optional
    :param oob_fill: Out-of-bounds fill mode, defaults to None (``none``).
    :type oob_fill: TensorMapFloatOOBFill, optional
    :param dtype: Optional logical element dtype override; defaults to None
        (inferred from the tensor's element type). Use this when a runtime
        tensor surfaces as byte storage but should be encoded as a narrower
        logical format, for example ``Float4E2M1FNx2`` plus ``B4X16_P64``.
    :type dtype: CUTLASS dtype, optional
    :param tma_format: Optional consumer-facing packed-layout or FTZ override.
        Scalar FP4 inference defaults to
        ``TensorMapDataFormat.B4X16_P64``. Packed ``Float4E2M1FNx2``
        inference defaults to ``TensorMapDataFormat.BYTE`` because one
        tensor element is one packed storage byte. Pass
        ``TensorMapDataFormat.B4X16`` or
        ``TensorMapDataFormat.B4X16_P64`` explicitly for unpacking-style
        FP4 tensor maps over packed inputs.
    :type tma_format: TensorMapDataFormat, optional
    :raises ValueError: If the tensor layout is not flattened (depth > 1)
        or has no leading (stride-1) dimension.
    :return: A :class:`TensorMap` wrapping the created ``!cuda.tensor_map`` and
        retaining the selected static *dtype*, *tma_format*, reordered
        *box_dims*, and *swizzle* metadata on the Python object. The
        shared-memory storage dtype and per-box byte count are derived from
        those fields.
    :rtype: TensorMap
    """
    # Accept either a layout-carrying ``cute.Tensor`` or a bare-metal ``cutlass.Array``
    # (the host-entry type the cutlass DSL tutorials use; a host param annotated
    # ``cutlass.Array`` arrives here as one). ``cute.Tensor`` is an ABC that both the
    # eager ``from_dlpack`` tensor and the traced tensor subclass, while a
    # ``cutlass.Array`` is not -- so ``isinstance`` discriminates them cleanly. Both carry
    # the shape / stride / element-type / base-pointer facts the TMA builder needs, spelled
    # differently: a ``cute.Tensor`` uses ``.stride`` / ``.element_type`` / ``.iterator``
    # and a (possibly nested) ``.layout``; a ``cutlass.Array`` uses ``.strides`` /
    # ``.dtype`` / ``.data_ptr()`` and is a flat dense view. Normalize here so the rest of
    # the builder is type-agnostic.
    if isinstance(tensor, cute.Tensor):
        if depth(tensor) > 1:
            raise ValueError(
                f"Expected tensor to have flattened layout, got {tensor.layout}"
            )
        tensor_shape = tensor.shape
        tensor_stride = tensor.stride
        if not isinstance(tensor_shape, tuple) or not isinstance(tensor_stride, tuple):
            raise ValueError(
                f"Expected tensor to have flattened layout, got {tensor.layout}"
            )
        if any(isinstance(shape, tuple) for shape in tensor_shape):
            raise ValueError(
                f"Expected tensor to have flattened layout, got {tensor.layout}"
            )
        if any(
            isinstance(stride, tuple) or isinstance(stride, ScaledBasis)
            for stride in tensor_stride
        ):
            raise ValueError(
                f"Expected tensor to have flat integer strides, got {tensor.layout}"
            )
        element_type = tensor.element_type
        global_address = cast(cute.Pointer, tensor.iterator).toint()
        layout_repr = str(tensor.layout)
    elif isinstance(tensor, cutlass.Array):  # bare-metal flat dense view
        # The param is annotated cute.Tensor, so read the Array's
        # shape/stride/dtype/pointer via Any to satisfy the type checker.
        arr = cast(Any, tensor)
        tensor_shape = tuple(arr.shape)
        tensor_stride = tuple(arr.strides)
        element_type = arr.dtype
        global_address = arr.data_ptr().toint()
        layout_repr = f"shape={tensor_shape}, strides={tensor_stride}"
    else:
        raise DSLUserCodeError(
            "`create_tensor_map_tiled_from_view` needs a `cute.Tensor` or a "
            "`cutlass.Array` (it reads the tensor's shape/stride layout to program the "
            f"TMA copy engine), but got `{type(tensor).__qualname__}`."
        )

    tensor_shapes = list(cast(tuple[Int32 | int, ...], tensor_shape))
    tensor_strides = list(cast(tuple[Integer | int, ...], tensor_stride))
    rank = len(tensor_shapes)

    leading_mode = leading_dim(tensor_shape, tensor_stride)
    if leading_mode is None or not isinstance(leading_mode, int):
        raise ValueError(
            "Expected tensor to have a leading (stride-1) dimension, but got "
            f"tensor layout {layout_repr}"
        )

    box_dims_list = list(box_dims)

    if stride_order is not None:
        order = list(stride_order)
    else:
        # A unique order requires all strides to be static and distinct.
        # Dynamic strides have unknown values; duplicate strides (common
        # when a dimension has size 1) make the sort order ambiguous.
        if any(is_dynamic_expression(s) for s in tensor_strides):
            raise ValueError(
                f"Cannot infer a unique stride order from tensor strides "
                f"{tensor_strides} due to dynamic strides. Please provide "
                "`stride_order` explicitly."
            )
        if len(set(tensor_strides)) < rank:
            raise ValueError(
                f"Cannot infer a unique stride order from tensor strides "
                f"{tensor_strides} due to duplicate strides. Please provide "
                "`stride_order` explicitly."
            )

        order = sorted(range(rank), key=lambda i: tensor_strides[i])

    # Pass the CUTLASS dtype through when inferred so the TensorMap keeps the exact
    # logical element type, including FP8 variants that TMA encodes as uint8.
    resolved_dtype = (
        dtype
        if dtype is not None
        else _canonicalize_tensor_element_type_for_tma(element_type)
    )
    resolved_tma_format, _ = _derive_tensormap_encoding(resolved_dtype, tma_format)
    stride_dtype = _derive_tensormap_stride_dtype(resolved_dtype, resolved_tma_format)

    global_dims = [tensor_shapes[order[j]] for j in range(rank)]
    # Convert tensor-element strides → the unit expected by the TMA encoder.
    # Explicit sub-byte scalar-lane formats over packed xN tensors use scalar
    # lane width while preserving the packed pointer dtype in descriptor metadata.
    global_strides = [
        _stride_to_tma_units(tensor_strides[order[i + 1]], stride_dtype)
        for i in range(rank - 1)
    ]
    reordered_box_dims = [box_dims_list[order[j]] for j in range(rank)]

    return create_tensor_map_tiled(
        global_address=global_address,
        dtype=resolved_dtype,
        global_dims=global_dims,
        global_strides=global_strides,
        box_dims=reordered_box_dims,
        interleave=interleave,
        swizzle=swizzle,
        l2_promotion=l2_promotion,
        oob_fill=oob_fill,
        tma_format=tma_format,
        loc=loc,
        ip=ip,
    )


__all__ = [
    # Enums
    "TensorMapDataType",
    "TensorMapDataFormat",
    "TensorMapFloatOOBFill",
    "TensorMapInterleave",
    "TensorMapL2Promotion",
    "TensorMapSwizzle",
    # TMA descriptor types and functions
    "TensorMap",
    "create_tensor_map_tiled",
    "create_tensor_map_tiled_from_view",
    "get_dsl_type_to_tensormap_type",
    "get_tensormap_type_to_dsl_type",
]
