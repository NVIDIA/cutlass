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

import struct
from typing import Optional, Union

from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm as _llvm
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from ..typing import (
    AddressSpace,
    Float32,
    Int32,
    Int64,
    Uint32,
    Uint64,
    Pointer,
    Integer,
)
from .common import CacheEvictionPriority as CacheEvictionPriority_

__all__ = ["CachePolicy"]

_CACHE_PRIORITY_TO_PTX = {
    "EVICT_NORMAL": "evict_normal",
    "EVICT_FIRST": "evict_first",
    "EVICT_LAST": "evict_last",
    "EVICT_UNCHANGED": "evict_unchanged",
}


def _cache_policy_priorities(
    primary_priority: CacheEvictionPriority_ | _cute_nvgpu_ir.CacheEvictionPriority,
    secondary_priority: CacheEvictionPriority_ | _cute_nvgpu_ir.CacheEvictionPriority,
) -> tuple[str, str]:
    """Validate the priorities shared by fractional and range policies."""
    priority_types = (CacheEvictionPriority_, _cute_nvgpu_ir.CacheEvictionPriority)
    for name, priority in (
        ("primary_priority", primary_priority),
        ("secondary_priority", secondary_priority),
    ):
        if not isinstance(priority, priority_types):
            raise ValueError(f"{name} must be a CacheEvictionPriority")
        if priority.name not in _CACHE_PRIORITY_TO_PTX:
            raise ValueError(f"{priority} is not supported for L2 cache policies")
    if secondary_priority.name not in ("EVICT_FIRST", "EVICT_UNCHANGED"):
        raise ValueError("secondary_priority must be EVICT_FIRST or EVICT_UNCHANGED")
    return (
        _CACHE_PRIORITY_TO_PTX[primary_priority.name],
        _CACHE_PRIORITY_TO_PTX[secondary_priority.name],
    )


def _cache_policy_unsigned_argument(
    name: str, value: int | Integer, width: int
) -> int | ir.Value:
    """Validate an unsigned PTX operand without truncating a wider integer."""
    types = (Int32, Uint32) if width == 32 else (Int64, Uint64)
    if isinstance(value, bool) or not isinstance(value, (int, *types)):
        raise ValueError(f"{name} must be a Python integer, Int{width}, or Uint{width}")
    static_value = value.value if isinstance(value, Integer) else value
    if isinstance(static_value, int) and not 0 <= static_value < (1 << width):
        raise ValueError(f"{name} must be in [0, 0x{(1 << width) - 1:x}]")
    return static_value


def _validate_cache_policy_range_sizes(
    primary_size: int | Int32 | Uint32, total_size: int | Int32 | Uint32
) -> None:
    primary = _cache_policy_unsigned_argument("primary_size", primary_size, 32)
    total = _cache_policy_unsigned_argument("total_size", total_size, 32)
    if isinstance(primary, int) and isinstance(total, int) and primary > total:
        raise ValueError("primary_size must be <= total_size")


class CachePolicy:
    """A typed L2 cache eviction policy for compatible memory operations.

    Construct this object in device code to emit a policy descriptor. The
    fractional, pointer-range, and converted CUDA policies can be passed to
    ``cute.copy(..., cache_policy=policy)`` or ``CopyAtom.with_``. Fabric-range
    policies instead require a compatible fabric operation. This is a typed
    device value, not a host-side configuration object.

    ``CachePolicy(...)`` creates a fractional policy; :meth:`range` creates an
    address-range policy, :meth:`range_fabric` creates a fabric-range policy,
    and :meth:`from_access_property` converts a CUDA access property.
    For the fractional constructor, the primary priority is requested with
    probability ``fraction``; the secondary priority applies otherwise.
    These are performance hints, not
    guarantees about the fraction of accesses or cache capacity retained.

    :param fraction: Probability in ``(0.0, 1.0]``, either a Python number or
        a ``Float32`` value. Defaults to 1.0. Known constants are validated;
        callers must ensure runtime values satisfy the same range.
    :param primary_priority: ``EVICT_NORMAL``, ``EVICT_FIRST``, ``EVICT_LAST``,
        or ``EVICT_UNCHANGED``. Defaults to ``EVICT_LAST``.
    :param secondary_priority: ``EVICT_FIRST`` or ``EVICT_UNCHANGED``.
        Defaults to ``EVICT_UNCHANGED``.

    Priorities are compile-time values from either ``cute.CacheEvictionPriority``
    or ``cute.nvgpu.CacheEvictionPriority``. ``NO_ALLOCATE`` is not supported.
    The fractional constructor implements PTX ``createpolicy.fractional.L2``
    and requires SM80 or newer; the consuming operation's architecture requirements
    still apply. The fabric constructor has stricter requirements below.

    .. code-block:: python

        policy = cache_policy.CachePolicy(
            fraction=0.25,
            primary_priority=cute.CacheEvictionPriority.EVICT_LAST,
            secondary_priority=cute.CacheEvictionPriority.EVICT_FIRST,
        )
        cute.copy(tma_store, source, destination, cache_policy=policy)
    """

    @dsl_user_op
    def __init__(
        self,
        fraction: Union[float, Float32] = 1.0,
        *,
        primary_priority: Union[
            CacheEvictionPriority_, _cute_nvgpu_ir.CacheEvictionPriority
        ] = CacheEvictionPriority_.EVICT_LAST,
        secondary_priority: Union[
            CacheEvictionPriority_, _cute_nvgpu_ir.CacheEvictionPriority
        ] = CacheEvictionPriority_.EVICT_UNCHANGED,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        primary, secondary = _cache_policy_priorities(
            primary_priority, secondary_priority
        )

        if isinstance(fraction, bool) or not isinstance(
            fraction, (int, float, Float32)
        ):
            raise ValueError("fraction must be a Python number or Float32")
        static_fraction = fraction.value if isinstance(fraction, Float32) else fraction
        if (
            isinstance(static_fraction, (int, float))
            and not 0.0 < static_fraction <= 1.0
        ):
            raise ValueError("fraction must be in (0.0, 1.0]")
        if isinstance(static_fraction, (int, float)):
            rounded_fraction = struct.unpack("f", struct.pack("f", static_fraction))[0]
            if rounded_fraction == 0.0:
                raise ValueError(
                    "fraction must be in (0.0, 1.0] after Float32 conversion"
                )

        # Use an f32 register operand: arbitrary fractions cannot use the integer
        # immediate constraint used by generic inline-PTX helpers.
        fraction_value = Float32(fraction).ir_value(loc=loc, ip=ip)
        descriptor = _llvm.inline_asm(
            Int64.mlir_type,
            [fraction_value],
            f"createpolicy.fractional.L2::{primary}.L2::{secondary}.b64 $0, $1;",
            "=l,f",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=_llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
        self._value = Int64(descriptor).ir_value(loc=loc, ip=ip)

    @classmethod
    @dsl_user_op
    def range(
        cls,
        base: Pointer,
        *,
        primary_size: Union[int, Int32, Uint32],
        total_size: Union[int, Int32, Uint32],
        primary_priority: Union[
            CacheEvictionPriority_, _cute_nvgpu_ir.CacheEvictionPriority
        ] = CacheEvictionPriority_.EVICT_LAST,
        secondary_priority: Union[
            CacheEvictionPriority_, _cute_nvgpu_ir.CacheEvictionPriority
        ] = CacheEvictionPriority_.EVICT_UNCHANGED,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "CachePolicy":
        """Create an L2 address-range policy using PTX ``createpolicy.range``.

        ``base`` must be a global-memory pointer, or a generic pointer that
        addresses global memory. Sizes are byte counts, independent of the
        pointer's element type. They may be Python integers or runtime
        ``Int32``/``Uint32`` values and must satisfy
        ``0 <= primary_size <= total_size <= 0xffffffff``. Known invalid
        constants are rejected; callers must satisfy these bounds at runtime.

        The primary priority applies to ``[base, base + primary_size)``.
        The secondary priority applies to both neighboring ranges:
        ``[base + primary_size, base + total_size)`` and
        ``[base - (total_size - primary_size), base)``. Behavior outside these
        ranges is unspecified. Priorities and defaults match ``CachePolicy``.

        This is an eviction hint, not an allocation, synchronization operation,
        or guarantee of cache residency. Requires SM80 or newer.

        .. code-block:: python

            policy = cache_policy.CachePolicy.range(
                tensor.iterator,
                primary_size=1024,
                total_size=2048,
                secondary_priority=cute.CacheEvictionPriority.EVICT_FIRST,
            )
            cute.copy(atom, source, destination, cache_policy=policy)
        """
        primary, secondary = _cache_policy_priorities(
            primary_priority, secondary_priority
        )
        if not isinstance(base, Pointer) or base.memspace not in (
            AddressSpace.gmem,
            AddressSpace.generic,
        ):
            raise ValueError("base must be a global or generic CuTe pointer")

        _validate_cache_policy_range_sizes(primary_size, total_size)

        address = base.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
        primary_bytes = Uint32(primary_size).ir_value(loc=loc, ip=ip)
        total_bytes = Uint32(total_size).ir_value(loc=loc, ip=ip)
        space = ".global" if base.memspace == AddressSpace.gmem else ""
        descriptor = _llvm.inline_asm(
            Int64.mlir_type,
            [address, primary_bytes, total_bytes],
            f"createpolicy.range{space}.L2::{primary}.L2::{secondary}.b64 $0, [$1], $2, $3;",
            "=l,l,r,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=_llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
        policy = object.__new__(cls)
        policy._value = Int64(descriptor).ir_value(loc=loc, ip=ip)
        return policy

    @classmethod
    @dsl_user_op
    def range_fabric(
        cls,
        le_id: int | Int32 | Uint32,
        offset: int | Int64 | Uint64,
        *,
        primary_size: int | Int32 | Uint32,
        total_size: int | Int32 | Uint32,
        primary_priority: CacheEvictionPriority_
        | _cute_nvgpu_ir.CacheEvictionPriority = CacheEvictionPriority_.EVICT_LAST,
        secondary_priority: CacheEvictionPriority_
        | _cute_nvgpu_ir.CacheEvictionPriority = CacheEvictionPriority_.EVICT_UNCHANGED,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "CachePolicy":
        """Create a policy for a CUDA Fabric Transport handle ``[le_id, offset]``.

        ``le_id`` is an unsigned 32-bit logical-endpoint identifier; ``offset``
        is an unsigned 64-bit byte offset within that endpoint. These are not
        a CUDA device ordinal and a global-memory pointer. Both may be Python
        integers or runtime integers of the corresponding width. Known bounds
        are checked; callers must provide a valid handle and runtime values.

        The primary and two secondary ranges follow :meth:`range`, relative
        to ``offset`` within the endpoint. Sizes are unsigned 32-bit byte
        counts with ``primary_size <= total_size``. Priorities have the same
        choices and defaults as the other constructors.

        Emits ``createpolicy.range.fabric.L2`` and requires PTX ISA 9.4 and
        SM100 or newer. This does not add fabric-copy support to TMA atoms;
        the consuming fabric operation must support the policy descriptor.
        """
        primary, secondary = _cache_policy_priorities(
            primary_priority, secondary_priority
        )
        _cache_policy_unsigned_argument("le_id", le_id, 32)
        _cache_policy_unsigned_argument("offset", offset, 64)
        _validate_cache_policy_range_sizes(primary_size, total_size)
        endpoint_value = Uint32(le_id).ir_value(loc=loc, ip=ip)
        offset_value = Uint64(offset).ir_value(loc=loc, ip=ip)
        primary_bytes = Uint32(primary_size).ir_value(loc=loc, ip=ip)
        total_bytes = Uint32(total_size).ir_value(loc=loc, ip=ip)
        descriptor = _llvm.inline_asm(
            Int64.mlir_type,
            [endpoint_value, offset_value, primary_bytes, total_bytes],
            f"createpolicy.range.fabric.L2::{primary}.L2::{secondary}.b64 $0, [$1, $2], $3, $4;",
            "=l,r,l,r,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=_llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
        policy = object.__new__(cls)
        policy._value = Int64(descriptor).ir_value(loc=loc, ip=ip)
        return policy

    @classmethod
    @dsl_user_op
    def from_access_property(
        cls,
        access_property: Int64 | Uint64,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "CachePolicy":
        """Convert an opaque CUDA access property with ``createpolicy.cvt.L2``.

        The input must contain the 64-bit representation of a valid CUDA
        access property, not a ``cudaAccessProperty`` enum or an already
        constructed cache-policy descriptor. This conversion preserves the
        policy encoded by CUDA; it does not take priorities or a fraction.
        Requires PTX ISA 7.4 and SM80 or newer.
        """
        if not isinstance(access_property, (Int64, Uint64)):
            raise ValueError(
                "access_property must be an opaque Int64 or Uint64 CUDA access property"
            )
        property_value = access_property.ir_value(loc=loc, ip=ip)
        descriptor = _llvm.inline_asm(
            Int64.mlir_type,
            [property_value],
            "createpolicy.cvt.L2.b64 $0, $1;",
            "=l,l",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=_llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
        policy = object.__new__(cls)
        policy._value = Int64(descriptor).ir_value(loc=loc, ip=ip)
        return policy

    def ir_value(self) -> ir.Value:
        """Return the underlying opaque 64-bit device descriptor."""
        return self._value

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return [self._value]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "CachePolicy":
        # Reconstruct the wrapper around an existing SSA value, without emitting
        # another createpolicy instruction or retaining the original SSA value.
        policy = object.__new__(type(self))
        policy._value = values[0]
        return policy
