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

"""Typed descriptors for hardware MMA instructions.

Provides thin Python wrappers around Int64/Int32 that expose hardware
descriptor bitfields as named properties.  Covers descriptors consumed
by Hopper ``wgmma`` (SM90) and ``tcgen05`` (SM100) instructions.
These are pure user-space types — no compiler or MLIR dialect changes required.

Each descriptor class is named after the **instruction** that consumes it
(e.g. ``Tcgen05SmemDesc`` for ``tcgen05.mma``, ``WgmmaSmemDesc`` for
``wgmma.mma_async``) because the bitfield layouts and swizzle encodings
differ across instruction families.

Usage::

    desc_a = cutlass.experimental.primitives.Tcgen05SmemDesc.build(
        smem_a, leading_byte_offset=16, stride_byte_offset=1024,
        layout=cutlass.experimental.primitives.Tcgen05SmemSwizzle.SWIZZLE_128B,
    )
    idesc = cutlass.experimental.primitives.Tcgen05InstrDesc.build(
        c_dtype=cutlass.Float32, n_dim=128, m_dim=128,
    )

    # Advance start address in K-loop by 32 bytes:
    desc_a = desc_a.advance_start_address(16 * 2)

    # Backward-compatible — accepted wherever Int64/Int32 is expected:
    nvvm.tcgen05_mma(kind, group, d, desc_a, desc_b, idesc, scale_d)
"""

from enum import IntEnum
from typing import Literal

import cutlass
from cutlass import dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass._mlir.dialects import nvvm as _nvvm_raw
from cutlass._mlir_helpers.dialect_proxy import DialectAutoConvertProxy
from cutlass.base_dsl.typing import (
    Boolean,
    Int8,
    Int32,
    Int64,
    Numeric,
    Uint8,
    Uint32,
)
import cutlass.base_dsl.typing as _cutlass
from cutlass.base_dsl.typing import Array

# Auto-converting proxy over the raw NVVM dialect bindings: lets the private
# descriptor builders below pass Python ints / Numeric wrappers straight to the
# nvvm ops without hand-rolling the ir.Value conversions.
_nvvm = DialectAutoConvertProxy(_nvvm_raw)


# =============================================================================
# Private NVVM descriptor builders
#
# Thin ``@dsl_user_op`` wrappers around the ``nvvm.tcgen05_mma_smem_desc`` ops.
# Using the NVVM intrinsic (rather than raw bit-shifts) lets compiler passes
# pattern-match the descriptor.  These are module-private; ``Tcgen05SmemDesc.build``
# is their only customer.  They live next to the descriptor types so descriptor
# construction does not depend on an unrelated wrapper namespace.
# =============================================================================


@dsl_user_op
def _tcgen05_mma_smem_desc(
    start_addr: int | Int32 | Uint32,
    leading_dim_offset: int | Int32 | Uint32,
    stride_dim_offset: int | Int32 | Uint32,
    base_offset: int | Int8 | Uint8,
    leading_dim_mode: int | Boolean,
    swizzle_mode: int | Int8 | Uint8,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Build a ``tcgen05.mma`` SMEM descriptor for an A or B matrix tile.

    The descriptor encodes the base address, stride, and swizzle of a
    shared-memory tile for SM100 ``tcgen05.mma``.  All offsets are in
    units of **16 bytes** (the descriptor granule).

    :param start_addr: Base SMEM address of the tile **divided by 16**
        (i.e. ``smem_ptr >> 4``).  The descriptor unit is 16 bytes.
    :param leading_dim_offset: Step size of the leading dimension in units of 16 B.
    :param stride_dim_offset: Size of one swizzle block in units of 16 B.
    :param base_offset: Additional byte offset added to the base (normally ``0``).
    :param leading_dim_mode: Leading-dimension mode flag (normally ``0`` / ``False``).
    :param swizzle_mode: SMEM swizzle mode applied during ``tcgen05.mma`` reads
        (``0``=NONE, ``2``=128B XOR, ``4``=64B XOR, ``6``=32B XOR).
    :return: Packed ``Int64`` descriptor value.
    """
    return _cutlass.Int64(
        _nvvm.tcgen05_mma_smem_desc(
            _cutlass.Int32(start_addr),
            _cutlass.Int32(leading_dim_offset),
            _cutlass.Int32(stride_dim_offset),
            _cutlass.Int8(base_offset),
            _cutlass.Boolean(leading_dim_mode),
            _cutlass.Int8(swizzle_mode),
            loc=loc,
            ip=ip,
        )
    )



# =============================================================================
# Enums
# =============================================================================


class Tcgen05OutputFormat(IntEnum):
    """``c_format`` field of :class:`Tcgen05InstrDesc`.

    Selects the output accumulator format for ``tcgen05.mma``.
    """

    F16 = 0
    F32 = 1
    S32 = 2


class Tcgen05InputFormat(IntEnum):
    """``a_format`` / ``b_format`` field of :class:`Tcgen05InstrDesc`.

    For ``.kind::f16``: F16=0, BF16=1, TF32=2.
    For ``.kind::f8f6f4``: E4M3=0, E5M2=1, E2M3=3, E3M2=4, E2M1=5.
    For ``.kind::i8``: U8=0, S8=1.
    """

    F16 = 0
    BF16 = 1
    TF32 = 2
    # FP8/FP6/FP4 — same encoding space, different .kind
    E4M3 = 0
    E5M2 = 1
    E2M3 = 3
    E3M2 = 4
    E2M1 = 5
    # INT8 — same encoding space, different .kind
    U8 = 0
    S8 = 1


class Tcgen05SmemSwizzle(IntEnum):
    """``layout_type`` field of :class:`Tcgen05SmemDesc`.

    SM100 swizzle encoding — differs from Hopper (SM90).
    """

    NONE = 0
    SWIZZLE_128B_ATOM_32B = 1
    SWIZZLE_128B = 2
    SWIZZLE_64B = 4
    SWIZZLE_32B = 6


class MxScaleFormat(IntEnum):
    """``scale_format`` field of :class:`Tcgen05MxInstrDesc`.

    Scale-factor encoding for MX block-scaled operations.
    """

    UE4M3 = 0
    E8M0 = 1
    UE5M3 = 2


# =============================================================================
# Generic bitfield operations
# =============================================================================


def _get_field(
    desc: Int64 | Int32, bit_start: int, bit_width: int
) -> Int64 | Int32 | int:
    """Extract a bitfield. Returns a plain ``int`` when the value is static."""
    mask = (1 << bit_width) - 1
    if isinstance(desc.value, int):
        return (desc.value >> bit_start) & mask
    result = (desc >> bit_start) & mask
    return type(desc)(result) if isinstance(desc, Int64) else Int32(result)


def _advance_field(
    desc: Int64 | Int32,
    bit_start: int,
    bit_width: int,
    increment: int | Int32 | Int64,
) -> Int64 | Int32:
    """Masked addition to a bitfield — carry doesn't leak.

    When ``bit_start == 0`` the shift-by-``bit_start`` terms are
    compile-time no-ops, so we skip emitting them. The common
    ``advance_start_address`` path hits this branch on every tcgen05/wgmma
    descriptor update; dropping the two ``<< 0`` ops shaves an MLIR op per
    call site (and makes the generated IR easier to read).
    """
    mask = ((1 << bit_width) - 1) << bit_start
    if isinstance(desc, Int64):
        inv_mask = ~mask & 0xFFFFFFFFFFFFFFFF
        int_t: type = Int64
    else:
        inv_mask = ~mask & 0xFFFFFFFF
        int_t = Int32
    # Do internal arithmetic through the base integer type. Descriptor
    # subclasses may overload ``__add__`` as user-facing start-address
    # shorthand; using the subclass here would recurse.
    desc_int = int_t(desc)
    shifted = int_t(increment) if bit_start == 0 else int_t(increment) << bit_start
    field_val = (desc_int & mask) + shifted
    return type(desc)((desc_int & inv_mask) | (field_val & mask))


def _drop_low_bits(
    value: int | Int32 | Int64, num_lsbs: int, name: str
) -> int | Int32 | Int64:
    """Drop the low ``num_lsbs`` bits, matching the PTX encoding convention.

    Many tcgen05/wgmma descriptor fields encode a value with its low bits
    *not included* — e.g. PTX defines ``n_dim`` as "Dimension of Matrix B
    (3 LSBs not included)". The user passes the logical value; this helper
    drops the LSBs so the result fits in the bitfield.

    For Python ``int`` values the dropped LSBs must be zero — otherwise we
    would silently lose information and produce a wrong descriptor. Traced
    ``Int32`` / ``Int64`` values pass through unchecked because their value
    is not known until runtime.
    """
    if isinstance(value, int):
        mask = (1 << num_lsbs) - 1
        if value & mask:
            raise ValueError(
                f"{name}={value} would lose information: the descriptor "
                f"encodes {name} with the low {num_lsbs} bits not included, "
                f"so {name} must be a multiple of {1 << num_lsbs}."
            )
        return value >> num_lsbs
    return value >> num_lsbs


def _set_field(
    desc: Int64 | Int32,
    bit_start: int,
    bit_width: int,
    value: int | Int32 | Int64,
) -> Int64 | Int32:
    """Replace a bitfield with a new value, preserving all other bits."""
    mask = ((1 << bit_width) - 1) << bit_start
    if isinstance(desc, Int64):
        inv_mask = ~mask & 0xFFFFFFFFFFFFFFFF
        new_bits = (Int64(value) & ((1 << bit_width) - 1)) << bit_start
    else:
        inv_mask = ~mask & 0xFFFFFFFF
        new_bits = (Int32(value) & ((1 << bit_width) - 1)) << bit_start
    return type(desc)((desc & inv_mask) | new_bits)


class WgmmaSwizzle(IntEnum):
    """``layout_type`` field of :class:`WgmmaSmemDesc`.

    Hopper (SM90) swizzle encoding — 2-bit field at [62:64).
    Note the encoding differs from SM100 tcgen05.
    """

    INTERLEAVE = 0  # No swizzling
    SWIZZLE_128B = 1
    SWIZZLE_64B = 2
    SWIZZLE_32B = 3


# =============================================================================
# WgmmaSmemDesc  (Hopper SM90)
# =============================================================================


class WgmmaSmemDesc(Int64):
    """Hopper ``wgmma.mma_async`` shared-memory matrix descriptor (64-bit).

    Consumed by ``wgmma.mma_async`` (SM90+).
    Reference: CUTLASS ``GmmaDescriptor`` in ``cute/arch/mma_sm90_desc.hpp``.

    Bitfield layout::

        [0:14)   start_address        (stored >> 4)
        [14:16)  (reserved)
        [16:30)  leading_byte_offset  (stored >> 4)
        [30:32)  (reserved)
        [32:46)  stride_byte_offset   (stored >> 4)
        [46:49)  (reserved)
        [49:52)  base_offset          (valid for SWIZZLE_128B/64B only)
        [52:62)  (reserved)
        [62:64)  layout_type          (WgmmaSwizzle, 2-bit)

    Compared to :class:`Tcgen05SmemDesc`:

    - ``layout_type`` is 2 bits [62:64) vs 3 bits [61:64)
    - No ``version`` field (SM100 adds this at [46:48))
    - Swizzle encoding differs: 1=128B here vs 2=128B on SM100
    """

    @property
    def start_address(self) -> Int64:
        """Bits [0:14): shared-memory start address (>> 4)."""
        return _get_field(self, 0, 14)

    @property
    def leading_byte_offset(self) -> Int64:
        """Bits [16:30): leading dimension byte offset (>> 4)."""
        return _get_field(self, 16, 14)

    @property
    def stride_byte_offset(self) -> Int64:
        """Bits [32:46): stride dimension byte offset (>> 4)."""
        return _get_field(self, 32, 14)

    @property
    def base_offset(self) -> Int64:
        """Bits [49:52): base-offset modifier (SWIZZLE_128B/64B only)."""
        return _get_field(self, 49, 3)

    @property
    def layout_type(self) -> Int64:
        """Bits [62:64): swizzle mode (:class:`WgmmaSwizzle`, 2-bit)."""
        return _get_field(self, 62, 2)

    def advance_start_address(
        self, byte_increment: int | Int32 | Int64
    ) -> "WgmmaSmemDesc":
        """Advance ``start_address`` by *byte_increment* bytes.

        The descriptor encodes ``start_address`` with the low 4 bits not
        included, so the byte offset must be a multiple of 16. Passing a
        Python ``int`` that violates this raises :class:`ValueError`.
        """
        return _advance_field(
            self, 0, 14, _drop_low_bits(byte_increment, 4, "byte_increment")
        )


WgmmaSmemDesc.width = Int64.width
WgmmaSmemDesc.bytes = Int64.bytes


# =============================================================================
# Tcgen05SmemDesc  (SM100)
# =============================================================================


class Tcgen05SmemDesc(Int64):
    """SM100 ``tcgen05.mma`` shared-memory descriptor (64-bit).

    Bitfield layout::

        [0:15)   start_address        (stored >> 4)     [14] reserved in SM100
        [15:16)  (reserved)
        [16:31)  leading_byte_offset  (stored >> 4)     [30] reserved in SM100
        [31:32)  (reserved)
        [32:46)  stride_byte_offset   (stored >> 4)
        [46:49)  version
        [49:52)  base_offset
        [52:53)  leading dimension mode                 [52] reserved in SM100
        [53:54)  K_segment start offset                 [53] reserved in SM100
        [54:61)  (reserved)
        [61:64)  layout_type          (Tcgen05SmemSwizzle)
    """

    # -- bitfield readers (generate MLIR arith ops at trace time) --

    @property
    def start_address(self) -> Int64:
        """Bits [0:15): shared-memory start address (>> 4)."""
        return _get_field(self, 0, 15)

    @property
    def leading_byte_offset(self) -> Int64:
        """Bits [16:31): leading dimension byte offset (>> 4)."""
        return _get_field(self, 16, 15)

    @property
    def stride_byte_offset(self) -> Int64:
        """Bits [32:46): stride dimension byte offset (>> 4)."""
        return _get_field(self, 32, 14)

    @property
    def version(self) -> Int64:
        """Bits [46:49): descriptor version."""
        return _get_field(self, 46, 3)

    @property
    def base_offset(self) -> Int64:
        """Bits [49:52): base-offset modifier."""
        return _get_field(self, 49, 3)

    @property
    def layout_type(self) -> Int64:
        """Bits [61:64): swizzle mode (:class:`Tcgen05SmemSwizzle`)."""
        return _get_field(self, 61, 3)

    # -- convenience mutators (return new descriptor) --

    def advance_start_address(
        self, byte_increment: int | Int32 | Int64
    ) -> "Tcgen05SmemDesc":
        """Advance ``start_address`` by *byte_increment* bytes.

        The descriptor encodes ``start_address`` with the low 4 bits not
        included, so the byte offset must be a multiple of 16. Passing a
        Python ``int`` that violates this raises :class:`ValueError`.

        This lowers to the same encoded start-address addition as
        ``desc + (byte_increment >> 4)``. The caller must ensure the
        resulting start address still fits the 14-bit field.
        """
        return self + _drop_low_bits(byte_increment, 4, "byte_increment")  # type: ignore[return-value]

    # Keep ``desc + encoded_offset_16b`` on the base Int64 path. A masked
    # ``__add__`` overload emits extra descriptor-field arithmetic in hot
    # tcgen05 K loops. ``advance_start_address()`` keeps the byte-count API
    # while lowering through the same fast encoded-add path.

    @classmethod
    def build(
        cls,
        start_address: Array | cutlass.Pointer | Int32 | int,
        leading_byte_offset: int = 0,
        stride_byte_offset: int = 0,
        base_offset: Literal[0, 1, 2, 3, 4, 5, 6, 7] = 0,
        layout: int | Tcgen05SmemSwizzle = 0,
        leading_dim_mode: int = 0,
    ) -> "Tcgen05SmemDesc":
        """Build the SMEM descriptor via the NVVM descriptor intrinsic.

        Using the NVVM intrinsic (rather than raw bit-shifts) allows
        compiler optimization passes to pattern-match the descriptor.

        **Address convention — do NOT pre-shift.** This method shifts
        ``start_address >> 4`` internally (converting bytes → 16-byte
        units, as the hardware expects).  Pass the raw SMEM byte address,
        not ``smem_addr >> 4``.  Passing a pre-shifted value produces a
        silently wrong descriptor — the MMA will read from the wrong SMEM
        region and output NaN / garbage (no CUDA error).  This is the
        single most common footgun when porting from the lower-level
        ``nvvm.tcgen05_mma_smem_desc`` wrapper (which *does* expect a
        pre-shifted address).

        :param start_address: Raw SMEM address in bytes — accepts
            ``Array``, :class:`cutlass.Pointer`, or ``Int32``
            (``smem.toint()`` / raw ``ptrtoint`` result).  The method
            applies ``>> 4`` internally.
        :param leading_byte_offset: In bytes (will be ``>> 4`` internally).
            For swizzled K-major FP16 / BF16 operands this is conventionally
            16 bytes because PTX treats the field as unused / assumed 1.
            For swizzled MN-major operands this is the stride from one
            swizzle-width MN group to the next; for a compact split-N
            FP16 128B-swizzle tile use ``K_TILE * 64 * 2`` bytes.
        :param stride_byte_offset: In bytes (will be ``>> 4`` internally).
            Major-specific PTX stride of the *physical* SMEM tile:
            ``8 × K_dim × elem_bytes`` for K-major operands, or
            ``8 × MN_group × elem_bytes`` for swizzled MN-major operands.
            The matching
            :meth:`Tcgen05InstrDesc.build` ``*_major`` flag and the
            per-K-step ``advance_start_address`` increment are derived from
            the same layout choice: ``MMA_K × elem_bytes`` for K-major and
            ``MMA_K × MN_group × elem_bytes`` for MN-major (``2 × SBO`` for
            FP16/BF16).
        :param layout: Swizzle — accepts :class:`Tcgen05SmemSwizzle`, int,
            :class:`cuda.TensorMapSwizzle`, or a canonical ``cutlass.Swizzle`` that
            can be converted to a tcgen05 descriptor encoding.
        :param leading_dim_mode: 0 for relative byte-offset mode. Use the
            default unless you explicitly need the SM103+ absolute-address
            leading-dimension mode.

        """
        # A swizzle-descriptor object (Tcgen05SmemSwizzle / cutlass.Swizzle /
        # TensorMapSwizzle) converts to the tcgen05 encoding via .to(); a plain
        # int / Int8 swizzle code is taken as-is.
        if not isinstance(layout, (int, Numeric)) and hasattr(layout, "to"):
            layout = layout.to(Tcgen05SmemSwizzle)
        # A traced Numeric (e.g. ``Int8(2)``) has no Python int value, so wrap
        # it directly; a Python int / IntEnum goes through ``int()``.
        swizzle_code = (
            _cutlass.Int8(layout)
            if isinstance(layout, Numeric)
            else _cutlass.Int8(int(layout))
        )

        if isinstance(start_address, (Array, cutlass.Pointer)):
            addr = _cutlass.Int32(
                llvm.ptrtoint(_cutlass.Int32.mlir_type, start_address.ir_value())
            )
        else:
            addr = _cutlass.Int32(start_address)

        leading_dim_offset = _cutlass.Int32(
            _drop_low_bits(leading_byte_offset, 4, "leading_byte_offset")
        )
        stride_dim_offset = _cutlass.Int32(
            _drop_low_bits(stride_byte_offset, 4, "stride_byte_offset")
        )

        return cls(
            _tcgen05_mma_smem_desc(
                addr >> 4,
                leading_dim_offset,
                stride_dim_offset,
                _cutlass.Int8(base_offset),
                _cutlass.Boolean(leading_dim_mode),
                swizzle_code,
            )
        )


Tcgen05SmemDesc.width = Int64.width
Tcgen05SmemDesc.bytes = Int64.bytes


# =============================================================================
# Tcgen05InstrDesc
# =============================================================================


class Tcgen05InstrDesc(Int32):
    """SM100 ``tcgen05.mma`` instruction descriptor (32-bit).

    Used for both ``.kind::f16`` and ``.kind::f8f6f4`` modes.

    Bitfield layout::

        [0:2)   sparse_id2
        [2:3)   sparse_flag
        [3:4)   saturate
        [4:6)   c_format      (Tcgen05OutputFormat)
        [6:7)   sparse_format
        [7:10)  a_format      (Tcgen05InputFormat)
        [10:13) b_format      (Tcgen05InputFormat)
        [13:14) a_negate
        [14:15) b_negate
        [15:16) a_major       (0=K-major, 1=MN-major)
        [16:17) b_major       (0=K-major, 1=MN-major)
        [17:23) n_dim         (N >> 3)
        [23:24) (reserved)
        [24:29) m_dim         (M >> 4)
        [29:30) k_dim                                   # [29] reserved in SM100
        [30:32) max_shift
    """

    # -- bitfield readers --

    @property
    def sparse_id2(self) -> Int32:
        """Bits [0:2)."""
        return _get_field(self, 0, 2)

    @property
    def sparse_flag(self) -> Int32:
        """Bits [2:3): 0=dense, 1=sparse."""
        return _get_field(self, 2, 1)

    @property
    def saturate(self) -> Int32:
        """Bits [3:4)."""
        return _get_field(self, 3, 1)

    @property
    def c_format(self) -> Int32:
        """Bits [4:6): output format (:class:`Tcgen05OutputFormat`)."""
        return _get_field(self, 4, 2)

    @property
    def sparse_format(self) -> Int32:
        """Bits [6:7)."""
        return _get_field(self, 6, 1)

    @property
    def a_format(self) -> Int32:
        """Bits [7:10): A operand format (:class:`Tcgen05InputFormat`)."""
        return _get_field(self, 7, 3)

    @property
    def b_format(self) -> Int32:
        """Bits [10:13): B operand format (:class:`Tcgen05InputFormat`)."""
        return _get_field(self, 10, 3)

    @property
    def a_negate(self) -> Int32:
        """Bits [13:14)."""
        return _get_field(self, 13, 1)

    @property
    def b_negate(self) -> Int32:
        """Bits [14:15)."""
        return _get_field(self, 14, 1)

    @property
    def a_major(self) -> Int32:
        """Bits [15:16): 0=K-major, 1=MN-major."""
        return _get_field(self, 15, 1)

    @property
    def b_major(self) -> Int32:
        """Bits [16:17): 0=K-major, 1=MN-major."""
        return _get_field(self, 16, 1)

    @property
    def n_dim(self) -> Int32:
        """Bits [17:23): encoded N dimension (N >> 3)."""
        return _get_field(self, 17, 6)

    @property
    def m_dim(self) -> Int32:
        """Bits [24:29): encoded M dimension (M >> 4)."""
        return _get_field(self, 24, 5)

    @property
    def k_dim(self) -> Int32:
        """Bits [29:30): k_dim."""
        return _get_field(self, 29, 1)

    @property
    def max_shift(self) -> Int32:
        """Bits [30:32)."""
        return _get_field(self, 30, 2)

    @staticmethod
    def _input_format_from_dtype(dtype: type[Numeric]) -> Tcgen05InputFormat:
        """Return ``a_format`` / ``b_format`` for a dense tcgen05 input dtype."""
        if dtype is _cutlass.Float16:
            return Tcgen05InputFormat.F16
        if dtype is _cutlass.BFloat16:
            return Tcgen05InputFormat.BF16
        if dtype is _cutlass.Float32:
            return Tcgen05InputFormat.TF32
        if dtype in {
            _cutlass.Float8E4M3,
            _cutlass.Float8E4M3FN,
            _cutlass.Float8E4M3B11FNUZ,
        }:
            return Tcgen05InputFormat.E4M3
        if dtype is _cutlass.Float8E5M2:
            return Tcgen05InputFormat.E5M2
        if dtype is _cutlass.Uint8:
            return Tcgen05InputFormat.U8
        if dtype is _cutlass.Int8:
            return Tcgen05InputFormat.S8
        raise TypeError(f"Unsupported tcgen05 input dtype: {dtype!r}")

    @staticmethod
    def _output_format_from_dtype(dtype: type[Numeric]) -> Tcgen05OutputFormat:
        """Return ``c_format`` for a dense tcgen05 accumulator dtype."""
        if dtype is _cutlass.Float16:
            return Tcgen05OutputFormat.F16
        if dtype is _cutlass.Float32:
            return Tcgen05OutputFormat.F32
        if dtype is _cutlass.Int32:
            return Tcgen05OutputFormat.S32
        raise TypeError(f"Unsupported tcgen05 accumulator dtype: {dtype!r}")

    @staticmethod
    def _validate_dtype_pattern(
        a_dtype: type[Numeric],
        b_dtype: type[Numeric],
        c_dtype: type[Numeric],
    ) -> None:
        """Reject dense dtype triples not covered by tcgen05 MMA encodings."""
        f16_like = {_cutlass.Float16, _cutlass.BFloat16}
        fp8_like = {
            _cutlass.Float8E4M3,
            _cutlass.Float8E4M3FN,
            _cutlass.Float8E4M3B11FNUZ,
            _cutlass.Float8E5M2,
        }
        int8_like = {_cutlass.Int8, _cutlass.Uint8}
        if a_dtype in f16_like and b_dtype in f16_like and c_dtype is _cutlass.Float32:
            return
        if (
            a_dtype is _cutlass.Float32
            and b_dtype is _cutlass.Float32
            and c_dtype is _cutlass.Float32
        ):
            return
        if (
            a_dtype in fp8_like
            and b_dtype in fp8_like
            and c_dtype in {_cutlass.Float16, _cutlass.Float32}
        ):
            return
        if a_dtype in int8_like and b_dtype in int8_like and c_dtype is _cutlass.Int32:
            return
        if (
            a_dtype is _cutlass.Float16
            and b_dtype is _cutlass.Float16
            and c_dtype is _cutlass.Float16
        ):
            return
        raise ValueError(
            "Unsupported dense tcgen05 dtype pattern: "
            f"a_dtype={a_dtype!r}, b_dtype={b_dtype!r}, c_dtype={c_dtype!r}"
        )

    @classmethod
    def build(
        cls,
        sparse_id2: Literal[0, 1, 2, 3] = 0,
        sparse_flag: Literal[0, 1] = 0,
        saturate: Literal[0, 1] = 0,
        sparse_format: Literal[0, 1] = 0,
        c_dtype: type[Numeric] | None = None,
        a_dtype: type[Numeric] | None = None,
        b_dtype: type[Numeric] | None = None,
        a_negate: Literal[0, 1] = 0,
        b_negate: Literal[0, 1] = 0,
        a_major: Literal[0, 1] = 0,
        b_major: Literal[0, 1] = 0,
        n_dim: int = 0,
        m_dim: int = 0,
        k_dim: Literal[0, 1] = 0,
        max_shift: Literal[0, 1, 2, 3] = 0,
    ) -> "Tcgen05InstrDesc":
        """Pack fields into a tcgen05 instruction descriptor.

        :param c_dtype: Accumulator dtype.  ``None`` (default) → format
            field 0 (the ``.kind::f16`` F16 layout).  Pass ``cutlass.Float32`` for F32
            accumulator, ``cutlass.Int32`` for S32, etc.
        :param a_dtype: A operand dtype.  ``None`` (default) → format
            field 0 (F16 / FP8 E4M3 — disambiguated by the MMA
            kind selected on the consumer ``nvvm.tcgen05_mma`` call).
            Pass ``cutlass.Int8`` / ``cutlass.Uint8`` / ``cutlass.Float16`` /
            ``cutlass.BFloat16`` / ``cutlass.Float32`` (= TF32) /
            ``cutlass.Float8E4M3FN`` / ``cutlass.Float8E5M2`` to be explicit.
            When all three of ``a_dtype`` / ``b_dtype`` / ``c_dtype`` are
            provided, unsupported dense dtype triples raise ``ValueError``.
        :param b_dtype: B operand dtype.  Same semantics as ``a_dtype``.
        :param n_dim: N dimension of Matrix B (3 LSBs not included in the
            encoded field). Pass the logical N; must be a multiple of 8.
        :param m_dim: M dimension of Matrix A (4 LSBs not included in the
            encoded field). Pass the logical M; must be a multiple of 16.
        :param a_major: 0 = K-major (default), 1 = M-major (A is
            transposed in SMEM — K stored along rows). Must match the
            physical layout described by the corresponding
            :class:`Tcgen05SmemDesc` and drives the per-K-step
            ``advance_start_address`` increment (``32`` bytes for FP16/BF16
            K-major, ``2 × stride_byte_offset`` bytes for FP16/BF16
            MN-major).
        :param b_major: 0 = K-major (default), 1 = N-major (B is
            transposed in SMEM — K stored along rows). Same coupling
            rules as ``a_major``.
        :param k_dim: for block-scaled: 0=[dense: K32, sparse: K64], 1=[dense: K64,
            sparse: invalid]
        """
        if a_dtype is not None and b_dtype is not None and c_dtype is not None:
            cls._validate_dtype_pattern(a_dtype, b_dtype, c_dtype)
        c_format = (
            int(cls._output_format_from_dtype(c_dtype)) if c_dtype is not None else 0
        )
        a_format = (
            int(cls._input_format_from_dtype(a_dtype)) if a_dtype is not None else 0
        )
        b_format = (
            int(cls._input_format_from_dtype(b_dtype)) if b_dtype is not None else 0
        )
        n_dim_enc = _drop_low_bits(n_dim, 3, "n_dim")
        m_dim_enc = _drop_low_bits(m_dim, 4, "m_dim")

        assert 0 <= sparse_id2 < 4, f"sparse_id2 must be in [0, 3], got {sparse_id2}"
        assert sparse_flag in [0, 1], f"sparse_flag must be 0 or 1, got {sparse_flag}"
        assert saturate in [0, 1], f"saturate must be 0 or 1, got {saturate}"
        assert 0 <= c_format < 4, f"c_format must be in [0, 3], got {c_format}"
        assert sparse_format in [0, 1], (
            f"sparse_format must be 0 or 1, got {sparse_format}"
        )
        assert 0 <= a_format < 8, f"a_format must be in [0, 7], got {a_format}"
        assert 0 <= b_format < 8, f"b_format must be in [0, 7], got {b_format}"
        assert a_negate in [0, 1], f"a_negate must be 0 or 1, got {a_negate}"
        assert b_negate in [0, 1], f"b_negate must be 0 or 1, got {b_negate}"
        assert a_major in [0, 1], f"a_major must be 0 or 1, got {a_major}"
        assert b_major in [0, 1], f"b_major must be 0 or 1, got {b_major}"
        assert 0 <= n_dim_enc < 64, (
            f"n_dim={n_dim} out of range: must be a multiple of 8 in [0, 504] "
            f"(64 valid values — encoded field is 6 bits, with 3 LSBs not encoded)"
        )
        assert 0 <= m_dim_enc < 32, (
            f"m_dim={m_dim} out of range: must be a multiple of 16 in [0, 496] "
            f"(32 valid values — encoded field is 5 bits, with 4 LSBs not encoded)"
        )
        assert k_dim in [0, 1], f"k_dim must be 0 or 1, got {k_dim}"
        assert 0 <= max_shift < 4, f"max_shift must be in [0, 3], got {max_shift}"

        desc = 0
        desc |= (sparse_id2 & 0x3) << 0
        desc |= (sparse_flag & 0x1) << 2
        desc |= (saturate & 0x1) << 3
        desc |= (c_format & 0x3) << 4
        desc |= (sparse_format & 0x1) << 6
        desc |= (a_format & 0x7) << 7
        desc |= (b_format & 0x7) << 10
        desc |= (a_negate & 0x1) << 13
        desc |= (b_negate & 0x1) << 14
        desc |= (a_major & 0x1) << 15
        desc |= (b_major & 0x1) << 16
        desc |= (n_dim_enc & 0x3F) << 17
        desc |= (m_dim_enc & 0x1F) << 24
        desc |= (k_dim & 0x1) << 29
        desc |= (max_shift & 0x3) << 30

        return cls(desc & 0xFFFFFFFF)


# =============================================================================
# Tcgen05MxInstrDesc
# =============================================================================


class Tcgen05MxInstrDesc(Int32):
    """Block-scaled (MX) ``tcgen05.mma`` instruction descriptor (32-bit).

    SM100 block-scaled FP4 is also supported by this descriptor.
    Newer block-scaled FP4 paths must use Tcgen05MxOmmaInstrDesc.

    Consumed by ``nvvm.tcgen05_mma_block_scale()``.
    Different bit layout from :class:`Tcgen05InstrDesc`.

    Bitfield layout::

        [0:2)   (reserved)
        [2:3)   sparse_flag
        [3:4)   (reserved)
        [4:6)   b_sf_id
        [6:7)   (reserved)
        [7:10)  a_format
        [10:13) b_format
        [13:14) a_negate
        [14:15) b_negate
        [15:16) a_major
        [16:17) b_major
        [17:23) n_dim        (N >> 3)
        [23:25) scale_format (MxScaleFormat)    # [24] reserved in SM100
        [25:26) (reserved)
        [26:27) a_sf_layout                     # [26] reserved in SM100
        [27:29) m_dim        (M >> 7)
        [29:31) a_sf_id
        [31:32) k_dim                           # [31] reserved in SM100 block-scaled
    """

    @property
    def sparse_flag(self) -> Int32:
        """Bits [2:3)."""
        return _get_field(self, 2, 1)

    @property
    def b_sf_id(self) -> Int32:
        """Bits [4:6): B scale-factor data ID."""
        return _get_field(self, 4, 2)

    @property
    def a_format(self) -> Int32:
        """Bits [7:10): A operand format."""
        return _get_field(self, 7, 3)

    @property
    def b_format(self) -> Int32:
        """Bits [10:13): B operand format."""
        return _get_field(self, 10, 3)

    @property
    def a_negate(self) -> Int32:
        """Bits [13:14)."""
        return _get_field(self, 13, 1)

    @property
    def b_negate(self) -> Int32:
        """Bits [14:15)."""
        return _get_field(self, 14, 1)

    @property
    def a_major(self) -> Int32:
        """Bits [15:16): 0=K-major, 1=MN-major."""
        return _get_field(self, 15, 1)

    @property
    def b_major(self) -> Int32:
        """Bits [16:17): 0=K-major, 1=MN-major."""
        return _get_field(self, 16, 1)

    @property
    def n_dim(self) -> Int32:
        """Bits [17:23): encoded N dimension (N >> 3)."""
        return _get_field(self, 17, 6)

    @property
    def scale_format(self) -> Int32:
        """Bits [23:25): :class:`MxScaleFormat`."""
        return _get_field(self, 23, 2)

    @property
    def a_sf_layout(self) -> Int32:
        """Bits [26:27): :SFA layout type."""
        return _get_field(self, 26, 1)

    @property
    def m_dim(self) -> Int32:
        """Bits [27:29): encoded M dimension (M >> 7)."""
        return _get_field(self, 27, 2)

    @property
    def a_sf_id(self) -> Int32:
        """Bits [29:31): A scale-factor data ID."""
        return _get_field(self, 29, 2)

    @property
    def k_dim(self) -> Int32:
        """Bits [31:32): K dimension flag."""
        return _get_field(self, 31, 1)

    def set_sf_ids(
        self, a_sf_id: int | Int32, b_sf_id: int | Int32
    ) -> "Tcgen05MxInstrDesc":
        """Return a copy with updated scale-factor data IDs."""
        result = _set_field(self, 4, 2, b_sf_id)  # b_sf_id at [4:6)
        return _set_field(result, 29, 2, a_sf_id)  # a_sf_id at [29:31)

    @staticmethod
    def _input_format_from_dtype(dtype: type[Numeric]) -> int:
        """Return ``a_format`` / ``b_format`` for a block-scaled tcgen05 input dtype.

        Block-scaled (MX) MMA encodings use a 3-bit format field that
        spans FP8/FP6/FP4 element types:

        * ``0`` — E4M3 (Float8E4M3 / Float8E4M3FN / Float8E4M3B11FNUZ)
        * ``1`` — E5M2 (Float8E5M2)
        * ``3`` — E2M3 (Float6E2M3FN)
        * ``4`` — E3M2 (Float6E3M2FN)
        * ``5`` — E2M1 (Float4E2M1FN)
        """
        if dtype in {
            _cutlass.Float8E4M3,
            _cutlass.Float8E4M3FN,
            _cutlass.Float8E4M3B11FNUZ,
        }:
            return 0
        if dtype is _cutlass.Float8E5M2:
            return 1
        if dtype is _cutlass.Float6E2M3FN:
            return 3
        if dtype is _cutlass.Float6E2M3FNx4:
            return 3
        if dtype is _cutlass.Float6E3M2FN:
            return 4
        if dtype is _cutlass.Float6E3M2FNx4:
            return 4
        if dtype is _cutlass.Float4E2M1FN:
            return 5
        if dtype is _cutlass.Float4E2M1FNx2:
            return 5
        raise TypeError(f"Unsupported block-scaled tcgen05 input dtype: {dtype!r}")

    @classmethod
    def build(
        cls,
        sparse_flag: int = 0,
        b_sf_id: int = 0,
        a_sf_id: int = 0,
        a_dtype: type[Numeric] | None = None,
        b_dtype: type[Numeric] | None = None,
        scale_format: int = 1,
        a_negate: int = 0,
        b_negate: int = 0,
        a_major: int = 0,
        b_major: int = 0,
        n_dim: int = 0,
        m_dim: int = 0,
        k_dim: int = 0,
        a_sf_layout: int = 0,
    ) -> "Tcgen05MxInstrDesc":
        """Pack a block-scaled tcgen05 MMA instruction descriptor.

        Use this builder for MX block-scaled ``tcgen05_mma_block_scale``
        operations such as FP8, FP6, and MX FP4 forms that use the
        ``Tcgen05MxInstrDesc`` bit layout.

        :param sparse_flag: Sparse-mode flag.
        :param b_sf_id: B scale-factor data ID.
        :param a_sf_id: A scale-factor data ID.
        :param a_dtype: A operand scalar dtype.  When provided, selects the
            encoded input-format field.
        :param b_dtype: B operand scalar dtype.  When provided, selects the
            encoded input-format field.
        :param scale_format: Scale-factor format encoding.
        :param a_negate: A operand negate flag.
        :param b_negate: B operand negate flag.
        :param a_major: A operand layout flag; ``0`` for K-major, ``1`` for
            MN-major.
        :param b_major: B operand layout flag; ``0`` for K-major, ``1`` for
            MN-major.
        :param n_dim: Logical N dimension.  Must be a multiple of 8 in
            ``[8, 256]``; the encoded field stores ``N >> 3``.
        :param m_dim: Logical M dimension.  Must be ``128`` or ``256``; the
            encoded field stores ``M >> 7``.
        :param k_dim: 1-bit K-mode flag, not a literal K dimension.
        :param a_sf_layout: A scale-factor layout flag.
        :returns: Packed block-scaled tcgen05 instruction descriptor.

        .. code-block:: python

            idesc = cutlass.experimental.primitives.Tcgen05MxInstrDesc.build(
                a_dtype=cutlass.Float8E4M3FN,
                b_dtype=cutlass.Float4E2M1FN,
                scale_format=1,
                n_dim=N_TILE,
                m_dim=M_TILE,
            )
        """
        a_format = cls._input_format_from_dtype(a_dtype) if a_dtype is not None else 0
        b_format = cls._input_format_from_dtype(b_dtype) if b_dtype is not None else 5
        n_dim_enc = _drop_low_bits(n_dim, 3, "n_dim")
        m_dim_enc = _drop_low_bits(m_dim, 7, "m_dim")

        assert sparse_flag in [0, 1]
        assert 0 <= b_sf_id <= 3
        assert 0 <= a_sf_id <= 3
        assert 0 <= a_format <= 5
        assert 0 <= b_format <= 5
        assert scale_format in [0, 1, 2]
        assert a_negate in [0, 1]
        assert b_negate in [0, 1]
        assert a_major in [0, 1]
        assert b_major in [0, 1]
        assert 1 <= n_dim_enc <= 32, (
            f"n_dim={n_dim} out of range: must be a multiple of 8 in [8, 256] "
            "(32 valid values; encoded field is 6 bits with 3 LSBs not encoded, "
            "valid encoded range 1..32)"
        )
        assert m_dim_enc in [1, 2], (
            f"m_dim={m_dim} out of range: must be 128 or 256 "
            "(only 2 valid values; encoded field is 2 bits with 7 LSBs not encoded, "
            "valid encoded range 1..2)"
        )
        assert k_dim in [0, 1]
        assert 0 <= a_sf_layout <= 1

        desc = 0
        desc |= (sparse_flag & 0x1) << 2
        desc |= (b_sf_id & 0x3) << 4
        desc |= (a_format & 0x7) << 7
        desc |= (b_format & 0x7) << 10
        desc |= (a_negate & 0x1) << 13
        desc |= (b_negate & 0x1) << 14
        desc |= (a_major & 0x1) << 15
        desc |= (b_major & 0x1) << 16
        desc |= (n_dim_enc & 0x3F) << 17
        desc |= (scale_format & 0x3) << 23
        desc |= (a_sf_layout & 0x1) << 26
        desc |= (m_dim_enc & 0x3) << 27
        desc |= (a_sf_id & 0x3) << 29
        desc |= (k_dim & 0x1) << 31
        return cls(desc & 0xFFFFFFFF)


class Tcgen05MxOmmaInstrDesc(Tcgen05MxInstrDesc):
    """Block-scaled (NVFP4) ``tcgen05.mma`` instruction descriptor (32-bit).

    Consumed by ``nvvm.tcgen05_mma_block_scale()``.
    Different bit layout from :class:`Tcgen05MxInstrDesc`.

    Bitfield layout that differs from :class:`Tcgen05MxInstrDesc`::

        [3:4)   k_dim_upper
        ...
        [10:12) b_format
        [12:13) sparsity_version
        ...
        [31:32) k_dim_lower
    """

    @property
    def k_dim_upper(self) -> Int32:
        """Bits [3:4): K dimension upper bit."""
        return _get_field(self, 3, 1)

    @property
    def b_format(self) -> Int32:
        """Bits [10:12): B operand format."""
        return _get_field(self, 10, 2)

    @property
    def sparsity_version(self) -> Int32:
        """Bits [12:13): Sparsity version."""
        return _get_field(self, 12, 1)

    @property
    def k_dim_lower(self) -> Int32:
        """Bits [31:32): K dimension lower bit."""
        return _get_field(self, 31, 1)

    @property
    def k_dim(self) -> Int32:
        """2-bit K size field."""
        return (_get_field(self, 3, 1) << 1) | _get_field(self, 31, 1)

    @staticmethod
    def _input_format_from_dtype(dtype: type[Numeric]) -> int:
        """Return ``a_format`` / ``b_format`` for a block-scaled tcgen05 input dtype.

        * ``0`` — invalid
        * ``1`` — E2M1 (Float4E2M1FN)
        """
        if dtype is _cutlass.Float4E2M1FN:
            return 1
        raise TypeError(f"Unsupported block-scaled tcgen05 input dtype: {dtype!r}")

    @classmethod
    def build(  # type: ignore[override]
        cls,
        sparse_flag: int = 0,
        a_sf_id: int = 0,
        a_sf_layout: int = 0,
        b_sf_id: int = 0,
        a_dtype: type[Numeric] | None = None,
        b_dtype: type[Numeric] | None = None,
        scale_format: int = 1,
        a_negate: int = 0,
        b_negate: int = 0,
        a_major: int = 0,
        b_major: int = 0,
        n_dim: int = 0,
        m_dim: int = 0,
        k_dim: int = 0,
        sparsity_version: int = 1,  # sparsity version (irrelevant for SM100)
    ) -> "Tcgen05MxOmmaInstrDesc":
        """Pack an NVFP4 block-scaled 4-bit tcgen05 instruction descriptor.

        Use this builder for FP4/NVFP4 ``tcgen05_mma_block_scale`` paths
        such as ``kind::mxf4nvf4``.  It extends the MX descriptor layout with
        FP4-specific ``k_dim`` and ``sparsity_version`` fields.

        :param sparse_flag: Sparse-mode flag.
        :param a_sf_id: A scale-factor data ID.
        :param a_sf_layout: A scale-factor layout flag.
        :param b_sf_id: B scale-factor data ID.
        :param a_dtype: A operand scalar dtype.  FP4 paths should pass
            ``cutlass.Float4E2M1FN``.
        :param b_dtype: B operand scalar dtype.  FP4 paths should pass
            ``cutlass.Float4E2M1FN``.
        :param scale_format: Scale-factor format encoding.
        :param a_negate: A operand negate flag.
        :param b_negate: B operand negate flag.
        :param a_major: A operand layout flag; ``0`` for K-major, ``1`` for
            MN-major.
        :param b_major: B operand layout flag; ``0`` for K-major, ``1`` for
            MN-major.
        :param n_dim: Logical collective N dimension.  Must be a multiple of 8
            in ``[8, 256]``; the encoded field stores ``N >> 3``.
        :param m_dim: Logical collective M dimension.  Must be ``128`` or
            ``256``; the encoded field stores ``M >> 7``.
        :param k_dim: 2-bit K-mode field split across upper/lower
            descriptor bits.
        :param sparsity_version: sparsity-version bit.
        :returns: Packed NVFP4 block-scaled tcgen05 instruction descriptor.

        .. code-block:: python

            idesc = cutlass.experimental.primitives.Tcgen05MxOmmaInstrDesc.build(
                a_dtype=cutlass.Float4E2M1FN,
                b_dtype=cutlass.Float4E2M1FN,
                scale_format=0,
                n_dim=N_COLLECTIVE,
                m_dim=M_COLLECTIVE,
            )
        """

        assert k_dim in [0, 1, 2], f"k_dim must be 0, 1, or 2, got {k_dim}"
        k_dim_upper_bit = (k_dim >> 1) & 0x1
        k_dim_lower_bit = k_dim & 0x1

        desc = Int32(
            Tcgen05MxInstrDesc.build(
                sparse_flag=sparse_flag,
                a_sf_id=a_sf_id,
                a_sf_layout=a_sf_layout,
                b_sf_id=b_sf_id,
                a_dtype=a_dtype,
                b_dtype=b_dtype,
                scale_format=scale_format,
                a_negate=a_negate,
                b_negate=b_negate,
                a_major=a_major,
                b_major=b_major,
                n_dim=n_dim,
                m_dim=m_dim,
                k_dim=k_dim_lower_bit,
            )
        )

        a_format = cls._input_format_from_dtype(a_dtype) if a_dtype is not None else 1
        b_format = cls._input_format_from_dtype(b_dtype) if b_dtype is not None else 1

        assert 0 <= a_format <= 1
        assert 0 <= b_format <= 1
        assert sparsity_version in [0, 1]

        desc |= (k_dim_upper_bit & 0x1) << 3
        # clear bits [7:13) and re-define
        desc &= 0xFFFFE07F
        desc |= (a_format & 0x7) << 7
        desc |= (b_format & 0x3) << 10
        desc |= (sparsity_version & 0x1) << 12
        # [31] does not actually need override here, just for completeness
        desc |= (k_dim_lower_bit & 0x1) << 31
        return cls(desc & 0xFFFFFFFF)


# =============================================================================
# TmemAddr
# =============================================================================


class TmemAddr(Int32):
    """Tensor-memory address encoding (32-bit).

    Used by ``make_tmem_ptr()`` and epilogue warps.

    Bitfield layout::

        [0:16)  col_id
        [16:32) row_id
    """

    @property
    def col_id(self) -> Int32:
        """Bits [0:16): column index."""
        return _get_field(self, 0, 16)

    @property
    def row_id(self) -> Int32:
        """Bits [16:32): row (lane) index."""
        return _get_field(self, 16, 16)

    @staticmethod
    def from_row_col(row: int | Int32, col: int | Int32) -> "TmemAddr":
        """Construct from separate row and column IDs."""
        return TmemAddr((Int32(row) << 16) | (Int32(col) & 0xFFFF))

    def as_ptr(self, dtype: type[Numeric]) -> Array:
        """Convert to a typed TMEM pointer (address space 6)."""
        tmem_space = cutlass.AddressSpace.tmem.value
        raw = self.ir_value() if hasattr(self, "ir_value") else self.value
        ptr = llvm.inttoptr(llvm.PointerType.get(tmem_space), raw)
        return Array(ptr, dtype=dtype, addrspace=tmem_space)


# =============================================================================
# Public API
# =============================================================================

__all__ = [
    # Hopper (SM90) descriptor types
    "WgmmaSmemDesc",
    "WgmmaSwizzle",
    # SM100 descriptor types
    "Tcgen05SmemDesc",
    "Tcgen05InstrDesc",
    "Tcgen05MxInstrDesc",
    "Tcgen05MxOmmaInstrDesc",
    "TmemAddr",
    # SM100 enums
    "Tcgen05OutputFormat",
    "Tcgen05InputFormat",
    "Tcgen05SmemSwizzle",
    "MxScaleFormat",
]
