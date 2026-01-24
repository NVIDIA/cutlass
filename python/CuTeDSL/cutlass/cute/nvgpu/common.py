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
from typing import Type, Optional

from cutlass.cutlass_dsl import DSLBaseError

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from .. import atom
from ..typing import Float16, Float32, Float64, Numeric


__all__ = [
    "OpError",
    "MmaUniversalOp",
    "MmaUniversalTrait",
    "CopyUniversalOp",
    "CopyUniversalTrait",
    "MemoryOrder",
    "MemoryScope",
    "CacheEvictionPriority",
]

class OpError(DSLBaseError):
    """
    An exception class for Op construction errors.
    """

    def __init__(
        self, op: atom.Op, message: str, suggestion: Optional[str] = None
    ) -> None:
        if suggestion is None:
            # Default suggestion
            suggestion = "Check your Op construction code"
        super().__init__(
            message,
            error_code=f"{op.__class__.__name__} error",
            suggestion=suggestion,
        )


####################################################################################################
#
# MMA Ops and Traits
#
####################################################################################################


@dataclass(frozen=True)
class MmaUniversalOp(atom.MmaOp):
    """
    The universal MMA Operation.

    This Operation currently expects the A/B operands as well as the accumulator to share the same
    data types.

    :param abacc_dtype: The data type for the A/B operands and the accumulator
    :type abacc_dtype:  Type[Numeric]
    """

    abacc_dtype: Type[Numeric]

    def __post_init__(self) -> None:
        if self.abacc_dtype not in [Float16, Float32, Float64]:
            raise OpError(
                self,
                "expects the 'abacc_dtype' Op parameter to be one of Float16, Float32, or Float64",
            )

    def __str__(self) -> str:
        return (
            "universal MMA Operation using FMA"
            f"\n  A/B/Accumulator data type = {self.abacc_dtype}"
        )

    def _make_trait(self, *, loc=None, ip=None, **kwargs) -> "MmaUniversalTrait":
        shape_mnk_attr = ir.Attribute.parse('#cute.shape<"(1,1,1)">')
        atom_ty = _cute_nvgpu_ir.UniversalFmaAtomType.get(
            shape_mnk_attr,
            self.abacc_dtype.mlir_type,
            self.abacc_dtype.mlir_type,
            self.abacc_dtype.mlir_type,
        )
        return MmaUniversalTrait(atom.make_atom(atom_ty, loc=loc, ip=ip))

    def _verify_fragment_A(self, input, *, loc=None, ip=None):
        pass

    def _verify_fragment_B(self, input, *, loc=None, ip=None):
        pass


class MmaUniversalTrait(atom.Trait):
    pass


####################################################################################################
#
# Copy Ops and Traits
#
####################################################################################################


class MemoryOrder(enum.Enum):
    WEAK = _cute_ir.MemOrderKind.WEAK
    RELAXED = _cute_ir.MemOrderKind.RELAXED
    ACQUIRE = _cute_ir.MemOrderKind.ACQUIRE
    RELEASE = _cute_ir.MemOrderKind.RELEASE
    ACQ_REL = _cute_ir.MemOrderKind.ACQ_REL
    SC = _cute_ir.MemOrderKind.SC
    MMIO = _cute_ir.MemOrderKind.MMIO
    CONSTANT = _cute_ir.MemOrderKind.CONSTANT
    VOLATILE = _cute_ir.MemOrderKind.VOLATILE

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.MemOrderKind:
        return self.value


class MemoryScope(enum.Enum):
    CTA = _cute_ir.MemScopeKind.CTA
    CLUSTER = _cute_ir.MemScopeKind.CLUSTER
    GPU = _cute_ir.MemScopeKind.GPU
    SYS = _cute_ir.MemScopeKind.SYS

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.MemScopeKind:
        return self.value


class CacheEvictionPriority(enum.Enum):
    EVICT_NORMAL = _cute_ir.CacheEvictionPriority.EVICT_NORMAL
    EVICT_FIRST = _cute_ir.CacheEvictionPriority.EVICT_FIRST
    EVICT_LAST = _cute_ir.CacheEvictionPriority.EVICT_LAST
    EVICT_UNCHANGED = _cute_ir.CacheEvictionPriority.EVICT_UNCHANGED
    NO_ALLOCATE = _cute_ir.CacheEvictionPriority.NO_ALLOCATE

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.CacheEvictionPriority:
        return self.value


@dataclass(frozen=True)
class CopyUniversalOp(atom.CopyOp):
    """
    The universal Copy Operation.

    When creating a Copy Atom out of this operation, the expected usage pattern is

    .. code-block:: python

        op = cute.nvgpu.CopyUniversalOp()
        atom = cute.make_copy_atom(
            op,
            tensor_dtype,
            num_bits_per_copy=64,
            l1c_evict_priority=cute.nvgpu.CacheEvictionPriority.EVICT_NORMAL
        )

    - ``tensor_dtype`` is the data type used to build the reference TV Layout (either the source \
        or the destination TV Layout) in unit of tensor elements and is used for partitioning by \
        ``TiledCopy`` for example
    - ``num_bits_per_copy`` is a kw argument specifying the number of bits to copy per Atom \
        execution. This can be larger than the width of the above data type. When not provided, \
        the compiler will do a best effort at auto-vectorizing.
    - ``l1c_evict_priority`` is a kw argument specifying the L1 cache eviction priority hint for \
        the copy operation. Defaults to ``EVICT_NORMAL`` if not provided.
    - ``invariant`` is a kw argument specifying whether the load is invariant (read-only data \
        that never changes). This enables compiler optimizations like instruction reordering. \
        Defaults to ``False`` if not provided.

    """

    def __str__(self) -> str:
        return "universal Copy Operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        num_bits_per_copy: int = 0,
        memory_order: MemoryOrder = MemoryOrder.WEAK,
        memory_scope: MemoryScope = MemoryScope.CTA,
        l1c_evict_priority: CacheEvictionPriority = CacheEvictionPriority.EVICT_NORMAL,
        invariant: bool = False,
        loc=None,
        ip=None,
    ) -> "CopyUniversalTrait":
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )
        atom_type = _cute_nvgpu_ir.CopyAtomSIMTSyncCopyType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
            memory_order._to_ir(),
            memory_scope._to_ir(),
            l1c_evict_priority._to_ir(),
            invariant,
        )
        return CopyUniversalTrait(atom.make_atom(atom_type, loc=loc, ip=ip))


class CopyUniversalTrait(atom.Trait):
    pass
