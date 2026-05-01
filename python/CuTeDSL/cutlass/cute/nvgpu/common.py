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
from dataclasses import dataclass
from typing import Any, Mapping, Optional, Type, Union
import warnings

from cutlass.cutlass_dsl import DSLBaseError, DSLRuntimeError

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir

from .. import atom
from ..typing import Float16, Float32, Float64, Numeric, Tensor, Int64
from abc import ABC, abstractmethod

__all__ = [
    "OperandMajorMode",
    "OutputMajorMode",
    "OpError",
    "normalize_field_to_ir_name",
    "MmaUniversalOp",
    "MmaUniversalTrait",
    "CopyUniversalOp",
    "CopyUniversalTrait",
    "CopyG2ROp",
    "CopyG2RTrait",
    "CopyR2GOp",
    "CopyR2GTrait",
    "CopyS2ROp",
    "CopyS2RTrait",
    "CopyR2SOp",
    "CopyR2STrait",
    "MemoryOrder",
    "MemoryScope",
    "L2PrefetchSize",
    "CacheEvictionPriority",
    "LoadCacheMode",
    "StoreCacheMode",
    "SharedSpace",
]


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


class OutputMajorMode(enum.Enum):
    """Major mode for the output operand D(M, N).

    M = M-major (column-major): stride=(1, M), contiguous along M.
    N = N-major (row-major):    stride=(N, 1), contiguous along N.
    """

    M = "m"
    N = "n"

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"


def normalize_field_to_ir_name(field: Any, admissible_fields: Any) -> str:
    """
    Normalize a field specifier to its IR logical field name.

    Accepted inputs:

    - Enum value present in admissible_fields (must expose _to_ir_field_name()).
    - Exact string IR name (e.g., "accum_c", "neg_a", "sf_a").

    Any other form is rejected.
    """
    # Enum path
    if any(field is f for f in admissible_fields):
        return field._to_ir_field_name()
    # String path (must match exactly one of the IR names exposed by admissible_fields)
    if isinstance(field, str):
        allowed = {f._to_ir_field_name() for f in admissible_fields}
        if field in allowed:
            return field
    # Otherwise, reject
    allowed_pretty = [f._to_ir_field_name() for f in admissible_fields]
    raise ValueError(
        f"invalid field, must be one of {allowed_pretty} or their enum counterparts, but got {field}"
    )


class OpError(DSLBaseError):
    """
    An exception class for Op construction errors.
    """

    def __init__(
        self,
        op: Union[atom.Op, atom.Trait],
        message: str,
        suggestion: Optional[str] = None,
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

    def _make_trait(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "MmaUniversalTrait":
        shape_mnk_attr = ir.Attribute.parse('#cute.shape<"(1,1,1)">')
        atom_ty = _cute_nvgpu_ir.UniversalFmaAtomType.get(
            shape_mnk_attr,
            self.abacc_dtype.mlir_type,
            self.abacc_dtype.mlir_type,
            self.abacc_dtype.mlir_type,
        )
        return MmaUniversalTrait(atom.make_atom(atom_ty, loc=loc, ip=ip))

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


class L2PrefetchSize(enum.Enum):
    NONE = _cute_ir.L2PrefetchSize.NONE
    RESERVED = _cute_ir.L2PrefetchSize.RESERVED
    SIZE_64B = _cute_ir.L2PrefetchSize.SIZE_64B
    SIZE_128B = _cute_ir.L2PrefetchSize.SIZE_128B
    SIZE_256B = _cute_ir.L2PrefetchSize.SIZE_256B

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_ir.L2PrefetchSize:
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


class LoadCacheMode(enum.Enum):
    ALWAYS = _cute_nvgpu_ir.LoadCacheMode.always
    GLOBAL = _cute_nvgpu_ir.LoadCacheMode.global_
    STREAMING = _cute_nvgpu_ir.LoadCacheMode.streaming
    LAST_USE = _cute_nvgpu_ir.LoadCacheMode.last_use
    NONE = _cute_nvgpu_ir.LoadCacheMode.none

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_nvgpu_ir.LoadCacheMode:
        return self.value


class StoreCacheMode(enum.Enum):
    WRITE_BACK = _cute_nvgpu_ir.StoreCacheMode.write_back
    GLOBAL = _cute_nvgpu_ir.StoreCacheMode.global_
    STREAMING = _cute_nvgpu_ir.StoreCacheMode.streaming
    WRITE_THROUGH = _cute_nvgpu_ir.StoreCacheMode.write_through
    NONE = _cute_nvgpu_ir.StoreCacheMode.none

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_nvgpu_ir.StoreCacheMode:
        return self.value


class SharedSpace(enum.Enum):
    CTA = _cute_nvgpu_ir.SharedSpace.CTA
    CLUSTER = _cute_nvgpu_ir.SharedSpace.CLUSTER

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_nvgpu_ir.SharedSpace:
        return self.value


COPY_CACHE_POLICY_FIELD_NAME = "cache_policy"


@dataclass(frozen=True)
class CopyUniversalOp(atom.CopyOp):
    """
    The universal Copy Operation.

    This operation is equivalent to the ``a = b`` assignment without any extra
    memory attributes.  For advanced memory features (memory order, memory scope,
    cache eviction priority, invariant loads, etc.) please use the specialized copy
    operations instead:

    - :class:`CopyG2ROp` -- global memory to register
    - :class:`CopyR2GOp` -- register to global memory
    - :class:`CopyS2ROp` -- shared memory to register
    - :class:`CopyR2SOp` -- register to shared memory

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
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyUniversalTrait":
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )

        # CopyUniversalOp is designed to be a universal copy operation that is
        # equivalent to the "a = b" assignment without any extra attributes.
        # For advanced memory features, such as memory order, please use the
        # specialized copy operations (e.g., CopyG2ROp) or their combinations instead.
        if (
            memory_order != MemoryOrder.WEAK
            or memory_scope != MemoryScope.CTA
            or l1c_evict_priority != CacheEvictionPriority.EVICT_NORMAL
            or invariant
        ):
            warnings.warn(
                "Using CopyUniversalOp with extra attributes is deprecated. Please use specialized copy ops "
                "(e.g., CopyG2ROp) for advanced memory features.",
                DeprecationWarning,
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


@dataclass(frozen=True)
class CopyG2ROp(atom.CopyOp):
    """
    The G2R copy operation.

    When creating a Copy Atom out of this operation, the expected usage pattern is

    .. code-block:: python

        op = cute.nvgpu.CopyG2ROp()
        atom = cute.make_copy_atom(
            op,
            tensor_dtype,
            num_bits_per_copy=64,
            memory_order=cute.nvgpu.MemoryOrder.VOLATILE,
            memory_scope=cute.nvgpu.MemoryScope.SYS,
            l2_prefetch_size=cute.nvgpu.L2PrefetchSize.NONE,
            l1c_evict_priority=cute.nvgpu.CacheEvictionPriority.EVICT_NORMAL,
            load_cache_mode=cute.nvgpu.LoadCacheMode.ALWAYS,
            shared_space=cute.nvgpu.SharedSpace.CTA,
            invariant=False,
        )
    """

    def __str__(self) -> str:
        return "G2R copy operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        num_bits_per_copy: int = 0,
        memory_order: MemoryOrder = MemoryOrder.WEAK,
        memory_scope: MemoryScope = MemoryScope.CTA,
        l2_prefetch_size: L2PrefetchSize = L2PrefetchSize.NONE,
        l1c_evict_priority: CacheEvictionPriority = CacheEvictionPriority.EVICT_NORMAL,
        load_cache_mode: LoadCacheMode = LoadCacheMode.ALWAYS,
        shared_space: SharedSpace = SharedSpace.CTA,
        invariant: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyG2RTrait":
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )
        atom_type = _cute_nvgpu_ir.CopyAtomG2RType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
            memory_order._to_ir(),
            memory_scope._to_ir(),
            l2_prefetch_size._to_ir(),
            l1c_evict_priority._to_ir(),
            load_cache_mode._to_ir(),
            shared_space._to_ir(),
            invariant,
        )
        return CopyG2RTrait(atom.make_atom(atom_type, loc=loc, ip=ip))


class CopyG2RTrait(atom.Trait):
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        if cache_policy is None:
            return self.value
        cache_policy_attr_str = (
            f"#cute_nvgpu.atom_copy_field_g2r<{COPY_CACHE_POLICY_FIELD_NAME}>"
        )
        cache_policy_attr = ir.Attribute.parse(cache_policy_attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value,
            cache_policy_attr,
            cache_policy.ir_value(),
            loc=loc,
            ip=ip,
        )
        return val


@dataclass(frozen=True)
class CopyR2GOp(atom.CopyOp):
    """
    The R2G copy operation.

    When creating a Copy Atom out of this operation, the expected usage pattern is

    .. code-block:: python

        op = cute.nvgpu.CopyR2GOp()
        atom = cute.make_copy_atom(
            op,
            tensor_dtype,
            num_bits_per_copy=64,
            memory_order=cute.nvgpu.MemoryOrder.RELEASE,
            memory_scope=cute.nvgpu.MemoryScope.CLUSTER,
            l1c_evict_priority=cute.nvgpu.CacheEvictionPriority.EVICT_NORMAL,
            shared_space=cute.nvgpu.SharedSpace.CTA,
        )
    """

    def __str__(self) -> str:
        return "R2G copy operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        num_bits_per_copy: int = 0,
        memory_order: MemoryOrder = MemoryOrder.WEAK,
        memory_scope: MemoryScope = MemoryScope.CTA,
        l1c_evict_priority: CacheEvictionPriority = CacheEvictionPriority.EVICT_NORMAL,
        store_cache_mode: StoreCacheMode = StoreCacheMode.WRITE_BACK,
        shared_space: SharedSpace = SharedSpace.CTA,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyR2GTrait":
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )
        atom_type = _cute_nvgpu_ir.CopyAtomR2GType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
            memory_order._to_ir(),
            memory_scope._to_ir(),
            l1c_evict_priority._to_ir(),
            store_cache_mode._to_ir(),
            shared_space._to_ir(),
        )
        return CopyR2GTrait(atom.make_atom(atom_type, loc=loc, ip=ip))


class CopyR2GTrait(atom.Trait):
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        if cache_policy is None:
            return self.value
        cache_policy_attr_str = (
            f"#cute_nvgpu.atom_copy_field_r2g<{COPY_CACHE_POLICY_FIELD_NAME}>"
        )
        cache_policy_attr = ir.Attribute.parse(cache_policy_attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value,
            cache_policy_attr,
            cache_policy.ir_value(),
            loc=loc,
            ip=ip,
        )
        return val


def _reject_unknown_copy_trait_kwargs(op: object, kwargs: Mapping[str, Any]) -> None:
    """Shared-memory load/store traits do not accept global-only keyword fields."""
    if kwargs:
        name = next(iter(kwargs))
        raise TypeError(
            f"{type(op).__name__}._make_trait() got an unexpected keyword argument {name!r}"
        )


@dataclass(frozen=True)
class CopyS2ROp(atom.CopyOp):
    """
    The S2R copy operation.

    When creating a Copy Atom out of this operation, the expected usage pattern is

    .. code-block:: python

        op = cute.nvgpu.CopyS2ROp()
        atom = cute.make_copy_atom(
            op,
            tensor_dtype,
            num_bits_per_copy=64,
            memory_order=cute.nvgpu.MemoryOrder.WEAK,
            memory_scope=cute.nvgpu.MemoryScope.CTA,
            shared_space=cute.nvgpu.SharedSpace.CTA,
        )
    """

    def __str__(self) -> str:
        return "S2R copy operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        num_bits_per_copy: int = 0,
        memory_order: MemoryOrder = MemoryOrder.WEAK,
        memory_scope: MemoryScope = MemoryScope.CTA,
        shared_space: SharedSpace = SharedSpace.CTA,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyS2RTrait":
        _reject_unknown_copy_trait_kwargs(self, kwargs)
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )
        atom_type = _cute_nvgpu_ir.CopyAtomS2RType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
            memory_order._to_ir(),
            memory_scope._to_ir(),
            shared_space._to_ir(),
        )
        return CopyS2RTrait(atom.make_atom(atom_type, loc=loc, ip=ip))


class CopyS2RTrait(atom.Trait):
    pass


@dataclass(frozen=True)
class CopyR2SOp(atom.CopyOp):
    """
    The R2S copy operation.

    When creating a Copy Atom out of this operation, the expected usage pattern is

    .. code-block:: python

        op = cute.nvgpu.CopyR2SOp()
        atom = cute.make_copy_atom(
            op,
            tensor_dtype,
            num_bits_per_copy=64,
            memory_order=cute.nvgpu.MemoryOrder.WEAK,
            memory_scope=cute.nvgpu.MemoryScope.CTA,
            shared_space=cute.nvgpu.SharedSpace.CTA,
        )
    """

    def __str__(self) -> str:
        return "R2S copy operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        num_bits_per_copy: int = 0,
        memory_order: MemoryOrder = MemoryOrder.WEAK,
        memory_scope: MemoryScope = MemoryScope.CTA,
        shared_space: SharedSpace = SharedSpace.CTA,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyR2STrait":
        _reject_unknown_copy_trait_kwargs(self, kwargs)
        if not isinstance(num_bits_per_copy, int) or num_bits_per_copy < 0:
            raise ValueError(
                f"'num_bits_per_copy' must be a non-negative int when creating a copy Atom for {self.__class__.__name__!r}"
            )
        atom_type = _cute_nvgpu_ir.CopyAtomR2SType.get(
            copy_internal_type.mlir_type,
            num_bits_per_copy,
            memory_order._to_ir(),
            memory_scope._to_ir(),
            shared_space._to_ir(),
        )
        return CopyR2STrait(atom.make_atom(atom_type, loc=loc, ip=ip))


class CopyR2STrait(atom.Trait):
    pass


########################################################
# Fragment Base Class
########################################################


class FragmentBase(ABC):
    @abstractmethod
    def make_fragment(
        self,
        tensor: Tensor,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor: ...
