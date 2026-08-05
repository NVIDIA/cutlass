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

"""
NVVM wrapper namespace — hand-maintained wrappers over raw MLIR NVVM dialect ops.

Purpose
-------
This module gives users a single ``nvvm.*`` namespace for all
NVVM-level GPU operations (barriers, TMA copies, tcgen05 tensor-core
ops, PTX special-register reads, etc.) without requiring them to deal
with raw MLIR ceremony.

How ops are exposed
-------------------
There are three categories of entries in this module:

1. **Wrapped ops** (``@dsl_user_op`` functions):
   A wrapper exists when it adds genuine value over the raw MLIR op:

   * *Return-type hiding* — the raw MLIR op requires the caller to
     pass the result type as the first positional argument (e.g.
     ``T.i32()``).  The wrapper inserts it automatically and wraps the
     return value in a typed wrapper (``Int32``, ``Boolean``, ...).
     Examples: ``shfl_sync``.

   * *Python-to-DSL type coercion* — the raw MLIR op expects every
     operand to be an ``ir.Value``.  The wrapper accepts plain Python
     ``int`` / ``bool`` and converts them to the correct DSL type
     (``Int32``, ``Int64``, ``Boolean``, ...) so the proxy can turn them
     into ``ir.Value``.  The proxy alone cannot do this because it does
     not know *which* MLIR type a Python literal should become.
     Because MLIR integers are signless, coerced parameters also accept
     the unsigned counterpart (e.g. ``count: int | Int32 | Uint32``).
     The coercion always uses the signed type internally — ``Int32``
     and ``Uint32`` both produce ``i32``.
     Examples: ``mbarrier_init``, ``tcgen05_alloc``, ``tcgen05_mma``.

   Every wrapper maps 1:1 to a single MLIR NVVM dialect op with the
   same argument order.  Higher-level convenience ops (e.g. computing
   derived parameters or specialising generic ops) belong in the
   higher-level namespace, not here.

2. **Direct aliases** (plain attribute assignments):
   When a raw NVVM op needs no coercion, no return-type hiding, and
   no default parameters, it is re-exported as-is so that it still
   appears in the ``nvvm.*`` namespace.  ``fence_mbarrier_init`` has a
   thin wrapper below for documentation; other fence aliases are bare.

3. **Auto-converting proxy** (``nvvm.dialect``):
   For any NVVM op that is *not* listed in this module at all, the
   proxy can be used directly.  It auto-converts any argument that has
   an ``.ir_value()`` method before forwarding to the raw dialect::

       nvvm.dialect.some_unlisted_nvvm_op(T.i32(), my_int32_value, ...)

   The proxy does **not** handle ``int -> Int32`` coercion (it cannot
   guess the target MLIR type), so callers must wrap Python literals
   themselves when using it.
"""

import inspect
import sys
from typing import TYPE_CHECKING, Any, Callable, TypeAlias

# ``enum.StrEnum`` landed in Python 3.11; use the no-op ``backports``
# shim on 3.10 (declared as a conditional dependency in pyproject.toml).
if TYPE_CHECKING:
    # typeshed gates ``enum.StrEnum`` to 3.11+ and ``backports.strenum`` ships
    # no stubs, so under ``--python-version 3.10`` mypy would otherwise see
    # ``StrEnum`` as ``Any`` and type every member as a bare ``str`` — breaking
    # enum-typed parameters and ``.name`` access. Model it as the str-mixin
    # enum it is.
    from enum import Enum

    class StrEnum(str, Enum):
        pass

elif sys.version_info >= (3, 11):
    from enum import StrEnum
else:
    from backports.strenum import StrEnum

import cutlass.base_dsl.typing as _cutlass
from cutlass import Pointer, dsl_user_op
from cutlass.base_dsl.version_info import CUDA_VERSION
from cutlass.cutlass_dsl import T
from cutlass.cute.testing import assert_ as _runtime_assert
from cutlass._mlir import ir
from cutlass._mlir.dialects import arith as _arith
from cutlass._mlir.dialects import llvm as _llvm
from cutlass._mlir.dialects import nvvm as _nvvm_raw
from cutlass._mlir_helpers.dialect_proxy import DialectAutoConvertProxy

# These ops also exist in ``cutlass.cute.arch`` with a signature-compatible
# API, so re-export them from there instead of redefining them here.
# ``red`` and ``fence_proxy`` are intentionally NOT re-exported: the
# ``cute.arch`` versions take string-literal kinds / a different argument
# order
from cutlass.cute.arch import (  # noqa: F401
    barrier,
    inline_ptx as _cute_inline_ptx,
    cp_async_commit_group,
    cp_async_wait_group,
    cp_async_bulk_commit_group,
    cp_async_bulk_wait_group,
)

from cutlass.base_dsl.typing import (
    Boolean,
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E4M3,
    Float8E4M3B11FNUZ,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Float16,
    BFloat16,
    Float32,
    Float64,
    Int8,
    Int16,
    Int32,
    Int64,
    Int128,
    Numeric,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Uint128,
)
from cutlass.base_dsl.typing import Array, Vector

# Wrapper-owned StrEnums shared with typed-memref / atomics API.
from cutlass.base_dsl.array import (
    EvictPriority,
    L1EvictKind,
    L2PrefetchSize,
    LoadCacheModifier,
    MemScope,
    StoreCacheModifier,
)
from cutlass import AddressSpace as _AddressSpace

# Re-export NVVM enums so users can pass them to wrappers / aliases.
from cutlass._mlir.dialects.nvvm import (
    AtomicOpKind as _AtomicOpKindDialect,
    BarrierReduction,
    BarrierReduxKind as _BarrierReduxKindDialect,
    BlockScaleFormat,
    CTAGroupKind as _CTAGroupKindDialect,
    CVTPackFloatKind as _CVTPackFloatKindDialect,
    CacheEvictionPriority as _CacheEvictionPriorityDialect,
    ClusterLaunchControlQueryType as _ClusterLaunchControlQueryTypeDialect,
    ConvertFP4Type,
    DotAccumulateType as _DotAccumulateTypeDialect,
    EvictKind as _EvictKindDialect,
    FPRoundingMode as _FPRoundingModeDialect,
    GridDepActionKind as _GridDepActionKindDialect,
    IntegerRoundingMode as _IntegerRoundingModeDialect,
    L2PrefetchSize as _L2PrefetchSizeDialect,
    LdStMatrixEltType,
    LoadCacheModifierExtKind as _LoadCacheModifierExtKindDialect,
    LoadCacheModifierKind as _LoadCacheModifierKindDialect,
    LoadShape as _LoadShapeDialect,
    LoadSrcFormat as _LoadSrcFormatDialect,
    MBarrierScopeKind as _MBarrierScopeKindDialect,
    MBarrierWaitKind as _MBarrierWaitKindDialect,
    MMAB1Op as _MMAB1OpDialect,
    MMABlockScaleKind,
    MMACtaCount,
    MMAFrag as _MMAFragDialect,
    MMAIntOverflow as _MMAIntOverflowDialect,
    MMAKind as _MMAKindDialect,
    MMALayout as _MMALayoutDialect,
    MMATypes as _MMATypesDialect,
    MatchSyncKind as _MatchSyncKindDialect,
    MemOrderKind as _MemOrderKindDialect,
    MemScopeKind as _MemScopeKindDialect,
    MulMode as _MulModeDialect,
    NVVMMemorySpace,
    PermuteMode as _PermuteModeDialect,
    PrefetchCacheLevel as _PrefetchCacheLevelDialect,
    ProxyKind as _ProxyKindDialect,
    ReductionKind,
    ReductionOp as _ReductionOpDialect,
    ReductionType as _ReductionTypeDialect,
    SaturationMode as _SaturationModeDialect,
    SaturationModeKind as _SaturationModeKindDialect,
    ScaleVecSize,
    SetMaxRegisterAction as _SetMaxRegisterActionDialect,
    SharedSpace,
    ShflKind as _ShflKindDialect,
    SparsityFormat,
    StateSpace,
    StoreCacheModifierKind as _StoreCacheModifierKindDialect,
    StoreShape as _StoreShapeDialect,
    TCBarParam,
    TMALoadMode as _TMALoadModeDialect,
    TMAReduxKind as _TMAReduxKindDialect,
    TMAStoreMode as _TMAStoreModeDialect,
    Tcgen05CpMulticast as _Tcgen05CpMulticastDialect,
    Tcgen05CpShape as _Tcgen05CpShapeDialect,
    Tcgen05CpSrcFormat as _Tcgen05CpSrcFormatDialect,
    Tcgen05FenceKind as _Tcgen05FenceKindDialect,
    Tcgen05LdStShape as _Tcgen05LdStShape,
    Tcgen05MMACollectorBBuffer as _Tcgen05MMACollectorBBufferDialect,
    Tcgen05MMACollectorOp as _Tcgen05MMACollectorOpDialect,
    Tcgen05MMAKind as _Tcgen05MMAKindDialect,
    Tcgen05WaitKind as _Tcgen05WaitKindDialect,
    TensormapField as _TensormapFieldDialect,
    TmemLayout,
    VoteSyncKind as _VoteSyncKindDialect,
    WGMMAScaleIn as _WGMMAScaleInDialect,
    WGMMAScaleOut as _WGMMAScaleOutDialect,
    WGMMATypes as _WGMMATypesDialect,
)


_Tcgen05MMABlockScaleDialect = getattr(_nvvm_raw, "Tcgen05MMABlockScale", None)
if _Tcgen05MMABlockScaleDialect is not None:
    if not hasattr(_Tcgen05MMABlockScaleDialect, "DEFAULT") and hasattr(
        _Tcgen05MMABlockScaleDialect, "Default"
    ):
        _Tcgen05MMABlockScaleDialect.DEFAULT = (  # type: ignore[attr-defined]
            _Tcgen05MMABlockScaleDialect.Default
        )
    Tcgen05MMABlockScale = _Tcgen05MMABlockScaleDialect
else:

    class Tcgen05MMABlockScale(StrEnum):
        """Fallback tcgen05 block-scale selector for older generated bindings."""

        DEFAULT = "default"
        Default = "default"
        BLOCK16 = "block16"
        BLOCK32 = "block32"


class Tcgen05MMAScaleVecSize:
    """Compatibility namespace for tcgen05 block-scale selectors.

    Older call sites spell the selector as ``Tcgen05MMAScaleVecSize`` while
    newer NVVM bindings split 1X/2X/4X and block16/block32 into separate
    enums.  Keep both spellings available at the wrapper boundary.
    """

    X1 = ScaleVecSize.X1
    X2 = ScaleVecSize.X2
    X4 = ScaleVecSize.X4
    DEFAULT = Tcgen05MMABlockScale.DEFAULT
    Default = Tcgen05MMABlockScale.DEFAULT
    BLOCK16 = Tcgen05MMABlockScale.BLOCK16
    BLOCK32 = Tcgen05MMABlockScale.BLOCK32


if not hasattr(_Tcgen05MMAKindDialect, "I8") and hasattr(
    _Tcgen05MMAKindDialect, "INT8"
):
    _Tcgen05MMAKindDialect.I8 = _Tcgen05MMAKindDialect.INT8  # type: ignore[attr-defined]

# =============================================================================
# Wrapper-owned types (decoupled from the underlying MLIR NVVM dialect enums)
# =============================================================================
#
# The public wrapper surface uses ``StrEnum`` classes for these parameter
# types rather than the raw MLIR enums.  Members ARE strings (via
# ``StrEnum``'s ``str`` inheritance), so callers can equivalently pass
# ``MemScope.CTA`` or ``"cta"``.  The mapping dicts below are keyed on
# the bare string and work for both forms.


#: Allowed values for the ``kind`` parameter of :func:`barrier_cta_red` and
#: :func:`barrier_cta_red_aligned`.  Lowercase to match the PTX modifier
#: (``bar.red.{and,or,popc}``).
class BarrierRedux(StrEnum):
    AND = "and"
    OR = "or"
    POPC = "popc"


_BARRIER_REDUX_TO_DIALECT = {
    "and": _BarrierReduxKindDialect.AND,
    "or": _BarrierReduxKindDialect.OR,
    "popc": _BarrierReduxKindDialect.POPC,
}


#: Mapping for the ``evict_priority`` / ``evict`` parameters of TMA copy
#: and prefetch ops.  Uses the :class:`EvictPriority` StrEnum imported
#: from ``cutlass.base_dsl.array`` so the same enum is shared with the
#: typed-memref copy primitives.  Members are the bare PTX modifiers
#: (``"first"``, ``"last"``, ``"normal"``, ...) with the ``evict_``
#: prefix dropped.
def _cache_eviction_priority_to_dialect() -> dict[str, Any]:
    mapping = {
        "first": _CacheEvictionPriorityDialect.EvictFirst,
        "last": _CacheEvictionPriorityDialect.EvictLast,
        "normal": _CacheEvictionPriorityDialect.EvictNormal,
        "unchanged": _CacheEvictionPriorityDialect.EvictUnchanged,
        "noallocate": _CacheEvictionPriorityDialect.NoAllocate,
    }
    for value, attr in (
        ("normal_demote", "EvictNormalDemote"),
        ("normal_near", "EvictNormalNear"),
        ("first_near", "EvictFirstNear"),
        ("last_near", "EvictLastNear"),
        ("normal_demote_near", "EvictNormalDemoteNear"),
    ):
        member = getattr(_CacheEvictionPriorityDialect, attr, None)
        if member is not None:
            mapping[value] = member
    return mapping


_EVICT_PRIORITY_TO_DIALECT = _cache_eviction_priority_to_dialect()


#: Eviction priorities the ``prefetch`` instruction accepts.  Unlike
#: ``ld`` / ``st`` / ``cp`` (which use the full :class:`EvictPriority` set),
#: PTX ``prefetch`` defines only
#: ``.level::eviction_priority = {.L2::evict_last, .L2::evict_normal}`` and the
#: NVVM ``prefetch`` op verifier rejects every other member.  Kept as a strict
#: subset so :func:`prefetch_l2` fails fast at trace time instead of deferring
#: to the dialect verifier (or, worse, ptxas).
_PREFETCH_EVICT_PRIORITIES = frozenset({"normal", "last"})


def _assert_prefetch_evict_priority(
    evict_priority: EvictPriority | None, instruction: str
) -> None:
    """Reject eviction priorities the ``prefetch`` instruction does not support.

    ``prefetch`` accepts only ``"normal"`` and ``"last"`` (and only on an L2
    ``.global`` address); the remaining :class:`EvictPriority` members are valid
    on ``ld`` / ``st`` / ``cp`` but not ``prefetch``.  ``None`` leaves the
    default policy and passes through unchecked.

    The membership test is against the ``StrEnum`` string values, so it
    accepts ``EvictPriority.LAST`` / ``"last"`` but rejects a raw NVVM dialect
    enum (``_CacheEvictionPriorityDialect.EvictLast``).  That rejection is
    intentional: the public ``nvvm`` surface takes only the wrapper-owned
    ``StrEnum`` twins, never the raw dialect enums (the StrEnum migration that
    removes the dialect-enum passthrough shim from ``_to_dialect``).
    """
    if evict_priority is not None and evict_priority not in _PREFETCH_EVICT_PRIORITIES:
        raise ValueError(
            f"{instruction}: evict_priority must be 'normal' or 'last', "
            f"got {evict_priority!r}"
        )


#: Cache levels (``L1`` / ``L2``) for prefetch cache-level selection.
#: Lowercase members match the PTX ``.level`` modifier.  The ``nvvm``
#: data-prefetch path splits L1/L2 into :func:`prefetch_l1` / :func:`prefetch_l2`,
#: but the enum is still part of the public surface: the PTX layer
#: aliases it as ``PrefetchCacheLevel`` for the unified ``ptx.prefetch`` op.
class CacheLevel(StrEnum):
    L1 = "l1"
    L2 = "l2"


#: Allowed values for the ``space`` parameter of :func:`prefetch_tensormap`.
#: Mirrors the PTX ``.tensormap_space = {.const, .param}`` modifier
#:.  Modelled as a ``StrEnum`` rather than a bool so
#: the API stays extensible if PTX ever adds a third tensormap address
#: space.
class TensormapSpace(StrEnum):
    CONST = "const"
    PARAM = "param"


_TENSORMAP_SPACE_TO_IN_PARAM = {
    "const": False,
    "param": True,
}


# =============================================================================
# StrEnum + dialect-enum mappings for NVVM enums migrated from the raw
# dialect API.  Each block translates the wrapper-facing string (StrEnum
# member or bare string) to its corresponding MLIR NVVM dialect enum at
# the wrapper boundary, so callers never see raw MLIR enums.
# =============================================================================

#: Allowed values for the ``scope`` parameter of memory-ordering ops.
#: Re-exports the :class:`MemScope` StrEnum from
#: ``cutlass.base_dsl.array`` so the memory-model API is uniform with
#: typed-memref and atomics code paths.
_MEMSCOPE_TO_DIALECT = {
    "cta": _MemScopeKindDialect.CTA,
    "cluster": _MemScopeKindDialect.CLUSTER,
    "gpu": _MemScopeKindDialect.GPU,
    "sys": _MemScopeKindDialect.SYS,
}

#: Allowed values for the load-cache-modifier parameter (PTX
#: ``ld.<modifier>``).  Re-exports :class:`LoadCacheModifier` from
#: ``cutlass.base_dsl.array``.  Used by wrappers typed against both
#: ``LoadCacheModifierKind`` and ``LoadCacheModifierExtKind`` — the
#: latter's ``NONE`` sentinel is dropped; callers pass ``None``.
_LOAD_CACHE_MODIFIER_TO_DIALECT = {
    "ca": _LoadCacheModifierKindDialect.CA,
    "cg": _LoadCacheModifierKindDialect.CG,
    "cs": _LoadCacheModifierKindDialect.CS,
    "lu": _LoadCacheModifierKindDialect.LU,
    "cv": _LoadCacheModifierKindDialect.CV,
}

_LOAD_CACHE_MODIFIER_EXT_TO_DIALECT = {
    "ca": _LoadCacheModifierExtKindDialect.CA,
    "cg": _LoadCacheModifierExtKindDialect.CG,
    "cs": _LoadCacheModifierExtKindDialect.CS,
    "lu": _LoadCacheModifierExtKindDialect.LU,
    "cv": _LoadCacheModifierExtKindDialect.CV,
}

#: Allowed values for the store-cache-modifier parameter (PTX
#: ``st.<modifier>``).  Re-exports :class:`StoreCacheModifier` from
#: ``cutlass.base_dsl.array``.  Dialect's ``NONE`` is dropped; callers
#: pass ``None``.
_STORE_CACHE_MODIFIER_TO_DIALECT = {
    "wb": _StoreCacheModifierKindDialect.WB,
    "cg": _StoreCacheModifierKindDialect.CG,
    "cs": _StoreCacheModifierKindDialect.CS,
    "wt": _StoreCacheModifierKindDialect.WT,
}

#: Allowed values for the L1 cache eviction kind.  Re-exports
#: :class:`L1EvictKind` from ``cutlass.base_dsl.array`` — the 5-member
#: subset of :class:`EvictPriority` valid on L1 (the L2 path adds 5
#: more Hopper ``*_demote`` / ``*_near`` variants).  Dialect's ``NONE``
#: is dropped; callers pass ``None``.
_L1_EVICT_KIND_TO_DIALECT = {
    "normal": _EvictKindDialect.NORMAL,
    "first": _EvictKindDialect.FIRST,
    "last": _EvictKindDialect.LAST,
    "noallocate": _EvictKindDialect.NOALLOCATE,
    "unchanged": _EvictKindDialect.UNCHANGED,
}

#: Mapping for the L2 prefetch size (PTX ``L2::<n>B``).  Uses the
#: :class:`L2PrefetchSize` StrEnum imported from ``cutlass.base_dsl.array``.
_L2_PREFETCH_SIZE_TO_DIALECT = {
    "size_64b": _L2PrefetchSizeDialect.SIZE_64B,
    "size_128b": _L2PrefetchSizeDialect.SIZE_128B,
    "size_256b": _L2PrefetchSizeDialect.SIZE_256B,
}


#: Allowed values for the ``mem_order`` / ``order`` parameter of atomic
#: and load/store ops.  Defined locally (NOT the same as
#: :class:`cutlass.base_dsl.array.MemOrdering`, which is keyed on LLVM
#: AtomicOrdering and has a different member set).  Matches PTX
#: ``.<order>`` modifiers exactly.
class MemOrder(StrEnum):
    WEAK = "weak"
    RELAXED = "relaxed"
    ACQUIRE = "acquire"
    RELEASE = "release"
    ACQ_REL = "acq_rel"
    SC = "sc"
    MMIO = "mmio"
    VOLATILE = "volatile"
    CONSTANT = "constant"


_MEMORDER_TO_DIALECT = {
    "weak": _MemOrderKindDialect.WEAK,
    "relaxed": _MemOrderKindDialect.RELAXED,
    "acquire": _MemOrderKindDialect.ACQUIRE,
    "release": _MemOrderKindDialect.RELEASE,
    "acq_rel": _MemOrderKindDialect.ACQ_REL,
    "sc": _MemOrderKindDialect.SC,
    "mmio": _MemOrderKindDialect.MMIO,
    "volatile": _MemOrderKindDialect.VOLATILE,
    "constant": _MemOrderKindDialect.CONSTANT,
}




#: ``mbarrier`` scope (PTX ``.cta`` / ``.cluster``).
class MBarrierScope(StrEnum):
    CTA = "cta"
    CLUSTER = "cluster"


_MBARRIER_SCOPE_TO_DIALECT = {
    "cta": _MBarrierScopeKindDialect.CTA,
    "cluster": _MBarrierScopeKindDialect.CLUSTER,
}


#: ``mbarrier`` wait variant.
class MBarrierWait(StrEnum):
    TEST = "test"
    TRY = "try"


_MBARRIER_WAIT_TO_DIALECT = {
    "test": _MBarrierWaitKindDialect.TEST,
    "try": _MBarrierWaitKindDialect.TRY,
}


#: ``mma`` operand fragment role.
#: ``mma`` single-bit (``.b1``) bit-op selector for ``.bitOp.popc``.
#: ``XOR_POPC`` / ``AND_POPC`` map to the ``.xor`` / ``.and`` PTX
#: modifiers; ``NONE`` is the dialect's "unset" sentinel for non-``b1``
#: multiplicand types.
class MMAB1Op(StrEnum):
    NONE = "none"
    XOR_POPC = "xor_popc"
    AND_POPC = "and_popc"


_MMA_B1OP_TO_DIALECT = {
    "none": _MMAB1OpDialect.none,
    "xor_popc": _MMAB1OpDialect.xor_popc,
    "and_popc": _MMAB1OpDialect.and_popc,
}


class MMAFrag(StrEnum):
    A = "a"
    B = "b"
    C = "c"


_MMA_FRAG_TO_DIALECT = {
    "a": _MMAFragDialect.a,
    "b": _MMAFragDialect.b,
    "c": _MMAFragDialect.c,
}


#: ``mma`` integer overflow behavior.
class MMAIntOverflow(StrEnum):
    SATFINITE = "satfinite"
    WRAPPED = "wrapped"


_MMA_INT_OVERFLOW_TO_DIALECT = {
    "satfinite": _MMAIntOverflowDialect.satfinite,
    "wrapped": _MMAIntOverflowDialect.wrapped,
}


#: ``mma`` kind selector.  "Kind" suffix kept — bare ``MMA`` is too
#: generic, and ``MMAKind`` is the natural name for the parameter.
class MMAKind(StrEnum):
    F8F6F4 = "f8f6f4"


_MMA_KIND_TO_DIALECT = {
    "f8f6f4": _MMAKindDialect.f8f6f4,
}


#: ``mma`` operand layout.
class MMALayout(StrEnum):
    ROW = "row"
    COL = "col"


_MMA_LAYOUT_TO_DIALECT = {
    "row": _MMALayoutDialect.row,
    "col": _MMALayoutDialect.col,
}


#: ``mma`` element type (singular, vs. the dialect's ``MMATypes``).
class MMAType(StrEnum):
    F16 = "f16"
    F32 = "f32"
    TF32 = "tf32"
    BF16 = "bf16"
    S8 = "s8"
    U8 = "u8"
    S32 = "s32"
    S4 = "s4"
    U4 = "u4"
    B1 = "b1"
    F64 = "f64"
    E4M3 = "e4m3"
    E5M2 = "e5m2"
    E3M2 = "e3m2"
    E2M3 = "e2m3"
    E2M1 = "e2m1"

_MMA_TYPE_TO_DIALECT = {
    "f16": _MMATypesDialect.f16,
    "f32": _MMATypesDialect.f32,
    "tf32": _MMATypesDialect.tf32,
    "bf16": _MMATypesDialect.bf16,
    "s8": _MMATypesDialect.s8,
    "u8": _MMATypesDialect.u8,
    "s32": _MMATypesDialect.s32,
    "s4": _MMATypesDialect.s4,
    "u4": _MMATypesDialect.u4,
    "b1": _MMATypesDialect.b1,
    "f64": _MMATypesDialect.f64,
    "e4m3": _MMATypesDialect.e4m3,
    "e5m2": _MMATypesDialect.e5m2,
    "e3m2": _MMATypesDialect.e3m2,
    "e2m3": _MMATypesDialect.e2m3,
    "e2m1": _MMATypesDialect.e2m1,
}


#: ``wgmma`` scale-A / scale-B selector.
class WGMMAScaleIn(StrEnum):
    ONE = "one"
    NEG = "neg"


_WGMMA_SCALE_IN_TO_DIALECT = {
    "one": _WGMMAScaleInDialect.one,
    "neg": _WGMMAScaleInDialect.neg,
}


#: ``wgmma`` scale-D selector.
class WGMMAScaleOut(StrEnum):
    ZERO = "zero"
    ONE = "one"


_WGMMA_SCALE_OUT_TO_DIALECT = {
    "zero": _WGMMAScaleOutDialect.zero,
    "one": _WGMMAScaleOutDialect.one,
}


#: ``wgmma`` element type (singular, vs. dialect's ``WGMMATypes``).
class WGMMAType(StrEnum):
    F16 = "f16"
    TF32 = "tf32"
    U8 = "u8"
    S8 = "s8"
    B1 = "b1"
    BF16 = "bf16"
    E4M3 = "e4m3"
    E5M2 = "e5m2"
    F32 = "f32"
    S32 = "s32"


_WGMMA_TYPE_TO_DIALECT = {
    "f16": _WGMMATypesDialect.f16,
    "tf32": _WGMMATypesDialect.tf32,
    "u8": _WGMMATypesDialect.u8,
    "s8": _WGMMATypesDialect.s8,
    "b1": _WGMMATypesDialect.b1,
    "bf16": _WGMMATypesDialect.bf16,
    "e4m3": _WGMMATypesDialect.e4m3,
    "e5m2": _WGMMATypesDialect.e5m2,
    "f32": _WGMMATypesDialect.f32,
    "s32": _WGMMATypesDialect.s32,
}


#: ``tcgen05.cp`` multicast pattern.
class Tcgen05CpMulticast(StrEnum):
    WARPX2_02_13 = "warpx2_02_13"
    WARPX2_01_23 = "warpx2_01_23"
    WARPX4 = "warpx4"


_TCGEN05_CP_MULTICAST_TO_DIALECT = {
    "warpx2_02_13": _Tcgen05CpMulticastDialect.WARPX2_02_13,
    "warpx2_01_23": _Tcgen05CpMulticastDialect.WARPX2_01_23,
    "warpx4": _Tcgen05CpMulticastDialect.WARPX4,
}


#: ``tcgen05.cp`` shape selector.
class Tcgen05CpShape(StrEnum):
    SHAPE_128X256B = "shape_128x256b"
    SHAPE_4X256B = "shape_4x256b"
    SHAPE_128X128B = "shape_128x128b"
    SHAPE_64X128B = "shape_64x128b"
    SHAPE_32X128B = "shape_32x128b"


_TCGEN05_CP_SHAPE_TO_DIALECT = {
    "shape_128x256b": _Tcgen05CpShapeDialect.SHAPE_128x256b,
    "shape_4x256b": _Tcgen05CpShapeDialect.SHAPE_4x256b,
    "shape_128x128b": _Tcgen05CpShapeDialect.SHAPE_128x128b,
    "shape_64x128b": _Tcgen05CpShapeDialect.SHAPE_64x128b,
    "shape_32x128b": _Tcgen05CpShapeDialect.SHAPE_32x128b,
}


#: ``tcgen05.cp`` source narrow-float packing.
class Tcgen05CpSrcFormat(StrEnum):
    B6X16_P32 = "b6x16_p32"
    B4X16_P64 = "b4x16_p64"


_TCGEN05_CP_SRC_FORMAT_TO_DIALECT = {
    "b6x16_p32": _Tcgen05CpSrcFormatDialect.B6x16_P32,
    "b4x16_p64": _Tcgen05CpSrcFormatDialect.B4x16_P64,
}


#: ``tcgen05.fence`` phase.
class Tcgen05Fence(StrEnum):
    BEFORE_THREAD_SYNC = "before_thread_sync"
    AFTER_THREAD_SYNC = "after_thread_sync"


_TCGEN05_FENCE_TO_DIALECT = {
    "before_thread_sync": _Tcgen05FenceKindDialect.BEFORE_THREAD_SYNC,
    "after_thread_sync": _Tcgen05FenceKindDialect.AFTER_THREAD_SYNC,
    "before": _Tcgen05FenceKindDialect.BEFORE_THREAD_SYNC,
    "after": _Tcgen05FenceKindDialect.AFTER_THREAD_SYNC,
}


#: ``tcgen05.mma`` collector-B buffer selector.
class Tcgen05MMACollectorBBuffer(StrEnum):
    B0 = "b0"
    B1 = "b1"
    B2 = "b2"
    B3 = "b3"


_TCGEN05_MMA_COLLECTOR_B_BUFFER_TO_DIALECT = {
    "b0": _Tcgen05MMACollectorBBufferDialect.B0,
    "b1": _Tcgen05MMACollectorBBufferDialect.B1,
    "b2": _Tcgen05MMACollectorBBufferDialect.B2,
    "b3": _Tcgen05MMACollectorBBufferDialect.B3,
}


#: ``tcgen05.mma`` collector op.
class Tcgen05MMACollectorOp(StrEnum):
    DISCARD = "discard"
    LASTUSE = "lastuse"
    FILL = "fill"
    USE = "use"


_TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT = {
    "discard": _Tcgen05MMACollectorOpDialect.DISCARD,
    "lastuse": _Tcgen05MMACollectorOpDialect.LASTUSE,
    "fill": _Tcgen05MMACollectorOpDialect.FILL,
    "use": _Tcgen05MMACollectorOpDialect.USE,
}


#: ``tcgen05.mma`` kind.  "Kind" suffix kept to disambiguate from
#: ``tcgen05.mma``'s many parameter names.
class Tcgen05MMAKind(StrEnum):
    MXF4NVF4 = "mxf4nvf4"
    F8F6F4 = "f8f6f4"
    MXF8F6F4 = "mxf8f6f4"
    INT8 = "int8"
    # ``I8`` is the historical spelling (the NVVM dialect renamed it to
    # ``INT8``); kept as a StrEnum alias so callers/tests using the older
    # name continue to work.
    I8 = "int8"
    F16 = "f16"
    TF32 = "tf32"
    MXF4 = "mxf4"

_TCGEN05_MMA_KIND_TO_DIALECT = {
    "mxf4nvf4": _Tcgen05MMAKindDialect.MXF4NVF4,
    "f8f6f4": _Tcgen05MMAKindDialect.F8F6F4,
    "mxf8f6f4": _Tcgen05MMAKindDialect.MXF8F6F4,
    # ``I8`` was renamed to ``INT8`` in a newer NVVM dialect revision; accept
    # either spelling so this works against the in-tree CI build and newer
    # locally-built dialects.
    "int8": getattr(_Tcgen05MMAKindDialect, "INT8", None) or _Tcgen05MMAKindDialect.I8,
    "f16": _Tcgen05MMAKindDialect.F16,
    "tf32": _Tcgen05MMAKindDialect.TF32,
    "mxf4": _Tcgen05MMAKindDialect.MXF4,
}


#: ``tcgen05.wait`` direction.
class Tcgen05Wait(StrEnum):
    LOAD = "load"
    STORE = "store"


_TCGEN05_WAIT_TO_DIALECT = {
    "load": _Tcgen05WaitKindDialect.LOAD,
    "store": _Tcgen05WaitKindDialect.STORE,
}

# ---- Miscellaneous Tier-B10 literals ----


#: ``cvt.pack`` source/destination float format selector.
class CVTPackFloat(StrEnum):
    F32 = "f32"
    F16X2 = "f16x2"
    E4M3X2 = "e4m3x2"
    E5M2X2 = "e5m2x2"
    BF16X2 = "bf16x2"
    E2M1X2 = "e2m1x2"
    E2M3X2 = "e2m3x2"
    E3M2X2 = "e3m2x2"
    UE8M0X2 = "ue8m0x2"

_CVT_PACK_FLOAT_TO_DIALECT = {
    "f32": _CVTPackFloatKindDialect.F32,
    "f16x2": _CVTPackFloatKindDialect.F16x2,
    "e4m3x2": _CVTPackFloatKindDialect.E4M3x2,
    "e5m2x2": _CVTPackFloatKindDialect.E5M2x2,
    "bf16x2": _CVTPackFloatKindDialect.BF16x2,
    "e2m1x2": _CVTPackFloatKindDialect.E2M1x2,
    "e2m3x2": _CVTPackFloatKindDialect.E2M3x2,
    "e3m2x2": _CVTPackFloatKindDialect.E3M2x2,
    "ue8m0x2": _CVTPackFloatKindDialect.UE8M0x2,
}


#: ``clusterlaunchcontrol.query`` query-type selector.  "Type" suffix
#: kept (bare ``ClusterLaunchControlQuery`` collides with the op name).
class ClusterLaunchControlQueryType(StrEnum):
    IS_CANCELED = "is_canceled"
    GET_FIRST_CTA_ID_X = "get_first_cta_id_x"
    GET_FIRST_CTA_ID_Y = "get_first_cta_id_y"
    GET_FIRST_CTA_ID_Z = "get_first_cta_id_z"


_CLUSTERLAUNCHCONTROLQUERYTYPE_TO_DIALECT = {
    "is_canceled": _ClusterLaunchControlQueryTypeDialect.IS_CANCELED,
    "get_first_cta_id_x": _ClusterLaunchControlQueryTypeDialect.GET_FIRST_CTA_ID_X,
    "get_first_cta_id_y": _ClusterLaunchControlQueryTypeDialect.GET_FIRST_CTA_ID_Y,
    "get_first_cta_id_z": _ClusterLaunchControlQueryTypeDialect.GET_FIRST_CTA_ID_Z,
}


#: Narrow-float ``cvt`` scale selector.
class ConvertScale(StrEnum):
    UE8M0 = "ue8m0"


def _convert_scale_to_dialect(value: ConvertScale | None) -> Any:
    if value is None:
        return None
    scale_kind = getattr(_nvvm_raw, "ConvertScaleKind", None) or getattr(
        _nvvm_raw, "ConvertScale", None
    )
    if scale_kind is None:
        raise ValueError(
            "scale_factor_kind requires a CUDA NVVM dialect with ConvertScale support"
        )
    return _to_dialect(value, {"ue8m0": scale_kind.UE8M0})


#: Dot-product integer accumulate signedness.  "Type" suffix kept.
class DotAccumulateType(StrEnum):
    SIGNED = "signed"
    UNSIGNED = "unsigned"


_DOT_ACCUMULATE_TYPE_TO_DIALECT = {
    "signed": _DotAccumulateTypeDialect.SIGNED,
    "unsigned": _DotAccumulateTypeDialect.UNSIGNED,
}


#: Floating-point rounding mode.  Dialect's ``NONE`` is dropped;
#: callers pass Python ``None``.
class FPRoundingMode(StrEnum):
    RN = "rn"
    RM = "rm"
    RP = "rp"
    RZ = "rz"
    RNA = "rna"
    RS = "rs"


_FP_ROUNDING_MODE_TO_DIALECT = {
    "rn": _FPRoundingModeDialect.RN,
    "rm": _FPRoundingModeDialect.RM,
    "rp": _FPRoundingModeDialect.RP,
    "rz": _FPRoundingModeDialect.RZ,
    "rna": _FPRoundingModeDialect.RNA,
    "rs": _FPRoundingModeDialect.RS,
}


#: ``griddepcontrol`` action.
class GridDepAction(StrEnum):
    WAIT = "wait"
    LAUNCH_DEPENDENTS = "launch_dependents"


_GRID_DEP_ACTION_TO_DIALECT = {
    "wait": _GridDepActionKindDialect.wait,
    "launch_dependents": _GridDepActionKindDialect.launch_dependents,
}


#: Integer rounding mode.  Dialect's ``NONE`` is dropped; callers pass
#: Python ``None``.
class IntRoundingMode(StrEnum):
    RNI = "rni"
    RZI = "rzi"
    RMI = "rmi"
    RPI = "rpi"


_INT_ROUNDING_MODE_TO_DIALECT = {
    "rni": _IntegerRoundingModeDialect.RNI,
    "rzi": _IntegerRoundingModeDialect.RZI,
    "rmi": _IntegerRoundingModeDialect.RMI,
    "rpi": _IntegerRoundingModeDialect.RPI,
}


#: ``ldmatrix`` shape selector.
class LoadShape(StrEnum):
    M8N8 = "m8n8"
    M8N16 = "m8n16"
    M16N16 = "m16n16"


_LOAD_SHAPE_TO_DIALECT = {
    "m8n8": _LoadShapeDialect.M8N8,
    "m8n16": _LoadShapeDialect.M8N16,
    "m16n16": _LoadShapeDialect.M16N16,
}


#: ``ldmatrix`` narrow-float source packing.
class LoadSrcFormat(StrEnum):
    B6X16_P32 = "b6x16_p32"
    B4X16_P64 = "b4x16_p64"
    B8 = "b8"


_LOAD_SRC_FORMAT_TO_DIALECT = {
    "b6x16_p32": _LoadSrcFormatDialect.B6x16_P32,
    "b4x16_p64": _LoadSrcFormatDialect.B4x16_P64,
    "b8": _LoadSrcFormatDialect.B8,
}


#: ``match.sync`` mode.
class MatchSync(StrEnum):
    ANY = "any"
    ALL = "all"


_MATCH_SYNC_TO_DIALECT = {
    "any": _MatchSyncKindDialect.any,
    "all": _MatchSyncKindDialect.all,
}


#: ``mul.{hi,lo,wide}`` mode.
class MulMode(StrEnum):
    HI = "hi"
    LO = "lo"
    WIDE = "wide"


_MUL_MODE_TO_DIALECT = {
    "hi": _MulModeDialect.HI,
    "lo": _MulModeDialect.LO,
    "wide": _MulModeDialect.WIDE,
}


#: ``prmt`` permute mode.
class PermuteMode(StrEnum):
    DEFAULT = "default"
    F4E = "f4e"
    B4E = "b4e"
    RC8 = "rc8"
    ECL = "ecl"
    ECR = "ecr"
    RC16 = "rc16"


_PERMUTE_MODE_TO_DIALECT = {
    "default": _PermuteModeDialect.DEFAULT,
    "f4e": _PermuteModeDialect.F4E,
    "b4e": _PermuteModeDialect.B4E,
    "rc8": _PermuteModeDialect.RC8,
    "ecl": _PermuteModeDialect.ECL,
    "ecr": _PermuteModeDialect.ECR,
    "rc16": _PermuteModeDialect.RC16,
}


#: ``fence.proxy`` / ``cp.async.bulk.tensor`` proxy kind.
class Proxy(StrEnum):
    ALIAS = "alias"
    ASYNC = "async"
    ASYNC_GLOBAL = "async_global"
    ASYNC_SHARED = "async_shared"
    TENSORMAP = "tensormap"
    GENERIC = "generic"


_PROXY_TO_DIALECT = {
    "alias": _ProxyKindDialect.alias,
    "async": _ProxyKindDialect.async_,
    "async.global": _ProxyKindDialect.async_global,
    "async_global": _ProxyKindDialect.async_global,
    "async.shared": _ProxyKindDialect.async_shared,
    "async_shared": _ProxyKindDialect.async_shared,
    "tensormap": _ProxyKindDialect.TENSORMAP,
    "generic": _ProxyKindDialect.GENERIC,
}

#: Proxy kinds for which ``fence.proxy`` accepts a ``space`` qualifier.
#: Per the PTX ISA the ``.shared::{cta,cluster}`` space only attaches to
#: ``.async`` and ``.async.shared``; ``.async.global`` is already fully
#: qualified and ``.alias`` / ``.tensormap`` / ``.generic`` take no space.
#: Keyed on the ``StrEnum`` string values: a ``Proxy`` member or a
#: bare string (incl. the dotted ``"async.shared"`` alias) passes; a raw NVVM
#: dialect enum does not (see ``project_reject_raw_nvvm_enums``).
_PROXY_KINDS_WITH_SPACE = frozenset({"async", "async_shared", "async.shared"})


#: ``red.{op}`` reduction op for global / shared atomics.
class ReductionOp(StrEnum):
    AND = "and"
    OR = "or"
    XOR = "xor"
    ADD = "add"
    INC = "inc"
    DEC = "dec"
    MIN = "min"
    MAX = "max"


_REDUCTION_OP_TO_DIALECT = {
    "and": _ReductionOpDialect.AND,
    "or": _ReductionOpDialect.OR,
    "xor": _ReductionOpDialect.XOR,
    "add": _ReductionOpDialect.ADD,
    "inc": _ReductionOpDialect.INC,
    "dec": _ReductionOpDialect.DEC,
    "min": _ReductionOpDialect.MIN,
    "max": _ReductionOpDialect.MAX,
}


#: ``red.{type}`` reduction operand type.
class ReductionType(StrEnum):
    B32 = "b32"
    B64 = "b64"
    U32 = "u32"
    U64 = "u64"
    S32 = "s32"
    S64 = "s64"
    F32 = "f32"
    F64 = "f64"
    F16 = "f16"
    F16X2 = "f16x2"
    BF16 = "bf16"
    BF16X2 = "bf16x2"


_REDUCTION_TYPE_TO_DIALECT = {
    "b32": _ReductionTypeDialect.B32,
    "b64": _ReductionTypeDialect.B64,
    "u32": _ReductionTypeDialect.U32,
    "u64": _ReductionTypeDialect.U64,
    "s32": _ReductionTypeDialect.S32,
    "s64": _ReductionTypeDialect.S64,
    "f32": _ReductionTypeDialect.F32,
    "f64": _ReductionTypeDialect.F64,
    "f16": _ReductionTypeDialect.F16,
    "f16x2": _ReductionTypeDialect.F16X2,
    "bf16": _ReductionTypeDialect.BF16,
    "bf16x2": _ReductionTypeDialect.BF16X2,
}

#: ``red`` types needing the ``.noftz`` qualifier in inline-PTX form.
_RED_NOFTZ_TYPES = frozenset(
    {
        ReductionType.F16,
        ReductionType.BF16,
        ReductionType.F16X2,
        ReductionType.BF16X2,
    }
)


#: Saturation mode for ``cvt`` family.
class SaturationMode(StrEnum):
    SATFINITE = "satfinite"
    SAT = "sat"


def _saturation_mode_to_dialect() -> dict[str, Any]:
    mapping = {"satfinite": _SaturationModeDialect.SATFINITE}
    sat = getattr(_SaturationModeDialect, "SAT", None)
    if sat is not None:
        mapping["sat"] = sat
    return mapping


_SATURATION_MODE_TO_DIALECT = _saturation_mode_to_dialect()


#: Saturation mode kind (adds ``satnarrow``).  "Kind" suffix kept to
#: disambiguate from :data:`SaturationMode`.
class SaturationModeKind(StrEnum):
    SATFINITE = "satfinite"

_SATURATION_MODE_KIND_TO_DIALECT = {
    "satfinite": _SaturationModeKindDialect.SATFINITE,
}


#: ``setmaxnreg`` action selector.
class SetMaxRegisterAction(StrEnum):
    DECREASE = "decrease"
    INCREASE = "increase"


_SET_MAX_REGISTER_ACTION_TO_DIALECT = {
    "decrease": _SetMaxRegisterActionDialect.decrease,
    "increase": _SetMaxRegisterActionDialect.increase,
}


#: ``shfl.sync`` mode.
class Shfl(StrEnum):
    BFLY = "bfly"
    UP = "up"
    DOWN = "down"
    IDX = "idx"


_SHFL_TO_DIALECT = {
    "bfly": _ShflKindDialect.bfly,
    "up": _ShflKindDialect.up,
    "down": _ShflKindDialect.down,
    "idx": _ShflKindDialect.idx,
}


#: ``stmatrix`` shape.
class StoreShape(StrEnum):
    M8N8 = "m8n8"
    M16N8 = "m16n8"


_STORE_SHAPE_TO_DIALECT = {
    "m8n8": _StoreShapeDialect.M8N8,
    "m16n8": _StoreShapeDialect.M16N8,
}


#: ``cp.async.bulk.tensor`` TMA load mode.
class TMALoadMode(StrEnum):
    TILE = "tile"
    IM2COL = "im2col"
    IM2COL_W = "im2col_w"
    IM2COL_W_128 = "im2col_w_128"
    TILE_GATHER4 = "tile_gather4"


_TMA_LOAD_MODE_TO_DIALECT = {
    "tile": _TMALoadModeDialect.TILE,
    "im2col": _TMALoadModeDialect.IM2COL,
    "im2col_w": _TMALoadModeDialect.IM2COL_W,
    "im2col_w_128": _TMALoadModeDialect.IM2COL_W_128,
    "tile_gather4": _TMALoadModeDialect.TILE_GATHER4,
}


#: ``cp.async.bulk.tensor`` TMA store mode.
class TMAStoreMode(StrEnum):
    TILE = "tile"
    IM2COL = "im2col"
    TILE_SCATTER4 = "tile_scatter4"

_TMA_STORE_MODE_TO_DIALECT = {
    "tile": _TMAStoreModeDialect.TILE,
    "im2col": _TMAStoreModeDialect.IM2COL,
    "tile_scatter4": _TMAStoreModeDialect.TILE_SCATTER4,
}


#: ``cp.reduce.async.bulk.tensor`` reduction kind.
class TMARedux(StrEnum):
    ADD = "add"
    MAX = "max"
    MIN = "min"
    INC = "inc"
    DEC = "dec"
    AND = "and"
    OR = "or"
    XOR = "xor"


_TMA_REDUX_TO_DIALECT = {
    "add": _TMAReduxKindDialect.ADD,
    "max": _TMAReduxKindDialect.MAX,
    "min": _TMAReduxKindDialect.MIN,
    "inc": _TMAReduxKindDialect.INC,
    "dec": _TMAReduxKindDialect.DEC,
    "and": _TMAReduxKindDialect.AND,
    "or": _TMAReduxKindDialect.OR,
    "xor": _TMAReduxKindDialect.XOR,
}



#: ``vote.sync`` mode.
class VoteSync(StrEnum):
    ANY = "any"
    ALL = "all"
    BALLOT = "ballot"
    UNI = "uni"


_VOTE_SYNC_TO_DIALECT = {
    "any": _VoteSyncKindDialect.any,
    "all": _VoteSyncKindDialect.all,
    "ballot": _VoteSyncKindDialect.ballot,
    "uni": _VoteSyncKindDialect.uni,
}


#: AtomicRMW operation (PTX-unified).  Members match the PTX modifier on
#: ``atom.{op}`` exactly.  The wrapper selects the dialect-level
#: ``FADD`` / ``UMIN`` / ``UMAX`` variant from the operand dtype at trace
#: time, so callers pass ``"add"`` / ``"min"`` / ``"max"`` whether the
#: operand is integer or floating-point.
class AtomicOp(StrEnum):
    AND = "and"
    OR = "or"
    XOR = "xor"
    CAS = "cas"
    EXCH = "exch"
    ADD = "add"
    INC = "inc"
    DEC = "dec"
    MIN = "min"
    MAX = "max"


#: 1:1 mappings — the op is the same regardless of operand dtype.
_ATOMIC_OP_SIMPLE_TO_DIALECT = {
    "and": _AtomicOpKindDialect.AND,
    "or": _AtomicOpKindDialect.OR,
    "xor": _AtomicOpKindDialect.XOR,
    "cas": _AtomicOpKindDialect.CAS,
    "exch": _AtomicOpKindDialect.EXCH,
    "inc": _AtomicOpKindDialect.INC,
    "dec": _AtomicOpKindDialect.DEC,
}

#: Floating-point types that pick the FADD / signless MIN / signless MAX
#: dialect enum variants.
_ATOMIC_OP_FLOAT_TYPES = (
    _cutlass.Float16,
    _cutlass.BFloat16,
    _cutlass.Float32,
    _cutlass.Float64,
)

#: Unsigned integer types that pick the UMIN / UMAX variants.
_ATOMIC_OP_UNSIGNED_TYPES = (
    _cutlass.Uint8,
    _cutlass.Uint16,
    _cutlass.Uint32,
    _cutlass.Uint64,
)


def _atomic_op_to_dialect(op: AtomicOp, operand: object) -> _AtomicOpKindDialect:
    """Resolve an :data:`AtomicOp` string to the matching dialect enum.

    For ``"add"`` / ``"min"`` / ``"max"`` the dialect distinguishes by
    operand dtype:

      * floating-point operand  -> ``FADD`` / ``MIN``  / ``MAX``
      * unsigned integer operand -> ``ADD``  / ``UMIN`` / ``UMAX``
      * signed   integer operand -> ``ADD``  / ``MIN``  / ``MAX``

    Caller passes the *coerced* operand (after the wrapper has run
    ``Int32(a)`` / ``Float32(a)``); this function inspects its type to
    pick the right variant.
    """
    if op in _ATOMIC_OP_SIMPLE_TO_DIALECT:
        return _ATOMIC_OP_SIMPLE_TO_DIALECT[op]
    is_float = isinstance(operand, _ATOMIC_OP_FLOAT_TYPES)
    is_unsigned = isinstance(operand, _ATOMIC_OP_UNSIGNED_TYPES)
    if op == "add":
        return _AtomicOpKindDialect.FADD if is_float else _AtomicOpKindDialect.ADD
    if op == "min":
        if is_float:
            return _AtomicOpKindDialect.MIN
        return _AtomicOpKindDialect.UMIN if is_unsigned else _AtomicOpKindDialect.MIN
    if op == "max":
        if is_float:
            return _AtomicOpKindDialect.MAX
        return _AtomicOpKindDialect.UMAX if is_unsigned else _AtomicOpKindDialect.MAX
    raise ValueError(f"atomicrmw: unknown op {op!r}")


# Type aliases for narrow-float destination types (used in convert op annotations).
_Float8Type: TypeAlias = (
    Float8E4M3
    | Float8E4M3B11FNUZ
    | Float8E4M3FN
    | Float8E5M2
    | Float8E8M0FNU
)
_Float6Type: TypeAlias = Float6E2M3FN | Float6E3M2FN
_Float4Type: TypeAlias = Float4E2M1FN

_Tcgen05BlockScaleLike: TypeAlias = Tcgen05MMAScaleVecSize | Tcgen05MMABlockScale

# Auto-converting proxy: passes through enums, wraps callables to
# convert any arg with .ir_value() before forwarding to the raw dialect.
_nvvm = DialectAutoConvertProxy(_nvvm_raw)


def _hl_inline_ptx(
    ptx_code: str,
    *,
    write_only_types: list | None = None,
    read_only_args: list | None = None,
    read_write_args: list | None = None,
    pred: Boolean | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> object:
    """High-level inline-PTX builder with optional ``@p`` predication.

    Wraps the ``cute.arch`` inline-PTX builder, which accepts ``{$r0}`` /
    ``{$w0}`` named operand refs and DSL ``write_only_types`` (auto register
    sizing + Python→DSL coercion) — distinct from the raw ``nvvm.inline_ptx``
    op (``write_only_args`` / positional ``ptx_code``) bound to
    :data:`inline_ptx`.

    When *pred* is given it appends ``pred`` to the read-only operands and
    prepends ``@{$rN}`` to the PTX,
    avoiding the upstream ``inline_ptx(predicate=...)`` operand-indexing issue
    when there are ``write_only`` outputs.  Lazily imported to avoid an import
    cycle.
    """
    from cutlass.cute.arch.nvvm_wrappers import inline_ptx as _hl  # noqa: PLC0415

    if pred is not None:
        read_only_args = list(read_only_args) if read_only_args else []
        ptx_code = f"@{{$r{len(read_only_args)}}} {ptx_code}"
        read_only_args.append(pred)
    return _hl(
        ptx_code,
        write_only_types=write_only_types,
        read_only_args=read_only_args,
        read_write_args=read_write_args,
        loc=loc,
        ip=ip,
    )


# Expose the proxy for direct access to unwrapped ops:
#   dialect.any_raw_op(T.i32(), ...)
dialect = _nvvm


# Safe accessor for ops that may be absent in older builds.
def _raw(name: str) -> object | None:
    return getattr(_nvvm_raw, name, None)


def _tcgen05_mma_block_scale_dialect() -> Any:
    block_scale = getattr(_nvvm_raw, "Tcgen05MMABlockScale", None)
    if block_scale is None:
        return Tcgen05MMABlockScale
    if not hasattr(block_scale, "DEFAULT") and hasattr(block_scale, "Default"):
        block_scale.DEFAULT = block_scale.Default
    return block_scale


def _to_tcgen05_block_scale(
    scale_vec_size: _Tcgen05BlockScaleLike | None,
) -> Any | None:
    """Map the old scale-vector enum to the new NVVM block-scale enum."""
    if scale_vec_size is None:
        return None
    block_scale = _tcgen05_mma_block_scale_dialect()
    if scale_vec_size is Tcgen05MMABlockScale.DEFAULT:
        return block_scale.DEFAULT
    if scale_vec_size is Tcgen05MMABlockScale.BLOCK16:
        return block_scale.BLOCK16
    if scale_vec_size is Tcgen05MMABlockScale.BLOCK32:
        return block_scale.BLOCK32
    if scale_vec_size is block_scale.DEFAULT:
        return block_scale.DEFAULT
    if scale_vec_size is block_scale.BLOCK16:
        return block_scale.BLOCK16
    if scale_vec_size is block_scale.BLOCK32:
        return block_scale.BLOCK32
    if scale_vec_size is Tcgen05MMAScaleVecSize.X1:
        return block_scale.DEFAULT
    if scale_vec_size is Tcgen05MMAScaleVecSize.X2:
        return block_scale.BLOCK16
    if scale_vec_size is Tcgen05MMAScaleVecSize.X4:
        return block_scale.BLOCK32
    raise ValueError(f"unsupported tcgen05 block-scale value: {scale_vec_size!r}")


def _to_tcgen05_scale_vec_size(
    scale_vec_size: _Tcgen05BlockScaleLike | None,
) -> Any | None:
    """Map tcgen05 block-scale selector aliases to the released NVVM enum."""
    if scale_vec_size is None:
        return None
    tcgen05_scale_vec_size = getattr(_nvvm_raw, "Tcgen05MMAScaleVecSize", None)
    if tcgen05_scale_vec_size is None:
        tcgen05_scale_vec_size = ScaleVecSize
    if scale_vec_size is Tcgen05MMAScaleVecSize.X1:
        return tcgen05_scale_vec_size.X1
    if scale_vec_size is Tcgen05MMAScaleVecSize.X2:
        return tcgen05_scale_vec_size.X2
    if scale_vec_size is Tcgen05MMAScaleVecSize.X4:
        return tcgen05_scale_vec_size.X4
    if scale_vec_size is Tcgen05MMABlockScale.DEFAULT:
        return getattr(
            tcgen05_scale_vec_size,
            "DEFAULT",
            getattr(tcgen05_scale_vec_size, "Default", tcgen05_scale_vec_size.X1),
        )
    if scale_vec_size is Tcgen05MMABlockScale.BLOCK16:
        return getattr(tcgen05_scale_vec_size, "BLOCK16", tcgen05_scale_vec_size.X2)
    if scale_vec_size is Tcgen05MMABlockScale.BLOCK32:
        return getattr(tcgen05_scale_vec_size, "BLOCK32", tcgen05_scale_vec_size.X4)
    raise ValueError(f"unsupported tcgen05 block-scale value: {scale_vec_size!r}")


_FULL_MASK: int = 0xFFFFFFFF
"""Full 32-thread warp participation mask (module-private; ``cute.arch.FULL_MASK``
is the public re-export)."""


def _assert_mask32(mask: int | Int32 | Uint32, instruction: str) -> None:
    """Validate a 32-bit warp participation mask for static int values."""
    if isinstance(mask, int) and not (0 <= mask <= 0xFFFFFFFF):
        raise ValueError(
            f"{instruction}: mask must fit in 32 bits [0, 0xFFFFFFFF], got {mask:#x}"
        )


#: ``cp.async.bulk`` requires the byte count to be a multiple of 16; a
#: non-multiple is undefined behavior per the PTX ISA.
_BULK_SIZE_ALIGN = 16


def _assert_bulk_size(size: int | Int32 | Uint32, instruction: str) -> None:
    """Validate a ``cp.async.bulk`` byte count for static int values.

    The PTX ISA requires ``size`` to be a positive multiple of 16; a
    non-multiple is undefined behavior.  Only Python ``int`` literals are
    checked here; runtime ``Int32`` / ``Uint32`` values pass through
    unchecked, per this module's trace-time-validator convention.
    """
    if isinstance(size, int):
        if size <= 0:
            raise ValueError(f"{instruction}: size must be > 0, got {size}")
        if size % _BULK_SIZE_ALIGN != 0:
            raise ValueError(
                f"{instruction}: size must be a multiple of "
                f"{_BULK_SIZE_ALIGN}, got {size}"
            )


#: TMA tensor ops address up to 5 dimensions.
_TMA_MAX_DIMS = 5


def _assert_coords(
    coords: object,
    instruction: str,
    *,
    mode: TMALoadMode | TMAStoreMode | None = None,
) -> None:
    """Validate a TMA coordinate tuple length (1-5D), mode-specific.

    The PTX ISA constrains the coordinate count by TMA mode: tile uses 1-5
    dimensions, im2col forms 3-5, and gather4/scatter4 exactly 2 (the dialect
    packs the remaining hardware values internally).
    """
    if not isinstance(coords, (tuple, list)):
        raise TypeError(
            f"{instruction}: coordinates must be a tuple or list, "
            f"got {type(coords).__name__}"
        )
    n = len(coords)
    if not 1 <= n <= _TMA_MAX_DIMS:
        raise ValueError(
            f"{instruction}: coordinates must have 1-{_TMA_MAX_DIMS} elements, got {n}"
        )
    if mode is None:
        return
    # StrEnum members compare by value, so listing the TMALoadMode members
    # also matches the equivalent TMAStoreMode variants.
    if mode in (TMALoadMode.TILE_GATHER4, TMAStoreMode.TILE_SCATTER4):
        if n != 2:
            raise ValueError(
                f"{instruction}: gather4/scatter4 mode requires exactly 2 "
                f"coordinate elements, got {n}"
            )
    elif mode in (TMALoadMode.IM2COL, TMALoadMode.IM2COL_W, TMALoadMode.IM2COL_W_128):
        if not 3 <= n <= _TMA_MAX_DIMS:
            raise ValueError(
                f"{instruction}: im2col mode requires 3-{_TMA_MAX_DIMS} "
                f"coordinate elements, got {n}"
            )


#: Minimum toolkit that ships any PTX ISA newer than 8.8.  We support exactly
#: two toolkits: CTK 12.9 (PTX ISA 8.8) and CTK 13.3 (PTX ISA 9.3).  Every
#: feature introduced after 8.8 (in PTX ISA 9.0/9.1/9.2/9.3) is therefore
#: available only on CTK 13.3, so a single CTK-13.3 floor masks all of them.
_MIN_POST_8_8_CTK = (13, 3)

#: Backwards-compatible alias; the only post-8.8 toolkit is CTK 13.3.
_PTX_9_3_CTK = _MIN_POST_8_8_CTK


def _assert_min_ptx(feature: str, instruction: str, ptx_version: str) -> None:
    """Reject a feature newer than PTX ISA 8.8 on CTK 12.9.

    ``ptx_version`` is the PTX ISA version that introduced ``feature`` (e.g.
    ``"9.1"``).  Supported toolkits are CTK 12.9 (PTX ISA 8.8) and CTK 13.3 (PTX ISA
    9.3); any post-8.8 feature exists only on CTK 13.3, so fail fast on the
    older toolkit with a clear message instead of an opaque backend "cannot
    select" error.  The caller names the specific *feature* and the PTX ISA
    version that introduced it.
    """
    if (CUDA_VERSION.major, CUDA_VERSION.minor) < _MIN_POST_8_8_CTK:
        raise ValueError(
            f"{instruction}: {feature} requires PTX ISA {ptx_version} "
            f"(CTK 13.3); current toolkit is CTK "
            f"{CUDA_VERSION.major}.{CUDA_VERSION.minor} (PTX ISA 8.8)"
        )


def _assert_ptx_9_3(feature: str, instruction: str) -> None:
    """Reject a PTX-ISA-9.3-only feature on an older toolkit.

    Thin shim over :func:`_assert_min_ptx` for the common 9.3 case (e.g. the
    ``im2col_w`` / ``im2col_w_128`` TMA modes).  CTK 12.9 ships PTX ISA 8.8 and
    cannot encode 9.3 qualifiers.
    """
    _assert_min_ptx(feature, instruction, "9.3")


def _assert_mask16(mask: int | Int16 | Int32 | Uint32, instruction: str) -> None:
    """Validate a 16-bit participation mask for static int values.

    The dialect operand is ``i16``, so a static literal outside ``[0, 0xFFFF]``
    would be silently truncated by the ``Int16`` coercion; reject it instead.
    Runtime IR values pass through.
    """
    if isinstance(mask, int) and not (0 <= mask <= 0xFFFF):
        raise ValueError(
            f"{instruction}: mask must fit in 16 bits [0, 0xFFFF], got {mask:#x}"
        )


# =============================================================================
# Trace-time validators (PTX ISA contract checks)
# =============================================================================
#
# These run only when the caller passes Python `int` literals — runtime
# `Int32` / `Uint32` values pass through unchecked.

_BARRIER_ID_MAX = 15
_WARP_SIZE = 32


def _assert_barrier_id(barrier_id: int | Int32 | Uint32, instruction: str) -> None:
    """Validate barrier ID is in [0, 15] per the PTX ISA."""
    if isinstance(barrier_id, int) and not (0 <= barrier_id <= _BARRIER_ID_MAX):
        raise ValueError(
            f"{instruction}: barrier_id must be in [0, 15], got {barrier_id}"
        )


def _assert_thread_count(thread_count: int | Int32 | Uint32, instruction: str) -> None:
    """Validate barrier thread count per the PTX ISA.

    Must be positive and a non-zero multiple of the warp size (32).
    """
    if isinstance(thread_count, int):
        if thread_count <= 0:
            raise ValueError(
                f"{instruction}: thread_count must be > 0, got {thread_count}"
            )
        if thread_count % _WARP_SIZE != 0:
            raise ValueError(
                f"{instruction}: thread_count must be a multiple of "
                f"{_WARP_SIZE}, got {thread_count}"
            )


def _assert_barrier_redux(kind: BarrierRedux, instruction: str) -> None:
    """Validate the reduction kind of a ``barrier.cta.red`` op.

    Accepts a :class:`BarrierRedux` member or its string value; raises a
    fail-fast ``ValueError`` (rather than a bare ``KeyError`` from the
    dialect lookup) for anything else.
    """
    if kind not in _BARRIER_REDUX_TO_DIALECT:
        valid = ", ".join(repr(e.value) for e in BarrierRedux)  # type: ignore[attr-defined]
        raise ValueError(f"{instruction}: kind must be one of {valid}, got {kind!r}")


def _assert_lane_offset(
    value: int | Int32 | Uint32, name: str, instruction: str
) -> None:
    """Validate a warp-shuffle lane offset/delta is in [0, 31].

    The ``shfl.sync`` source operand is a 5-bit field (absolute lane for
    ``idx``, relative delta for ``up``/``down``, XOR lane mask for ``bfly``),
    so it must lie in ``[0, 31]``. Checks static ``int`` literals only; runtime
    ``Int32`` / ``Uint32`` values pass through unchecked.
    """
    if isinstance(value, int) and not (0 <= value <= _WARP_SIZE - 1):
        raise ValueError(f"{instruction}: {name} must be in [0, 31], got {value}")


def _assert_shfl_kind(kind: Shfl, instruction: str) -> None:
    """Validate the shuffle mode of a ``shfl.sync`` op.

    Accepts a :class:`Shfl` member or its string value; raises a fail-fast
    ``ValueError`` (rather than a bare ``KeyError`` from the dialect lookup)
    for anything else.
    """
    if kind not in _SHFL_TO_DIALECT:
        valid = ", ".join(repr(e.value) for e in Shfl)
        raise ValueError(f"{instruction}: kind must be one of {valid}, got {kind!r}")


def _assert_vote_kind(kind: VoteSync, instruction: str) -> None:
    """Validate the mode of a ``vote.sync`` op.

    Accepts a :class:`VoteSync` member or its string value; raises a fail-fast
    ``ValueError`` (rather than a bare ``KeyError`` from the dialect lookup)
    for anything else.
    """
    if kind not in _VOTE_SYNC_TO_DIALECT:
        valid = ", ".join(repr(e.value) for e in VoteSync)
        raise ValueError(f"{instruction}: kind must be one of {valid}, got {kind!r}")


def _assert_reduction_op(op: ReductionOp, instruction: str) -> None:
    """Validate the operation of a ``red`` op.

    Accepts a :class:`ReductionOp` member or its string value; raises a
    fail-fast ``ValueError`` (rather than a bare ``KeyError`` from the dialect
    lookup) for anything else.
    """
    if op not in _REDUCTION_OP_TO_DIALECT:
        valid = ", ".join(repr(e.value) for e in ReductionOp)
        raise ValueError(f"{instruction}: op must be one of {valid}, got {op!r}")


def _assert_reduction_type(type_: ReductionType, instruction: str) -> None:
    """Validate the operand type of a ``red`` op.

    Accepts a :class:`ReductionType` member or its string value; raises a
    fail-fast ``ValueError`` (rather than a bare ``KeyError`` from the dialect
    lookup) for anything else.
    """
    if type_ not in _REDUCTION_TYPE_TO_DIALECT:
        valid = ", ".join(repr(e.value) for e in ReductionType)
        raise ValueError(f"{instruction}: type_ must be one of {valid}, got {type_!r}")


# =============================================================================
# Raw aliases (direct pass-through to raw MLIR dialect, no auto-conversion)
# =============================================================================


@dsl_user_op
def barrier_cluster_arrive(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Register an acquire-release arrival on the cluster-wide barrier.

    Emits ``barrier.cluster.arrive`` (non-aligned, the ordered ``.release``
    form): each CTA registers its arrival, and the arrival also orders the
    issuing CTA's prior memory writes so they become visible to every other
    CTA once it returns from the paired wait.  This is the ordered
    counterpart of the relaxed :func:`barrier_cluster_arrive_relaxed` (which
    registers arrival without any memory ordering); prefer the relaxed form
    plus an explicit fence when you do not need the built-in acquire-release
    ordering.  Pair every arrive with :func:`barrier_cluster_wait` from every
    CTA.

    The aligned variant :func:`barrier_cluster_arrive_aligned` additionally
    asserts that every thread in the issuing warp executes the instruction
    convergently.

    .. code-block:: python

        # Cluster rendezvous with built-in acquire-release ordering.
        if nvvm.elect_sync():
            nvvm.barrier_cluster_arrive()
            nvvm.barrier_cluster_wait()
    """
    return _nvvm_raw.cluster_arrive(aligned=False, loc=loc, ip=ip)


@dsl_user_op
def barrier_cluster_arrive_aligned(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Aligned variant of :func:`barrier_cluster_arrive`.

    Emits ``barrier.cluster.arrive.aligned``.  Same acquire-release cluster
    arrival, but the ``.aligned`` qualifier additionally asserts that every
    thread in the issuing warp executes this instruction convergently
    (behaviour is undefined if any lane in the warp does not reach it).  Do
    not combine with single-thread election (e.g. inside ``elect_sync``): the
    other lanes would never reach the instruction.
    """
    return _nvvm_raw.cluster_arrive(aligned=True, loc=loc, ip=ip)


@dsl_user_op
def barrier_cluster_arrive_relaxed(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Register a relaxed arrival on the cluster-wide barrier.

    Emits ``barrier.cluster.arrive.relaxed`` (non-aligned): each CTA in the
    cluster registers its arrival, but no memory ordering is implied.  Pair
    every arrive with a :func:`barrier_cluster_wait` from every CTA to block
    until all have arrived.  The relaxed variant is cheaper than the
    acquire-release :func:`barrier_cluster_arrive`; prefer relaxed + an
    explicit fence where ordering is genuinely needed.

    The aligned variant :func:`barrier_cluster_arrive_relaxed_aligned`
    additionally asserts that every thread in the issuing warp executes the
    instruction convergently.

    .. code-block:: python

        # CTA_2 GEMM cleanup — both CTAs rendezvous before dealloc.
        if nvvm.elect_sync():
            nvvm.barrier_cluster_arrive_relaxed()
            nvvm.barrier_cluster_wait()
    """
    return _nvvm_raw.cluster_arrive_relaxed(aligned=False, loc=loc, ip=ip)


@dsl_user_op
def barrier_cluster_arrive_relaxed_aligned(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Aligned variant of :func:`barrier_cluster_arrive_relaxed`.

    Emits ``barrier.cluster.arrive.relaxed.aligned``.  Same relaxed cluster
    arrival (no memory ordering), but the ``.aligned`` qualifier additionally
    asserts that every thread in the issuing warp executes this instruction
    convergently (behaviour is undefined if any lane in the warp does not
    reach it).  Do not combine with single-thread election (e.g. inside
    ``elect_sync``): the other lanes would never reach the instruction.
    """
    return _nvvm_raw.cluster_arrive_relaxed(aligned=True, loc=loc, ip=ip)


@dsl_user_op
def barrier_cluster_wait(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Block until every CTA in the cluster has called ``barrier.cluster.arrive*``.

    Emits ``barrier.cluster.wait`` (non-aligned): the issuing thread stalls
    until the cluster-wide arrival counter reaches the cluster's CTA count.
    The counter is set by the paired arrive call from every CTA
    (see :func:`barrier_cluster_arrive_relaxed` for the relaxed form,
    or :func:`barrier_cluster_arrive` when acquire-release ordering is
    needed).

    The aligned variant :func:`barrier_cluster_wait_aligned` additionally
    asserts that every thread in the issuing warp executes the instruction
    convergently.

    .. code-block:: python

        # See barrier_cluster_arrive_relaxed for the paired usage.
        if nvvm.elect_sync():
            nvvm.barrier_cluster_arrive_relaxed()
            nvvm.barrier_cluster_wait()
    """
    return _nvvm_raw.cluster_wait(aligned=False, loc=loc, ip=ip)


@dsl_user_op
def barrier_cluster_wait_aligned(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Aligned variant of :func:`barrier_cluster_wait`.

    Emits ``barrier.cluster.wait.aligned``.  Same cluster-scope wait, but the
    ``.aligned`` qualifier additionally asserts that every thread in the
    issuing warp executes this instruction convergently (behaviour is
    undefined if any lane in the warp does not reach it).  Do not combine
    with single-thread election (e.g. inside ``elect_sync``): the other lanes
    would never reach the instruction.
    """
    return _nvvm_raw.cluster_wait(aligned=True, loc=loc, ip=ip)


@dsl_user_op
def exit(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Terminate the issuing thread's execution of the kernel.

    Emits PTX ``exit``: the issuing thread stops running immediately.
    Other threads in the warp / CTA continue.  Rarely needed: a natural
    return from ``@cute.kernel`` is almost always preferable, because
    ``exit`` does not cooperate with mbarrier-based control-flow
    staging.  CTA barriers (``bar.sync`` / ``barrier.cta``) exclusively
    waiting on arrivals from exited threads are released automatically by
    hardware (a PTX guarantee), but ``mbarrier`` arrivals are explicit and
    are NOT auto-completed: a thread that exits before its
    ``mbarrier.arrive`` leaves any consumer of that arrival hung
    indefinitely.

    .. code-block:: python

        # Rarely needed — prefer an ``if`` guard around the work.
        if tid >= num_valid:
            nvvm.exit()
        # ... remaining threads continue ...
    """
    return _nvvm_raw.exit(loc=loc, ip=ip)


@dsl_user_op
def griddepcontrol(
    kind: GridDepAction,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Coordinate execution between consecutive dependent grids.

    Emits ``griddepcontrol.{launch_dependents|wait}``.  Used between back-to-back kernels that the runtime
    has wired with a producer/consumer dependency: the producer kernel
    issues ``launch_dependents`` to let the dependent kernel start as
    soon as scheduling permits, and the dependent kernel issues
    ``wait`` to ensure all prerequisite-grid memory operations have
    drained before reading.

    :param kind: ``"launch_dependents"`` (producer side, hint that
        dependents may start) or ``"wait"`` (consumer side, block
        until prerequisites done).
    :type kind: GridDepAction
    :raises ValueError: if ``kind`` is not a :class:`GridDepAction`
        member or its string value (raw NVVM dialect enums are rejected).

    .. code-block:: python

        # Producer kernel — at the end, allow the consumer kernel to start
        if nvvm.elect_sync():
            nvvm.griddepcontrol("launch_dependents")

        # Consumer kernel — at the start, wait for producer's writes
        if nvvm.elect_sync():
            nvvm.griddepcontrol("wait")
    """
    return _nvvm_raw.griddepcontrol(
        _to_dialect(kind, _GRID_DEP_ACTION_TO_DIALECT), loc=loc, ip=ip
    )


# ``inline_ptx`` uses the clean cute.arch wrapper signature (ptx_code first).
# Normalize pointer-like operands here so compatibility paths such as
# ``inline_ptx_hl`` can pass CuTe pointers through ``prims`` without forcing
# every caller to unwrap them manually. The raw 1:1 NVVM op remains available as
# ``prims.dialect.inline_ptx``.


def _inline_ptx_arg(arg: object, loc: object | None, ip: object | None) -> object:
    """Convert pointer-like DSL operands for ``cute.arch.inline_ptx``."""
    if isinstance(arg, (bool, int, float)):
        return arg
    if isinstance(arg, (list, tuple)):
        converted = [_inline_ptx_arg(item, loc, ip) for item in arg]
        return type(arg)(converted)
    ir_value = getattr(arg, "ir_value", None)
    if callable(ir_value):
        try:
            return ir_value(loc=loc, ip=ip)
        except TypeError:
            return ir_value()
    return arg


def _inline_ptx_args(
    args: list[object] | tuple[object, ...] | None,
    loc: object | None,
    ip: object | None,
) -> list[object] | None:
    if args is None:
        return None
    return [_inline_ptx_arg(arg, loc, ip) for arg in args]


@dsl_user_op
def inline_ptx(
    ptx_code: str,
    *,
    write_only_types: list[type[Numeric]] | None = None,
    read_only_args: list[object] | None = None,
    read_write_args: list[object] | None = None,
    predicate: Boolean | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Any:
    return _cute_inline_ptx(
        ptx_code,
        write_only_types=write_only_types,
        read_only_args=_inline_ptx_args(read_only_args, loc, ip),
        read_write_args=_inline_ptx_args(read_write_args, loc, ip),
        predicate=predicate,
        loc=loc,
        ip=ip,
    )


inline_ptx_hl = inline_ptx


def mma_block_scale(
    res: Any,
    shape: Any,
    scale_vec_size: Any,
    block_scale_format: Any,
    kind: Any,
    *args: Any,
    **kwargs: Any,
) -> Any:
    """Gated 1:1 wrapper over ``nvvm.mma.block_scale``.

    The ``.scale_vec::4X`` + ``.ue8m0`` scale type + ``.kind::mxf4nvf4``
    combination was introduced in PTX ISA 9.1 and is unavailable on CTK 12.9
    (PTX ISA 8.8); every other combination predates it, so only that one is
    gated.
    """
    if (
        scale_vec_size == ScaleVecSize.X4
        and block_scale_format == BlockScaleFormat.UE8M0
        and kind == MMABlockScaleKind.MXF4NVF4
    ):
        _assert_min_ptx(
            ".scale_vec::4X with .ue8m0 and .kind::mxf4nvf4",
            "mma.block_scale",
            "9.1",
        )
    return _nvvm_raw.mma_block_scale(
        res, shape, scale_vec_size, block_scale_format, kind, *args, **kwargs
    )



def mma_sp_block_scale(
    res: Any,
    shape: Any,
    scale_vec_size: Any,
    block_scale_format: Any,
    kind: Any,
    *args: Any,
    **kwargs: Any,
) -> Any:
    """Gated 1:1 wrapper over ``nvvm.mma.sp.block_scale``.

    The ``.scale_vec::4X`` + ``.ue8m0`` scale type + ``.kind::mxf4nvf4``
    combination was introduced in PTX ISA 9.1 and is unavailable on CTK 12.9
    (PTX ISA 8.8); every other combination predates it, so only that one is
    gated.
    """
    if (
        scale_vec_size == ScaleVecSize.X4
        and block_scale_format == BlockScaleFormat.UE8M0
        and kind == MMABlockScaleKind.MXF4NVF4
    ):
        _assert_min_ptx(
            ".scale_vec::4X with .ue8m0 and .kind::mxf4nvf4",
            "mma.sp.block_scale",
            "9.1",
        )
    return _nvvm_raw.mma_sp_block_scale(
        res, shape, scale_vec_size, block_scale_format, kind, *args, **kwargs
    )



# setmaxnreg immediate operand bounds (PTX ISA: imm-reg-count must be an
# integer constant in [24, 256] and a multiple of 8).
_SETMAXNREG_MIN = 24
_SETMAXNREG_MAX = 256
_SETMAXNREG_ALIGN = 8


def _assert_setmaxnreg_count(reg_count: object, instruction: str) -> None:
    """Validate the ``setmaxnreg`` immediate at trace time.

    The register count is a compile-time immediate, so it must be a Python
    ``int`` in ``[24, 256]`` and a multiple of 8.  Mirrors the dialect
    verifier (which rejects out-of-range counts) and the PTX
    sibling, but fails earlier with a clearer message.
    """
    if not isinstance(reg_count, int):
        raise TypeError(
            f"{instruction}: reg_count must be an int literal, "
            f"got {type(reg_count).__name__}"
        )
    if not (_SETMAXNREG_MIN <= reg_count <= _SETMAXNREG_MAX):
        raise ValueError(
            f"{instruction}: reg_count must be in [24, 256], got {reg_count}"
        )
    if reg_count % _SETMAXNREG_ALIGN != 0:
        raise ValueError(
            f"{instruction}: reg_count must be a multiple of 8, got {reg_count}"
        )


@dsl_user_op
def setmaxregister(
    reg_count: int,
    action: SetMaxRegisterAction,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Adjust the per-thread register budget for the issuing warp.

    Emits ``setmaxnreg.inc`` / ``setmaxnreg.dec``.  The instruction
    provides a hint that changes the maximum number of per-thread
    registers owned by the executing warp, claiming registers from or
    releasing registers to the CTA register pool.  PTX requires every
    warp in a warpgroup to execute the same ``setmaxnreg`` instruction;
    branch on a warpgroup-uniform role, not on an individual warp role.

    :param reg_count: Target per-thread register count.  Must be a
        multiple of 8, within ``[24, 256]``.
    :type reg_count: int
    :param action: ``"increase"`` (claim more from the pool) or
        ``"decrease"`` (release to the pool).
    :type action: SetMaxRegisterAction
    :raises TypeError: if ``reg_count`` is not an ``int`` literal.
    :raises ValueError: if ``reg_count`` is outside ``[24, 256]`` or not
        a multiple of 8.

    .. code-block:: python

        warpgroup = cute.arch.warp_idx() // 4
        if warpgroup == PROD_WARPGROUP:
            nvvm.setmaxregister(40, "decrease")
            # ... TMA issue + mbarrier arrive ...
        else:
            nvvm.setmaxregister(232, "increase")
            # ... MMA + epilogue ...
        nvvm.barrier_cta_sync()
    """
    _assert_setmaxnreg_count(reg_count, "setmaxnreg")
    return _nvvm_raw.setmaxregister(
        reg_count, _SET_MAX_REGISTER_ACTION_TO_DIALECT[action], loc=loc, ip=ip
    )


_MMA_SYNC_INT_TYPES = frozenset({"u8", "s8", "u4", "s4"})


def _build_mma_shape_attr(
    shape: ir.Attribute | tuple[int, int, int] | dict, instruction: str
) -> ir.Attribute:
    """Coerce an ``(m, n, k)`` tuple/dict into the NVVM ``MMAShapeAttr``.

    Accepts a pre-built ``ir.Attribute`` unchanged.  ``int`` triples and
    ``{"m": ..., "n": ..., "k": ...}`` dicts are constructed via the
    NVVM shape attribute syntax.
    """
    if isinstance(shape, ir.Attribute):
        return shape
    if isinstance(shape, (tuple, list)):
        if len(shape) != 3 or not all(isinstance(v, int) for v in shape):
            raise ValueError(
                f"{instruction}: shape must be a 3-tuple of ``int`` (m, n, k); "
                f"got {shape!r}"
            )
        m, n, k = shape
    elif isinstance(shape, dict):
        try:
            m, n, k = int(shape["m"]), int(shape["n"]), int(shape["k"])
        except KeyError as e:
            raise ValueError(
                f"{instruction}: shape dict missing key {e}; expected keys 'm', 'n', 'k'"
            ) from None
    else:
        raise TypeError(
            f"{instruction}: shape must be an ``ir.Attribute``, a 3-tuple of "
            f"``int`` (m, n, k), or a dict with keys 'm','n','k'; got "
            f"{type(shape).__name__}"
        )
    return ir.Attribute.parse(f"#nvvm.shape<m = {m}, n = {n}, k = {k}>")


@dsl_user_op
def mma_sync(
    res: ir.Type,
    shape: ir.Attribute | tuple[int, int, int] | dict,
    layout_a: MMALayout,
    layout_b: MMALayout,
    operand_a: list[ir.Value],
    operand_b: list[ir.Value],
    operand_c: list[ir.Value],
    *,
    b1_op: MMAB1Op | None = None,
    int_overflow_behavior: MMAIntOverflow | None = None,
    multiplicand_a_ptx_type: MMAType | None = None,
    multiplicand_b_ptx_type: MMAType | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Any:
    """Cooperative warp-wide matrix multiply-accumulate (``D = A*B + C``).

    Emits ``mma.sync.aligned.{shape}.{alayout}.{blayout}{.kind}.{dtype}.{atype}.{btype}.{ctype}``.
    All 32 lanes of the issuing warp collectively compute one MMA on the
    fragments distributed across their registers; the four matrices are sliced
    across the warp per the PTX ISA's per-shape fragment layout.

    The wrapper is a 1:1 mapping over the NVVM dialect ``nvvm.mma.sync`` op.
    The dialect verifier validates the shape/type/operand-count combination
    (e.g. ``m16n8k16.f16`` requires 4 ``f16x2`` ``a``, 2 ``f16x2`` ``b``, and
    2 ``f16x2`` or 4 ``f32`` ``c``/``d`` registers).  This wrapper adds string/StrEnum
    coercion for the qualifier attributes and trace-time guards for the
    qualifier-vs-multiplicand-type coupling that the dialect cannot infer.

    :param res: MLIR result type of the fragment ``D`` — typically an
        ``llvm.struct<...>`` whose element layout matches the per-thread
        fragment for the given ``shape`` x type combination.
    :type res: ir.Type
    :param shape: MMA shape attribute.  Either a pre-built ``ir.Attribute``
        (``#nvvm.shape<m = ..., n = ..., k = ...>``), a 3-tuple
        ``(m, n, k)``, or a ``{"m": ..., "n": ..., "k": ...}`` dict.
    :type shape: ir.Attribute or tuple[int, int, int] or dict
    :param layout_a: Layout of multiplicand A.  Usually ``MMALayout.ROW``.
        ``MMALayout.COL`` is only legal for ``mma.m8n8k4.f16``.
    :type layout_a: MMALayout
    :param layout_b: Layout of multiplicand B.  Usually ``MMALayout.COL``.
        ``MMALayout.ROW`` is only legal for ``mma.m8n8k4.f16``.
    :type layout_b: MMALayout
    :param operand_a: Per-thread fragment of A as a sequence of ``ir.Value``.
    :param operand_b: Per-thread fragment of B as a sequence of ``ir.Value``.
    :param operand_c: Per-thread fragment of accumulator C as a sequence of
        ``ir.Value``.
    :param b1_op: Bit-op selector for single-bit (``.b1``) multiplicands;
        ``MMAB1Op.XOR_POPC`` for ``mma.xor.popc`` (default for ``.b1``),
        ``MMAB1Op.AND_POPC`` for ``mma.and.popc``.  Only valid when both
        multiplicand types are ``.b1``.
    :type b1_op: MMAB1Op or None
    :param int_overflow_behavior: Accumulator overflow handling for integer
        multiplicands (``.u8`` / ``.s8`` / ``.u4`` / ``.s4``).
        ``MMAIntOverflow.SATFINITE`` clamps to the ``s32`` range (PTX
        ``.satfinite`` modifier); ``MMAIntOverflow.WRAPPED`` wraps modulo
        ``2**32``.
    :type int_overflow_behavior: MMAIntOverflow or None
    :param multiplicand_a_ptx_type: Element type of multiplicand A as a
        ``MMAType``.  Defaults to the type the dialect infers from
        ``operand_a``'s MLIR type; pass it explicitly when the operand
        carrier type does not uniquely determine the PTX element type
        (e.g. ``i32`` carriers for packed ``s8`` / ``u8`` / ``f8`` data).
    :type multiplicand_a_ptx_type: MMAType or None
    :param multiplicand_b_ptx_type: Element type of multiplicand B as a
        ``MMAType``.  Same inference rules as ``multiplicand_a_ptx_type``.
    :type multiplicand_b_ptx_type: MMAType or None
    :raises ValueError: ``b1_op`` is given but ``multiplicand_{a,b}_ptx_type``
        is set to a non-``.b1`` type.
    :raises ValueError: ``int_overflow_behavior`` is given but
        ``multiplicand_{a,b}_ptx_type`` is set to a non-integer type.
    :raises ValueError: ``shape`` is a tuple/list of the wrong arity or with
        non-``int`` entries, or a dict missing the required ``m``/``n``/``k``
        keys.

    .. code-block:: python

        # m16n8k16 f16 = f16 * f16 + f16
        d = nvvm.mma_sync(
            T.struct([T.vector(2, T.f16())] * 2),
            shape=(16, 8, 16),
            layout_a=nvvm.MMALayout.ROW,
            layout_b=nvvm.MMALayout.COL,
            operand_a=[a0, a1, a2, a3],   # 4 x f16x2
            operand_b=[b0, b1],           # 2 x f16x2
            operand_c=[c0, c1],           # 2 x f16x2
        )
    """
    instruction = "mma.sync"
    a_type = (
        str(multiplicand_a_ptx_type) if multiplicand_a_ptx_type is not None else None
    )
    b_type = (
        str(multiplicand_b_ptx_type) if multiplicand_b_ptx_type is not None else None
    )

    if b1_op is not None:
        for label, ptx_type in (("a", a_type), ("b", b_type)):
            if ptx_type is not None and ptx_type != "b1":
                raise ValueError(
                    f"{instruction}: b1_op={b1_op!r} is only valid for ``.b1`` "
                    f"multiplicands; got multiplicand_{label}_ptx_type={ptx_type!r}"
                )

    if int_overflow_behavior is not None:
        for label, ptx_type in (("a", a_type), ("b", b_type)):
            if ptx_type is not None and ptx_type not in _MMA_SYNC_INT_TYPES:
                raise ValueError(
                    f"{instruction}: int_overflow_behavior={int_overflow_behavior!r} "
                    f"is only valid for integer multiplicands "
                    f"({sorted(_MMA_SYNC_INT_TYPES)}); got "
                    f"multiplicand_{label}_ptx_type={ptx_type!r}"
                )

    return _nvvm_raw.mma_sync(
        res,
        _build_mma_shape_attr(shape, instruction),
        _to_dialect(layout_a, _MMA_LAYOUT_TO_DIALECT),
        _to_dialect(layout_b, _MMA_LAYOUT_TO_DIALECT),
        operand_a,
        operand_b,
        operand_c,
        b1_op=_to_dialect(b1_op, _MMA_B1OP_TO_DIALECT),
        int_overflow_behavior=_to_dialect(
            int_overflow_behavior, _MMA_INT_OVERFLOW_TO_DIALECT
        ),
        multiplicand_a_ptx_type=_to_dialect(
            multiplicand_a_ptx_type, _MMA_TYPE_TO_DIALECT
        ),
        multiplicand_b_ptx_type=_to_dialect(
            multiplicand_b_ptx_type, _MMA_TYPE_TO_DIALECT
        ),
        loc=loc,
        ip=ip,
    )


wmma_mma = _nvvm_raw.wmma_mma


# =============================================================================
# Proxy aliases (auto-convert .ir_value() only)
# =============================================================================

auto = _nvvm.auto
clusterlaunchcontrol_try_cancel = _nvvm.clusterlaunchcontrol_try_cancel

def convert_bf16x2_to_s2f6x2(*args: Any, **kwargs: Any) -> Any:
    """Gated 1:1 wrapper over ``nvvm.convert_bf16x2_to_s2f6x2`` (PTX ISA 9.1).

    The ``.s2f6x2`` cvt instruction type was introduced in PTX ISA 9.1 and is
    unavailable on CTK 12.9 (PTX ISA 8.8).
    """
    _assert_min_ptx(".s2f6x2 destination type", "cvt.s2f6x2.bf16x2", "9.1")
    return _nvvm.convert_bf16x2_to_s2f6x2(*args, **kwargs)


_convert_f4x2_to_f16x2 = _nvvm.convert_f4x2_to_f16x2
_convert_f6x2_to_f16x2 = _nvvm.convert_f6x2_to_f16x2


def convert_f8x2_to_bf16x2(*args: Any, **kwargs: Any) -> Any:
    """Gated 1:1 wrapper over ``nvvm.convert_f8x2_to_bf16x2`` (PTX ISA 9.2).

    The ``.bf16x2`` destination from an ``.e4m3x2`` / ``.e5m2x2`` source was
    introduced in PTX ISA 9.2 and is unavailable on CTK 12.9 (PTX ISA 8.8).
    """
    _assert_min_ptx(".bf16x2 destination from fp8 source", "cvt.bf16x2.f8x2", "9.2")
    return _nvvm.convert_f8x2_to_bf16x2(*args, **kwargs)


_convert_f8x2_to_f16x2 = _nvvm.convert_f8x2_to_f16x2
fabs = _nvvm.fabs
fmin = _nvvm.fmin
register_attribute_builder = _nvvm.register_attribute_builder

#: Field selector for :func:`tensormap_replace`.  Values match the NVVM
#: dialect ``tensormap_field`` keywords.  Fields split into two groups: the
#: integer-valued fields (set via ``new_value``) and the enum-valued fields
#: (set via ``new_value_attr``).
class TensormapField(StrEnum):
    GLOBAL_ADDRESS = "global_address"
    RANK = "rank"
    BOX_DIM = "box_dim"
    GLOBAL_DIM = "global_dim"
    GLOBAL_STRIDE = "global_stride"
    ELEMENT_STRIDE = "element_stride"
    ELEMTYPE = "elemtype"
    INTERLEAVE_LAYOUT = "interleave_layout"
    SWIZZLE_MODE = "swizzle_mode"
    SWIZZLE_ATOMICITY = "swizzle_atomicity"
    FILL_MODE = "fill_mode"


#: ``elemtype`` field value.  Values are the NVVM dialect attribute keywords.
class TensormapElemtype(StrEnum):
    U8 = "u8"
    U16 = "u16"
    U32 = "u32"
    S32 = "s32"
    U64 = "u64"
    S64 = "s64"
    F16 = "f16"
    F32 = "f32"
    F32_FTZ = "f32.ftz"
    F64 = "f64"
    BF16 = "bf16"
    TF32 = "tf32"
    TF32_FTZ = "tf32.ftz"
    B4X16 = "b4x16"
    B4X16P64 = "b4x16_p64"
    B6X16P32 = "b6x16_p32"


#: ``interleave_layout`` field value.
class TensormapInterleaveLayout(StrEnum):
    NO_INTERLEAVE = "no_interleave"
    B16 = "b16"
    B32 = "b32"


#: ``swizzle_mode`` field value.
class TensormapSwizzleMode(StrEnum):
    NO_SWIZZLING = "no_swizzling"
    B32 = "b32"
    B64 = "b64"
    B128 = "b128"
    B96 = "b96"


#: ``swizzle_atomicity`` field value.
class TensormapSwizzleAtomicity(StrEnum):
    B16 = "b16"
    B32 = "b32"
    B32_FLIP_8B = "b32_flip_b8"
    B64 = "b64"


#: ``fill_mode`` field value.
class TensormapFillMode(StrEnum):
    ZERO = "zero"
    OOB_NAN = "oob_nan"


_TENSORMAP_FIELD_TO_DIALECT = {
    "global_address": _TensormapFieldDialect.GLOBAL_ADDRESS,
    "rank": _TensormapFieldDialect.RANK,
    "box_dim": _TensormapFieldDialect.BOX_DIM,
    "global_dim": _TensormapFieldDialect.GLOBAL_DIM,
    "global_stride": _TensormapFieldDialect.GLOBAL_STRIDE,
    "element_stride": _TensormapFieldDialect.ELEMENT_STRIDE,
    "elemtype": _TensormapFieldDialect.ELEMTYPE,
    "interleave_layout": _TensormapFieldDialect.INTERLEAVE_LAYOUT,
    "swizzle_mode": _TensormapFieldDialect.SWIZZLE_MODE,
    "swizzle_atomicity": _TensormapFieldDialect.SWIZZLE_ATOMICITY,
    "fill_mode": _TensormapFieldDialect.FILL_MODE,
}

# Fields that take an integer ordinal across tensor dimensions.
_TENSORMAP_ORD_FIELDS = frozenset(
    {"box_dim", "global_dim", "global_stride", "element_stride"}
)
# Valid range for the ``ord`` dimension ordinal (zero-based; [0, 4] for TMA's
# max rank of 5).  The public dialect currently constrains it to [1, 5], an
# off-by-one being fixed upstream (llvm/llvm-project#202853, now that PTX ISA
# 9.3 documents the zero-based range).  Until that fix reaches the pinned
# solid we mirror the dialect verifier for the target build; afterwards both
# branches collapse to [0, 4] and this guard can be removed.
_TENSORMAP_ORD_MIN = 1
_TENSORMAP_ORD_MAX = 5
# Fields whose value is a 64-bit integer (the rest of the integer fields are
# 32-bit).
_TENSORMAP_B64_FIELDS = frozenset({"global_address", "global_stride"})
# Enum-valued fields: field -> (dialect attribute mnemonic, value enum type).
_TENSORMAP_ATTR_INFO = {
    "elemtype": ("tensormap_elemtype", TensormapElemtype),
    "interleave_layout": ("tensormap_interleave_layout", TensormapInterleaveLayout),
    "swizzle_mode": ("tensormap_swizzle_mode", TensormapSwizzleMode),
    "swizzle_atomicity": ("tensormap_swizzle_atomicity", TensormapSwizzleAtomicity),
    "fill_mode": ("tensormap_fill_mode", TensormapFillMode),
}


def _tensormap_value_str(value: object, enum_ty: Any, field: str) -> str:
    """Validate an enum-valued tensormap field value and return its keyword.

    Accepts a ``StrEnum`` member of *enum_ty* (or its string value);
    rejects a wrong-field enum, a raw NVVM dialect enum, or an unknown string.
    """
    if isinstance(value, enum_ty):
        return value.value
    valid = {m.value for m in enum_ty}
    if isinstance(value, str) and value in valid:
        return value
    raise ValueError(
        f"tensormap.replace: field '{field}' requires a {enum_ty.__name__} "
        f"member or its string value (one of: "
        f"{', '.join(repr(v) for v in sorted(valid))}), got {value!r}. "
        f"Raw NVVM dialect enums are not accepted."
    )


@dsl_user_op
def tensormap_replace(
    field: TensormapField,
    addr: Array | Pointer,
    *,
    new_value: int | Int32 | Int64 | None = None,
    ord: int | None = None,
    new_value_attr: (
        TensormapElemtype
        | TensormapInterleaveLayout
        | TensormapSwizzleMode
        | TensormapSwizzleAtomicity
        | TensormapFillMode
        | None
    ) = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Replace one field of an in-memory TMA tensor-map descriptor.

    Emits ``tensormap.replace`` against the descriptor at ``addr`` (global or
    shared memory).  Used to patch a TMA descriptor at runtime, e.g. swap the
    ``global_address`` or resize a ``global_dim`` between launches without
    rebuilding the whole descriptor on the host.

    Fields split into two groups:

    - **integer-valued** (pass ``new_value``): ``global_address``, ``rank``,
      ``box_dim``, ``global_dim``, ``global_stride``, ``element_stride``.
      ``global_address`` / ``global_stride`` are 64-bit; the rest are 32-bit
      (coerced for you).  ``rank`` takes one less than the desired tensor rank
      (zero-based).
    - **enum-valued** (pass ``new_value_attr``): ``elemtype``,
      ``interleave_layout``, ``swizzle_mode``, ``swizzle_atomicity``,
      ``fill_mode``, each taking the matching enum.

    The ``ord`` (dimension ordinal) is required for ``box_dim``,
    ``global_dim``, ``global_stride``, and ``element_stride``, and rejected for
    all other fields.

    :param field: Which descriptor field to replace.
    :type field: TensormapField
    :param addr: Pointer/Array to the tensor-map descriptor (global or shared).
    :param new_value: New value for an integer-valued field (coerced to
        ``Int64`` or ``Int32`` by field width).  Mutually exclusive with
        ``new_value_attr``.
    :param ord: Dimension ordinal of the field across the tensor; required for
        ``box_dim`` / ``global_dim`` / ``global_stride`` / ``element_stride``
        and rejected otherwise.  The valid range is enforced by the dialect
        verifier for the target build.
    :param new_value_attr: New value for an enum-valued field, as the matching
        enum (or its string).  Mutually exclusive with ``new_value``.
    :raises ValueError: if ``field`` is not a :class:`TensormapField` (raw NVVM
        dialect enums are rejected); if the wrong one of
        ``new_value`` / ``new_value_attr`` is supplied for the field; if
        ``ord`` is supplied for a field that forbids it or omitted for one that
        requires it, or is outside the dialect's valid range; or if
        ``new_value_attr`` is not
        the enum type the field expects.
    :raises TypeError: if ``ord`` is supplied but is not a Python ``int``.

    .. code-block:: python

        # Patch the source pointer of a copied TMA descriptor at runtime.
        if nvvm.elect_sync():
            nvvm.tensormap_replace(
                nvvm.TensormapField.GLOBAL_ADDRESS, desc_ptr,
                new_value=cutlass.Int64(new_base),
            )
            nvvm.tensormap_replace(
                nvvm.TensormapField.GLOBAL_DIM, desc_ptr,
                new_value=cutlass.Int32(new_dim), ord=0,
            )
    """
    dialect_field = _to_dialect(field, _TENSORMAP_FIELD_TO_DIALECT)
    field = TensormapField(field)

    if field in _TENSORMAP_ORD_FIELDS:
        if ord is None:
            raise ValueError(
                f"tensormap.replace: field '{field}' requires the 'ord' "
                f"(dimension ordinal) parameter"
            )
        if not isinstance(ord, int):
            raise TypeError(
                f"tensormap.replace: ord must be a Python int literal "
                f"(PTX immediate), got {type(ord).__name__}"
            )
        if not (_TENSORMAP_ORD_MIN <= ord <= _TENSORMAP_ORD_MAX):
            raise ValueError(
                f"tensormap.replace: ord must be in "
                f"[{_TENSORMAP_ORD_MIN}, {_TENSORMAP_ORD_MAX}], got {ord}"
            )
    elif ord is not None:
        raise ValueError(
            f"tensormap.replace: field '{field}' does not accept the 'ord' parameter"
        )

    if field in _TENSORMAP_ATTR_INFO:
        if new_value is not None:
            raise ValueError(
                f"tensormap.replace: field '{field}' is enum-valued; pass "
                f"'new_value_attr', not 'new_value'"
            )
        if new_value_attr is None:
            raise ValueError(
                f"tensormap.replace: field '{field}' requires 'new_value_attr'"
            )
        mnemonic, enum_ty = _TENSORMAP_ATTR_INFO[field]
        value_str = _tensormap_value_str(new_value_attr, enum_ty, field)
        attr = ir.Attribute.parse(f"#nvvm.{mnemonic}<{value_str}>")
        return _nvvm.tensormap_replace(
            dialect_field, addr, new_value_attr=attr, loc=loc, ip=ip
        )

    if new_value_attr is not None:
        raise ValueError(
            f"tensormap.replace: field '{field}' is integer-valued; pass "
            f"'new_value', not 'new_value_attr'"
        )
    if new_value is None:
        raise ValueError(f"tensormap.replace: field '{field}' requires 'new_value'")
    coerce = Int64 if field in _TENSORMAP_B64_FIELDS else Int32
    return _nvvm.tensormap_replace(
        dialect_field, addr, new_value=coerce(new_value), ord=ord, loc=loc, ip=ip
    )


@dsl_user_op
def breakpoint(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Suspend the executing thread for an attached debugger.

    Emits ``brkpt``.  Suspends the issuing thread so a debugger can inspect
    state; it is effectively a no-op when no debugger is attached.

    .. code-block:: python

        nvvm.breakpoint()
    """
    _nvvm_raw.breakpoint(loc=loc, ip=ip)


@dsl_user_op
def memory_barrier(
    scope: MemScope,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Order this thread's memory accesses at the given scope.

    Emits ``membar.{scope}``.  Guarantees that the issuing thread's prior
    memory accesses are performed at ``scope`` before any of its subsequent
    accesses.  This is the legacy ``membar`` ordering primitive; prefer
    :func:`fence_proxy` / the acquire-release atomics for finer control.

    :param scope: Scope at which the ordering is observed
        (``"cta"`` / ``"cluster"`` / ``"gpu"`` / ``"sys"``).
    :type scope: MemScope

    .. code-block:: python

        nvvm.memory_barrier("gpu")
    """
    _nvvm_raw.memory_barrier(_MEMSCOPE_TO_DIALECT[scope], loc=loc, ip=ip)


@dsl_user_op
def pmevent(
    event_id: int | None = None,
    *,
    mask: int | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Trigger one or more performance-monitor events.

    Emits ``pmevent`` (single event) or ``pmevent.mask`` (a set of events).
    Exactly one of ``event_id`` / ``mask`` must be given.

    :param event_id: Single event index in ``[0, 15]`` (``pmevent``).
    :type event_id: int | None
    :param mask: 16-bit mask selecting a set of events (``pmevent.mask``);
        bit ``i`` triggers event ``i``.
    :type mask: int | None
    :raises ValueError: neither or both of ``event_id`` / ``mask`` are given,
        ``event_id`` is outside ``[0, 15]``, or ``mask`` is outside
        ``[0, 0xFFFF]``.

    .. code-block:: python

        nvvm.pmevent(event_id=3)
        nvvm.pmevent(mask=0b1010)
    """
    if (event_id is None) == (mask is None):
        raise ValueError("pmevent: pass exactly one of event_id / mask")
    if isinstance(event_id, int) and not 0 <= event_id <= 15:
        raise ValueError(f"pmevent: event_id must be in [0, 15], got {event_id}")
    if isinstance(mask, int) and not 0 <= mask <= 0xFFFF:
        raise ValueError(f"pmevent: mask must be in [0, 0xFFFF], got {mask}")
    masked = _cutlass.Int16(mask) if mask is not None else None
    eid = _cutlass.Int16(event_id) if event_id is not None else None
    _nvvm_raw.pmevent(masked_event_id=masked, event_id=eid, loc=loc, ip=ip)



@dsl_user_op
def mbarrier_inval(
    addr: Array | Pointer,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Invalidate an mbarrier object so its storage can be reused.

    Emits ``mbarrier.inval``.  Marks the mbarrier at ``addr`` invalid; the
    underlying shared-memory bytes may then be repurposed.  Pair with
    :func:`mbarrier_init` to recreate a barrier in the same storage.

    :param addr: Pointer to the mbarrier.  Must reside in shared memory
        (generic addressing into ``.shared`` is also accepted).
    :type addr: Array | Pointer
    :raises TypeError: ``addr`` is a typed operand in an address space other
        than shared or generic.

    .. code-block:: python

        if nvvm.elect_sync():
            nvvm.mbarrier_inval(mbar)
    """
    if hasattr(addr, "space") and addr.space not in (
        _cutlass.AddressSpace.smem,
        _cutlass.AddressSpace.generic,
    ):
        raise TypeError(
            f"mbarrier.inval requires a shared or generic operand, got {addr.space!r}"
        )
    _nvvm.mbarrier_inval(addr, loc=loc, ip=ip)


@dsl_user_op
def read_ptx_sreg_total_smem_size(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Read ``%total_smem_size`` for the executing CTA.

    PTX defines this as the total statically and dynamically allocated CTA
    shared memory, excluding the reserved system region, reported in multiples
    of the target architecture's shared-memory allocation unit.

    .. code-block:: python

        total = nvvm.read_ptx_sreg_total_smem_size()
    """
    return _cutlass.Int32(
        _nvvm.read_ptx_sreg_total_smem_size(_cutlass.Int32.mlir_type, loc=loc, ip=ip)
    )


@dsl_user_op
def read_ptx_sreg_dynamic_smem_size(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Read ``%dynamic_smem_size`` for the executing CTA.

    Emits a read of ``%dynamic_smem_size`` (the dynamic SMEM requested at
    launch, excluding statically-declared SMEM).

    .. code-block:: python

        dyn = nvvm.read_ptx_sreg_dynamic_smem_size()
    """
    return _cutlass.Int32(
        _nvvm.read_ptx_sreg_dynamic_smem_size(_cutlass.Int32.mlir_type, loc=loc, ip=ip)
    )


@dsl_user_op
def read_ptx_sreg_aggr_smem_size(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Read ``%aggr_smem_size`` for the executing CTA.

    PTX defines this as the total CTA shared memory plus the reserved system
    shared-memory region.

    .. code-block:: python

        aggr = nvvm.read_ptx_sreg_aggr_smem_size()
    """
    return _cutlass.Int32(
        _nvvm.read_ptx_sreg_aggr_smem_size(_cutlass.Int32.mlir_type, loc=loc, ip=ip)
    )


@dsl_user_op
def wgmma_fence_aligned(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Fence register accesses around async warpgroup MMA.

    Emits ``wgmma.fence.sync.aligned``.  Orders the executing warpgroup's
    accesses to the registers/shared memory that feed ``wgmma.mma_async``,
    so the async MMA observes a consistent view.  Issue once before the
    first ``wgmma.mma_async`` of a sequence (and after writing its inputs).

    .. code-block:: python

        nvvm.wgmma_fence_aligned()
        # ... wgmma.mma_async issues ...
        nvvm.wgmma_commit_group_sync_aligned()
    """
    _nvvm_raw.wgmma_fence_aligned(loc=loc, ip=ip)


@dsl_user_op
def wgmma_commit_group_sync_aligned(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Commit outstanding async warpgroup MMAs into a group.

    Emits ``wgmma.commit_group.sync.aligned``.  Bundles all ``wgmma.mma_async``
    operations issued by the warpgroup since the last commit into a new group,
    which :func:`wgmma_wait_group_sync_aligned` can later wait on.

    .. code-block:: python

        nvvm.wgmma_commit_group_sync_aligned()
        nvvm.wgmma_wait_group_sync_aligned(0)
    """
    _nvvm_raw.wgmma_commit_group_sync_aligned(loc=loc, ip=ip)


@dsl_user_op
def wgmma_wait_group_sync_aligned(
    group: int,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wait until at most ``group`` async warpgroup-MMA groups are pending.

    Emits ``wgmma.wait_group.sync.aligned``.  Blocks the warpgroup until no
    more than ``group`` previously-committed MMA groups remain in flight;
    ``group=0`` waits for all of them.  Registers written by completed MMAs
    are safe to read afterwards.

    :param group: Maximum number of committed groups allowed to remain
        pending.  Must be a non-negative ``int``.
    :type group: int
    :raises ValueError: ``group`` is a negative ``int``.

    .. code-block:: python

        nvvm.wgmma_wait_group_sync_aligned(0)  # drain all pending MMAs
    """
    if isinstance(group, int) and group < 0:
        raise ValueError(f"wgmma.wait_group: group must be >= 0, got {group}")
    _nvvm_raw.wgmma_wait_group_sync_aligned(group, loc=loc, ip=ip)


@dsl_user_op
def cp_async_mbarrier_arrive(
    addr: Array | Pointer,
    *,
    noinc: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Tie outstanding ``cp.async`` operations to an mbarrier.

    Emits ``cp.async.mbarrier.arrive[.noinc][.shared{::cta}]``.  Causes an asynchronous arrive-on operation to fire
    on the mbarrier at ``addr`` once all prior ``cp.async`` ops issued
    by the executing thread have completed.  This lets a consumer
    block on the mbarrier and only wake when the cp.async data is
    ready, without polling.

    Two semantic flavours via ``noinc``:

    * ``noinc=False`` (default) — pending count is incremented by 1
      before the asynchronous arrive, giving a net-zero effect on the
      pending count for the current phase.  ``mbarrier.init`` only
      needs to account for ``mbarrier.arrive`` arrivals.
    * ``noinc=True`` — no pre-increment.  The asynchronous arrive
      decrement must be pre-accounted for in ``mbarrier.init``'s
      thread-count.  Use when issuing many ``cp.async`` operations
      and aggregating them into a single arrival.

    In a ``cp_async_shared_global`` pipeline, this is the producer's completion signal:
    consumers wait the mbarrier, not ``cp_async_wait_group``.  Count the
    lane-level async-arrives that will be delivered to the mbarrier.  For
    example, a hybrid TMA + per-thread cp.async producer commonly initializes the full
    barrier with ``1 + 32``: one elected-thread TMA arrival plus one
    ``cp_async_mbarrier_arrive(noinc=True)`` from each lane in a cp.async
    warp.  The TMA transaction byte count should not include the cp.async
    bytes because these copies complete through the async arrive path.

    ``cp_async_mbarrier_arrive`` is CTA-local.  In CTA_2 kernels where a
    leader CTA's barrier gates collective MMA, have each CTA's cp.async lanes
    arrive on a local mbarrier, then use a completion-forwarder warp to wait
    the local mbarrier and cross-CTA arrive on the leader barrier with the
    ``shared::cluster`` pointer returned by ``mapa``.

    .. code-block:: python

        # One TMA elected-thread arrival plus 32 cp.async lane arrivals.
        if nvvm.elect_sync():
            nvvm.mbarrier_init(full_mbar + stage, 1 + 32)

        # Each cp.async lane issues its copies, then contributes one
        # asynchronous arrive after its prior cp.async operations retire.
        nvvm.cp_async_shared_global(
            sfa_smem,
            sfa_gmem,
            8,
            "ca",
        )
        nvvm.cp_async_mbarrier_arrive(full_mbar + stage, noinc=True)
    """
    _assert_shared_or_generic(addr, "cp.async.mbarrier.arrive")
    return _nvvm.cp_async_mbarrier_arrive(addr, noinc=noinc, loc=loc, ip=ip)


# =============================================================================
# Helpers
# =============================================================================


# PTX-aligned string literals for tcgen05 ld/st shapes (.shape1 / .shape2 in
# the PTX ISA syntax).  This is the public type for the wrappers' ``shape``
# parameter; the raw NVVM dialect enum lives privately at ``_Tcgen05LdStShape``
# and is reconstructed inside each wrapper before the dialect call.
class Tcgen05LdStShape(StrEnum):
    SHAPE_16X32BX2 = "16x32bx2"
    SHAPE_16X64B = "16x64b"
    SHAPE_32X32B = "32x32b"
    SHAPE_16X128B = "16x128b"
    SHAPE_16X256B = "16x256b"


_TCGEN05_LD_ST_SHAPES: dict[str, _Tcgen05LdStShape] = {
    "16x32bx2": _Tcgen05LdStShape.SHAPE_16X32BX2,
    "16x64b": _Tcgen05LdStShape.SHAPE_16X64B,
    "32x32b": _Tcgen05LdStShape.SHAPE_32X32B,
    "16x128b": _Tcgen05LdStShape.SHAPE_16X128B,
    "16x256b": _Tcgen05LdStShape.SHAPE_16X256B,
}

# Registers per element per shape.
_TCGEN05_REGS_PER_ELEM: dict[str, int] = {
    "16x32bx2": 1,
    "16x64b": 1,
    "32x32b": 1,
    "16x128b": 2,
    "16x256b": 4,
}

# Valid ``.num`` repeat factors for tcgen05 ld/st (powers of 2 in [1, 128]).
_VALID_TCGEN05_NUM = frozenset({1, 2, 4, 8, 16, 32, 64, 128})

# Per-instruction cap on total registers; regs = num * regs/elem.
_TCGEN05_MAX_TOTAL_REGS = 128

_to_ir = DialectAutoConvertProxy._convert_arg


def _raw_nvvm_op_requires_explicit_result(op: Callable[..., object]) -> bool:
    """Return True when a generated raw NVVM op still takes leading ``res``."""
    try:
        parameters = tuple(inspect.signature(op).parameters.values())
    except (TypeError, ValueError):
        return False
    return bool(parameters) and parameters[0].name == "res"


def _call_nvvm_result_compat(
    op: Callable[..., object],
    inferred_result_type: object,
    *operands: object,
    **kwargs: object,
) -> object:
    """Call raw generated ops from either explicit-result or inferred-result builds."""
    if _raw_nvvm_op_requires_explicit_result(op):
        return op(inferred_result_type, *operands, **kwargs)
    return op(*operands, **kwargs)


# Manual wrappers for mbarrier arrive family.
# Result is Optional<I64>: PTX ISA requires sink symbol '_'
# for shared::cluster pointers (address space 7), meaning no return value.
# The wrapper inspects the pointer's address space at trace time.


def _is_cluster_ptr(addr: Array | Pointer) -> bool:
    """Check if addr is in shared::cluster address space."""
    try:
        ir_val = _to_ir(addr, None, None)
        return (
            _llvm.PointerType(ir_val.type).address_space == _cutlass.AddressSpace.dsmem
        )
    except Exception:
        return False


def _assert_shared(obj: Array | Pointer, instruction: str) -> None:
    """Raise TypeError if *obj* does not reside in shared memory.

    For typed wrappers that expose ``.space``, the check fires at trace
    time. Opaque pointers without ``.space`` are accepted here and
    forwarded to the MLIR verifier.
    """
    if hasattr(obj, "space") and obj.space != _cutlass.AddressSpace.smem:
        raise TypeError(
            f"{instruction} requires a shared-memory operand, got {obj.space!r}"
        )


def _assert_shared_or_generic(obj: Array | Pointer, instruction: str) -> None:
    """Raise TypeError if *obj* is in a space that is definitely not shared.

    Use for a shared-memory operand kernels may pass generic-addressed: a
    bulk-copy data tile (source or destination) or an mbarrier pointer.
    Kernels commonly hand these in as ``cutlass.AddressSpace.generic``
    (addr space 0) pointers that the dialect coerces to shared, so GENERIC is
    accepted alongside ``SHARED`` / ``SHARED_CLUSTER``; only an explicitly
    non-shared space (e.g. ``GLOBAL``) is rejected. Opaque pointers without
    ``.space`` are forwarded to the MLIR verifier.
    """
    if hasattr(obj, "space") and obj.space not in (
        _cutlass.AddressSpace.smem,
        _cutlass.AddressSpace.dsmem,
        _cutlass.AddressSpace.generic,
    ):
        raise TypeError(
            f"{instruction} requires a shared-memory source operand, got {obj.space!r}"
        )


def _addrspacecast_to_shared(
    obj: Array | Pointer,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Any:
    """Cast a pointer operand to CTA shared memory for NVVM verifier matching."""
    ir_val = _to_ir(obj, loc, ip)
    return _llvm.addrspacecast(
        _llvm.PointerType.get(_AddressSpace.smem),
        ir_val,
        loc=loc,
        ip=ip,
    )


def _assert_tensor_mem(obj: Array | Pointer, instruction: str) -> None:
    """Raise TypeError if *obj* does not reside in tensor memory (TMEM).

    Mirrors :func:`_assert_shared`: the check fires at trace time for typed
    wrappers that expose ``.space`` (e.g. the ``Array`` returned by
    an addrspace-6 (TMEM) pointer, whose address
    space is ``cutlass.AddressSpace.tmem``). Opaque pointers without ``.space`` are
    accepted here and forwarded to the MLIR verifier, which enforces the
    dialect's ``LLVM_PointerTensor`` operand type.
    """
    if hasattr(obj, "space") and obj.space != _cutlass.AddressSpace.tmem:
        raise TypeError(
            f"{instruction} requires a tensor-memory (TMEM) operand, got {obj.space!r}"
        )


# DSL scalar dtypes that ``nvvm.load.ext`` / ``nvvm.store.ext`` can move:
# the ExtLoadOp/ExtStoreOp verifier accepts integers of width
# {8,16,32,64,128} and only f32/f64 floats.  A 16-bit float (f16/bf16)
# must be moved as ``Int16`` and bitcast by the caller.
_EXT_SCALAR_DTYPES = frozenset(
    {
        Int8,
        Uint8,
        Int16,
        Uint16,
        Int32,
        Uint32,
        Int64,
        Uint64,
        Int128,
        Uint128,
        Float32,
        Float64,
    }
)

# Legal vector widths for ``nvvm.load.ext`` / ``nvvm.store.ext`` -- PTX ``.vec``
# is exactly ``{.v2, .v4, .v8}`` (no .v1/.v3/.v16).  Width-vs-type/space
# restrictions (e.g. .v8 needs a 32-bit type) are left to the backend.
_EXT_VEC_COUNTS = frozenset({2, 4, 8})


def _assert_ext_store_value_dtype(value: ir.Value, instruction: str) -> None:
    """Reject a 16-bit-float store payload before the op is built.

    ``nvvm.store.ext`` accepts only integers of width {8,16,32,64,128} and
    f32/f64; a half (f16/bf16) value otherwise fails the MLIR verifier with a
    cryptic message.  Best-effort: when the value's MLIR type can't be resolved
    statically we pass through and let the verifier decide.
    """
    ty = getattr(value, "type", None)
    if not isinstance(ty, ir.Type):
        ir_value = getattr(value, "ir_value", None)
        if callable(ir_value):
            try:
                ty = ir_value().type
            except Exception:
                ty = None
    if not isinstance(ty, ir.Type):
        return
    if ir.VectorType.isinstance(ty):
        ty = ir.VectorType(ty).element_type
    if ir.F16Type.isinstance(ty) or ir.BF16Type.isinstance(ty):
        raise TypeError(
            f"{instruction}: cannot store a 16-bit float directly "
            "(nvvm.store.ext supports only b8/b16/b32/b64/b128 + f32/f64); "
            "bitcast the value to Int16 first."
        )


def _assert_load_ext_qualifiers(
    order: MemOrder | None,
    scope: MemScope | None,
    cache_modifier: LoadCacheModifier | None,
    evict: L1EvictKind | None,
    l2_cache_hint: object,
    prefetch: L2PrefetchSize | None,
    unified: bool | None,
    shared_space: SharedSpace | None,
    instruction: str,
) -> None:
    """Fail-fast checks for the statically-known ``nvvm.load.ext`` qualifier
    combinations, mirroring the ``ExtLoadOp`` verifier and the PTX ISA ``ld``
    constraints.

    Only enum / presence combinations (all known at trace time) are checked
    here.  The pointer's actual address space and any runtime ``l2_cache_hint``
    value are left to the MLIR verifier.  See :func:`load_ext` for the surfaced
    ``:raises:`` list.
    """
    # Cache ops (.ca/.cg/.cs/.lu/.cv) are mutually exclusive with an eviction
    # priority and are only legal on the (default) .weak form.
    if cache_modifier is not None:
        if evict is not None:
            raise ValueError(
                f"{instruction}: cache_modifier and evict are mutually exclusive"
            )
        if order is not None and order != MemOrder.WEAK:
            raise ValueError(
                f"{instruction}: cache_modifier is only allowed with weak "
                f"(default) ordering, got order={order}"
            )
    # .relaxed / .acquire require an explicit scope.
    if order in (MemOrder.RELAXED, MemOrder.ACQUIRE) and scope is None:
        raise ValueError(f"{instruction}: order={order} requires an explicit scope")
    # .volatile forbids cache ops/hints and the .unified qualifier.  PTX
    # `ld.volatile{.level::prefetch_size}{.vec}` DOES allow prefetch and vec, so
    # those are intentionally not rejected here.
    if order == MemOrder.VOLATILE:
        if cache_modifier is not None or evict is not None or l2_cache_hint is not None:
            raise ValueError(
                f"{instruction}: volatile ordering forbids cache_modifier, "
                f"evict, and l2_cache_hint"
            )
        if unified:
            raise ValueError(f"{instruction}: volatile ordering forbids unified")
    # .mmio is system-scoped only.
    if order == MemOrder.MMIO and scope != MemScope.SYS:
        raise ValueError(
            f"{instruction}: mmio ordering requires scope=MemScope.SYS, got "
            f"scope={scope}"
        )
    # Shared-space loads cannot carry L2 cache-hint / prefetch / unified / mmio
    # qualifiers (those apply only to generic or global address spaces).
    if shared_space is not None:
        bad = [
            name
            for name, val in (
                ("l2_cache_hint", l2_cache_hint),
                ("prefetch", prefetch),
            )
            if val is not None
        ]
        if unified:
            bad.append("unified")
        if order == MemOrder.MMIO:
            bad.append("order=mmio")
        if bad:
            raise ValueError(
                f"{instruction}: shared-space load is incompatible with "
                f"{', '.join(bad)} (those apply only to generic/global space)"
            )


def _assert_store_ext_qualifiers(
    order: MemOrder | None,
    scope: MemScope | None,
    cache_modifier: StoreCacheModifier | None,
    evict: L1EvictKind | None,
    l2_cache_hint: object,
    shared_space: SharedSpace | None,
    instruction: str,
) -> None:
    """Fail-fast checks for the statically-known ``nvvm.store.ext`` qualifier
    combinations, mirroring the ``ExtStoreOp`` verifier and the PTX ISA ``st``
    constraints.

    The store side mirrors :func:`_assert_load_ext_qualifiers`, except the
    ordered form is ``relaxed`` / ``release`` (not ``acquire``) and ``st`` has
    no ``prefetch`` / ``unified`` qualifiers.
    """
    # Cache ops (.wb/.cg/.cs/.wt) are mutually exclusive with an eviction
    # priority and are only legal on the (default) .weak form.
    if cache_modifier is not None:
        if evict is not None:
            raise ValueError(
                f"{instruction}: cache_modifier and evict are mutually exclusive"
            )
        if order is not None and order != MemOrder.WEAK:
            raise ValueError(
                f"{instruction}: cache_modifier is only allowed with weak "
                f"(default) ordering, got order={order}"
            )
    # .relaxed / .release require an explicit scope.
    if order in (MemOrder.RELAXED, MemOrder.RELEASE) and scope is None:
        raise ValueError(f"{instruction}: order={order} requires an explicit scope")
    # .volatile forbids any cache op / hint.
    if order == MemOrder.VOLATILE and (
        cache_modifier is not None or evict is not None or l2_cache_hint is not None
    ):
        raise ValueError(
            f"{instruction}: volatile ordering forbids cache_modifier, evict, "
            f"and l2_cache_hint"
        )
    # .mmio is system-scoped only.
    if order == MemOrder.MMIO and scope != MemScope.SYS:
        raise ValueError(
            f"{instruction}: mmio ordering requires scope=MemScope.SYS, got "
            f"scope={scope}"
        )
    # Shared-space stores cannot carry an L2 cache-hint or mmio qualifier
    # (those apply only to generic or global address spaces).
    if shared_space is not None:
        bad = []
        if l2_cache_hint is not None:
            bad.append("l2_cache_hint")
        if order == MemOrder.MMIO:
            bad.append("order=mmio")
        if bad:
            raise ValueError(
                f"{instruction}: shared-space store is incompatible with "
                f"{', '.join(bad)} (those apply only to generic/global space)"
            )


# Valid nCols for tcgen05.alloc / tcgen05.dealloc:
# must be a power of 2 in [32, 512].
_TCGEN05_REGULAR_NCOLS = frozenset({32, 64, 128, 256, 512})
_TCGEN05_SPECIAL_NCOLS = set()
_TCGEN05_VALID_NCOLS = frozenset().union(_TCGEN05_REGULAR_NCOLS, _TCGEN05_SPECIAL_NCOLS)


def _assert_tcgen05_ncols(n_cols: int | Int32 | Uint32, instruction: str) -> None:
    """Validate ``nCols`` for tcgen05.alloc / dealloc at trace time.

    Statically known ``int`` values are checked against the whitelist
    ``{32, 64, 128, 256, 512}``. Dynamic IR values pass through — the
    kernel will fault at runtime if invalid.
    """
    if isinstance(n_cols, int) and n_cols not in _TCGEN05_VALID_NCOLS:
        raise ValueError(
            f"{instruction}: nCols must be a power of 2 in [32, 512], got {n_cols}"
        )


def _to_dialect(value: object, mapping: dict) -> Any:
    """Translate a ``StrEnum`` member (or bare string) to its NVVM
    dialect enum member.

    Returns ``None`` when ``value`` is ``None`` so wrappers can pass the
    parameter through unchanged for "use the dialect default" semantics.

    Raises ``ValueError`` if ``value`` is not a recognised ``StrEnum``
    member / string.  In particular, raw NVVM dialect enums (e.g.
    ``cutlass._mlir.dialects.nvvm.ShflKind.idx``) are *rejected*: the public
    surface accepts only the wrapper-owned ``StrEnum`` twins (or their bare
    string values).
    """
    if value is None:
        return None
    try:
        return mapping[value]
    except KeyError:
        valid = ", ".join(repr(str(k)) for k in mapping)
        raise ValueError(
            f"expected a StrEnum member or its string value "
            f"(one of: {valid}), got {value!r}. Raw NVVM dialect enums are "
            f"no longer accepted by these wrappers."
        ) from None


def _to_load_mode(mode: TMALoadMode | None) -> Any:
    """Translate a ``TMALoadMode`` to its dialect attr, version-gating the
    PTX-ISA-9.3-only modes.

    ``im2col_w`` / ``im2col_w_128`` require PTX ISA 9.3 (CTK 13.3); reject them
    on an older toolkit with a clear trace-time error instead of a backend
    "cannot select".  Shared by every TMA-tensor wrapper that forwards a
    ``mode``.
    """
    if mode in (TMALoadMode.IM2COL_W, TMALoadMode.IM2COL_W_128):
        _assert_ptx_9_3("im2col_w / im2col_w_128 TMA mode", "TMA tensor op")
    return _to_dialect(mode, _TMA_LOAD_MODE_TO_DIALECT)


# CTA-group selector for tcgen05.{alloc,mma,...}.
#
# Lowercase members match the PTX modifier (``.cta_group::1`` /
# ``.cta_group::2``).
class CTAGroup(StrEnum):
    CTA_1 = "cta_1"
    CTA_2 = "cta_2"


_CTAGROUP_TO_DIALECT = {
    "cta_1": _CTAGroupKindDialect.CTA_1,
    "cta_2": _CTAGroupKindDialect.CTA_2,
}


# Valid ``mma_kind`` for the ``scale-input-d`` modifier of ``tcgen05.mma``.
# PTX ISA 9.3: "scale-input-d is only valid for .kind::tf32 and .kind::f16".
_TCGEN05_SCALE_INPUT_D_KINDS = frozenset({Tcgen05MMAKind.F16, Tcgen05MMAKind.TF32})

# ``disableOutputLane`` (write_disable_mask) element count by CTA group:
# vector<4xi32> for CTA_1 (128 M-rows), vector<8xi32> for CTA_2 (256 M-rows).
_TCGEN05_WDM_LEN = {CTAGroup.CTA_1: 4, CTAGroup.CTA_2: 8}


def _assert_tcgen05_scale_input_d(
    scale_input_d: int | Int64 | Uint64 | None,
    mma_kind: Tcgen05MMAKind,
    instruction: str,
) -> None:
    """Validate the ``scale-input-d`` modifier of ``tcgen05.mma`` at trace time.

    PTX ISA 9.3 allows ``scale-input-d`` only for ``.kind::f16`` /
    ``.kind::tf32``; the immediate must be in ``[0, 15]``.  The kind is always
    checked (it is a static enum); the range is checked for statically known
    ``int`` values and dynamic IR values are forwarded as-is.
    """
    if scale_input_d is None:
        return
    if mma_kind not in _TCGEN05_SCALE_INPUT_D_KINDS:
        raise ValueError(
            f"{instruction}: scale_input_d is only valid for kind::f16 and "
            f"kind::tf32, got {mma_kind!r}"
        )
    if isinstance(scale_input_d, int) and not (0 <= scale_input_d <= 15):
        raise ValueError(
            f"{instruction}: scale_input_d must be in [0, 15], got {scale_input_d}"
        )


def _assert_tcgen05_write_disable_mask(
    mask: Vector | None, cta_group: CTAGroup, instruction: str
) -> None:
    """Validate ``write_disable_mask`` length matches the CTA group.

    ``disableOutputLane`` is ``vector<4xi32>`` for ``CTA_1`` and
    ``vector<8xi32>`` for ``CTA_2``.  The length is checked when statically
    known (a ``Vector`` whose ``numel`` resolves, or a tuple/list); otherwise
    the MLIR verifier enforces the fixed vector width.
    """
    if mask is None:
        return
    expected = _TCGEN05_WDM_LEN.get(cta_group)
    if expected is None:
        return
    n = None
    if isinstance(mask, (tuple, list)):
        n = len(mask)
    elif hasattr(mask, "numel"):
        try:
            n = mask.numel()
        except Exception:
            n = None
    if n is not None and n != expected:
        raise ValueError(
            f"{instruction}: write_disable_mask must have {expected} elements "
            f"for {cta_group}, got {n}"
        )


# ``tcgen05.cp`` shape -> allowed ``multicast`` policies (PTX ISA constraints):
# the wide shapes take no multicast; ``64x128b`` requires
# ``warpx2::{01_23,02_13}``; ``32x128b`` requires ``warpx4``.
_TCGEN05_CP_VALID_MULTICAST = {
    Tcgen05CpShape.SHAPE_128X256B: frozenset({None}),
    Tcgen05CpShape.SHAPE_128X128B: frozenset({None}),
    Tcgen05CpShape.SHAPE_4X256B: frozenset({None}),
    Tcgen05CpShape.SHAPE_64X128B: frozenset(
        {Tcgen05CpMulticast.WARPX2_01_23, Tcgen05CpMulticast.WARPX2_02_13}
    ),
    Tcgen05CpShape.SHAPE_32X128B: frozenset({Tcgen05CpMulticast.WARPX4}),
}


def _assert_tcgen05_cp_multicast(
    shape: Tcgen05CpShape,
    multicast: Tcgen05CpMulticast | None,
    instruction: str,
) -> None:
    """Validate the ``tcgen05.cp`` shape<->multicast coupling at trace time.

    The wide shapes (``128x256b`` / ``128x128b`` / ``4x256b``) take no
    multicast; ``64x128b`` requires ``warpx2::{01_23,02_13}``; ``32x128b``
    requires ``warpx4``.  Unknown shapes are forwarded to the MLIR verifier.
    """
    valid = _TCGEN05_CP_VALID_MULTICAST.get(shape)
    if valid is None:
        return
    if multicast not in valid:
        names = ", ".join("None" if v is None else str(v) for v in valid)
        raise ValueError(
            f"{instruction}: shape {shape!r} requires multicast in "
            f"{{{names}}}, got {multicast!r}"
        )


# Valid ``mma_kind`` for ``tcgen05.mma.block_scale`` (PTX ISA "Block Scaling
# for tcgen05.mma").  Keyed by the lowercase member name so the wrapper StrEnum,
# a bare string, and the raw NVVM block-scale kind all resolve the same way.
_TCGEN05_BLOCK_SCALE_VALID_KIND_NAMES = frozenset(
    {
        "mxf8f6f4",
        "mxf4",
        "mxf4nvf4",
    }
)


def _assert_tcgen05_block_scale_kind(
    mma_kind: Tcgen05MMAKind, instruction: str
) -> None:
    """Validate that ``mma_kind`` is a block-scaled kind at trace time.

    ``tcgen05.mma.block_scale`` accepts only the block-scaled kinds
    (``mxf8f6f4`` / ``mxf4`` / ``mxf4nvf4``).  Non-block-scaled kinds (e.g.
    ``f16``) should use :func:`tcgen05_mma` instead.
    """
    key = mma_kind.name.lower() if hasattr(mma_kind, "name") else mma_kind
    if key not in _TCGEN05_BLOCK_SCALE_VALID_KIND_NAMES:
        raise ValueError(
            f"{instruction}: block_scale requires a block-scaled mma_kind "
            f"(mxf8f6f4, mxf4, mxf4nvf4), got {mma_kind!r}"
        )


# Valid swizzle modes for the tcgen05.mma SMEM descriptor: 0 (none), 1, 2
# (128B XOR), 4 (64B XOR), 6 (32B XOR).
_TCGEN05_VALID_SWIZZLE_MODES = frozenset({0, 1, 2, 4, 6})


def _assert_tcgen05_swizzle(swizzle: int | Int8 | Uint8, instruction: str) -> None:
    """Validate the SMEM-descriptor swizzle mode at trace time.

    Statically known ``int`` values must be in ``{0, 1, 2, 4, 6}``; dynamic
    IR values are forwarded as-is.
    """
    if isinstance(swizzle, int) and swizzle not in _TCGEN05_VALID_SWIZZLE_MODES:
        raise ValueError(
            f"{instruction}: swizzle must be in "
            f"{sorted(_TCGEN05_VALID_SWIZZLE_MODES)}, got {swizzle}"
        )


# =============================================================================
# @dsl_user_op wrapper functions
# =============================================================================





def _packed_f32x2_to_vec(
    x: tuple | Vector,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Accept a 2-tuple of f32 scalars OR a ``Vector``; return a ``Vector``."""
    if isinstance(x, tuple):
        return Vector.from_elements(x, _cutlass.Float32, loc=loc, ip=ip)
    return x


def _unpack_packed_f32x2(vec: Vector) -> tuple:
    """Extract a 2-element f32x2 ``Vector`` result into a ``(Float32, Float32)``."""
    return _cutlass.Float32(vec[0]), _cutlass.Float32(vec[1])


@dsl_user_op
def add_packed_f32x2(
    src_a: tuple | Vector,
    src_b: tuple | Vector,
    *,
    rnd: FPRoundingMode | None = None,
    ftz: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> tuple | Vector:
    """Wrapper over ``nvvm.add_packed_f32x2``.

    Accepts a 2-tuple of f32 scalars or a ``Vector`` for each operand and
    returns a tuple when called with tuples, else a ``Vector``
    """
    returns_tuple = isinstance(src_a, tuple)
    vec_a = _packed_f32x2_to_vec(src_a, loc=loc, ip=ip)
    vec_b = _packed_f32x2_to_vec(src_b, loc=loc, ip=ip)
    vec_a_ir = _to_ir(vec_a, loc, ip)
    vec_res = _call_nvvm_result_compat(
        _nvvm_raw.add_packed_f32x2,
        vec_a_ir.type,
        vec_a_ir,
        _to_ir(vec_b, loc, ip),
        rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
        ftz=ftz,
        loc=loc,
        ip=ip,
    )
    return _unpack_packed_f32x2(vec_res) if returns_tuple else vec_res




@dsl_user_op
def bar_warp_sync(
    mask: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Rendezvous all lanes named in *mask* at a warp-level barrier.

    Maps to PTX ``bar.warp.sync membermask``.  Every lane whose bit is set in
    *mask* must execute this call before any of them may proceed.  The barrier
    also acts as an acquire-release memory fence: stores to shared or global
    memory issued by any lane in *mask* before the call are visible to all other
    lanes in *mask* after it, and loads issued after the call observe those
    stores.  Use ``cute.arch.FULL_MASK`` (``0xFFFFFFFF``) to rendezvous all 32 lanes;
    pass a narrower mask to synchronize only a known active subset.

    This is the warp-level equivalent of ``__syncwarp(mask)`` in CUDA C++.

    **Constraints:**

    * Every lane named in *mask* must reach ``bar_warp_sync`` with the
      **same** *mask* value.  If any named lane diverges (e.g. is inside a
      branch only some lanes take), the remaining lanes stall indefinitely.
    * Do not call inside a branch unless **all** lanes in *mask* are guaranteed
      to enter that branch.

    .. code-block:: python

        # All 32 lanes rendezvous in a uniform region (SMEM read-after-write)
        nvvm.bar_warp_sync(cute.arch.FULL_MASK)

        # Warp-specialization: all lanes converge before diverging by role.
        # bar_warp_sync guarantees every lane sees any prior register/SMEM
        # writes (e.g. from nvvm.setmaxregister) before the if-branch.
        warp = cute.arch.warp_idx()
        is_tma_warp = warp == cutlass.Int32(0)
        nvvm.setmaxregister(40, "decrease")
        nvvm.bar_warp_sync(cute.arch.FULL_MASK)   # all lanes rendezvous here
        if is_tma_warp:
            ...  # TMA producer path
        else:
            ...  # compute consumer path

        # Partial mask — only lanes 0–15 synchronize (must all be active)
        nvvm.bar_warp_sync(0x0000FFFF)

    :param mask: 32-bit member mask; bit *i* set means lane *i* participates.
        All participating lanes must execute this call with the **same** *mask*
        value or the remaining lanes stall indefinitely.
        Pass ``cute.arch.FULL_MASK`` (``0xFFFFFFFF``) for all 32 lanes.
    :type mask: int or cutlass.Int32 or cutlass.Uint32
    :raises ValueError: if a static ``int`` *mask* does not fit in 32 bits
        (outside ``[0, 0xFFFFFFFF]``).  Runtime ``Int32`` / ``Uint32`` values
        pass through unchecked.
    """
    _assert_mask32(mask, "bar.warp.sync")
    _nvvm.bar_warp_sync(
        _cutlass.Int32(mask),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def barrier_cta_arrive(
    barrier_id: int | Int32 | Uint32,
    thread_count: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Signal arrival at a named CTA barrier without waiting.

    Emits ``barrier.cta.arrive a, b;`` (non-aligned).  Works in any
    control flow, including divergent on sm_70+.  Producer/consumer
    pairs use the arrive/sync split: the producer arrives and runs ahead
    while the consumer :func:`barrier_cta_sync` blocks until the count
    is reached.  Each CTA has 16 named barrier slots (``barrier_id`` in
    0..15).

    For the aligned variant (``barrier.cta.arrive.aligned``, equivalent
    to the legacy ``bar.cta.arrive``) use :func:`barrier_cta_arrive_aligned`
    — that form promises that every CTA thread executes the barrier
    and is undefined behavior under divergent control flow.

    :param barrier_id: Barrier slot ID in 0..15.  Must match the consumer's id.
    :type barrier_id: int or Int32 or Uint32
    :param thread_count: Number of participating threads.  Required by PTX
        for ``barrier.cta.arrive``; must be a non-zero multiple of the warp
        size (32) and consistent across all arrive/sync calls on this slot.
    :type thread_count: int or Int32 or Uint32
    :raises ValueError: if a static ``barrier_id`` is outside ``[0, 15]`` or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        # Producer warps signal arrival, then continue work
        if warp < N_PRODUCERS:
            nvvm.barrier_cta_arrive(0, (N_PRODUCERS + N_CONSUMERS) * 32)
            # ... continue producing ...
        else:
            # Consumer warps wait at the same id
            nvvm.barrier_cta_sync(0, thread_count=(N_PRODUCERS + N_CONSUMERS) * 32)
            # ... safe to read producer outputs ...
    """
    _assert_barrier_id(barrier_id, "barrier.cta.arrive")
    _assert_thread_count(thread_count, "barrier.cta.arrive")
    _nvvm.barrier_cta_arrive(
        _cutlass.Int32(barrier_id),
        _cutlass.Int32(thread_count),
        aligned=False,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def barrier_cta_arrive_aligned(
    barrier_id: int | Int32 | Uint32,
    thread_count: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Aligned variant of :func:`barrier_cta_arrive`.

    Emits ``barrier.cta.arrive.aligned a, b;`` — equivalent to the legacy
    ``bar.cta.arrive``.  Promises that every CTA thread executes this
    barrier in convergence; undefined behavior on sm_70+ when a strict
    subset of CTA threads reaches the instruction.  Use this only when
    the call site is provably all-CTA-converged; otherwise fall back to
    the non-aligned :func:`barrier_cta_arrive`.

    :param barrier_id: Barrier slot ID in 0..15.  Must match the consumer's id.
    :type barrier_id: int or Int32 or Uint32
    :param thread_count: Number of participating threads.  Non-zero
        multiple of the warp size (32), consistent across arrive/sync
        calls on this slot.
    :type thread_count: int or Int32 or Uint32
    :raises ValueError: if a static ``barrier_id`` is outside ``[0, 15]`` or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        # Every CTA thread reaches this barrier, no divergent guards above
        nvvm.barrier_cta_arrive_aligned(0, threads_per_cta)
    """
    _assert_barrier_id(barrier_id, "barrier.cta.arrive.aligned")
    _assert_thread_count(thread_count, "barrier.cta.arrive.aligned")
    _nvvm.barrier_cta_arrive(
        _cutlass.Int32(barrier_id),
        _cutlass.Int32(thread_count),
        aligned=True,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def barrier_cta_red(
    pred: int | Boolean,
    barrier_id: int | Int32 | Uint32,
    kind: BarrierRedux,
    *,
    thread_count: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Boolean:
    """Synchronize a CTA barrier and reduce a predicate.

    Emits the ``barrier.cta.red.{popc,and,or}`` family (non-aligned).
    The call marks the issuing thread's arrival at a named CTA barrier,
    waits until the barrier's participant count is reached, then
    broadcasts the predicate reduction result to every waiting thread.

    For the aligned variant (``.aligned`` modifier, equivalent to the
    legacy ``bar.cta.red``) use :func:`barrier_cta_red_aligned` — that
    form promises all CTA threads execute the barrier and is undefined
    behavior under divergent control flow.

    Reduction kinds (selected by ``kind``):

    * ``"and"`` → ``.and.pred`` — returns :class:`Boolean`,
      ``True`` iff every participant contributed ``pred=True``.
    * ``"or"`` → ``.or.pred`` — returns :class:`Boolean`,
      ``True`` iff any participant contributed ``pred=True``.
    * ``"popc"`` → ``.popc.u32`` — returns :class:`Int32`,
      the count of participants whose ``pred`` was ``True``.

    Do not mix ``barrier_cta_red`` with the non-reducing variants
    (:func:`barrier_cta_sync`, :func:`barrier_cta_arrive`) on the same
    active barrier generation.  PTX marks that use as unpredictable; use
    a different ``barrier_id`` or wait for the barrier to complete and
    reinitialize before reusing it.

    :param pred: Per-thread predicate contributed to the reduction.
    :type pred: int or Boolean
    :param barrier_id: CTA barrier slot ID in 0..15.
    :type barrier_id: int or Int32 or Uint32
    :param kind: Reduction kind — ``"and"`` / ``"or"`` yield :class:`Boolean`,
        ``"popc"`` yields :class:`Int32`.
    :type kind: BarrierRedux
    :param thread_count: Number of participating threads.  Omit for all CTA
        threads; otherwise pass a non-zero multiple of the warp size and
        keep it consistent across participants on this slot.
    :type thread_count: int or Int32 or Uint32, optional
    :return: For AND/OR: the reduced :class:`Boolean` broadcast to all
        participants.  For POPC: the count :class:`Int32`.
    :raises ValueError: if ``kind`` is not one of ``"and"`` / ``"or"`` /
        ``"popc"``, if a static ``barrier_id`` is outside ``[0, 15]``, or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        tx, _, _ = cute.arch.thread_idx()

        any_lane_zero = nvvm.barrier_cta_red(
            tx == 0,
            barrier_id=0,
            kind="or",
            thread_count=64,
        )
        all_in_range = nvvm.barrier_cta_red(
            tx < 64,
            barrier_id=1,
            kind="and",
            thread_count=64,
        )
        n_true = nvvm.barrier_cta_red(   # returns Int32
            tx % 2 == 0,
            barrier_id=2,
            kind="popc",
            thread_count=64,
        )
    """
    _assert_barrier_id(barrier_id, "barrier.cta.red")
    _assert_barrier_redux(kind, "barrier.cta.red")
    if thread_count is not None:
        _assert_thread_count(thread_count, "barrier.cta.red")
        thread_count = _cutlass.Int32(thread_count)
    result = _nvvm.barrier_cta_red(
        _cutlass.Boolean(pred),
        _cutlass.Int32(barrier_id),
        _BARRIER_REDUX_TO_DIALECT[kind],
        thread_count=thread_count,
        aligned=False,
        loc=loc,
        ip=ip,
    )
    if kind == "popc":
        return _cutlass.Int32(result)
    return _cutlass.Boolean(result)


@dsl_user_op
def barrier_cta_red_aligned(
    pred: int | Boolean,
    barrier_id: int | Int32 | Uint32,
    kind: BarrierRedux,
    *,
    thread_count: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Boolean:
    """Aligned variant of :func:`barrier_cta_red`.

    Emits ``barrier.cta.red.{popc,and,or}.aligned`` — equivalent to the
    legacy ``bar.cta.red``.  Promises that every CTA thread executes this
    barrier in convergence; undefined behavior on sm_70+ when a strict
    subset of CTA threads reaches the instruction.  Use this only when
    the call site is provably all-CTA-converged; otherwise fall back to
    the non-aligned :func:`barrier_cta_red`.

    Reduction kinds and return-type rules match :func:`barrier_cta_red`.

    :param pred: Per-thread predicate contributed to the reduction.
    :type pred: int or Boolean
    :param barrier_id: CTA barrier slot ID in 0..15.
    :type barrier_id: int or Int32 or Uint32
    :param kind: Reduction kind — ``"and"`` / ``"or"`` yield :class:`Boolean`,
        ``"popc"`` yields :class:`Int32`.
    :type kind: BarrierRedux
    :param thread_count: Number of participating threads.  Omit for all
        CTA threads; otherwise a non-zero multiple of the warp size and
        consistent across the barrier slot.
    :type thread_count: int or Int32 or Uint32, optional
    :return: For AND/OR: the reduced :class:`Boolean`.  For POPC: the count :class:`Int32`.
    :raises ValueError: if ``kind`` is not one of ``"and"`` / ``"or"`` /
        ``"popc"``, if a static ``barrier_id`` is outside ``[0, 15]``, or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        # Every CTA thread reaches this reduction barrier
        all_true = nvvm.barrier_cta_red_aligned(
            tx < threads_per_cta,
            barrier_id=0,
            kind="and",
        )
    """
    _assert_barrier_id(barrier_id, "barrier.cta.red.aligned")
    _assert_barrier_redux(kind, "barrier.cta.red.aligned")
    if thread_count is not None:
        _assert_thread_count(thread_count, "barrier.cta.red.aligned")
        thread_count = _cutlass.Int32(thread_count)
    result = _nvvm.barrier_cta_red(
        _cutlass.Boolean(pred),
        _cutlass.Int32(barrier_id),
        _BARRIER_REDUX_TO_DIALECT[kind],
        thread_count=thread_count,
        aligned=True,
        loc=loc,
        ip=ip,
    )
    if kind == "popc":
        return _cutlass.Int32(result)
    return _cutlass.Boolean(result)


@dsl_user_op
def barrier_cta_sync(
    barrier_id: int | Int32 | Uint32 = 0,
    *,
    thread_count: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Synchronize threads at a named CTA barrier.

    Emits ``barrier.cta.sync a{, b};`` (non-aligned).  Works in any
    control flow, including divergent on sm_70+.  All participants at
    slot ``barrier_id`` wait until ``thread_count`` of them have arrived,
    then proceed together.  Omit ``thread_count`` for the "all CTA
    threads" rendezvous.  ``nvvm.barrier_cta_sync()`` with no arguments
    is the ``__syncthreads()`` equivalent (slot 0, all CTA threads).

    For the aligned variant (``barrier.cta.sync.aligned``, equivalent to
    the legacy ``bar.cta.sync``) use :func:`barrier_cta_sync_aligned` —
    that form promises every CTA thread executes the barrier and is
    undefined behavior under divergent control flow.

    :param barrier_id: Barrier slot ID in 0..15.
    :type barrier_id: int or Int32 or Uint32
    :param thread_count: Number of participating threads.  Omit for all CTA
        threads; otherwise pass a non-zero multiple of the warp size and
        keep it consistent across all uses of this barrier slot.
    :type thread_count: int or Int32 or Uint32, optional
    :raises ValueError: if a static ``barrier_id`` is outside ``[0, 15]`` or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        # All CTA threads sync (equivalent to __syncthreads at slot 0)
        nvvm.barrier_cta_sync(0)

        # Only warps 2–3 (64 threads) sync at slot 1
        nvvm.barrier_cta_sync(1, thread_count=64)

    .. note::

        In warp-specialized kernels, a slot-0 all-CTA sync stalls *every*
        warp, including idle producer warps.  Use a named barrier scoped
        to the relevant warps, or use per-consumer ``mbarrier`` signals
        instead.
    """
    _assert_barrier_id(barrier_id, "barrier.cta.sync")
    if thread_count is not None:
        _assert_thread_count(thread_count, "barrier.cta.sync")
        thread_count = _cutlass.Int32(thread_count)
    _nvvm.barrier_cta_sync(
        _cutlass.Int32(barrier_id),
        thread_count=thread_count,
        aligned=False,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def barrier_cta_sync_aligned(
    barrier_id: int | Int32 | Uint32 = 0,
    *,
    thread_count: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Aligned variant of :func:`barrier_cta_sync`.

    Emits ``barrier.cta.sync.aligned a{, b};`` — equivalent to the legacy
    ``bar.cta.sync``.  Promises that every CTA thread executes this
    barrier in convergence; undefined behavior on sm_70+ when a strict
    subset of CTA threads reaches the instruction.  Use this only when
    the call site is provably all-CTA-converged; otherwise fall back to
    the non-aligned :func:`barrier_cta_sync`.

    :param barrier_id: Barrier slot ID in 0..15.
    :type barrier_id: int or Int32 or Uint32
    :param thread_count: Number of participating threads.  Omit for all
        CTA threads; otherwise a non-zero multiple of the warp size and
        consistent across the barrier slot.
    :type thread_count: int or Int32 or Uint32, optional
    :raises ValueError: if a static ``barrier_id`` is outside ``[0, 15]`` or a
        static ``thread_count`` is not a positive multiple of 32.  Runtime
        ``Int32`` / ``Uint32`` values pass through unchecked.

    .. code-block:: python

        # Every CTA thread reaches this barrier (no divergent guards above)
        nvvm.barrier_cta_sync_aligned(0)
    """
    _assert_barrier_id(barrier_id, "barrier.cta.sync.aligned")
    if thread_count is not None:
        _assert_thread_count(thread_count, "barrier.cta.sync.aligned")
        thread_count = _cutlass.Int32(thread_count)
    _nvvm.barrier_cta_sync(
        _cutlass.Int32(barrier_id),
        thread_count=thread_count,
        aligned=True,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def convert_and_pack_integer(
    src_a: int | Int32 | Uint32,
    src_b: int | Int32 | Uint32,
    convert_type: ir.Type,
    *,
    src_c: int | Int32 | Uint32 | None = None,
    is_signed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.convert_and_pack_integer``."""
    if hasattr(convert_type, "mlir_type"):
        convert_type = convert_type.mlir_type
    if isinstance(convert_type, ir.Type):
        convert_type = ir.TypeAttr.get(convert_type)
    if src_c is not None:
        src_c = _cutlass.Int32(src_c)
    return _cutlass.Int32(
        _nvvm.convert_and_pack_integer(
            _cutlass.Int32(src_a),
            _cutlass.Int32(src_b),
            convert_type,
            src_c=src_c,
            is_signed=is_signed,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def cp_async_bulk_global_shared_cta(
    dst_mem: Array | Pointer,
    src_mem: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    byte_mask: int | Int16 | Uint16 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Async bulk-copy a byte range from CTA shared memory to global memory.

    Emits the ``.shared::cta -> .global`` form of ``cp.async.bulk`` with
    ``.bulk_group`` completion: ``cp.async.bulk.global.shared::cta.bulk_group
    [dst], [src], size;``.  Copies a byte range from SMEM to GMEM without a
    tensor-map descriptor; useful for 1-D / flat buffers where TMA setup is
    not justified.  ``size`` must be a positive multiple of 16 and both
    ``dst_mem`` and ``src_mem`` must be 16-byte aligned (the PTX ISA leaves
    non-conforming values undefined).  The wrapper exposes the full option set this
    direction has in PTX (unchanged across ISA 8.8 and 9.3): the
    ``.L2::cache_hint`` cache policy (``l2_cache_hint``) and the ``.cp_mask``
    byte mask (``byte_mask``).

    :param dst_mem: GMEM destination pointer/array (the ``[dst]`` operand);
        must be 16-byte aligned.
    :type dst_mem: cutlass.Array or cutlass.Pointer
    :param src_mem: CTA-scope SMEM source pointer/array (the ``[src]`` operand);
        must be 16-byte aligned.
    :type src_mem: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to copy; must be a positive multiple of 16.
    :type size: int or cutlass.Int32 or cutlass.Uint32
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor
        (emits ``.L2::cache_hint`` with the policy operand).  Defaults to None.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :param byte_mask: Optional 16-bit ``.cp_mask`` selecting which bytes of
        each 16-byte source chunk are written: bit *i* set copies byte *i* of
        every 16-byte chunk, bit *i* clear skips it.  Defaults to None (all
        bytes copied).
    :type byte_mask: int or cutlass.Int16 or cutlass.Uint16, optional
    :raises TypeError: if ``src_mem`` exposes an address space that is not
        shared memory.
    :raises ValueError: if a statically known ``size`` is not a positive
        multiple of 16.

    .. code-block:: python

        # Drain-on-completion SMEM -> GMEM bulk store of `nbytes` bytes.
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_global_shared_cta(gmem_dst, smem_src, nbytes)
        nvvm.cp_async_bulk_commit_group()
        nvvm.cp_async_bulk_wait_group(0)
    """
    _assert_shared_or_generic(src_mem, "cp.async.bulk.global.shared::cta")
    _assert_bulk_size(size, "cp.async.bulk.global.shared::cta")
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    if byte_mask is not None:
        byte_mask = _cutlass.Int16(byte_mask)
    _nvvm.cp_async_bulk_global_shared_cta(
        dst_mem,
        src_mem,
        _cutlass.Int32(size),
        l2_cache_hint=l2_cache_hint,
        byte_mask=byte_mask,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_bulk_prefetch(
    src_mem: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Prefetch a byte range from global memory into L2.

    Emits ``cp.async.bulk.prefetch.L2.global  [src], size;``.  Pulls
    ``size`` bytes starting at ``src_mem`` into L2 without writing any
    destination; the GMEM access is asynchronous and best-effort.

    :param src_mem: Global-memory source pointer/array.
    :type src_mem: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to prefetch; must be a positive
        multiple of 16.
    :type size: int or cutlass.Int32 or cutlass.Uint32
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy
        descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :raises ValueError: if a statically known ``size`` is not a
        positive multiple of 16.

    """
    _assert_bulk_size(size, "cp.async.bulk.prefetch")
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.cp_async_bulk_prefetch(
        src_mem,
        _cutlass.Int32(size),
        l2_cache_hint=l2_cache_hint,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_bulk_shared_cluster_global(
    dst_mem: Array | Pointer,
    src_mem: Array | Pointer,
    mbar: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    multicast_mask: Int16 | Int32 | None = None,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Async bulk-copy a byte range from global memory into cluster shared memory.

    Emits ``cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes
    [dst], [src], size, [mbar];``.  Copies a byte range (``size`` a positive
    multiple of 16) from GMEM to SMEM without a tensor map; hardware fires the
    mbarrier's ``complete_tx`` automatically when the transfer finishes.  For
    per-CTA self-delivery, omit ``multicast_mask`` (or pass ``None``); passing
    ``1 << cta_rank`` still emits the ``.multicast::cluster`` PTX modifier and
    pays the multicast-routing overhead even though every byte only lands in the
    issuing CTA.  The tensor-descriptor variant
    :func:`cp_async_bulk_tensor_shared_cluster_global` follows the same rule.

    :param dst_mem: Cluster-scope SMEM destination pointer/array; must be
        16-byte aligned.  A ``shared::cta`` pointer is auto-cast to
        ``shared::cluster`` (the cluster bulk-copy intrinsic requires it).
    :type dst_mem: cutlass.Array or cutlass.Pointer
    :param src_mem: GMEM source pointer/array; must be 16-byte aligned.
    :type src_mem: cutlass.Array or cutlass.Pointer
    :param mbar: Pointer/Array to the SMEM mbarrier signalled on completion.
    :type mbar: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to copy (the same value the consumer arms via
        ``arrive_expect_tx``); must be a positive multiple of 16.
    :type size: int or cutlass.Int32 or cutlass.Uint32
    :param multicast_mask: Optional per-bit mask over CTA ranks.  Defaults to
        None: omit it for per-CTA self-delivery (each issuing CTA delivers to
        itself only).  A non-None value emits the ``.multicast::cluster``
        modifier, gated on mask *presence* not value, so ``1 << cta_rank`` is a
        footgun (same delivery as omitted, but pays the multicast-routing
        overhead).  Set it only for genuine cluster broadcast: e.g. ``3``
        (``0b11``) on a 2-CTA cluster delivers identical bytes to both CTAs
        from one issuer.
    :type multicast_mask: cutlass.Int16 or cutlass.Int32, optional
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :raises TypeError: if ``dst_mem`` is not shared or cluster-shared memory,
        or ``mbar`` is not shared memory.
    :raises ValueError: if a statically known ``size`` is not a positive
        multiple of 16, or a statically known ``multicast_mask`` does not fit
        in 32 bits.

    .. code-block:: python

        # GMEM -> cluster-SMEM bulk load of `nbytes`, signalled on `mbar`.
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_shared_cluster_global(smem_dst, gmem_src, mbar, nbytes)
    """
    _assert_shared_or_generic(dst_mem, "cp.async.bulk.shared::cluster.global")
    _assert_shared_or_generic(mbar, "cp.async.bulk.shared::cluster.global")
    _assert_bulk_size(size, "cp.async.bulk.shared::cluster.global")
    _assert_mask32(multicast_mask, "cp.async.bulk.shared::cluster.global")
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    # LLVM's cluster bulk-copy intrinsic requires the destination as
    # shared::cluster even though the NVVM op also accepts shared::cta.
    dst_mem_ir = _to_ir(dst_mem, loc, ip)
    if _llvm.PointerType(dst_mem_ir.type).address_space == _cutlass.AddressSpace.smem:
        dst_mem = _llvm.addrspacecast(
            _llvm.PointerType.get(_cutlass.AddressSpace.dsmem),
            dst_mem_ir,
            loc=loc,
            ip=ip,
        )
    _nvvm.cp_async_bulk_shared_cluster_global(
        dst_mem,
        src_mem,
        mbar,
        _cutlass.Int32(size),
        multicast_mask=multicast_mask,
        l2_cache_hint=l2_cache_hint,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_bulk_shared_cluster_shared_cta(
    dst_mem: Array | Pointer,
    src_mem: Array | Pointer,
    mbar: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Async bulk-copy a byte range between two CTAs' shared memory.

    Emits ``cp.async.bulk.shared::cluster.shared::cta.mbarrier::complete_tx::bytes
    [dst], [src], size, [mbar];``.  Copies ``size`` bytes from the
    issuing CTA's SMEM (``src_mem``) to a peer CTA's SMEM within the
    same cluster (``dst_mem``, addressed via ``shared::cluster``);
    hardware fires the destination ``mbarrier``'s ``complete_tx`` when
    the transfer finishes.

    :param dst_mem: Cluster-scope SMEM destination pointer/array on
        the peer CTA; must be 16-byte aligned.
    :type dst_mem: cutlass.Array or cutlass.Pointer
    :param src_mem: CTA-scope SMEM source pointer/array on the issuing
        CTA; must be 16-byte aligned.
    :type src_mem: cutlass.Array or cutlass.Pointer
    :param mbar: Pointer to the destination CTA's SMEM mbarrier; signalled
        on completion.
    :type mbar: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to copy (must match the consumer's
        ``arrive_expect_tx`` count); positive multiple of 16.
    :type size: int or cutlass.Int32 or cutlass.Uint32
    :raises ValueError: if a statically known ``size`` is not a
        positive multiple of 16.

    """
    _assert_bulk_size(size, "cp.async.bulk.shared::cluster.shared::cta")
    mbar = _addrspacecast_to_shared(mbar, loc=loc, ip=ip)
    _nvvm.cp_async_bulk_shared_cluster_shared_cta(
        dst_mem,
        src_mem,
        mbar,
        _cutlass.Int32(size),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_bulk_tensor_global_shared_cta(
    tma_descriptor: Array | Pointer,
    src_mem: Array | Pointer,
    coordinates: list[int | Int32 | Uint32],
    *,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    mode: TMAStoreMode | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Async TMA-store a tile from CTA shared memory to global memory.

    Emits ``cp.async.bulk.tensor.<N>d.global.shared::cta.bulk_group
    [tensor_map, {coords}], [src];`` where ``<N>`` is the number of
    ``coordinates``.  Stores a CTA-shared tile to the global tensor selected by
    the TMA descriptor at ``coordinates``.  Completion uses the bulk-group
    mechanism (no mbarrier signal), so the store must be drained with
    :func:`cp_async_bulk_commit_group` and :func:`cp_async_bulk_wait_group`.

    :param tma_descriptor: TMA tensor-map descriptor for the destination
        global tensor.
    :type tma_descriptor: cutlass.Array or cutlass.Pointer
    :param src_mem: CTA-scope SMEM source pointer/array.
    :type src_mem: cutlass.Array or cutlass.Pointer
    :param coordinates: 1-5D tile coordinate into the descriptor's tensor.
    :type coordinates: list of (int or cutlass.Int32 or cutlass.Uint32)
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :param mode: Optional TMA store mode (``tile`` default, ``im2col``, or
        ``tile_scatter4``).
    :type mode: TMAStoreMode, optional
    :raises TypeError: if ``src_mem`` does not reside in shared memory.
    :raises ValueError: if the ``coordinates`` count is invalid for ``mode``
        (1-5 for tile, 3-5 for im2col, exactly 2 for scatter4).

    Reverse of :func:`cp_async_bulk_tensor_shared_cta_global` (load).
    TMA hardware reads SMEM and writes the tile to the global tensor
    described by ``tma_descriptor`` at the given ``coordinates``.
    Argument order is ``(desc, smem, coords)`` — no mbarrier; TMA stores
    use commit/wait groups instead of mbarriers.

        **Proxy fence required before issue**: thread SMEM writes go
        through the "generic" proxy; the TMA engine reads through the
        "async" proxy.  Issue
        ``nvvm.fence_proxy("async_shared", space=SharedSpace.shared_cta)``
        before this call so the TMA engine sees the latest SMEM data.
        Without it, TMA may read stale SMEM.

    .. code-block:: python

        # TMA store of an SMEM tile to GMEM at (x, y), then drain.
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_global_shared_cta(tma_desc, smem_src, [x, y])
        nvvm.cp_async_bulk_commit_group()
        nvvm.cp_async_bulk_wait_group(0)
    """
    _assert_shared_or_generic(src_mem, "cp.async.bulk.tensor.global.shared::cta")
    _assert_coords(coordinates, "cp.async.bulk.tensor.global.shared::cta", mode=mode)
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.cp_async_bulk_tensor_global_shared_cta(
        tma_descriptor,
        src_mem,
        [_cutlass.Int32(x) for x in coordinates],
        l2_cache_hint=l2_cache_hint,
        mode=_to_dialect(mode, _TMA_STORE_MODE_TO_DIALECT),
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def cp_async_bulk_tensor_prefetch(
    tma_descriptor: Array | Pointer,
    coordinates: list[int | Int32 | Uint32],
    im2col_offsets: list[int | Int16 | Uint16],
    *,
    mode: TMALoadMode | None = None,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Prefetch a TMA-tensor tile from global memory into L2.

    Emits ``cp.async.bulk.prefetch.tensor.<N>d.L2.global  [tma_desc,
    {coords}];``.  Pulls the tile selected by ``coordinates`` (and
    ``im2col_offsets`` for im2col mode) into L2 without any
    destination; the access is asynchronous and best-effort.

    :param tma_descriptor: TMA tensor-map descriptor for the global tensor.
    :type tma_descriptor: cutlass.Array or cutlass.Pointer
    :param coordinates: 1-5D tile coordinate into the descriptor's tensor.
    :type coordinates: list of (int or cutlass.Int32 or cutlass.Uint32)
    :param im2col_offsets: Im2col offsets; empty list for tile mode.
    :type im2col_offsets: list of (int or cutlass.Int16 or cutlass.Uint16)
    :param mode: Optional TMA load mode (``tile`` default, ``im2col``).
    :type mode: TMALoadMode, optional
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :raises ValueError: if the ``coordinates`` count is invalid for ``mode``.

    The descriptor-override path is exposed separately as
    :func:`cp_async_bulk_tensor_prefetch_override`.
    """
    _assert_coords(coordinates, "cp.async.bulk.prefetch.tensor", mode=mode)
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.cp_async_bulk_tensor_prefetch(
        tma_descriptor,
        [_cutlass.Int32(x) for x in coordinates],
        [_cutlass.Int16(x) for x in im2col_offsets],
        mode=_to_load_mode(mode),
        l2_cache_hint=l2_cache_hint,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def cp_async_bulk_tensor_reduce(
    tma_descriptor: Array | Pointer,
    src_mem: Array | Pointer,
    red_kind: TMARedux,
    coordinates: list[int | Int32 | Uint32],
    *,
    mode: TMAStoreMode | None = None,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a TMA async tensor reduction from shared memory to global memory.

    Lowers to PTX ``cp.reduce.async.bulk.tensor``.  The source tile in
    shared::cta memory is reduced into the destination tensor described by
    ``tma_descriptor`` at ``coordinates`` using ``red_kind``.  The tensor-map
    element type determines which reduction kinds are valid; PTX supports
    ``ADD`` for integer/fp elements, ``MIN``/``MAX`` for integer and fp16/bf16
    element types, ``INC``/``DEC`` for ``u32``, and bitwise reductions for
    ``b32``/``b64``.

    The operation is non-blocking and uses bulk async-group completion.  It does
    not take an mbarrier operand; issue the operation, commit the bulk group,
    then wait on the group before consuming completion.

    :param tma_descriptor: Tensor-map descriptor for the global destination.
    :type tma_descriptor: Array or Pointer
    :param src_mem: Shared-memory source tile.
    :type src_mem: Array or Pointer
    :param red_kind: TMA reduction operation, such as ``ADD``, ``MIN``,
        ``MAX``, ``INC``, ``DEC``, ``AND``, ``OR``, or ``XOR``.
    :type red_kind: TMARedux
    :param coordinates: One to five ``s32`` tensor coordinates matching the
        descriptor rank.
    :type coordinates: list[int or Int32 or Uint32]
    :param mode: Optional TMA store mode.  Omit for tile mode; im2col modes
        require descriptor-compatible ranks and coordinates.
    :type mode: TMAStoreMode, optional
    :param l2_cache_hint: Optional 64-bit L2 cache policy.
    :type l2_cache_hint: int or Int64 or Uint64, optional
    :raises TypeError: if ``src_mem`` does not reside in shared memory.
    :raises ValueError: if ``red_kind`` is not a valid ``TMARedux``, if ``mode``
        is ``tile_scatter4`` (unsupported by reduce), or if the ``coordinates``
        count is invalid for ``mode`` (1-5 for tile, 3-5 for im2col).

    .. code-block:: python

        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_reduce(
                desc,
                smem_tile,
                "add",
                [row, col],
            )
            nvvm.cp_async_bulk_commit_group()
            nvvm.cp_async_bulk_wait_group(0)
    """
    _assert_shared_or_generic(src_mem, "cp.reduce.async.bulk.tensor")
    _assert_coords(coordinates, "cp.reduce.async.bulk.tensor", mode=mode)
    if mode == TMAStoreMode.TILE_SCATTER4:
        raise ValueError(
            "cp.reduce.async.bulk.tensor: tile_scatter4 mode is not supported "
            "for reduce (valid modes: tile, im2col)"
        )
    if red_kind not in _TMA_REDUX_TO_DIALECT:
        raise ValueError(
            "cp.reduce.async.bulk.tensor: red_kind must be a TMARedux "
            f"({', '.join(_TMA_REDUX_TO_DIALECT)}), got {red_kind!r}"
        )
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.cp_async_bulk_tensor_reduce(
        tma_descriptor,
        src_mem,
        _TMA_REDUX_TO_DIALECT[red_kind],
        [_cutlass.Int32(x) for x in coordinates],
        mode=_to_dialect(mode, _TMA_STORE_MODE_TO_DIALECT),
        l2_cache_hint=l2_cache_hint,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def cp_async_bulk_tensor_shared_cluster_global(
    dst_mem: Array | Pointer,
    tma_descriptor: Array | Pointer,
    coordinates: list[int | Int32 | Uint32],
    mbar: Array | Pointer,
    im2col_offsets: list[int | Int16 | Uint16],
    *,
    multicast_mask: Int16 | Int32 | None = None,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    mode: TMALoadMode | None = None,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a TMA async load into shared memory with optional cluster multicast.

    Like ``cp_async_bulk_tensor_shared_cta_global`` but supports multicast
    across all CTAs in a cluster (``group="cta_2"``).

    **Arg order**: ``(dst_smem, tma_desc, coords, mbar, im2col_offsets, ...)``
    — coords come **before** mbar.  This is the opposite of
    ``cp_async_bulk_tensor_shared_cta_global`` (mbar before coords) and is
    the #1 footgun when porting CTA_1 code to CTA_2.

    **CTA_2 mbar routing — bit 24 maps to 2-SM-group leader, NOT
    cluster leader**.  When ``group="cta_2"``, this wrapper
    masks the mbar pointer with ``& 0xFEFFFFFF`` (clears bit 24 only).
    Bit 24 holds the LSB of ``%cluster_ctarank`` — clearing it routes
    the address from a peer CTA back to its **2-SM-group leader** (the
    even-rank CTA in the same pair).

    * In a 2-CTA cluster (``cluster_shape=(2,1,1)``), the only group
      leader is cluster rank 0, so this is equivalent to "route to
      cluster leader" and is what ``2cta_mma_basic.py`` relies on.

    * In multi-group clusters (``cluster_shape=(2, n, 1)`` with n > 1),
      complete_tx still routes only to the **issuer's** group leader
      (the even-rank CTA in the issuer's pair).  It does NOT route
      across groups: a TMA issued in group 0 cannot deliver
      ``complete_tx`` to group 1's mbar through this wrapper.  Cross-
      group multicast TMA (e.g. broadcast B to all groups) requires
      manually constructing a cluster-shared mbar pointer via
      ``mapa.shared::cluster`` so all issuers target the same
      cluster-leader mbar; this wrapper does not expose that path.

    **Shared-tile multicast vs per-CTA unicast** — two distinct topologies,
    commonly confused.  The right choice comes from the pseudo-code:

    * *Shared-tile multicast* (``multicast @cta`` in the pseudo-code on a
      tile declared at the cluster scale, e.g. ``tile B_smem: f16:K×N @
      SMEM`` with ``N = N_TILE`` covering the full cluster width).  Each
      CTA gets an identical copy of one full tile.  One descriptor with
      ``box_dims`` spanning the whole tile; ``multicast_mask`` includes
      **every CTA** in the cluster (``0b11`` for 2-CTA, ``0xff`` for 8-CTA).
      **Mbar protocol depends on cluster_size:**

      - *cluster_size == 2 (with downstream MMA reuse)*: optionally pass
        ``group="cta_2"`` to enable bit-24 mbar collapse — only
        the leader inits + does ``arrive_expect_tx`` with the **full-tile**
        byte count, and only the leader waits.  All CTAs' ``complete_tx``
        is redirected to the leader's mbar.  This is the right shape when
        the same mbar is then reused as the MMA's input-ready bar.

      - *cluster_size ≥ 2 (general, including > 2)*: **omit** ``group=``
        and use **per-CTA local mbars** — every CTA inits its own mbar
        (at the same SMEM offset), every CTA does ``arrive_expect_tx``
        with the **per-CTA** tile byte count, only the leader issues the
        TMA, every CTA waits on its own mbar.  Per the PTX ISA,
        the hardware multicasts ``complete_tx`` to that same SMEM offset
        in every destination CTA's local SMEM.  Works for cluster_size
        ∈ {2, 4, 8, 16}.

      Trying ``group="cta_2"`` with cluster_size > 2 hangs:
      the bit-24 mask redirects to the *issuer's* 2-SM-group leader only
      (cluster ranks 0+1), so cross-group receivers' mbars never arrive.

    * *Per-CTA unicast* (used when each CTA consumes a different slice of
      the tensor, e.g. each CTA gets a different half of the M-dimension).
      Descriptor ``box_dims`` covers only the per-CTA slice, **omit
      ``multicast_mask`` entirely** (or pass ``None``), coordinates shift
      by ``cta_rank * slice`` per CTA, and each CTA calls
      ``mbarrier_arrive_expect_tx`` independently.  This is functionally
      the CTA_1 pattern wrapped in ``group=CTA_2`` for the routing
      bookkeeping; it is **not** a multicast.

    **Multicast modifier rule** — the ``multicast::cluster`` PTX modifier
    is gated by *whether ``multicast_mask`` is present*, not by the value
    the mask carries.  A "selfcast" mask such as ``1 << cta_rank``
    therefore still emits the modifier and pays the multicast-routing
    overhead even though the bytes only land in the issuing CTA.  For
    per-CTA unicast topology, omit ``multicast_mask``.  Set
    ``multicast_mask`` only when the topology is genuinely
    *shared-tile multicast* (one issuer, mask covers every receiving
    CTA).  Applies to both ``group=CTA_1`` and ``group=CTA_2``.

    Do not split a shared-tile multicast into per-CTA unicasts to "save
    bytes" — the multicast is a single HBM read fanned out over the
    cluster interconnect, so per-CTA unicast **increases** HBM pressure
    instead of reducing it, in addition to producing a different SMEM
    layout than the spec.

    .. code-block:: python

        # Shared-tile multicast — both CTAs see the same 128×128 tile.
        # arrive_expect_tx is called by the leader only, with the FULL tile's
        # byte count (not per-CTA).
        if is_leader:
            nvvm.mbarrier_arrive_expect_tx(mbar + s, A_full_bytes + B_full_bytes)
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cluster_global(
                smem_B + s * tile_b,
                tma_b_desc,
                (k, n),                    # full tile origin
                mbar + s,
                [],                        # ← coords BEFORE mbar
                multicast_mask=Int16(0b11),   # every CTA in the 2-CTA cluster
                group="cta_2",
            )

    :param dst_mem: Cluster-scope SMEM destination tile (shared or
        cluster-shared); must be 16-byte aligned.
    :type dst_mem: cutlass.Array or cutlass.Pointer
    :param tma_descriptor: TMA tensor-map descriptor for the source tensor.
    :type tma_descriptor: cutlass.Array or cutlass.Pointer
    :param coordinates: 1-5D tile coordinate into the descriptor's tensor
        (note: coords come BEFORE ``mbar`` in the arg order).
    :type coordinates: list of (int or cutlass.Int32 or cutlass.Uint32)
    :param mbar: Shared-memory mbarrier signalled on completion.
    :type mbar: cutlass.Array or cutlass.Pointer
    :param im2col_offsets: im2col offsets (empty list for tile mode).
    :type im2col_offsets: list of (int or cutlass.Int16 or cutlass.Uint16)
    :param multicast_mask: Optional per-bit CTA-rank mask for cluster
        multicast (omit for per-CTA unicast).
    :type multicast_mask: cutlass.Int16 or cutlass.Int32, optional
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :param mode: Optional TMA load mode (tile default, or im2col).
    :type mode: TMALoadMode, optional
    :param group: CTA group selector (``cta_1`` default, or ``cta_2``).
    :type group: CTAGroup, optional
    :raises TypeError: if ``dst_mem`` is not shared/cluster-shared memory or
        ``mbar`` is not shared memory.
    :raises ValueError: if the ``coordinates`` count is invalid for ``mode``,
        or a statically known ``multicast_mask`` does not fit in 32 bits.

    """
    _instr = "cp.async.bulk.tensor.shared::cluster.global"
    _assert_shared_or_generic(dst_mem, _instr)
    _assert_shared_or_generic(mbar, _instr)
    _assert_coords(coordinates, _instr, mode=mode)
    _assert_mask32(multicast_mask, _instr)
    if multicast_mask is not None:
        # The TMA-tensor multicast intrinsic takes a 16-bit CTA mask; emitting
        # an i32 operand matches no libNVVM ISel pattern ("Cannot select
        # cp.async.bulk.tensor.g2s.tile.Nd").  Coerce to Int16.
        multicast_mask = _cutlass.Int16(multicast_mask)
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    # CTA_2 cluster mbar routing: clear bit 24 so all CTAs address CTA-0's mbar.
    if group == "cta_2":
        mbar = mbar.data_ptr() & _cutlass.Int32(0xFEFFFFFF)
    # LLVM's cluster TMA intrinsic requires the destination as shared::cluster
    # even though the NVVM op also accepts shared::cta.
    dst_mem_ir = _to_ir(dst_mem, loc, ip)
    if _llvm.PointerType(dst_mem_ir.type).address_space == _cutlass.AddressSpace.smem:
        dst_mem = _llvm.addrspacecast(
            _llvm.PointerType.get(_cutlass.AddressSpace.dsmem),
            dst_mem_ir,
            loc=loc,
            ip=ip,
        )
    _nvvm.cp_async_bulk_tensor_shared_cluster_global(
        dst_mem,
        tma_descriptor,
        [_cutlass.Int32(x) for x in coordinates],
        mbar,
        [_cutlass.Int16(x) for x in im2col_offsets],
        multicast_mask=multicast_mask,
        l2_cache_hint=l2_cache_hint,
        mode=_to_load_mode(mode),
        # Omit the attr (None) for the cluster path, matching the dst
        # addrspacecast above; an explicit False mis-lowers (serialization ICE).
        is_cta_only=None,
        group=_to_dialect(group, _CTAGROUP_TO_DIALECT),
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def cp_async_bulk_tensor_shared_cta_global(
    dst_mem: Array | Pointer,
    tma_descriptor: Array | Pointer,
    coordinates: list[int | Int32 | Uint32],
    mbar: Array | Pointer,
    im2col_offsets: list[int | Int16 | Uint16] | None = None,
    *,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    mode: TMALoadMode | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a TMA async load from global memory into this CTA's shared memory.

    TMA hardware performs the DMA without stalling the issuing warp.
    Completion is signaled by an mbarrier ``complete_tx`` decrement, which
    fires the barrier once all bytes have arrived.

    **Arg order**: ``(dst_smem, tma_desc, coords, mbar)`` — coords **before**
    mbar, matching :func:`cp_async_bulk_tensor_shared_cluster_global` so porting
    CTA_1 code to CTA_2 only changes the function name, not the argument order.

    **Calling convention**:

    * Call from exactly **one thread** (e.g. ``if nvvm.elect_sync()``).
    * Call ``arrive_expect_tx(mbar, nbytes)`` **before** this function so the
      transaction counter is set before TMA can decrement it.
    * ``nbytes`` = rows × cols × sizeof(dtype) for the tile being loaded.
    * Coordinates are tensor-space element indices, not byte offsets.  For a
      2-D descriptor created via ``create_tensor_map_tiled_from_view`` on a
      row-major (M, K) tensor, the TMA coord order is column-major:
      ``(k_offset, m_offset)`` — K (innermost) first.

    .. code-block:: python

        # Separate elect_sync for arrive vs each TMA load (performance)
        if nvvm.elect_sync():
            nvvm.mbarrier_arrive_expect_tx(mbar + s, A_bytes + B_bytes)
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cta_global(
                smem_A + s * tile_a, tma_a_desc, (k, m), mbar + s)
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cta_global(
                smem_B + s * tile_b, tma_b_desc, (k, n), mbar + s)

    For multicast / cluster TMA (CTA_2) use
    ``cp_async_bulk_tensor_shared_cluster_global`` instead.

    ``mode`` selects the TMA access pattern (``TILE`` default; also the
    ``IM2COL`` family and ``TILE_GATHER4``).  For im2col modes pass the per-dim
    ``im2col_offsets``; tile and gather4 modes leave it empty.

    :param dst_mem: This CTA's SMEM destination tile; must be 16-byte aligned.
    :type dst_mem: cutlass.Array or cutlass.Pointer
    :param tma_descriptor: TMA tensor-map descriptor for the source tensor.
    :type tma_descriptor: cutlass.Array or cutlass.Pointer
    :param coordinates: 1-5D tile coordinate into the descriptor's tensor
        (coords come before ``mbar`` in the arg order).
    :type coordinates: list of (int or cutlass.Int32 or cutlass.Uint32)
    :param mbar: Shared-memory mbarrier signalled on completion.
    :type mbar: cutlass.Array or cutlass.Pointer
    :param im2col_offsets: im2col offsets (empty / omitted for tile mode).
    :type im2col_offsets: list of (int or cutlass.Int16 or cutlass.Uint16), optional
    :param l2_cache_hint: Optional 64-bit L2 cache-eviction policy descriptor.
    :type l2_cache_hint: int or cutlass.Int64 or cutlass.Uint64, optional
    :param mode: Optional TMA load mode (``TILE`` default, im2col, or gather4).
    :type mode: TMALoadMode, optional
    :raises TypeError: if ``dst_mem`` or ``mbar`` is not shared memory.
    :raises ValueError: if the ``coordinates`` count is invalid for ``mode``.

    """
    _instr = "cp.async.bulk.tensor.shared::cta.global"
    _assert_shared_or_generic(dst_mem, _instr)
    _assert_shared_or_generic(mbar, _instr)
    _assert_coords(coordinates, _instr, mode=mode)
    if im2col_offsets is None:
        im2col_offsets = []
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.cp_async_bulk_tensor_shared_cluster_global(
        dst_mem,
        tma_descriptor,
        [_cutlass.Int32(x) for x in coordinates],
        mbar,
        [_cutlass.Int16(x) for x in im2col_offsets],
        l2_cache_hint=l2_cache_hint,
        mode=_to_load_mode(mode),
        is_cta_only=True,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cp_async_shared_global(
    dst: Array | Pointer,
    src: Array | Pointer,
    size: int,
    modifier: LoadCacheModifier,
    *,
    cp_size: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a per-thread async copy from global to shared memory (SM80+).

    Each thread independently copies ``size`` bytes from ``src`` (GMEM) to
    ``dst`` (SMEM) without stalling.  Unlike TMA, no descriptor is required
    and every participating thread issues its own copy.

    :param dst: Destination in shared memory (addr-space 3).
    :type dst: cutlass.Array or cutlass.Pointer
    :param src: Source pointer in global memory.
    :type src: cutlass.Array or cutlass.Pointer
    :param size: Bytes per thread.  Must be ``4``, ``8``, or ``16``.
        Use ``16`` (128-bit) for maximum throughput (one ``float4``).
    :type size: int
    :param modifier: Cache policy — ``"ca"`` (cache L1+L2, 4/8/16 B) or
        ``"cg"`` (bypass L1, L2 only, 16 B only).  Prefer ``"cg"`` for
        streaming loads that won't be reused.
    :type modifier: LoadCacheModifier
    :param cp_size: Source byte count for a **masked (zero-fill) copy**.
        When ``cp_size < size``, the bytes ``[cp_size, size)`` in ``dst`` are
        zeroed rather than left undefined.  Pass ``cp_size=0`` to write all
        zeros (useful for out-of-bounds boundary tiles).  Leave ``None`` for
        full-size copies.
    :type cp_size: int or cutlass.Int32 or cutlass.Uint32, optional
    :raises TypeError: if ``dst`` is not shared memory.
    :raises ValueError: if ``size`` is not 4/8/16, if ``modifier`` is ``cg``
        with ``size`` != 16, or if ``cp_size`` falls outside ``[0, size]``.

    **Synchronization:** copies are asynchronous.  Use
    ``nvvm.cp_async_commit_group()`` to mark a batch and
    ``nvvm.cp_async_wait_group(n)`` to drain until ≤ ``n`` groups remain.

    **Swizzle requirement for tcgen05.mma:** when the SMEM tile will be read
    by ``tcgen05.mma``, use the SMEM layout expected by the corresponding
    matrix descriptor.  For the common 128B XOR layout, produce the same layout
    that ``Pointer.store_swizzled`` or a 128B-swizzled tensor map would create.

    .. code-block:: python

        # 16-byte streaming load per thread, bypass L1
        nvvm.cp_async_shared_global(smem_dst, gmem_src, 16, "cg")
        nvvm.cp_async_commit_group()
        # ... later ...
        nvvm.cp_async_wait_group(0)   # wait for all groups
    """
    _instr = "cp.async.shared.global"
    _assert_shared_or_generic(dst, _instr)
    if isinstance(size, int) and size not in (4, 8, 16):
        raise ValueError(f"{_instr}: size must be 4, 8, or 16, got {size}")
    if modifier == LoadCacheModifier.CG and isinstance(size, int) and size != 16:
        raise ValueError(
            f"{_instr}: the .cg cache modifier supports only 16-byte copies, "
            f"got size={size}"
        )
    if isinstance(cp_size, int) and not 0 <= cp_size <= size:
        raise ValueError(f"{_instr}: cp_size must be within [0, {size}], got {cp_size}")
    if cp_size is not None:
        cp_size = _cutlass.Int32(cp_size)
    _nvvm.cp_async_shared_global(
        dst,
        src,
        size,
        _LOAD_CACHE_MODIFIER_TO_DIALECT[modifier],
        cp_size=cp_size,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_packfloat(
    src_a: int | Int32 | Uint32,
    src_c: int | Int32 | Uint32,
    from_: CVTPackFloat,
    to: CVTPackFloat,
    *,
    rnd: FPRoundingMode | None = None,
    sat: SaturationModeKind | None = None,
    relu: bool | None = None,
    extract_hi: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.cvt_packfloat``."""
    return _cutlass.Int32(
        _nvvm.cvt_packfloat(
            _cutlass.Int32(src_a),
            _cutlass.Int32(src_c),
            _CVT_PACK_FLOAT_TO_DIALECT[from_],
            _CVT_PACK_FLOAT_TO_DIALECT[to],
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_KIND_TO_DIALECT),
            relu=relu,
            extract_hi=extract_hi,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def cvt_packfloat_f32(
    src_a: float | Float32,
    src_b: float | Float32,
    src_c: int | Int32 | Uint32,
    to: CVTPackFloat,
    *,
    rnd: FPRoundingMode | None = None,
    sat: SaturationModeKind | None = None,
    relu: bool | None = None,
    extract_hi: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.cvt_packfloat_f32``."""
    return _cutlass.Int32(
        _nvvm.cvt_packfloat_f32(
            _cutlass.Float32(src_a),
            _cutlass.Float32(src_b),
            _cutlass.Int32(src_c),
            _CVT_PACK_FLOAT_TO_DIALECT[to],
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_KIND_TO_DIALECT),
            relu=relu,
            extract_hi=extract_hi,
            loc=loc,
            ip=ip,
        )
    )





@dsl_user_op
def dot_accumulate_2way(
    a: Vector,
    a_type: DotAccumulateType,
    b: Vector,
    b_type: DotAccumulateType,
    c: int | Int32 | Uint32,
    b_hi: bool,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.dot_accumulate_2way``."""
    return _cutlass.Int32(
        _nvvm.dot_accumulate_2way(
            a,
            _DOT_ACCUMULATE_TYPE_TO_DIALECT[a_type],
            b,
            _DOT_ACCUMULATE_TYPE_TO_DIALECT[b_type],
            _cutlass.Int32(c),
            b_hi,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def dot_accumulate_4way(
    a: Vector,
    a_type: DotAccumulateType,
    b: Vector,
    b_type: DotAccumulateType,
    c: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.dot_accumulate_4way``."""
    return _cutlass.Int32(
        _nvvm.dot_accumulate_4way(
            a,
            _DOT_ACCUMULATE_TYPE_TO_DIALECT[a_type],
            b,
            _DOT_ACCUMULATE_TYPE_TO_DIALECT[b_type],
            _cutlass.Int32(c),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def elect_sync(
    *,
    membermask: int | Int32 | Uint32 = _FULL_MASK,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Elect one lane from a warp-convergent group.

    Exactly one predicated active lane in ``membermask`` is elected.  That
    lane receives ``True``; every other participating lane receives
    ``False``.  PTX guarantees deterministic election for a fixed member
    mask, but does not specify which lane ID wins.  Use this as the
    compiler-visible gate for non-idempotent single-issuer operations such
    as one TMA issuer per warp, one ``mbarrier_arrive_expect_tx`` call, or
    one ``tcgen05_commit`` call.

    Convergence requirement: every executing lane must be named in
    ``membermask``, and all lanes named by ``membermask`` must actively
    execute the instruction.  Lanes outside the mask should branch around
    the call.

    :param membermask: 32-bit warp participation mask; every set bit
        identifies a lane that must be executing this instruction.
        Defaults to ``FULL_MASK`` (``0xFFFFFFFF``, all 32 lanes).
    :type membermask: int or Int32 or Uint32
    :return: ``True`` in the elected lane; ``False`` in every other
        participating lane.
    :rtype: Boolean
    :raises ValueError: if ``membermask`` is a Python ``int`` outside
        ``[0, 0xFFFFFFFF]``.

    .. code-block:: python

        # Elect one lane per warp to perform a non-idempotent op.
        if nvvm.elect_sync():           # uses FULL_MASK by default
            nvvm.mbarrier_arrive_expect_tx(full_bar + s, tile_bytes)
    """
    _assert_mask32(membermask, "elect.sync")
    return _cutlass.Boolean(
        _nvvm.elect_sync(
            membermask=_cutlass.Int32(membermask),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def fence_proxy_acquire(
    scope: MemScope,
    addr: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    from_proxy: Proxy | None = None,
    to_proxy: Proxy | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Acquire a memory region modified in another proxy.

    Emits the uni-directional acquire proxy fence
    ``fence.proxy.{to_proxy}::{from_proxy}.acquire.{scope} [addr], size``.
    The canonical use is acquiring a tensormap (``to_proxy="tensormap"``,
    ``from_proxy="generic"``) that was edited in the generic proxy (e.g. via
    ``tensormap.replace``) before reading it through the tensormap proxy with
    a TMA copy.  Unlike most proxies, the tensormap proxy is **not** acquired
    from the generic proxy at kernel start, so this explicit fence is
    required whenever a tensormap is modified at runtime.

    :param scope: Scope at which the prior writes become visible
        (``"cta"`` / ``"cluster"`` / ``"gpu"`` / ``"sys"``).
    :type scope: MemScope
    :param addr: Base address of the region being acquired (e.g. the
        tensormap object).  Generic-addressed; the runtime address must
        fall within the ``.global`` window (not enforced at trace time).
    :type addr: Array | Pointer
    :param size: Size of that region in bytes.  The only value the
        instruction supports is ``128`` (the tensormap size), and it must
        be an immediate.
    :type size: int | Int32 | Uint32
    :param from_proxy: Source proxy the writes were performed in.  Only
        ``"generic"`` is valid (the default); leave as ``None`` to use it.
    :type from_proxy: Proxy | None
    :param to_proxy: Target proxy the subsequent reads use.  Only
        ``"tensormap"`` is valid (the default); leave as ``None`` to use it.
    :type to_proxy: Proxy | None
    :raises ValueError: a static ``int`` ``size`` other than ``128``; an
        explicit ``from_proxy`` other than ``"generic"``; or an explicit
        ``to_proxy`` other than ``"tensormap"``.

    .. code-block:: python

        # Acquire a runtime-edited tensormap before using it in a TMA copy:
        nvvm.fence_proxy_acquire(
            "gpu",
            tma_desc,
            128,
            from_proxy="generic",
            to_proxy="tensormap",
        )
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cta_global(
                smem, tma_desc, src_coords, mbar
            )
    """
    # The instruction supports a single immediate size (128); static ints
    # other than 128 are always invalid, so reject them up front.  Runtime
    # values pass through to the MLIR verifier.
    if isinstance(size, int) and size != 128:
        raise ValueError(
            f"fence.proxy.acquire: the only supported size is 128 bytes, got {size}"
        )
    # The uni-directional acquire fence is defined only for the
    # tensormap::generic proxy pair; any other explicit proxy is invalid.
    if from_proxy is not None and from_proxy != Proxy.GENERIC:
        raise ValueError(
            f'fence.proxy.acquire: from_proxy must be "generic", got {from_proxy!r}'
        )
    if to_proxy is not None and to_proxy != Proxy.TENSORMAP:
        raise ValueError(
            f'fence.proxy.acquire: to_proxy must be "tensormap", got {to_proxy!r}'
        )
    _nvvm.fence_proxy_acquire(
        _MEMSCOPE_TO_DIALECT[scope],
        addr,
        _cutlass.Int32(size),
        from_proxy=_to_dialect(from_proxy, _PROXY_TO_DIALECT),
        to_proxy=_to_dialect(to_proxy, _PROXY_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_proxy_release(
    scope: MemScope,
    *,
    from_proxy: Proxy | None = None,
    to_proxy: Proxy | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Release a memory region to another proxy.

    Emits the uni-directional release proxy fence
    ``fence.proxy.{to_proxy}::{from_proxy}.release.{scope}``.  It is the
    release counterpart of :func:`fence_proxy_acquire`: a
    ``fence.proxy.release`` forms a release sequence that synchronises with
    an acquire sequence containing a matching ``fence.proxy.acquire``.  The
    canonical use is publishing a tensormap (``to_proxy="tensormap"``,
    ``from_proxy="generic"``) edited in the generic proxy before another
    agent acquires and reads it through the tensormap proxy.  Unlike
    :func:`fence_proxy_acquire`, the release form takes no address window.

    :param scope: Scope at which the prior writes are released
        (``"cta"`` / ``"cluster"`` / ``"gpu"`` / ``"sys"``).
    :type scope: MemScope
    :param from_proxy: Source proxy the writes were performed in.  Only
        ``"generic"`` is valid (the default); leave as ``None`` to use it.
    :type from_proxy: Proxy | None
    :param to_proxy: Target proxy the subsequent reads use.  Only
        ``"tensormap"`` is valid (the default); leave as ``None`` to use it.
    :type to_proxy: Proxy | None
    :raises ValueError: an explicit ``from_proxy`` other than ``"generic"``
        or an explicit ``to_proxy`` other than ``"tensormap"``.

    .. code-block:: python

        # Publish a runtime-edited tensormap to the tensormap proxy:
        nvvm.fence_proxy_release(
            "gpu",
            from_proxy="generic",
            to_proxy="tensormap",
        )
    """
    # The uni-directional release fence is defined only for the
    # tensormap::generic proxy pair; any other explicit proxy is invalid.
    if from_proxy is not None and from_proxy != Proxy.GENERIC:
        raise ValueError(
            f'fence.proxy.release: from_proxy must be "generic", got {from_proxy!r}'
        )
    if to_proxy is not None and to_proxy != Proxy.TENSORMAP:
        raise ValueError(
            f'fence.proxy.release: to_proxy must be "tensormap", got {to_proxy!r}'
        )
    _nvvm_raw.fence_proxy_release(
        _MEMSCOPE_TO_DIALECT[scope],
        from_proxy=_to_dialect(from_proxy, _PROXY_TO_DIALECT),
        to_proxy=_to_dialect(to_proxy, _PROXY_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_proxy_sync_restrict(
    order: MemOrder,
    *,
    from_proxy: Proxy | None = None,
    to_proxy: Proxy | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Order memory between the async and generic proxies, sync-restricted.

    Emits ``fence.proxy.async::generic.{order}.sync_restrict...``.  The
    ``sync_restrict`` qualifier narrows the ordering so that ``acquire``
    applies to ``shared::cluster`` and ``release`` to ``shared::cta``, both
    at cluster scope.  Ordering is supported only between the async and
    generic proxies.

    :param order: ``"acquire"`` or ``"release"``.
    :type order: MemOrder
    :param from_proxy: Source proxy.  Only ``"generic"`` is valid (the
        default); leave as ``None`` to use it.
    :type from_proxy: Proxy | None
    :param to_proxy: Target proxy.  Only ``"async"`` is valid (the
        default); leave as ``None`` to use it.
    :type to_proxy: Proxy | None
    :raises ValueError: ``order`` is not ``"acquire"`` / ``"release"``; an
        explicit ``from_proxy`` other than ``"generic"``; or an explicit
        ``to_proxy`` other than ``"async"``.

    .. code-block:: python

        nvvm.fence_proxy_sync_restrict("acquire")
    """
    if order not in (MemOrder.ACQUIRE, MemOrder.RELEASE):
        raise ValueError(
            f'fence.proxy.sync_restrict: order must be "acquire" or "release", '
            f"got {order!r}"
        )
    if from_proxy is not None and from_proxy != Proxy.GENERIC:
        raise ValueError(
            f"fence.proxy.sync_restrict: from_proxy must be "
            f'"generic", got {from_proxy!r}'
        )
    if to_proxy is not None and to_proxy != Proxy.ASYNC:
        raise ValueError(
            f'fence.proxy.sync_restrict: to_proxy must be "async", got {to_proxy!r}'
        )
    _nvvm.fence_proxy_sync_restrict(
        _MEMORDER_TO_DIALECT[order],
        from_proxy=_to_dialect(from_proxy, _PROXY_TO_DIALECT),
        to_proxy=_to_dialect(to_proxy, _PROXY_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_sc_cluster(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Sequentially-consistent memory fence at cluster scope.

    Emits ``fence.sc.cluster``.  Contributes this thread's prior memory
    accesses to a single total order over the sequentially-consistent
    operations observed by all threads in the cluster, ordering them before
    the thread's subsequent accesses with respect to the whole cluster.

    .. code-block:: python

        nvvm.fence_sc_cluster()
    """
    _nvvm_raw.fence_sc_cluster(loc=loc, ip=ip)


@dsl_user_op
def fence_sync_restrict(
    order: MemOrder,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Thread fence restricted to a memory class at cluster scope.

    Emits ``fence.{order}.sync_restrict::shared::{cluster|cta}.cluster``.
    The ``sync_restrict`` qualifier restricts ``acquire`` ordering to
    ``shared::cluster`` and ``release`` to ``shared::cta``, both at cluster
    scope.

    :param order: ``"acquire"`` or ``"release"``.
    :type order: MemOrder
    :raises ValueError: ``order`` is not ``"acquire"`` / ``"release"``.

    .. code-block:: python

        nvvm.fence_sync_restrict("release")
    """
    if order not in (MemOrder.ACQUIRE, MemOrder.RELEASE):
        raise ValueError(
            f'fence.sync_restrict: order must be "acquire" or "release", got {order!r}'
        )
    _nvvm.fence_sync_restrict(_MEMORDER_TO_DIALECT[order], loc=loc, ip=ip)


@dsl_user_op
def fma_packed_f32x2(
    src_a: tuple | Vector,
    src_b: tuple | Vector,
    src_c: tuple | Vector,
    *,
    rnd: FPRoundingMode | None = None,
    ftz: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> tuple | Vector:
    """Wrapper over ``nvvm.fma_packed_f32x2``.

    Accepts a 2-tuple of f32 scalars or a ``Vector`` for each operand and
    returns a tuple when called with tuples, else a ``Vector``.
    """
    returns_tuple = isinstance(src_a, tuple)
    vec_a = _packed_f32x2_to_vec(src_a, loc=loc, ip=ip)
    vec_b = _packed_f32x2_to_vec(src_b, loc=loc, ip=ip)
    vec_c = _packed_f32x2_to_vec(src_c, loc=loc, ip=ip)
    vec_a_ir = _to_ir(vec_a, loc, ip)
    vec_res = _call_nvvm_result_compat(
        _nvvm_raw.fma_packed_f32x2,
        vec_a_ir.type,
        vec_a_ir,
        _to_ir(vec_b, loc, ip),
        _to_ir(vec_c, loc, ip),
        rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
        ftz=ftz,
        loc=loc,
        ip=ip,
    )
    return _unpack_packed_f32x2(vec_res) if returns_tuple else vec_res




_VALID_LDST_MATRIX_NUM = frozenset({1, 2, 4})

# .m8n16 and .m16n16 both require a `src_format` (FP4/FP6 unpacking variants).
_LDMATRIX_SHAPES_REQUIRING_SRC_FORMAT = frozenset({"m8n16", "m16n16"})
# .m16n16 must be transposed (`.trans`, i.e. layout=col) per the PTX ISA.
_LDMATRIX_TRANS_ONLY_SHAPES = frozenset({"m16n16"})


@dsl_user_op
def ldmatrix(
    ptr: Array | Pointer,
    num: int,
    layout: MMALayout,
    *,
    shape: LoadShape | None = None,
    src_format: LoadSrcFormat | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Vector:
    """Warp-cooperative load of one to four 8x8 matrix tiles from shared memory.

    Emits ``ldmatrix.sync.aligned.{shape}.{num}{.trans}{.ss}.{type} d, [a]``.
    All 32 lanes of the issuing warp collectively load ``num`` 8x8 tiles whose
    row starts each lane holds in ``ptr``; the result is the per-thread
    fragment carried in 32-bit register words as required by subsequent
    ``mma.sync`` / ``stmatrix`` instructions.

    Lane addressing convention (per ``num``):

    +-------+---------------------+---------------------+----------------------+
    | num   | lanes 0..7          | lanes 8..15         | lanes 16..31         |
    +=======+=====================+=====================+======================+
    |   1   | row starts of tile 0|                     |                      |
    |   2   | rows of tile 0      | rows of tile 1      |                      |
    |   4   | rows of tile 0      | rows of tile 1      | rows of tiles 2..3   |
    +-------+---------------------+---------------------+----------------------+

    :param ptr: Pointer/Array into shared memory; per the PTX ISA the address
        space must be ``.shared{::cta}``.
    :type ptr: cutlass.Array or cutlass.Pointer
    :param num: Number of 8x8 tiles per warp.  Must be one of ``1``, ``2``,
        ``4`` (the PTX ``.x1`` / ``.x2`` / ``.x4`` qualifiers).
    :type num: int
    :param layout: ``MMALayout.ROW`` for the default load.  ``MMALayout.COL``
        selects ``.trans``, which transposes the loaded tile inside the lane
        registers without reading from a transposed memory layout.
    :type layout: MMALayout
    :param shape: Tile shape selector.  Defaults to ``m8n8`` (the historical
        SM75 form).  ``m8n16`` and ``m16n16`` unpack the narrow-float
        ``.dst_fmt.src_fmt`` forms and require ``src_format`` to be set.
        ``m16n16`` additionally requires ``layout=MMALayout.COL`` (``.trans``).
    :type shape: LoadShape or None
    :param src_format: Source packing for ``m8n16`` / ``m16n16``.
        ``b6x16_p32`` / ``b4x16_p64`` unpack ``e3m2`` / ``e2m1`` matrices into
        the ``.b8x16`` destination format; ``b8`` is the byte form.
        Must be paired with one of ``m8n16`` / ``m16n16``.
    :type src_format: LoadSrcFormat or None

    :return: ``Int32`` when ``num=1``; ``Vector[num x Int32]`` when ``num=2``
        or ``num=4``.  Each element is one 32-bit register word.
    :raises ValueError: ``num`` is not one of ``1`` / ``2`` / ``4``.
    :raises ValueError: ``src_format`` is given without a matching
        ``shape in {m8n16, m16n16}``, or ``shape in {m8n16, m16n16}`` is given
        without a matching ``src_format``.
    :raises ValueError: ``shape=m16n16`` without ``layout=MMALayout.COL``
        (the PTX ISA requires ``.trans`` for the ``m16n16`` form).

    .. code-block:: python

        # 4 x 8x8 b16 tiles, non-transposed, into a vector<4xi32> fragment.
        smem = cutlass.Array(cutlass.Int16, 4 * 8 * 8, space=cutlass.AddressSpace.smem)
        regs = nvvm.ldmatrix(smem, num=4, layout=nvvm.MMALayout.ROW)
        # regs is Vector[4 x Int32], ready as a multiplicand for mma_sync.
    """
    instruction = "ldmatrix"
    # Address-space enforcement is delegated to the dialect's
    # ``LLVM_PointerShared`` operand type, which checks the actual MLIR
    # pointer.  We deliberately do not duplicate the check on the
    # ``Array.space`` field: that field is a construction-time hint, not a
    # contract, and may read ``GENERIC`` for an Array built from a raw
    # ``ir.Value`` whose MLIR type is in fact ``!llvm.ptr<3>``.
    if isinstance(num, int) and num not in _VALID_LDST_MATRIX_NUM:
        raise ValueError(f"{instruction}: num must be 1, 2, or 4, got {num}")
    shape_str = str(shape) if shape is not None else None
    src_format_str = str(src_format) if src_format is not None else None
    if (
        src_format_str is not None
        and shape_str not in _LDMATRIX_SHAPES_REQUIRING_SRC_FORMAT
    ):
        raise ValueError(
            f"{instruction}: src_format={src_format!r} requires "
            f"shape in {sorted(_LDMATRIX_SHAPES_REQUIRING_SRC_FORMAT)}; got shape={shape!r}"
        )
    if shape_str in _LDMATRIX_SHAPES_REQUIRING_SRC_FORMAT and src_format_str is None:
        raise ValueError(
            f"{instruction}: shape={shape!r} requires a src_format "
            f"({sorted(_LOAD_SRC_FORMAT_TO_DIALECT)}); got src_format=None"
        )
    if shape_str in _LDMATRIX_TRANS_ONLY_SHAPES and str(layout) != "col":
        raise ValueError(
            f"{instruction}: shape={shape!r} is only valid as a transposed "
            f"load (layout=MMALayout.COL); got layout={layout!r}"
        )

    shape_d = _to_dialect(shape, _LOAD_SHAPE_TO_DIALECT)
    src_format_d = _to_dialect(src_format, _LOAD_SRC_FORMAT_TO_DIALECT)
    layout_d = _to_dialect(layout, _MMA_LAYOUT_TO_DIALECT)
    if num == 1:
        return _cutlass.Int32(
            _nvvm_raw.ldmatrix(
                _cutlass.Int32.mlir_type,
                ptr,
                num,
                layout_d,
                shape=shape_d,
                src_format=src_format_d,
                loc=loc,
                ip=ip,
            )
        )
    # num=2 or num=4: result type is !llvm.struct<(i32, i32, ...)>
    _i32 = ir.IntegerType.get_signless(32)
    struct_ty = _llvm.StructType.get_literal([_i32] * num)
    result = _nvvm_raw.ldmatrix(
        struct_ty,
        ptr,
        num,
        layout_d,
        shape=shape_d,
        src_format=src_format_d,
        loc=loc,
        ip=ip,
    )
    # Extract each i32 element from the struct, then build a Vector.
    from cutlass._mlir.dialects import vector as _vector_d

    vec_ty = ir.VectorType.get([num], _i32)
    elems = [
        _llvm.extractvalue(_i32, result, position=[i], loc=loc, ip=ip)
        for i in range(num)
    ]
    return Vector(
        _vector_d.from_elements(vec_ty, elems, loc=loc, ip=ip),
        dtype=_cutlass.Int32,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def load_ext(
    addr: Array | Pointer,
    *,
    dtype: type | None = None,
    count: int | None = None,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    order: MemOrder | None = None,
    scope: MemScope | None = None,
    prefetch: L2PrefetchSize | None = None,
    evict: L1EvictKind | None = None,
    cache_modifier: LoadCacheModifier | None = None,
    shared_space: SharedSpace | None = None,
    unified: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> (
    Int8
    | Uint8
    | Int16
    | Uint16
    | Int32
    | Uint32
    | Int64
    | Uint64
    | Int128
    | Uint128
    | Float32
    | Float64
    | Vector
):
    """Load a scalar (or a ``count``-element vector) from generic, global, or
    shared memory with explicit cache, eviction, and memory-ordering qualifiers
    (``nvvm.load.ext`` / PTX ``ld`` / ``ld.<vec>``).

    The element type is inferred from the pointer's ``dtype``; pass an explicit
    ``dtype`` to override (e.g. for untyped raw pointers).  Pass ``count`` to
    load a vector (PTX ``.v2``/``.v4``/``.v8``) and get a :class:`Vector` back.
    The underlying op supports only ``b8/b16/b32/b64/b128`` integer widths and
    ``f32``/``f64`` floats: load a 16-bit float as ``Int16`` and bitcast it
    yourself.

    :param addr: Address to load from (generic, global, or shared pointer).
    :type addr: Array | Pointer
    :param dtype: DSL type of the loaded value; inferred from ``addr.dtype``
        when omitted.  Must be an 8/16/32/64/128-bit integer (signed or
        unsigned) or ``Float32``/``Float64``; a 16-bit float must be loaded as
        ``Int16`` and bitcast.
    :type dtype: type | None
    :param count: If set, load ``count`` elements as a :class:`Vector` (PTX
        ``.v2``/``.v4``/``.v8``); if omitted, load a scalar.
    :type count: int | None
    :param l2_cache_hint: 64-bit L2 cache-eviction policy handle (generic /
        global space only).
    :type l2_cache_hint: int | Int64 | Uint64 | None
    :param order: Memory ordering (``weak`` default, ``relaxed``, ``acquire``,
        ``volatile``, ``mmio``).  ``relaxed`` / ``acquire`` require ``scope``.
    :type order: MemOrder | None
    :param scope: Memory scope (``cta``, ``cluster``, ``gpu``, ``sys``) for an
        ordered load.
    :type scope: MemScope | None
    :param prefetch: L2 prefetch size hint (generic / global space only).
    :type prefetch: L2PrefetchSize | None
    :param evict: L1 eviction-priority hint; mutually exclusive with
        ``cache_modifier``.
    :type evict: L1EvictKind | None
    :param cache_modifier: Cache operator (``ca``/``cg``/``cs``/``lu``/``cv``);
        only valid on the default ``weak`` ordering.
    :type cache_modifier: LoadCacheModifier | None
    :param shared_space: Shared sub-space (``cta`` default, ``cluster`` for
        distributed shared memory); for shared-space pointers only.
    :type shared_space: SharedSpace | None
    :param unified: Set the ``.unified`` qualifier (generic / global space
        only).
    :type unified: bool | None
    :return: The loaded scalar as the requested DSL type, or a :class:`Vector`
        of ``count`` elements when ``count`` is set.
    :rtype: Int8 | Uint8 | Int16 | Uint16 | Int32 | Uint32 | Int64 | Uint64 | Int128 | Uint128 | Float32 | Float64 | Vector
    :raises TypeError: if ``dtype`` is omitted and ``addr`` carries no
        ``dtype`` to infer from.
    :raises ValueError: if the qualifier combination is illegal, e.g.
        ``cache_modifier`` with ``evict`` or with non-``weak`` ordering;
        ``relaxed``/``acquire`` without ``scope``; ``volatile`` with a cache
        op/hint or ``unified`` (``prefetch`` is allowed); ``mmio`` without
        ``scope=sys``; or ``shared_space`` combined with
        ``l2_cache_hint``/``prefetch``/``unified``/``mmio``.

    .. code-block:: python

        ptr = arr.data_ptr() + tx
        # Stream a global value through L2 only (bypass L1).
        v = nvvm.load_ext(ptr, dtype=cutlass.Int32,
                          cache_modifier=LoadCacheModifier.CG)
        # Vectorized load: 4 x f32 in one ld.global.v4.b32, with cache control.
        v4 = nvvm.load_ext(ptr, dtype=cutlass.Float32, count=4,
                           cache_modifier=LoadCacheModifier.CG)
    """
    if dtype is None:
        dtype = getattr(addr, "dtype", None)
        if dtype is None:
            raise TypeError(
                "load_ext: cannot infer result type — addr has no dtype. "
                "Pass dtype= explicitly."
            )
    if dtype not in _EXT_SCALAR_DTYPES:
        raise TypeError(
            f"load_ext: unsupported dtype {getattr(dtype, '__name__', dtype)!r} "
            "(nvvm.load.ext supports only 8/16/32/64/128-bit integers and "
            "f32/f64); load a 16-bit float as Int16 and bitcast explicitly."
        )
    if count is not None and count not in _EXT_VEC_COUNTS:
        raise ValueError(
            f"load_ext: count must be one of {{2, 4, 8}} (PTX .v2/.v4/.v8), got {count}"
        )
    _assert_load_ext_qualifiers(
        order,
        scope,
        cache_modifier,
        evict,
        l2_cache_hint,
        prefetch,
        unified,
        shared_space,
        "load_ext",
    )
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    res_ty = (
        dtype.mlir_type  # type: ignore[union-attr]
        if count is None
        else ir.VectorType.get([count], dtype.mlir_type)  # type: ignore[union-attr]
    )
    raw = _nvvm.load_ext(
        res_ty,
        addr,
        l2_cache_hint=l2_cache_hint,
        order=_to_dialect(order, _MEMORDER_TO_DIALECT),
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        prefetch=_to_dialect(prefetch, _L2_PREFETCH_SIZE_TO_DIALECT),
        evict=_to_dialect(evict, _L1_EVICT_KIND_TO_DIALECT),
        cache_modifier=_to_dialect(cache_modifier, _LOAD_CACHE_MODIFIER_EXT_TO_DIALECT),
        shared_space=shared_space,
        unified=unified,
        loc=loc,
        ip=ip,
    )
    if count is None:
        return dtype(raw)
    # Vectorized load: return a register-backed Vector of `count` elements.
    if hasattr(raw, "ir_value"):
        raw = raw.ir_value()
    return Vector(raw, dtype=dtype, loc=loc, ip=ip)


@dsl_user_op
def mapa(
    addr: Array | Pointer,
    cta_rank: int | Int32 | Uint32,
    *,
    addrspace: int = 7,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array | Pointer:
    """Translate a local SMEM address to a peer CTA's distributed-SMEM address.

    Emits ``mapa.shared::cluster`` — given a
    pointer to local shared memory and a peer CTA's cluster rank, returns
    a pointer to the same SMEM offset in that peer's local SMEM, valid
    in the cluster (``shared::cluster``) state space.  The translation
    is a single-cycle hardware operation that exposes another CTA's
    SMEM through the cluster interconnect.  Passing ``addrspace=0``
    selects the generic-addressing form (PTX ``mapa`` without ``.space``),
    where both the source and result are generic addresses pointing to
    shared memory.

    Used to construct cluster-shared mbarrier pointers (so all
    participating CTAs can signal/wait on the same physical mbar) and
    for direct peer-CTA SMEM reads/writes that bypass GMEM.

    :param addr: Local-SMEM ``Array``/``Pointer``.  The same offset
        will be translated in the peer CTA's SMEM.
    :param cta_rank: Cluster rank of the target peer CTA.  Must be a
        valid rank within the launched cluster (``< cluster_size``);
        out-of-range values produce undefined results.
    :param addrspace: Address space of the returned pointer.  Default
        ``7`` is the distributed-shared (``shared::cluster``) space; pass
        ``0`` for the generic-addressing form.  No other address space is
        representable.  (A generic-addressed pointer to shared memory may be
        used with either form; the NVVM verifier enforces the exact rule.)
    :return: Pointer/Array (matching input type) addressing the peer
        CTA's SMEM at the same offset, in the requested address space.
    :raises ValueError: if ``addrspace`` is neither ``7``
        (shared::cluster) nor ``0`` (generic), or if a statically known
        ``cta_rank`` is negative.
    """
    # mapa maps either a shared source -> shared::cluster, or a generic
    # source -> generic (PTX `mapa{.space}`).  No other result space is
    # representable, so reject early with a clear message rather than
    # emitting an op the NVVM verifier would reject.
    _valid_spaces = (
        int(_cutlass.AddressSpace.generic),
        int(_cutlass.AddressSpace.dsmem),
    )
    if addrspace not in _valid_spaces:
        raise ValueError(
            f"mapa: addrspace must be {int(_cutlass.AddressSpace.dsmem)} "
            f"(shared::cluster) or {int(_cutlass.AddressSpace.generic)} (generic), "
            f"got {addrspace}"
        )
    # The CTA rank is an unsigned cluster rank; a negative static literal
    # is always invalid (out-of-range ranks give undefined results).
    if isinstance(cta_rank, int) and cta_rank < 0:
        raise ValueError(f"mapa: cta_rank must be non-negative, got {cta_rank}")

    # We deliberately do NOT cross-check the source vs result address space
    # here: a generic-addressed pointer to shared memory legitimately maps to
    # shared::cluster (e.g. a cvta'd accumulator passed with the default
    # addrspace=7), so the source space is not a reliable predictor of the
    # result form.  The NVVM verifier enforces the real operand-type rule.
    res_ty = _llvm.PointerType.get(addrspace)
    addr_ir = addr.ir_value() if hasattr(addr, "ir_value") else addr
    dsmem_ptr = _nvvm.mapa(res_ty, addr_ir, _cutlass.Int32(cta_rank), loc=loc, ip=ip)
    _dtype = addr.dtype if hasattr(addr, "dtype") else _cutlass.Int64
    if isinstance(addr, Pointer):
        return Pointer(dsmem_ptr, dtype=_dtype, space=_AddressSpace(addrspace))
    return Array(dsmem_ptr, dtype=_dtype, addrspace=addrspace)


@dsl_user_op
def mbarrier_arrive(
    addr: Array | Pointer,
    *,
    count: int | Int32 | Uint32 | None = None,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64 | None:
    """Decrement an mbarrier's pending arrival count by ``count`` (default 1).

    When the total arrivals satisfy the barrier's ``count`` threshold, the
    barrier fires: its internal parity flips and all waiters unblock.

    :param addr: Pointer/Array to the 64-bit SMEM mbarrier.
    :param count: How many arrival credits to consume in one call.  Defaults
        to 1 (the usual case).  Pass ``count=N`` to let a single thread
        batch-arrive on behalf of N threads — useful for pre-signaling slots:

        .. code-block:: python

            # Prologue: pre-signal all empty_bar slots so the producer's
            # first wait(parity=0) passes immediately.
            if nvvm.elect_sync():
                for i in cutlass.range_constexpr(NUM_STAGES):
                    nvvm.mbarrier_arrive(empty_bar + i)

    :param scope: Memory-ordering scope for the arrive (default CTA).
    :param relaxed: When ``True`` use ``.relaxed`` ordering instead of the
        default ``.release``.
    :raises TypeError: ``addr`` is not in shared, shared::cluster, or generic
        memory.
    :raises ValueError: ``count`` is a Python ``int`` outside ``[1, 2**20 - 1]``.

    **`mbarrier_arrive` vs `mbarrier_arrive_expect_tx`**: both count as a
    software arrive.  Use ``arrive_expect_tx`` instead when a TMA load is
    involved — it additionally registers the byte count that TMA hardware must
    deliver via ``complete_tx`` before the barrier fires.  For pure software
    producer-consumer pipelines (non-TMA), use ``mbarrier_arrive``.

    :return: Opaque 64-bit state token for shared/generic pointers; ``None``
        for cluster-space pointers.
    """
    count_max = 2**20 - 1
    if isinstance(count, int):
        if not (1 <= count <= count_max):
            raise ValueError(
                f"mbarrier_arrive: count must be in [1, {count_max}], got {count}"
            )
    elif count is not None:
        _runtime_assert(
            _cutlass.Int32(count) >= _cutlass.Int32(1),
            "mbarrier_arrive: count must be >= 1",
        )
        _runtime_assert(
            _cutlass.Int32(count) <= _cutlass.Int32(count_max),
            f"mbarrier_arrive: count must be <= {count_max}",
        )

    _addr = _to_ir(addr, loc, ip)
    addr_space = _llvm.PointerType(_addr.type).address_space
    if addr_space not in (
        _AddressSpace.smem,
        _AddressSpace.generic,
        _AddressSpace.dsmem,
    ):
        raise TypeError(
            f"mbarrier_arrive requires a pointer in shared "
            f"(address space {int(_AddressSpace.smem)}), generic "
            f"(address space {int(_AddressSpace.generic)}), or shared::cluster "
            f"(address space {int(_AddressSpace.dsmem)}) memory; "
            f"got address space {addr_space}."
        )

    if count is not None:
        count = _cutlass.Int32(count)
    _count = _to_ir(count, loc, ip) if count is not None else None
    is_cluster = addr_space == _AddressSpace.dsmem

    if is_cluster:
        # Inline PTX: the dialect lowering for a shared::cluster arrive emits an
        # extern func call with a dotted name that ptxas rejects on older LLVM
        # NVPTX backends, so we hand-write it.  The pointer's address space fixes
        # the .shared::cluster *space* (where the mbarrier resides); the .scope
        # is an independent qualifier (which threads observe the release) taken
        # from `scope`, defaulting to cluster for a cluster-resident barrier.
        _sem = ".relaxed" if relaxed else ".release"
        if scope is None or scope == MemScope.CLUSTER:
            _scope = ".cluster"
        elif scope == MemScope.CTA:
            _scope = ".cta"
        else:
            raise ValueError(
                f"mbarrier_arrive: scope {scope} is not valid for a "
                f"shared::cluster barrier arrive; use cta or cluster"
            )
        if count is not None:
            _nvvm_raw.inline_ptx(
                write_only_args=[],
                read_only_args=[_addr, _count],
                read_write_args=[],
                ptx_code=f"mbarrier.arrive{_sem}{_scope}.shared::cluster.b64"
                f" _, [{{$r0}}], {{$r1}};",
                loc=loc,
                ip=ip,
            )
        else:
            _nvvm_raw.inline_ptx(
                write_only_args=[],
                read_only_args=[_addr],
                read_write_args=[],
                ptx_code=f"mbarrier.arrive{_sem}{_scope}.shared::cluster.b64"
                f" _, [{{$r0}}];",
                loc=loc,
                ip=ip,
            )
        return None

    result = _nvvm_raw.mbarrier_arrive(
        _cutlass.Int64.mlir_type,
        _addr,
        count=_count,
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )
    result.owner.verify()
    return _cutlass.Int64(result)


@dsl_user_op
def mbarrier_arrive_drop(
    addr: Array | Pointer,
    *,
    count: int | Int32 | Uint32 | None = None,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64 | None:
    """1:1 wrapper over ``nvvm.mbarrier_arrive_drop``.

    Returns an opaque 64-bit state token for shared/generic pointers.
    Returns None for shared::cluster pointers.

    """
    if count is not None:
        count = _cutlass.Int32(count)
    _addr = _to_ir(addr, loc, ip)
    _count = _to_ir(count, loc, ip) if count is not None else None

    if _is_cluster_ptr(addr):
        op = _nvvm_raw.mbarrier_arrive_drop(
            None,
            _addr,
            count=_count,
            scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
            relaxed=relaxed,
            loc=loc,
            ip=ip,
        )
        op.operation.verify()
        return None
    result = _nvvm_raw.mbarrier_arrive_drop(
        _cutlass.Int64.mlir_type,
        _addr,
        count=_count,
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )
    result.owner.verify()
    return _cutlass.Int64(result)


@dsl_user_op
def mbarrier_arrive_drop_expect_tx(
    addr: Array | Pointer,
    txcount: int | Int32 | Uint32,
    *,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64 | None:
    """1:1 wrapper over ``nvvm.mbarrier_arrive_drop_expect_tx``.

    Returns an opaque 64-bit state token for shared/generic pointers.
    Returns None for shared::cluster pointers.

    """
    _addr = _to_ir(addr, loc, ip)
    _txcount = _to_ir(_cutlass.Int32(txcount), loc, ip)

    if _is_cluster_ptr(addr):
        op = _nvvm_raw.mbarrier_arrive_drop_expect_tx(
            None,
            _addr,
            _txcount,
            scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
            relaxed=relaxed,
            loc=loc,
            ip=ip,
        )
        op.operation.verify()
        return None
    result = _nvvm_raw.mbarrier_arrive_drop_expect_tx(
        _cutlass.Int64.mlir_type,
        _addr,
        _txcount,
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )
    result.owner.verify()
    return _cutlass.Int64(result)


@dsl_user_op
def mbarrier_arrive_drop_nocomplete(
    addr: Array | Pointer,
    count: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Wrapper over ``nvvm.mbarrier_arrive_drop_nocomplete``."""
    return _cutlass.Int64(
        _nvvm.mbarrier_arrive_drop_nocomplete(
            addr,
            _cutlass.Int32(count),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_arrive_expect_tx(
    addr: Array | Pointer,
    txcount: int | Int32 | Uint32,
    *,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64 | None:
    """Signal an mbarrier's TMA transaction count and count as the software arrive.

    Used in TMA pipelines where ``mbarrier_init(bar, count=1)`` was used:
    this call serves as the single software arrive *and* registers ``txcount``
    bytes that TMA hardware must deliver via ``complete_tx`` before the barrier
    fires.  No separate ``mbarrier_arrive`` call is needed.

    :param addr: Pointer/Array to the 64-bit SMEM mbarrier.
    :param txcount: Bytes that TMA ``complete_tx`` signals must deliver before
        the barrier fires.  The interpretation depends on how many producers
        share this barrier:

        * **Single producer** (``mbarrier_init(bar, count=1)``): one call,
          pass the *total* bytes for all TMA loads sharing this barrier:
          ``txcount = A_bytes + B_bytes``.  The barrier fires once TMA
          delivers all bytes.

        * **Two producers** (``mbarrier_init(bar, count=2)``): each producer
          calls ``arrive_expect_tx`` independently with *its own share only*
          (producer-A passes ``tx_A``, producer-B passes ``tx_B``).  The
          barrier fires after both arrives **and** ``tx_A + tx_B`` bytes
          have been delivered.

        Formula per load: ``num_rows * num_cols * sizeof(dtype)``.

    :raises ValueError: ``txcount`` is a negative Python ``int``.
    :raises TypeError: ``addr`` is not in shared, shared::cluster, or generic
        memory.

    **Must be called before** the corresponding ``cp_async_bulk_tensor_*``
    call(s), so the transaction counter is set before TMA can decrement it.

    **Call from one thread only** — either ``tx == 0`` or a single elected
    thread (``nvvm.elect_sync()``).  For CTA_2 multicast: leader only;
    multiply ``txcount`` by the number of CTAs in the cluster.

    :return: Opaque 64-bit state token for shared/generic pointers; ``None``
        for cluster-space pointers.

    .. code-block:: python

        # Single producer: separate elect_sync for arrive vs TMA loads (performance)
        if nvvm.elect_sync():
            nvvm.mbarrier_arrive_expect_tx(full_bar + s, A_bytes + B_bytes)
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cta_global(sA, tma_a, full_bar + s, coord_a)
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_shared_cta_global(sB, tma_b, full_bar + s, coord_b)
    """
    if isinstance(txcount, int) and txcount < 0:
        raise ValueError(
            f"mbarrier_arrive_expect_tx: txcount must be non-negative, got {txcount}"
        )

    _addr = _to_ir(addr, loc, ip)
    addr_space = _llvm.PointerType(_addr.type).address_space
    if addr_space not in (
        _AddressSpace.smem,
        _AddressSpace.generic,
        _AddressSpace.dsmem,
    ):
        raise TypeError(
            f"mbarrier_arrive_expect_tx requires a pointer in shared "
            f"(address space {int(_AddressSpace.smem)}), generic "
            f"(address space {int(_AddressSpace.generic)}), or shared::cluster "
            f"(address space {int(_AddressSpace.dsmem)}) memory; "
            f"got address space {addr_space}."
        )

    _txcount = _to_ir(_cutlass.Int32(txcount), loc, ip)
    is_cluster = addr_space == _AddressSpace.dsmem

    if is_cluster:
        op = _nvvm_raw.mbarrier_arrive_expect_tx(
            None,
            _addr,
            _txcount,
            scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
            relaxed=relaxed,
            loc=loc,
            ip=ip,
        )
        op.operation.verify()
        return None

    result = _nvvm_raw.mbarrier_arrive_expect_tx(
        _cutlass.Int64.mlir_type,
        _addr,
        _txcount,
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        relaxed=relaxed,
        loc=loc,
        ip=ip,
    )
    result.owner.verify()
    return _cutlass.Int64(result)


@dsl_user_op
def mbarrier_arrive_nocomplete(
    addr: Array | Pointer,
    count: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Wrapper over ``nvvm.mbarrier_arrive_nocomplete``."""
    return _cutlass.Int64(
        _nvvm.mbarrier_arrive_nocomplete(
            addr,
            _cutlass.Int32(count),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_complete_tx(
    addr: Array | Pointer,
    txcount: int | Int32 | Uint32,
    *,
    scope: MemScope | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Manually report completed async-copy bytes to an mbarrier (SM90+).

    Decrements the barrier's expected transaction count by ``txcount`` bytes
    without issuing a software arrive.  Use this when the hardware does not
    deliver the ``complete_tx`` signal automatically — for example, after a
    ``cp_async_shared_global`` pipeline that does *not* use TMA.

    For TMA-based pipelines (``cp_async_bulk_tensor_*``), the TMA hardware
    delivers ``complete_tx`` automatically when the copy finishes — do **not**
    call ``mbarrier_complete_tx`` in that case (double-counting corrupts the
    barrier state).

    :param addr: Pointer/Array to the 64-bit SMEM mbarrier.
    :param txcount: Number of bytes to report as completed.  Must equal the
        total bytes delivered by the corresponding async copies.
    :param scope: Memory scope (default: ``cta``).
    :raises ValueError: ``txcount`` is a negative Python ``int``.
    :raises TypeError: ``addr`` is not in shared, shared::cluster, or generic
        memory.
    """
    if isinstance(txcount, int) and txcount < 0:
        raise ValueError(
            f"mbarrier_complete_tx: txcount must be non-negative, got {txcount}"
        )
    _addr = _to_ir(addr, loc, ip)
    addr_space = _llvm.PointerType(_addr.type).address_space
    if addr_space not in (
        _AddressSpace.smem,
        _AddressSpace.generic,
        _AddressSpace.dsmem,
    ):
        raise TypeError(
            f"mbarrier_complete_tx requires a pointer in shared "
            f"(address space {int(_AddressSpace.smem)}), generic "
            f"(address space {int(_AddressSpace.generic)}), or shared::cluster "
            f"(address space {int(_AddressSpace.dsmem)}) memory; "
            f"got address space {addr_space}."
        )

    _nvvm.mbarrier_complete_tx(
        addr,
        _cutlass.Int32(txcount),
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mbarrier_expect_tx(
    addr: Array | Pointer,
    txcount: int | Int32 | Uint32,
    *,
    scope: MemScope | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wrapper over ``nvvm.mbarrier_expect_tx``.

    """
    _nvvm.mbarrier_expect_tx(
        addr,
        _cutlass.Int32(txcount),
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mbarrier_init(
    addr: Array | Pointer,
    count: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Initialize a 64-bit mbarrier object in shared memory.

    Sets the expected-arrival count and resets the barrier's phase to 0.
    Lowers to ``mbarrier.init{.shared{::cta}}.b64 [addr], count``.

    :param addr: Pointer or Array addressing the 64-bit mbarrier object.
        Must resolve to shared memory at runtime.  ``cutlass.AddressSpace.smem``
        is preferred (NVVM emits the ``.shared`` variant with a 32-bit
        address operand); ``cutlass.AddressSpace.generic`` is also accepted and
        emits the generic-form ``mbarrier.init.b64`` instruction, which
        requires the runtime address to fall within the ``.shared::cta``
        window (behavior is undefined otherwise).
        Typically allocated via
        ``cutlass.Array(cutlass.Int64, N, space=cutlass.AddressSpace.smem)``.
    :type addr: cutlass.Array or cutlass.Pointer
    :param count: Expected arrival count: how many ``mbarrier_arrive`` (or
        ``mbarrier_arrive_expect_tx``) calls must be satisfied before the
        barrier fires and flips its phase.  Valid range is
        ``[1, 2**20 - 1]``.  Constexpr ``int`` values are checked at trace
        time; dynamic values get a ``--enable-assertions``-gated runtime
        check.  For TMA pipelines use ``1``: one elected thread calls
        ``arrive_expect_tx`` and TMA hardware delivers ``complete_tx``.
    :type count: int or cutlass.Int32 or cutlass.Uint32
    :raises TypeError: ``addr`` is in an address space other than
        ``SHARED`` or ``GENERIC`` (e.g. global, local, tensor memory, or
        ``SHARED_CLUSTER``: the PTX ISA does not define ``mbarrier.init``
        for these).
    :raises ValueError: ``count`` is a Python ``int`` outside ``[1, 2**20 - 1]``.

    .. code-block:: python

        # Preferred: one warp initializes one disjoint mbarrier group.
        warp_idx = cute.arch.warp_idx()
        tidx, _, _ = cute.arch.thread_idx()
        lane_idx = tidx & 31

        if warp_idx == 0:
            if lane_idx < NUM_AB_STAGES:
                nvvm.mbarrier_init(ab_full_bar + lane_idx, 1)
            nvvm.bar_warp_sync(cute.arch.FULL_MASK)
        elif warp_idx == 1:
            if lane_idx < NUM_AB_STAGES:
                nvvm.mbarrier_init(ab_empty_bar + lane_idx, ab_empty_count)
            nvvm.bar_warp_sync(cute.arch.FULL_MASK)
        elif warp_idx == 2:
            if lane_idx < NUM_SF_STAGES:
                nvvm.mbarrier_init(sf_full_bar + lane_idx, 1)
            nvvm.bar_warp_sync(cute.arch.FULL_MASK)
        elif warp_idx == 3:
            if lane_idx < NUM_SF_STAGES:
                nvvm.mbarrier_init(sf_empty_bar + lane_idx, sf_empty_count)
            nvvm.bar_warp_sync(cute.arch.FULL_MASK)
        elif warp_idx == 4:
            if lane_idx < 3:
                count = 1 if lane_idx == 0 else 8 if lane_idx == 1 else 32
                nvvm.mbarrier_init(aux_bar + lane_idx, count)
            nvvm.bar_warp_sync(cute.arch.FULL_MASK)

        nvvm.fence_mbarrier_init()
        nvvm.barrier_cta_sync()

    .. code-block:: python

        # Fallback: simple elected-thread init for a few barriers.
        if warp_idx == 0:
            if nvvm.elect_sync():
                for i in cutlass.range_constexpr(NUM_STAGES):
                    nvvm.mbarrier_init(full_bar + i, 1)
                    nvvm.mbarrier_init(empty_bar + i, 1)
        nvvm.fence_mbarrier_init()
        nvvm.barrier_cta_sync()
    """
    # Address-space check: PTX ISA defines mbarrier.init on .shared{::cta}
    # and (with no state-space qualifier) on generic addressing.  Generic
    # is legal but emits the slower form with a 64-bit address operand and
    # an implicit cvta.shared.u64 upstream.  Any other address space
    # (global, local, tensor, shared::cluster) makes the lowered PTX
    # ill-typed for mbarrier.init, so we reject it at trace time.
    ir_addr = _to_ir(addr, None, None)
    addr_space = _llvm.PointerType(ir_addr.type).address_space
    if addr_space not in (_cutlass.AddressSpace.smem, _cutlass.AddressSpace.generic):
        raise TypeError(
            f"mbarrier_init requires a pointer in shared "
            f"(address space {int(_cutlass.AddressSpace.smem)}) or generic "
            f"(address space {int(_cutlass.AddressSpace.generic)}) memory; "
            f"got address space {addr_space}."
        )

    count_max = 2**20 - 1
    if isinstance(count, int):
        if not (1 <= count <= count_max):
            raise ValueError(
                f"mbarrier_init count must be in [1, {count_max}], got {count}"
            )
    else:
        _runtime_assert(
            _cutlass.Int32(count) >= _cutlass.Int32(1),
            "mbarrier_init: count must be >= 1",
        )
        _runtime_assert(
            _cutlass.Int32(count) <= _cutlass.Int32(count_max),
            f"mbarrier_init: count must be <= {count_max}",
        )

    _nvvm.mbarrier_init(
        addr,
        _cutlass.Int32(count),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_mbarrier_init(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Make mbarrier init writes visible to all threads before first use.

    PTX address-space semantics require an explicit fence between writing an
    mbarrier object (via :func:`mbarrier_init`) and the first arrive or wait
    on that barrier.  Without this fence the init write may not be visible
    to threads in a different warp or address space.  The fence itself is a
    per-thread no-op; visibility comes from the CTA-wide sync that follows.

    .. code-block:: python

        # One elected thread initialises all stages.
        if warp_idx == 0:
            if nvvm.elect_sync():
                for i in cutlass.range_constexpr(NUM_STAGES):
                    nvvm.mbarrier_init(full_bar + i, 1)
                    nvvm.mbarrier_init(empty_bar + i, 1)
        # Make init visible before any warp calls arrive/wait.
        nvvm.fence_mbarrier_init()
        nvvm.barrier_cta_sync()
    """
    _nvvm_raw.fence_mbarrier_init(loc=loc, ip=ip)


@dsl_user_op
def mbarrier_test_wait(
    addr: Array | Pointer,
    state_or_phase: Int64 | Int32,
    *,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Test whether an mbarrier phase has completed.

    Returns the PTX ``waitComplete`` predicate for ``mbarrier.test_wait``.
    The PTX ISA 9.3 primary-phase form can also produce ``reportPredicate`` and
    ``reportValue`` operands; this wrapper intentionally exposes only the
    completion boolean.

    :param addr: Pointer/Array to the 64-bit mbarrier object.
    :param state_or_phase: State token returned by ``mbarrier_arrive`` or a
        parity value for parity-style waits.
    :param scope: Optional memory scope when using explicit acquire/relaxed
        semantics.
    :param relaxed: Emit relaxed ordering when ``True``; omit for default
        acquire semantics.
    :return: ``True`` when the requested phase has completed.

    """
    return _cutlass.Boolean(
        _nvvm.mbarrier_test_wait(
            _cutlass.Boolean.mlir_type,
            None,
            None,
            addr,
            state_or_phase,
            scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
            relaxed=relaxed,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_try_wait(
    addr: Array | Pointer,
    state_or_phase: Int64 | Int32,
    *,
    ticks: int | Int32 | Uint32 | None = None,
    scope: MemScope | None = None,
    relaxed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Try to wait for an mbarrier phase, optionally with a time hint.

    Returns the PTX ``waitComplete`` predicate for ``mbarrier.try_wait``.  If the
    phase has not completed, the executing thread may suspend for up to
    ``ticks`` nanoseconds, or for an implementation-defined time when ``ticks``
    is omitted.  PTX ISA 9.3 primary-phase report operands are not exposed by
    this wrapper.

    :param addr: Pointer/Array to the 64-bit mbarrier object.
    :param state_or_phase: State token returned by ``mbarrier_arrive`` or a
        parity value for parity-style waits.
    :param ticks: Optional time hint in nanoseconds.
    :param scope: Optional memory scope when using explicit acquire/relaxed
        semantics.
    :param relaxed: Emit relaxed ordering when ``True``; omit for default
        acquire semantics.
    :return: ``True`` when the requested phase has completed.

    """
    if ticks is not None:
        ticks = _cutlass.Int32(ticks)
    _addr = _to_ir(addr, loc, ip)
    _state = _to_ir(state_or_phase, loc, ip)
    operands = [_addr, _state]
    if ticks is not None:
        operands.append(_to_ir(ticks, loc, ip))
    attrs: dict[str, ir.Attribute] = {
        "resultSegmentSizes": ir.DenseI32ArrayAttr.get([1, 0, 0]),
    }
    _ctx = ir.Context.current
    if scope is not None:
        attrs["scope"] = ir.AttrBuilder.get("MemScopeKindAttr")(
            _MEMSCOPE_TO_DIALECT[scope], context=_ctx
        )
    if relaxed is not None:
        attrs["relaxed"] = ir.AttrBuilder.get("BoolAttr")(relaxed, context=_ctx)
    op = ir.Operation.create(
        "nvvm.mbarrier.try_wait",
        results=[_cutlass.Boolean.mlir_type],
        operands=operands,
        attributes=attrs,
        loc=loc,
        ip=ip,
    )
    return _cutlass.Boolean(op.result)


@dsl_user_op
def mbarrier_try_wait_parity(
    addr: Array | Pointer,
    phase: int | Int32 | Uint32,
    *,
    time_limit: int | Int32 | Uint32 = 10_000_000,
    scope: MBarrierScope | None = None,
    order: MemOrder | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Attempt a parity try-wait on an mbarrier phase.

    This issues one ``mbarrier.try_wait.parity`` attempt. If the phase has not
    completed, the executing thread may be hardware-suspended for up to
    ``time_limit`` nanoseconds before returning ``False``. The caller is
    responsible for retrying when a blocking wait is needed.

    :param addr: Pointer/Array to the 64-bit SMEM mbarrier object.
    :param phase: Parity value to wait **against**.  Returns ``True`` once the
        barrier's internal parity differs from ``phase`` (i.e. the barrier
        fired and advanced its phase).  Returns ``False`` on timeout.

        * Fresh barrier starts at parity **0**.
        * Pass ``phase=0`` to block until the first arrival: waits because
          current parity (0) equals ``phase`` (0).
        * Pass ``phase=1`` on a fresh barrier to pass immediately: current
          parity (0) ≠ ``phase`` (1), so no waiting needed.

    :param time_limit: Hardware suspend timeout in nanoseconds.  Defaults to
        ``10_000_000`` (10 ms). Omit it unless you need a different suspend
        window. The warp may be hardware-suspended for up to this many
        nanoseconds on each call.

    :return: ``True`` when the barrier phase has advanced past ``phase``;
        ``False`` if ``time_limit`` expired without completion.
    :raises ValueError: ``phase`` is a Python ``int`` other than 0 or 1.
    :raises ValueError: ``time_limit`` is a negative Python ``int``.
    :raises TypeError: ``addr`` is not in shared or generic memory.

    **Always wrap in a while loop** — the retry is the caller's responsibility:

    .. code-block:: python

        while not nvvm.mbarrier_try_wait_parity(bar + s, parity):
            pass

    This lowers to ``mbarrier.try_wait.parity.acquire.cta.shared::cta.b64``
    with explicit ``.acquire.cta`` ordering (ensures TMA writes are visible
    after the wait).  The same intrinsic without the ``.acquire.cta``
    qualifier has weaker ordering and benchmarks ~5% slower, so avoid it.

    **Phase formula for a circular N-stage pipeline at iteration k:**

    .. code-block:: python

        cons_parity = (k // cutlass.Int32(NUM_STAGES)) & cutlass.Int32(1)
        while not nvvm.mbarrier_try_wait_parity(full_bar + s, cons_parity):
            pass

    """
    # Trace-time-only checks (this is a hot inner-loop op, so no runtime
    # asserts): catch constexpr misuse and a wrong address space cheaply.
    if isinstance(phase, int) and phase not in (0, 1):
        raise ValueError(
            f"mbarrier_try_wait_parity: phase (parity) must be 0 or 1, got {phase}"
        )
    if isinstance(time_limit, int) and time_limit < 0:
        raise ValueError(
            f"mbarrier_try_wait_parity: time_limit must be "
            f"non-negative, got {time_limit}"
        )
    addr_space = _llvm.PointerType(_to_ir(addr, loc, ip).type).address_space
    if addr_space not in (_AddressSpace.smem, _AddressSpace.generic):
        raise TypeError(
            f"mbarrier_try_wait_parity requires a pointer in shared "
            f"(address space {int(_AddressSpace.smem)}) or generic "
            f"(address space {int(_AddressSpace.generic)}) memory; "
            f"got address space {addr_space}."
        )
    return _cutlass.Boolean(
        _nvvm.mbarrier_try_wait_parity_timelimit(
            addr,
            _cutlass.Int32(phase),
            _cutlass.Int32(time_limit),
            scope=_to_dialect(scope, _MBARRIER_SCOPE_TO_DIALECT),
            order=_to_dialect(order, _MEMORDER_TO_DIALECT),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_try_wait_timelimit(
    addr: Array | Pointer,
    state: int | Int64 | Uint64,
    time_limit: int | Int32 | Uint32,
    *,
    scope: MBarrierScope | None = None,
    order: MemOrder | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Try to wait for a state-token mbarrier phase with an explicit time limit.

    This is the non-parity time-limited ``mbarrier.try_wait`` form.  It returns
    only the PTX ``waitComplete`` predicate; PTX ISA 9.3
    ``reportPredicate``/``reportValue`` operands are not exposed here.

    :param addr: Pointer/Array to the 64-bit mbarrier object.
    :param state: State token returned by a previous mbarrier arrive operation.
    :param time_limit: Time hint in nanoseconds before the suspended thread may
        resume and return ``False``.
    :param scope: Optional memory scope for the wait.
    :param order: Optional memory-order qualifier.
    :return: ``True`` when the state-token phase has completed; ``False`` when
        the time limit expires first.

    """
    return _cutlass.Boolean(
        _nvvm.mbarrier_try_wait_timelimit(
            addr,
            _cutlass.Int64(state),
            _cutlass.Int32(time_limit),
            scope=_to_dialect(scope, _MBARRIER_SCOPE_TO_DIALECT),
            order=_to_dialect(order, _MEMORDER_TO_DIALECT),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_wait(
    addr: Array | Pointer,
    state: int | Int64 | Uint64,
    kind: MBarrierWait,
    *,
    scope: MBarrierScope | None = None,
    order: MemOrder | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Wrapper over ``nvvm.mbarrier_wait``."""
    return _cutlass.Boolean(
        _nvvm.mbarrier_wait(
            addr,
            _cutlass.Int64(state),
            _MBARRIER_WAIT_TO_DIALECT[kind],
            scope=_to_dialect(scope, _MBARRIER_SCOPE_TO_DIALECT),
            order=_to_dialect(order, _MEMORDER_TO_DIALECT),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mbarrier_wait_parity(
    addr: Array | Pointer,
    phase: int | Int32 | Uint32,
    kind: MBarrierWait,
    *,
    scope: MBarrierScope | None = None,
    order: MemOrder | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean:
    """Test- or try-wait on an mbarrier's parity (no time-limit form).

    Returns the ``waitComplete`` predicate: ``True`` once the barrier's phase
    has advanced past ``phase`` (its internal parity differs), else ``False``.

    :param addr: Pointer/Array to the 64-bit mbarrier, in shared or generic
        memory.
    :param phase: Parity to wait against (``0`` or ``1``).  Completes when the
        barrier's internal parity differs from ``phase``; a fresh barrier
        starts at parity 0.
    :param kind: ``MBarrierWait.TEST`` selects ``mbarrier.test_wait.parity``
        (a non-blocking check that never suspends); ``MBarrierWait.TRY``
        selects ``mbarrier.try_wait.parity`` (may hardware-suspend the thread
        until the phase completes or an implementation-defined limit).  Both
        return the ``waitComplete`` predicate, so a ``TRY`` wait is wrapped in
        a retry loop.
    :param scope: Memory-ordering scope (default CTA).
    :param order: Memory ordering; the underlying op supports only ``acquire``
        (the effective default) or ``relaxed``.
    :raises ValueError: ``phase`` is a Python ``int`` other than 0 or 1.
    :return: ``True`` when the barrier phase has advanced past ``phase``;
        ``False`` otherwise.

    .. code-block:: python

        # Blocking consumer wait (TRY): retry until the phase flips.
        while not nvvm.mbarrier_wait_parity(bar, parity, nvvm.MBarrierWait.TRY):
            pass

        # Non-blocking probe (TEST): single check, never suspends.
        done = nvvm.mbarrier_wait_parity(bar, parity, nvvm.MBarrierWait.TEST)
    """
    # Trace-time-only check (hot inner-loop op): catch constexpr parity misuse.
    if isinstance(phase, int) and phase not in (0, 1):
        raise ValueError(
            f"mbarrier_wait_parity: phase (parity) must be 0 or 1, got {phase}"
        )
    return _cutlass.Boolean(
        _nvvm.mbarrier_wait_parity(
            addr,
            _cutlass.Int32(phase),
            _MBARRIER_WAIT_TO_DIALECT[kind],
            scope=_to_dialect(scope, _MBARRIER_SCOPE_TO_DIALECT),
            order=_to_dialect(order, _MEMORDER_TO_DIALECT),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mma_smem_desc(
    pointer: int | Int32 | Uint32,
    ldm: int | Int32 | Uint32,
    stride: int | Int32 | Uint32,
    base_offset: int | Int8 | Uint8,
    swizzle: int | Int8 | Uint8,
    *,
    mma_desc_version: int | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Wrapper over ``nvvm.mma_smem_desc``."""
    return _cutlass.Int64(
        _nvvm.mma_smem_desc(
            _cutlass.Int32(pointer),
            _cutlass.Int32(ldm),
            _cutlass.Int32(stride),
            _cutlass.Int8(base_offset),
            _cutlass.Int8(swizzle),
            mma_desc_version=mma_desc_version,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def mma_sp_sync(
    res: ir.Type,
    shape: ir.Attribute,
    operand_a: ir.Value,
    operand_b: ir.Value,
    operand_c: ir.Value,
    sparse_metadata: int | Int32 | Uint32,
    sparsity_selector: int | Int32 | Uint32,
    *,
    int_overflow_behavior: MMAIntOverflow | None = None,
    multiplicand_a_ptx_type: MMAType | None = None,
    multiplicand_b_ptx_type: MMAType | None = None,
    ordered_metadata: bool | None = None,
    kind: MMAKind | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    """Wrapper over ``nvvm.mma_sp_sync``.

    Returns an LLVM struct.  Caller provides the raw MLIR result type
    as *res*.
    """
    return _nvvm_raw.mma_sp_sync(
        res,
        shape,
        operand_a,
        operand_b,
        operand_c,
        _cutlass.Int32(sparse_metadata),
        _cutlass.Int32(sparsity_selector),
        int_overflow_behavior=_to_dialect(
            int_overflow_behavior, _MMA_INT_OVERFLOW_TO_DIALECT
        ),
        multiplicand_a_ptx_type=_to_dialect(
            multiplicand_a_ptx_type, _MMA_TYPE_TO_DIALECT
        ),
        multiplicand_b_ptx_type=_to_dialect(
            multiplicand_b_ptx_type, _MMA_TYPE_TO_DIALECT
        ),
        ordered_metadata=ordered_metadata,
        kind=_to_dialect(kind, _MMA_KIND_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def mul(
    a: Int16 | Int32 | Int64,
    b: Int16 | Int32 | Int64,
    mode: MulMode,
    *,
    is_signed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Int32 | Int64:
    """Wrapper over ``nvvm.mul``."""
    _wide_type = {Int16: Int32, Int32: Int64}
    src_type = type(a)
    if mode == "wide":
        res_type = _wide_type[src_type]
    else:
        res_type = src_type
    return res_type(
        _nvvm.mul(
            res_type.mlir_type,
            a,
            b,
            _MUL_MODE_TO_DIALECT[mode],
            is_signed=is_signed,
            loc=loc,
            ip=ip,
        )
    )






@dsl_user_op
def mul_packed_f32x2(
    src_a: tuple | Vector,
    src_b: tuple | Vector,
    *,
    rnd: FPRoundingMode | None = None,
    ftz: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> tuple | Vector:
    """Wrapper over ``nvvm.mul_packed_f32x2``.

    Accepts a 2-tuple of f32 scalars or a ``Vector`` for each operand and
    returns a tuple when called with tuples, else a ``Vector``.
    """
    returns_tuple = isinstance(src_a, tuple)
    vec_a = _packed_f32x2_to_vec(src_a, loc=loc, ip=ip)
    vec_b = _packed_f32x2_to_vec(src_b, loc=loc, ip=ip)
    vec_a_ir = _to_ir(vec_a, loc, ip)
    vec_res = _call_nvvm_result_compat(
        _nvvm_raw.mul_packed_f32x2,
        vec_a_ir.type,
        vec_a_ir,
        _to_ir(vec_b, loc, ip),
        rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
        ftz=ftz,
        loc=loc,
        ip=ip,
    )
    return _unpack_packed_f32x2(vec_res) if returns_tuple else vec_res


@dsl_user_op
def nanosleep(
    duration: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wrapper over ``nvvm.nanosleep``."""
    _nvvm.nanosleep(
        _cutlass.Int32(duration),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def prefetch_l1(
    addr: Array | Pointer,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Bring a cache line into L1.

    Emits ``prefetch.L1 [addr]`` (or ``prefetch.global.L1`` /
    ``prefetch.local.L1`` when the address space is statically
    visible).  Per-thread, non-collective; the cache line is warm
    but no register is loaded — subsequent reads of ``addr`` still
    have to issue an ``ld``.

    For TMA descriptor warm-up use :func:`prefetch_tensormap`; for
    the uniform-cache hint use :func:`prefetchu`; for an L2 warm-up
    (with optional eviction-priority hint) use :func:`prefetch_l2`.

    For conditional execution wrap the call: ``if pred:
    nvvm.prefetch_l1(addr)`` — the dialect does support a PTX
    ``@p prefetch`` guard, but that lowering is undocumented and
    equivalent to the explicit ``if`` for every observable effect.

    :param addr: Pointer/Array in generic, global, or local space.
        Prefetch on SMEM is a no-op per the PTX ISA.
    :type addr: Array or Pointer

    .. code-block:: python

        # Warm L1 ahead of a global load
        nvvm.prefetch_l1(gmem_ptr)
    """
    _nvvm.prefetch(
        addr,
        cache_level=_PrefetchCacheLevelDialect.L1,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def prefetch_l2(
    addr: Array | Pointer,
    *,
    evict_priority: EvictPriority | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Bring a cache line into L2, optionally with eviction-priority hint.

    Emits ``prefetch.L2 [addr]`` (or
    ``prefetch.global.L2::<priority> [addr]`` when
    ``evict_priority`` is set).  Use to warm L2 before a TMA
    descriptor read or to bias L2 replacement against re-fetched
    data with ``"last"``.

    For conditional execution wrap the call in ``if``; the same
    note on :func:`prefetch_l1` applies.

    :param addr: Pointer/Array in generic, global, or local space.
        Prefetch on SMEM is a no-op per the PTX ISA.
    :type addr: Array or Pointer
    :param evict_priority: ``"normal"`` or ``"last"`` (the only two policies
        the ``prefetch`` instruction supports), or ``None`` (default) to leave
        the default policy.  Maps to the PTX ``.L2::evict_normal`` /
        ``.L2::evict_last`` modifier with the ``evict_`` prefix dropped, to
        match the rest of the memory-model API.  Other ``EvictPriority``
        members are valid on ``ld`` / ``st`` / ``cp`` but rejected here.
    :type evict_priority: EvictPriority, optional
    :raises ValueError: if ``evict_priority`` is neither ``"normal"`` nor
        ``"last"``.

    .. code-block:: python

        # Warm L2 with an eviction hint
        nvvm.prefetch_l2(gmem_ptr, evict_priority="last")
    """
    _assert_prefetch_evict_priority(evict_priority, "prefetch")
    _nvvm.prefetch(
        addr,
        cache_level=_PrefetchCacheLevelDialect.L2,
        evict_priority=_to_dialect(evict_priority, _EVICT_PRIORITY_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def prefetchu(
    addr: Array | Pointer,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Prefetch into the uniform L1 cache.

    Emits ``prefetchu.L1 [addr]``.  The uniform cache backs
    addresses that all lanes in a warp agree on (e.g. constants,
    kernel parameters) and is separate from the per-thread L1
    data cache.  Use when a uniformly-addressed value is about
    to be read by many warps.

    For conditional execution wrap the call in ``if``; the same
    note on :func:`prefetch_l1` applies.

    :param addr: Pointer/Array to a uniformly-addressed location.
    :type addr: Array or Pointer

    .. code-block:: python

        nvvm.prefetchu(param_ptr)
    """
    _nvvm.prefetch(
        addr,
        uniform=True,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def prefetch_tensormap(
    addr: Array | Pointer,
    *,
    space: TensormapSpace = "const",  # type: ignore[assignment]
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Warm the TMA tensormap descriptor cache.

    Emits ``prefetch.tensormap [addr]`` (default ``space="const"``)
    or ``prefetch.param.tensormap [addr]`` (``space="param"``).
    Issue once, on a single thread, before the first
    ``cp.async.bulk.tensor`` that consumes the descriptor — cuts the
    first TMA's launch latency by hiding the descriptor fetch behind
    independent work.

    The canonical pattern is ``if nvvm.elect_sync(): prefetch_tensormap(...)``
    — the explicit ``if`` is the recommended way to make the prefetch
    conditional; the dialect's undocumented ``@p`` guard is equivalent.

    Typical pattern (one lane warms each descriptor):

    .. code-block:: python

        if nvvm.elect_sync():
            nvvm.prefetch_tensormap(tma_desc_a.get_ptr())
            nvvm.prefetch_tensormap(tma_desc_b.get_ptr())

    :param addr: Pointer to the tensormap descriptor.
    :type addr: Array or Pointer
    :param space: ``"const"`` (default) or ``"param"`` — the state
        space the descriptor lives in.  ``"param"`` is the
        kernel-argument case; ``"const"`` covers the typical
        ``__constant__`` / ``cutlass.GridConstant`` case.
    :type space: TensormapSpace

    """
    _nvvm.prefetch(
        addr,
        tensormap=True,
        in_param_space=_TENSORMAP_SPACE_TO_IN_PARAM[space],
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def prmt(
    lo: int | Int32 | Uint32,
    selector: int | Int32 | Uint32,
    mode: PermuteMode,
    *,
    hi: int | Int32 | Uint32 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.prmt``."""
    if hi is not None:
        hi = _cutlass.Int32(hi)
    return _cutlass.Int32(
        _nvvm.prmt(
            _cutlass.Int32(lo),
            _cutlass.Int32(selector),
            _PERMUTE_MODE_TO_DIALECT[mode],
            hi=hi,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def read_sreg_hw(
    num: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.read_sreg_hw``."""
    return _cutlass.Int32(
        _nvvm.read_sreg_hw(
            _cutlass.Int32(num),
            loc=loc,
            ip=ip,
        )
    )



@dsl_user_op
def shfl_sync(
    thread_mask: int | Int32 | Uint32,
    val: Int32 | Float32,
    offset: int | Int32 | Uint32,
    mask_and_clamp: int | Int32 | Uint32,
    kind: Shfl,
    *,
    return_value_and_is_valid: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Float32 | tuple[Int32 | Float32, Boolean]:
    """Synchronise participating lanes and shuffle a 32-bit value within a warp.

    Emits ``shfl.sync.{idx|up|down|bfly}.b32`` — the PTX warp-shuffle family.
    All lanes named in *thread_mask* must execute the same instruction before
    any lane receives a shuffled value from another lane.  This synchronizes the
    register exchange itself, but it does **not** provide the memory-ordering
    guarantee of ``bar.sync`` / :func:`bar_warp_sync`.

    **ShflKind variants:**

    * ``"idx"``  — each lane reads from absolute source lane *offset*;
      ``result[lane] = val[offset]``.  Used for broadcast (``offset=0``).
    * ``"up"``   — each lane reads from lane ``max(lane - offset, lower_bound)``;
      result is the value *offset* lanes earlier in the warp.
    * ``"down"`` — each lane reads from lane ``min(lane + offset, upper_bound)``;
      result is the value *offset* lanes ahead.  Used in butterfly reductions.
    * ``"bfly"`` — each lane reads from lane ``lane XOR offset``; enables
      butterfly reduction trees without out-of-range clamping.

    **mask_and_clamp encoding:**

    ``mask_and_clamp`` is a packed 32-bit integer that controls sub-warp
    segmentation and the out-of-range clamp boundary:

    * Bits ``[12:8]`` — *segmask*: ``(WARP_SIZE - 1) XOR (width - 1)``.  Lanes
      that differ only in the low ``log2(width)`` bits form one shuffle segment.
      Use ``(31 << 8) | clamp`` for a full 32-lane warp.
    * Bits ``[4:0]``  — *clamp*: upper boundary (``width - 1``) for
      ``idx`` / ``down`` / ``bfly``; lower boundary (``0``) for ``up``.
      When a source lane would fall outside the segment, the clamped boundary
      lane's value is returned instead.

    For a full 32-lane warp these precomputed values are correct:

    * ``"idx"`` / ``down`` / ``bfly``: ``mask_and_clamp = 0x1F``
      (segmask = 0, clamp = 31)
    * ``"up"``:  ``mask_and_clamp = 0x00``
      (segmask = 0, clamp = 0)

    The following higher-level helpers compute ``mask_and_clamp`` automatically
    from a ``width`` argument; prefer them unless you need explicit control
    over the packed field:

    * ``shuffle_sync``
    * ``shuffle_sync_up``
    * ``shuffle_sync_down``
    * ``shuffle_sync_xor``

    :param thread_mask: 32-bit participation mask; bit *i* = 1 means lane *i*
        takes part.  All participating lanes must execute the instruction
        together.  Pass ``0xFFFFFFFF`` for a full-warp shuffle.
    :type thread_mask: int or cutlass.Int32 or cutlass.Uint32
    :param val: The 32-bit value this lane contributes to the shuffle.
    :type val: cutlass.Int32 or cutlass.Float32
    :param offset: Interpretation depends on *kind*:
        ``idx`` → absolute source lane ID ``[0, 31]``;
        ``up`` / ``down`` → relative lane delta ``[0, 31]``;
        ``bfly`` → XOR lane mask ``[0, 31]``.
    :type offset: int or cutlass.Int32 or cutlass.Uint32
    :param mask_and_clamp: Packed sub-warp segmentation and clamp boundary.
        See encoding description above.  For full-warp shuffles use
        ``0x1F`` (idx/down/bfly) or ``0x00`` (up).
    :type mask_and_clamp: int or cutlass.Int32 or cutlass.Uint32
    :param kind: Shuffle direction.  One of ``"idx"``,
        ``"up"``, ``"down"``, ``"bfly"``.
    :type kind: Shfl
    :param return_value_and_is_valid: If ``True``, return a
        ``(value, is_valid)`` tuple where *is_valid* is ``True`` when the
        source lane was within the active segment (i.e. the result is not the
        clamped fallback).  Defaults to ``None`` (return value only).
    :type return_value_and_is_valid: bool, optional
    :return: Shuffled value from the source lane, or a
        ``(value, is_valid)`` tuple when *return_value_and_is_valid* is
        ``True``.
    :rtype: cutlass.Int32 or cutlass.Float32, or
        tuple[cutlass.Int32 or cutlass.Float32, cutlass.Boolean]
    :raises ValueError: if a static *thread_mask* or *mask_and_clamp* does not
        fit in 32 bits, if a static *offset* is outside ``[0, 31]``, or if
        *kind* is not one of ``"idx"``, ``"up"``, ``"down"``, ``"bfly"``.
        Runtime (non-``int``) values are not checked at trace time.

    **Constraints:**

    * All lanes in *thread_mask* must reach the instruction; a subset that
      diverges before ``shfl.sync`` causes undefined behaviour.
    * *offset* and the low bits of *mask_and_clamp* must be in ``[0, 31]``.
    * Available on SM30+ (Kepler); the synchronisation guarantee requires
      SM70+ (Volta) for correctness in independently-scheduled warps.
    * Prefer the higher-level helpers (``shuffle_sync``,
      ``shuffle_sync_down``, ``shuffle_sync_xor``) for common
      patterns; use ``nvvm.shfl_sync`` directly only when you need
      fine-grained control over ``mask_and_clamp`` or ``kind``.

    .. code-block:: python

        # Broadcast lane 0's value to all lanes (full warp)
        val = cutlass.Float32(cute.arch.lane_idx)
        broadcast = nvvm.shfl_sync(0xFFFFFFFF, val, 0, 0x1F, "idx")

        # Butterfly reduction: warp sum
        acc = cutlass.Int32(cute.arch.lane_idx)
        for delta in [16, 8, 4, 2, 1]:
            other = nvvm.shfl_sync(0xFFFFFFFF, acc, delta, 0x1F, "bfly")
            acc = acc + other
        # acc now holds the warp sum on all lanes
    """
    _assert_mask32(thread_mask, "shfl.sync")
    _assert_mask32(mask_and_clamp, "shfl.sync")
    _assert_lane_offset(offset, "offset", "shfl.sync")
    _assert_shfl_kind(kind, "shfl.sync")
    dialect_kind = _SHFL_TO_DIALECT[kind]
    val_type = type(val)
    shfl_args = (
        _to_ir(_cutlass.Int32(thread_mask), loc, ip),
        _to_ir(val, loc, ip),
        _to_ir(_cutlass.Int32(offset), loc, ip),
        _to_ir(_cutlass.Int32(mask_and_clamp), loc, ip),
        dialect_kind,
    )
    if return_value_and_is_valid:
        _i1 = _cutlass.Boolean.mlir_type
        result_type = _llvm.StructType.get_literal([val_type.mlir_type, _i1])
        raw = _nvvm_raw.shfl_sync(
            result_type,
            *shfl_args,
            return_value_and_is_valid=True,
            loc=loc,
            ip=ip,
        )
        result_value = val_type(_llvm.extractvalue(val_type.mlir_type, raw, [0]))
        predicate = _cutlass.Boolean(_llvm.extractvalue(_i1, raw, [1]))
        return result_value, predicate
    return val_type(
        _nvvm_raw.shfl_sync(
            val_type.mlir_type,
            *shfl_args,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def st_bulk(
    addr: Array | Pointer,
    size: int | Int64 | Uint64,
    *,
    init_val: int | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Bulk-initialize a shared-memory byte range to a constant value.

    Emits ``st.bulk.shared::cta  [addr], size, init_val;``.  Writes a
    contiguous run of ``size`` bytes at ``addr`` (SMEM) to
    ``init_val`` (currently the only legal value is ``0``).  Useful
    for zero-initializing tiles without a per-thread loop.

    :param addr: SMEM destination pointer/array; must be 16-byte
        aligned.
    :type addr: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to write; positive multiple of 16.
    :type size: int or cutlass.Int64 or cutlass.Uint64
    :param init_val: Constant byte pattern; PTX currently mandates 0.
    :type init_val: int, optional
    :raises ValueError: if a statically known ``size`` is not a
        positive multiple of 16, or ``init_val`` is not ``0`` / ``None``.

    """
    _assert_bulk_size(size, "st.bulk")
    if init_val is not None and init_val != 0:
        raise ValueError(f"st.bulk: init_val must be 0 (or None); got {init_val!r}")
    _nvvm.st_bulk(
        addr,
        _cutlass.Int64(size),
        init_val=init_val,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def stmatrix(
    ptr: Array | Pointer,
    sources: int | Int32 | Uint32 | Vector | list | tuple,
    layout: MMALayout,
    *,
    shape: StoreShape | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Warp-cooperative store of one to four 8x8 (or 16x8) matrix tiles to SMEM.

    Emits ``stmatrix.sync.aligned.{shape}.{num}{.trans}{.ss}.{type} [a], d``.
    All 32 lanes of the issuing warp collectively store ``num`` tiles whose
    fragment registers they hold; the per-lane row-start address goes through
    ``ptr`` exactly as for :func:`ldmatrix`.

    ``sources`` accepts three shapes:

    * a single scalar (``int`` / ``Int32`` / ``Uint32``) -- stores ``num=1``,
    * a ``Vector[N x Int32]`` -- stores ``num=N`` (``N`` in ``{1, 2, 4}``);
      decomposed via ``vector.extract`` before forwarding to the dialect,
    * a Python ``list`` / ``tuple`` of scalars -- stores
      ``num=len(sources)``; each element is coerced to ``Int32``.

    :param ptr: Pointer/Array into shared memory; per the PTX ISA the address
        space must be ``.shared{::cta}``.
    :type ptr: cutlass.Array or cutlass.Pointer
    :param sources: Per-lane source fragment.  Length (or ``Vector`` shape)
        must be 1, 2, or 4 -- the PTX ``.x1`` / ``.x2`` / ``.x4`` qualifiers.
    :type sources: int or Int32 or Uint32 or Vector or list or tuple
    :param layout: ``MMALayout.ROW`` for the default store.
        ``MMALayout.COL`` selects ``.trans`` (in-register transpose before
        committing to SMEM).
    :type layout: MMALayout
    :param shape: Tile shape selector.  Defaults to ``m8n8``; ``m16n8`` is
        the new PTX 9.3 ``.b8`` store variant.
    :type shape: StoreShape or None

    :return: ``None`` -- ``stmatrix`` writes to SMEM and has no SSA result.
    :raises ValueError: ``sources`` count is statically known and is not in
        ``{1, 2, 4}``.

    .. code-block:: python

        # Store a Vector[4 x Int32] accumulator fragment to a 4 x 8x8 SMEM tile.
        smem = cutlass.Array(cutlass.Int16, 4 * 8 * 8, space=cutlass.AddressSpace.smem)
        nvvm.stmatrix(smem, frag, nvvm.MMALayout.ROW)  # frag : Vector[4 x Int32]
    """
    instruction = "stmatrix"
    # See the matching note in :func:`ldmatrix`: address-space enforcement
    # is delegated to the dialect's ``LLVM_PointerShared`` operand type;
    # ``Array.space`` is intentionally a hint, not a contract, and is
    # not checked here.
    shape_d = _to_dialect(shape, _STORE_SHAPE_TO_DIALECT)
    if isinstance(sources, Vector):
        from cutlass._mlir.dialects import vector as _vector_d

        # Reject vectors whose total payload is not a whole number of i32
        # register words before the bitcast -- otherwise the user gets a
        # low-level MLIR bitcast failure instead of the wrapper guard below.
        total_bits = sources.type.shape[0] * sources.dtype.width
        if total_bits % _cutlass.Int32.width != 0:
            raise ValueError(
                f"{instruction}: source vector must lower to whole i32 "
                f"register words; got {total_bits} bits "
                f"({sources.type.shape[0]} x {sources.dtype.__name__})"
            )
        # Bitcast to Int32 lanes when the carrier type differs.  The bitcast
        # can change the lane count for non-32-bit element types, so capture
        # ``n`` from the i32-canonical view, not the original.
        if sources.dtype is not _cutlass.Int32:
            sources = sources.bitcast(_cutlass.Int32, loc=loc, ip=ip)
        n = sources.type.shape[0]
        if n not in _VALID_LDST_MATRIX_NUM:
            raise ValueError(
                f"{instruction}: source vector must lower to 1, 2, or 4 i32 "
                f"register words; got {n}"
            )
        src_ir = sources.ir_value() if hasattr(sources, "ir_value") else sources
        elems = [
            _vector_d.ExtractOp(src_ir, [], static_position=[i], loc=loc, ip=ip).result
            for i in range(n)
        ]
        _nvvm.stmatrix(
            ptr,
            elems,
            _to_dialect(layout, _MMA_LAYOUT_TO_DIALECT),
            shape=shape_d,
            loc=loc,
            ip=ip,
        )
        return
    if isinstance(sources, (list, tuple)):
        if len(sources) not in _VALID_LDST_MATRIX_NUM:
            raise ValueError(
                f"{instruction}: source count must be 1, 2, or 4, got {len(sources)}"
            )
        _nvvm.stmatrix(
            ptr,
            [_cutlass.Int32(x) for x in sources],
            _to_dialect(layout, _MMA_LAYOUT_TO_DIALECT),
            shape=shape_d,
            loc=loc,
            ip=ip,
        )
        return
    _nvvm.stmatrix(
        ptr,
        [_cutlass.Int32(sources)],
        _to_dialect(layout, _MMA_LAYOUT_TO_DIALECT),
        shape=shape_d,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def store_ext(
    value: ir.Value,
    addr: Array | Pointer,
    *,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    order: MemOrder | None = None,
    scope: MemScope | None = None,
    evict: L1EvictKind | None = None,
    cache_modifier: StoreCacheModifier | None = None,
    shared_space: SharedSpace | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Store a scalar to generic, global, or shared memory with explicit cache,
    eviction, and memory-ordering qualifiers (``nvvm.store.ext`` / PTX ``st``).

    The underlying op supports only ``b8/b16/b32/b64/b128`` integer widths and
    ``f32``/``f64`` floats: store a 16-bit float by bitcasting it to ``Int16``
    first.

    :param value: Register value to store; its type selects the store width.
        May be a scalar or a :class:`Vector` (PTX ``.v2``/``.v4``/``.v8``).
    :type value: ir.Value | Vector
    :param addr: Destination address (generic, global, or shared pointer).
    :type addr: Array | Pointer
    :param l2_cache_hint: 64-bit L2 cache-eviction policy handle (generic /
        global space only).
    :type l2_cache_hint: int | Int64 | Uint64 | None
    :param order: Memory ordering (``weak`` default, ``relaxed``, ``release``,
        ``volatile``, ``mmio``).  ``relaxed`` / ``release`` require ``scope``.
    :type order: MemOrder | None
    :param scope: Memory scope (``cta``, ``cluster``, ``gpu``, ``sys``) for an
        ordered store.
    :type scope: MemScope | None
    :param evict: L1 eviction-priority hint; mutually exclusive with
        ``cache_modifier``.
    :type evict: L1EvictKind | None
    :param cache_modifier: Cache operator (``wb``/``cg``/``cs``/``wt``); only
        valid on the default ``weak`` ordering.
    :type cache_modifier: StoreCacheModifier | None
    :param shared_space: Shared sub-space (``cta`` default, ``cluster`` for
        distributed shared memory); for shared-space pointers only.
    :type shared_space: SharedSpace | None
    :raises ValueError: if the qualifier combination is illegal, e.g.
        ``cache_modifier`` with ``evict`` or with non-``weak`` ordering;
        ``relaxed``/``release`` without ``scope``; ``volatile`` with any cache
        op/hint; ``mmio`` without ``scope=sys``; or ``shared_space`` combined
        with ``l2_cache_hint``/``mmio``.
    :raises TypeError: if ``value`` is a 16-bit float (``Float16``/``BFloat16``);
        bitcast it to ``Int16`` before calling ``store_ext``.

    .. code-block:: python

        ptr = arr.data_ptr() + tx
        # Streaming store (likely written once): bypass L1 reuse tracking.
        nvvm.store_ext(val.ir_value(), ptr,
                       cache_modifier=StoreCacheModifier.CS)
    """
    _assert_store_ext_qualifiers(
        order,
        scope,
        cache_modifier,
        evict,
        l2_cache_hint,
        shared_space,
        "store_ext",
    )
    _assert_ext_store_value_dtype(value, "store_ext")
    if l2_cache_hint is not None:
        l2_cache_hint = _cutlass.Int64(l2_cache_hint)
    _nvvm.store_ext(
        value,
        addr,
        l2_cache_hint=l2_cache_hint,
        order=_to_dialect(order, _MEMORDER_TO_DIALECT),
        scope=_to_dialect(scope, _MEMSCOPE_TO_DIALECT),
        evict=_to_dialect(evict, _L1_EVICT_KIND_TO_DIALECT),
        cache_modifier=_to_dialect(cache_modifier, _STORE_CACHE_MODIFIER_TO_DIALECT),
        shared_space=shared_space,
        loc=loc,
        ip=ip,
    )




@dsl_user_op
def sub_packed_f32x2(
    src_a: Vector,
    src_b: Vector,
    *,
    rnd: FPRoundingMode | None = None,
    ftz: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Wrapper over ``nvvm.sub_packed_f32x2``."""
    src_a_ir = _to_ir(src_a, loc, ip)
    return _call_nvvm_result_compat(
        _nvvm_raw.sub_packed_f32x2,
        src_a_ir.type,
        src_a_ir,
        _to_ir(src_b, loc, ip),
        rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
        ftz=ftz,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def tcgen05_alloc(
    addr: Array | Pointer,
    n_cols: int | Int32 | Uint32,
    *,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Allocate TMEM columns for tcgen05 operations.

    :param addr: Pointer/Array to a 32-bit SMEM cell that receives the TMEM
        token (start column address).  Pass ``tmem_ptr`` (an ``Array`` or
        ``Pointer`` of dtype ``Int32``) and read it back after alloc.

        Validated at trace time: must reside in shared memory when the
        passed object exposes ``.space``; opaque pointers are deferred to
        the MLIR verifier.
    :param n_cols: Number of TMEM columns to allocate.  The allocation unit
        is 32 columns and all lanes per column.  Statically known ``int``
        values must be a power of 2 in ``[32, 512]`` (validated at trace
        time); dynamic IR values are forwarded as-is and may fault at
        runtime if out of range.  PTX also requires the number of columns
        allocated not to increase between any two allocations in CTA
        execution order.  Standard values:

        * **CTA_1**: ``n_cols = (N_TILE // 8) * 32`` where ``N_TILE`` is the
          per-CTA accumulator N.  ``N_TILE=128`` → ``512`` columns (fills
          entire TMEM); ``N_TILE=64`` → ``256`` columns (two accumulators
          fit: 256 + 256 = 512).
        * **CTA_2**: each CTA in the 2-SM group still allocates from its own
          512-column TMEM bank, but the accumulator is split M-wise (Layout
          A: leader holds top M-half × full pair-N, peer holds bot M-half
          × full pair-N).  The CTA_1 formula applied to the **per-CTA**
          half (``N_TILE = N_PER_GROUP / 2``) gives the minimum, but the
          simpler safe default is to **always allocate 512** for any CTA_2
          GEMM (over-allocation is harmless).  Applying the CTA_1 formula
          with ``N_TILE = N_PER_GROUP`` (collective N) instead of per-CTA
          N over-allocates beyond 512 and faults with
          ``cudaErrorIllegalInstruction``.
    :param group: ``'CTA_1'`` (default) or ``'CTA_2'``.  See :data:`CTAGroup`.
        All ``tcgen05`` instructions within a kernel must use the same group.

    .. code-block:: python

        # Correct — both alloc and relinquish are warp-collective, neither
        # is inside elect_sync.  mbarrier_init IS elect-safe so it stays
        # inside the elect_sync block.
        if warp == 0:
            if nvvm.elect_sync():
                for s in cutlass.range_constexpr(S):
                    nvvm.mbarrier_init(full_bar + s, 1)
            nvvm.tcgen05_alloc(tmem_ptr, num_cols, group="cta_1")
            nvvm.tcgen05_relinquish_alloc_permit(group="cta_1")
    """
    _assert_shared(addr, "tcgen05.alloc")
    _assert_tcgen05_ncols(n_cols, "tcgen05.alloc")
    _nvvm.tcgen05_alloc(
        addr,
        _cutlass.Int32(n_cols),
        group=_to_dialect(group, _CTAGROUP_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_commit(
    addr: Array | Pointer,
    *,
    multicast_mask: Int16 | Int32 | None = None,
    smem_a_read: bool | None = None,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Track prior async tcgen05 operations with an mbarrier.

    Used in pipelined kernels to release the SMEM staging buffer back to the
    producer after prior async ``tcgen05`` operations have completed.  Emits
    ``tcgen05.commit.cta_group::N.mbarrier::arrive::one`` and makes *addr*
    track all prior async ``tcgen05`` operations of the same CTA group that
    were initiated by the executing thread.

    :param addr: Pointer/Array to the 64-bit mbarrier to signal (typically
        ``empty_bar + stage``).
    :param smem_a_read: When ``True``, tells the hardware that this commit
        releases the A-operand SMEM buffer (default ``None`` = both A and B).
    :param multicast_mask: CTA participation mask for CTA_2 multicast —
        a per-bit mask **over cluster ranks** (not pair-internal).  Bit
        ``i`` set means the arrive lands on the mbar copy at the same SMEM
        offset in cluster rank ``i``.  Two regimes:

        * **Single 2-CTA cluster** (``cluster_shape=(2,1,1)``) — only
          one 2-SM group, leader at rank 0.  Canonical value is
          ``3`` (= ``0b11`` covering ranks 0 and 1 = both pair members);
          this is the value you see in ``2cta_mma_basic.py`` and is
          right whenever there is exactly one 2-SM group in the
          cluster.

        * **Multi-group clusters** (``cluster_shape=(2, n_groups, 1)``
          with ``n_groups > 1``) — each 2-SM group ``G`` has its
          leader at cluster rank ``2*G``.  Use
          ``multicast_mask = 3 << cluster_rank`` so the issuing group
          leader signals ranks ``2G`` and ``2G+1`` (its own pair),
          NOT ranks 0,1.  Hard-coding ``mask=3`` is a frequent
          deadlock cause: groups 1, 2, ... never receive the arrive
          and stall at the next ``try_wait_parity``.

        ``multicast_mask=1 << cta_rank`` (commit only to the issuer)
        is also valid when the follower CTA never waits on this
        mbar; otherwise the follower deadlocks.

        Note that the *value semantics differ* from cluster TMA
        loads, where commits count arrives on named mbar copies
        but TMA counts bytes delivered per CTA.  Do not cross-apply
        multicast masks between TMA loads and ``tcgen05.commit`` without
        rechecking which mbarrier copies are signaled.  Default ``None``
        selects the CTA_1 path with no multicast.  Static ``int`` values are
        validated at trace time to fit in 16 bits (the dialect mask is
        ``i16``); larger literals would be silently truncated.
    :param group: ``"cta_1"`` (default) or ``"cta_2"``.

    .. code-block:: python

        # Per-k-tile: signal empty_bar when prior async tcgen05 ops complete.
        if warp == MMA_WARP:
            if nvvm.elect_sync():
                nvvm.tcgen05_commit(empty_bar + s, group="cta_1")

        # After K-loop: signal acc_mbar to release the TMEM accumulator
        if warp == MMA_WARP:
            if nvvm.elect_sync():
                nvvm.tcgen05_commit(acc_mbar, group="cta_1")
    """
    _assert_mask16(multicast_mask, "tcgen05.commit")
    if multicast_mask is not None:
        multicast_mask = _cutlass.Int16(multicast_mask)
    kwargs = {
        "multicast_mask": multicast_mask,
        "group": _to_dialect(group, _CTAGROUP_TO_DIALECT),
        "loc": loc,
        "ip": ip,
    }
    if smem_a_read is not None:
        kwargs["smem_a_read"] = smem_a_read
    _nvvm.tcgen05_commit(addr, **kwargs)


@dsl_user_op
def tcgen05_cp(
    shape: Tcgen05CpShape,
    taddr: Array | Pointer,
    smem_desc: int | Int64 | Uint64,
    *,
    group: CTAGroup | None = None,
    multicast: Tcgen05CpMulticast | None = None,
    src_format: Tcgen05CpSrcFormat | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Asynchronous SMEM → TMEM copy with optional decompression / multicast.

    Emits ``tcgen05.cp`` — staged into the TC issue queue alongside
    ``tcgen05.mma`` and ``tcgen05.shift`` (the PTX ISA lists the legal
    ordering pairs).  Used to seed an A-from-TMEM operand, to gather
    narrow-format data (FP6/FP4) into TMEM with on-the-fly widening, or
    to place block-scaled SFA/SFB metadata in TMEM before the matching
    :func:`tcgen05_mma_block_scale`-style wrapper consumes ``scale_a`` /
    ``scale_b``.

    :param shape: ``Tcgen05CpShape`` selecting the data dimensions.
        Per the PTX ISA these come with ``.multicast`` constraints:
        ``.64x128b`` requires ``warpx2::02_13`` or ``warpx2::01_23``;
        ``.32x128b`` requires ``warpx4``; the wider shapes
        (``.128x256b`` / ``.4x256b`` / ``.128x128b``) take no multicast.
        The ``.64x128b.warpx2::01_23`` form is the direct SFB scale
        metadata copy used by the 2x2 CTA_2 block-scaled N=256 example.
        The shape<->multicast coupling is validated at trace time.
    :param taddr: TMEM destination address (``Array``/``Pointer``).
        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space`` (dialect operand type ``LLVM_PointerTensor``).
    :param smem_desc: 64-bit SMEM matrix descriptor (built via
        :meth:`cutlass.experimental.primitives.Tcgen05SmemDesc.build`).
    :param group: ``"cta_1"`` (default) — destination is the
        issuing CTA's TMEM.  ``"cta_2"`` — also writes the
        peer CTA's TMEM (cluster-collective; both CTAs' issuing warp
        must reach this op cooperatively).  All ``tcgen05.*`` ops in a
        kernel must agree on ``group``.
    :param multicast: Warp-pair / quad-warp multicast policy for the
        narrow shapes; see ``shape`` constraints above.
    :param src_format: ``B6x16_P32`` / ``B4x16_P64`` to enable on-the-fly
        decompression to ``b8x16`` in TMEM.  ``None`` means same-format
        copy.

    .. code-block:: python

        # Stage A from SMEM to TMEM ahead of an A-from-TMEM MMA
        if warp == TMA_WARP:
            if nvvm.elect_sync():
                nvvm.tcgen05_cp(
                    "shape_128x256b",
                    a_tmem_addr,
                    smem_desc_a,
                    group="cta_1",
                )
                nvvm.tcgen05_commit(empty_bar)

        # Stage 2x2 SFB scale metadata before the block-scaled MMA reads scale_b.
        sfb_shape, sfb_multicast = ...  # S2T copy mode, e.g. 64x128b WARPX2_01_23
        if warp == MMA_WARP:
            if nvvm.elect_sync():
                nvvm.tcgen05_cp(
                    sfb_shape,
                    sfb_tmem_addr,
                    sfb_smem_desc,
                    group=nvvm.CTAGroup.CTA_2,
                    multicast=sfb_multicast,
                )
    """
    _assert_tensor_mem(taddr, "tcgen05.cp")
    _assert_tcgen05_cp_multicast(shape, multicast, "tcgen05.cp")
    _nvvm.tcgen05_cp(
        _TCGEN05_CP_SHAPE_TO_DIALECT[shape],
        taddr,
        _cutlass.Int64(smem_desc),
        group=_to_dialect(group, _CTAGROUP_TO_DIALECT),
        multicast=_to_dialect(multicast, _TCGEN05_CP_MULTICAST_TO_DIALECT),
        src_format=_to_dialect(src_format, _TCGEN05_CP_SRC_FORMAT_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_dealloc(
    taddr: Array | Pointer,
    n_cols: int | Int32 | Uint32,
    *,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Free TMEM columns previously allocated by :func:`tcgen05_alloc`.

    :param taddr: TMEM base pointer (addrspace 6) — typically the value read
        back from the SMEM slot :func:`tcgen05_alloc` wrote to, converted with
        an addrspace-6 (TMEM) pointer.

        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space``; opaque pointers are deferred to the MLIR
        verifier (the dialect operand type is ``LLVM_PointerTensor``).
    :param n_cols: Number of TMEM columns to free; must equal the value passed
        to the paired :func:`tcgen05_alloc`.  Statically known ``int`` values
        are validated against the same whitelist as :func:`tcgen05_alloc`
        (``{32, 64, 128, 256, 512}``) at trace time.
    :param group: ``'CTA_1'`` (default) or ``'CTA_2'`` — must match the group
        used at alloc time.  See :data:`CTAGroup`.

    .. code-block:: python

        # After the epilogue's TMEM reads and their sync:
        nvvm.barrier_cta_sync()
        if warp_idx == 0:
            nvvm.tcgen05_dealloc(tmem_ptr, NUM_TMEM_COLS, group="cta_1")
    """
    _assert_tensor_mem(taddr, "tcgen05.dealloc")
    _assert_tcgen05_ncols(n_cols, "tcgen05.dealloc")
    _nvvm.tcgen05_dealloc(
        taddr,
        _cutlass.Int32(n_cols),
        group=_to_dialect(group, _CTAGROUP_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_fence(
    kind: Tcgen05Fence,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Order async tcgen05 operations around thread synchronization.

    Emits ``tcgen05.fence.{before_thread_sync|after_thread_sync}``.

    :param kind: ``"before_thread_sync"`` — place **before**
        an execution-ordering operation such as ``nvvm.barrier_cta_sync()`` or a flag
        store to order all prior async ``tcgen05`` operations before that
        synchronization point.  ``"after_thread_sync"`` — place **after** such
        a synchronization point and before subsequent
        async ``tcgen05`` operations.
    :type kind: Tcgen05Fence

    .. code-block:: python

        # After reading TMEM, fence before syncing:
        c_vec = nvvm.tcgen05_ld(shape, tmem_addr, num=n)
        nvvm.tcgen05_wait("load")
        nvvm.tcgen05_fence("before_thread_sync")
        nvvm.barrier_cta_sync()
    """
    _nvvm_raw.tcgen05_fence(_TCGEN05_FENCE_TO_DIALECT[kind], loc=loc, ip=ip)


@dsl_user_op
def tcgen05_ld(
    shape: Tcgen05LdStShape,
    tmem_addr: Array | Pointer,
    *,
    num: int = 1,
    pack: bool | None = None,
    offset: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Vector:
    """Load data from TMEM into registers.

    Emits ``tcgen05.ld.sync.aligned.{shape}{.xN}{.pack}.b32``.  The issuing
    warp collectively loads from TMEM; each lane receives its own register
    slice from the warp's accessible TMEM sub-partition.  Pair with
    :func:`tcgen05_wait` (``LOAD``) before reading the result.

    **TMEM access restriction.**  TMEM is divided into
    4 lane-chunks of 32 lanes each.  A given lane is accessible by **exactly
    one warp** in each warpgroup, determined by the warp's position within
    its warpgroup (i.e. ``warp_idx % 4``):

    +------------------------------+--------------------+
    | Warp position in warpgroup   | Accessible lanes   |
    +==============================+====================+
    | 0                            | 0–31               |
    +------------------------------+--------------------+
    | 1                            | 32–63              |
    +------------------------------+--------------------+
    | 2                            | 64–95              |
    +------------------------------+--------------------+
    | 3                            | 96–127             |
    +------------------------------+--------------------+

    All warps see all 512 columns; the lane (row) restriction is the only
    cross-warp partitioning.  A warp cannot read another warp's lanes by
    changing the address — the row field in ``tmem_addr[31:16]`` is a
    **local** index within the warp's own chunk (5 bits; values ≥ 32 wrap
    as ``row mod 32``).

    **Implication for ``M_TILE=128`` GEMM epilogues.**  Covering all 128
    accumulator rows requires 4 issuing warps whose warpgroup positions cover
    0..3.  For a 4-warp CTA those are warps 0..3.  A shifted TMEM-load range
    such as warps 2..5 is also valid because ``warp_idx % 4`` covers
    2, 3, 0, 1.  In that case, derive the TMEM row and output row from the
    physical SP position, not from the logical TMEM-load rank:
    ``tmem_sp = warp_idx % 4`` and ``row = tmem_sp * 32 + lane``.  Using
    ``warp_idx - tmem_ld_warp_start`` for the row offset makes warp 4 try
    to read SP2 rows while the hardware routes it to SP0, causing wrong data
    or an illegal instruction.  Valid organizations include:

    * **Time-multiplex** — 4-warp CTA; warp 0 does TMA + MMA in the
      K-loop, then warps 0..3 do epilogue.
    * **Split with shifted epilogue** — producer / MMA use earlier warps,
      and four epilogue warps such as 2..5 drain rows via ``warp_idx % 4``.

    Also note: ``tcgen05.mma`` only fills rows for the ``m_dim`` it was given.
    If ``m_dim < 8`` (i.e. ``M_TILE < 128``), rows beyond ``m_dim * 4`` per
    chunk contain stale data.  Use ``M_TILE=128`` (``m_dim=8``) to populate
    all rows.

    :param shape: Load shape (PTX ``.shape1`` / ``.shape2``).  One of
        ``"16x32bx2"``, ``"16x64b"``, ``"32x32b"``, ``"16x128b"``,
        ``"16x256b"``.  Most common is ``"32x32b"`` (one 32-bit register per
        thread, reads 32 rows × 32 bits = 128 bytes per warp).
        ``num > 1`` stacks multiple shapes into a contiguous ``Vector``.
    :type shape: Tcgen05LdStShape
    :param tmem_addr: Pointer/Array to the TMEM location.  The address encodes
        ``(row << 16) | col`` where *row* is the local row within the
        sub-partition and *col* is the TMEM column from ``tcgen05_alloc``.
        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space`` (the dialect operand type is
        ``LLVM_PointerTensor``); opaque pointers are deferred to the verifier.
    :type tmem_addr: cutlass.Array or cutlass.Pointer
    :param num: Number of shape repetitions; result has ``regs_per_elem * num``
        registers.  ``regs_per_elem`` is determined by the ``shape``:
        ``"16x32bx2"`` / ``"16x64b"`` / ``"32x32b"`` → 1, ``"16x128b"`` → 2,
        ``"16x256b"`` → 4.  Must be a power of 2 in [1, 128]; total
        registers (``regs_per_elem * num``) must not exceed 128.
    :type num: int
    :param pack: Enable element packing (reduces register count for sub-32-bit
        dtypes).
    :type pack: bool, optional
    :param offset: Required (and only valid) for ``"16x32bx2"`` — column
        offset added to ``tmem_addr`` at runtime.  Must be ``None`` for all
        other shapes.
    :type offset: int or cutlass.Int64 or cutlass.Uint64, optional
    :return: A ``Vector`` of the loaded registers (always a vector, even for a
        single register).  If ``tmem_addr.dtype`` is not ``Int32``, the result
        is bitcast to that dtype automatically (e.g. ``Float32``).
    :rtype: cutlass.Vector
    :raises ValueError: ``shape`` is not a recognized literal; ``num`` is
        not a power of 2 in [1, 128]; total registers exceed 128; ``offset``
        is set for a shape other than ``"16x32bx2"`` (or missing for
        ``"16x32bx2"``).
    :raises TypeError: ``tmem_addr`` exposes a ``.space`` that is not tensor
        memory (TMEM).

    .. code-block:: python

        # Each issuing warp loads its own 32 lanes from the accumulator tile.
        # Use the physical TMEM/SP owner, not the logical TMEM-load rank.
        # Build the encoded (row << 16) | col integer address, then convert
        # to a TMEM pointer in one shot -- pointer arithmetic on an already-
        # constructed TMEM pointer does not interpret the row/col layout the
        # way callers expect.
        tmem_sp = warp_idx % 4
        base_row = tmem_sp * 32
        tmem_addr = (base_row << 16) | base_col
        tmem_ptr = ...  # addrspace-6 TMEM pointer built from tmem_addr
        result = nvvm.tcgen05_ld("32x32b", tmem_ptr)
    """
    _assert_tensor_mem(tmem_addr, "tcgen05.ld")
    shape_enum = _TCGEN05_LD_ST_SHAPES.get(shape)
    if shape_enum is None:
        raise ValueError(
            f"tcgen05.ld: shape must be one of "
            f"{sorted(_TCGEN05_LD_ST_SHAPES)}, got {shape!r}"
        )
    if num not in _VALID_TCGEN05_NUM:
        raise ValueError(f"tcgen05.ld: num must be a power of 2 in [1, 128], got {num}")
    n_regs = _TCGEN05_REGS_PER_ELEM[shape] * num
    if n_regs > _TCGEN05_MAX_TOTAL_REGS:
        raise ValueError(
            f"tcgen05.ld: {shape!r}.x{num} requires {n_regs} registers, "
            f"exceeds maximum of {_TCGEN05_MAX_TOTAL_REGS}"
        )
    if shape == "16x32bx2":
        if offset is None:
            raise ValueError(
                "tcgen05.ld: offset (immHalfSplitoff) is required for '16x32bx2'"
            )
    elif offset is not None:
        raise ValueError(
            f"tcgen05.ld: offset is only valid for '16x32bx2', not {shape!r}"
        )
    offset_value = None
    if offset is not None:
        offset_obj: Any = (
            offset if hasattr(offset, "ir_value") else _cutlass.Int64(offset)
        )
        offset_value = offset_obj.ir_value(loc=loc, ip=ip)
    _out_dtype = tmem_addr.dtype if hasattr(tmem_addr, "dtype") else _cutlass.Int32
    _tmem_addr = tmem_addr.ir_value() if hasattr(tmem_addr, "ir_value") else tmem_addr
    res_ty = T.i32() if n_regs == 1 else T.vector(n_regs, T.i32())
    out = _nvvm_raw.tcgen05_ld(
        res_ty,
        shape_enum,
        _tmem_addr,
        pack=pack,
        offset=offset_value,
        loc=loc,
        ip=ip,
    )
    from cutlass._mlir.dialects import vector as vector_d

    if n_regs == 1:
        out = vector_d.from_elements(T.vector(1, T.i32()), [out], loc=loc, ip=ip)
    out = Vector(out, dtype=_cutlass.Int32, loc=loc, ip=ip)
    if _out_dtype is not _cutlass.Int32:
        new_count = n_regs * _cutlass.Int32.width // _out_dtype.width
        target_vec_ty = T.vector(new_count, _out_dtype.mlir_type)
        res_vec = vector_d.bitcast(target_vec_ty, out, loc=loc, ip=ip)
        return Vector(res_vec, dtype=_out_dtype, loc=loc, ip=ip)
    return out



@dsl_user_op
def tcgen05_mma(
    mma_kind: Tcgen05MMAKind,
    cta_group: CTAGroup,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    *,
    collector_op: Tcgen05MMACollectorOp | None = None,
    a_shift: bool | None = None,
    scale_input_d: int | Int64 | Uint64 | None = None,
    write_disable_mask: Vector | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a 5th-generation Blackwell tensor-core multiply-accumulate (``tcgen05.mma``).

    Emits ``tcgen05.mma.cta_group::{1|2}.kind::<kind>`` with optional
    ``.collector::a::*``, ``.ashift``, and ``scale-input-d`` modifiers.
    The accumulator ``D = A * B [+ D]`` lives in Tensor Memory (TMEM); A is
    read from SMEM (default) or TMEM; B is always an SMEM descriptor.
    Requires ``sm_100a`` or a supported family target.

    :param mma_kind: Data-type/kind selector.  Dense kinds are issued by this
        wrapper; block-scaled kinds are listed for descriptor compatibility and
        should be issued with :func:`tcgen05_mma_block_scale`.

        * ``"f16"`` — f16/bf16 operands, f32 accumulator. K=16.
        * ``"tf32"`` — tf32 operands, f32 accumulator. K=8.
        * ``"int8"`` — signed/unsigned 8-bit, i32 accumulator.
          K=32.
        * ``"f8f6f4"`` — mixed {E4M3, E5M2, E2M3, E3M2, E2M1}
          inputs, f32 accumulator. K=32.
        * ``"mxf8f6f4"`` — block-scaled F8F6F4 (use
          :func:`tcgen05_mma_block_scale`). K=32.
        * ``"mxf4"`` — block-scaled E2M1. K=64.
        * ``"mxf4nvf4"`` — block-scaled E2M1+NVFP4. K=64.

    :type mma_kind: Tcgen05MMAKind
    :param cta_group: ``"cta_1"`` for single-CTA scope
        (M ∈ {32, 64, 128}); ``"cta_2"`` for 2-CTA cooperative
        scope (collective M ∈ {128, 256} across peer CTAs; N effectively
        doubled via peer SMEM).  Every ``tcgen05.*`` op in a kernel must
        use the same group.
    :type cta_group: CTAGroup
    :param d: TMEM accumulator pointer returned by
        :func:`tcgen05_alloc` (address-space 6).  Rows fill according to
        ``m_dim``; hardware routes writes to sub-partitions by row.
        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space`` (dialect operand type ``LLVM_PointerTensor``).
    :type d: cutlass.Array or cutlass.Pointer
    :param a: Either a 64-bit SMEM descriptor from
        :meth:`cutlass.experimental.primitives.Tcgen05SmemDesc.build` (``A-from-SMEM`` path, common) **or** a
        TMEM pointer (``A-from-TMEM`` path — used in BMM2 of FMHA where the
        previous MMA's output is reused as the next A).

        For the TMEM path:

        * Build an addrspace-6 pointer from ``tmem_addr``
          where ``tmem_addr = (row << 16) | col`` is the packed 32-bit
          TMEM address.  Pointer arithmetic on TMEM pointers applies raw
          packed-token offsets; it does not interpret row/col fields.
        * A's columns advance by the K-granule per K-step (e.g. 64 TMEM
          columns per BF16 K-step, not per K element).
        * Load A into TMEM beforehand via :func:`tcgen05_cp` (SMEM→TMEM
          copy) or :func:`tcgen05_st` (register→TMEM store), or produce it
          as the output of a prior :func:`tcgen05_mma` accumulator.
    :type a: cutlass.Int64, cutlass.Array, or cutlass.Pointer
    :param b: 64-bit SMEM descriptor for B from
        :meth:`cutlass.experimental.primitives.Tcgen05SmemDesc.build`.
    :type b: int, cutlass.Int64, or cutlass.Uint64
    :param idesc: Packed 32-bit instruction descriptor encoding
        ``c_format`` / ``a_format`` / ``b_format`` / ``a_major`` /
        ``b_major`` / ``m_dim`` / ``n_dim``.  Build with
        :meth:`cutlass.experimental.primitives.Tcgen05InstrDesc.build`:

        .. code-block:: python

            idesc = cutlass.experimental.primitives.Tcgen05InstrDesc.build(
                c_dtype=cutlass.Float32,        # 1 = f32 accumulator
                a_dtype=cutlass.Float16,        # MUST match A dtype — see table below
                b_dtype=cutlass.Float16,        # MUST match B dtype — see table below
                n_dim=N_TILE,      # logical N (multiple of 8); 3 LSBs not encoded
                m_dim=M_TILE,      # logical M (multiple of 16); 4 LSBs not encoded
            )

        Common ``a_format`` / ``b_format`` values (must match operand dtype):

        ===== ========== =============================
        Value Dtype      Applicable ``mma_kind``
        ===== ========== =============================
        0     FP16       ``F16``
        1     BF16       ``F16``
        2     TF32       ``TF32``
        0..4  E4M3..E2M1 ``F8F6F4`` / ``MX*`` variants
        0     U8         ``INT8``
        1     S8         ``INT8``
        ===== ========== =============================

        See :class:`cutlass.experimental.primitives.Tcgen05InstrDesc` for the full bit layout.  For
        ``CTA_2`` the ``m_dim`` / ``n_dim`` describe the **collective**
        tile across both CTAs (e.g. M=256 → ``m_dim=16``).

        .. warning::
            ``a_format`` / ``b_format`` **must match the operand dtype**.
            A mismatch (e.g. BF16 operands with ``a_format=0``) produces
            **silently wrong results** (~40–60 max_err on random data); no
            compile or runtime error is raised.
    :type idesc: int, cutlass.Int32, or cutlass.Uint32
    :param enable_input_d: Controls first-tile behavior.  ``True`` / non-zero
        computes ``D = A*B + D`` (accumulate into existing TMEM content);
        ``False`` / zero computes ``D = A*B`` (overwrite).  Typically passed
        as ``k > 0`` in a k-tile loop so the first k-tile clears the
        accumulator and subsequent tiles accumulate.
    :type enable_input_d: int or cutlass.Boolean
    :param collector_op: Collector cache usage for operand A.  The collector
        is a small per-MMA-issuer cache that lets consecutive MMAs reuse the
        same A operand without re-reading SMEM.  Values:

        * ``"fill"`` — load A into the collector and use
          it (seeds the cache on the first MMA of a chain).
        * ``"use"`` — read A from the collector (later
          MMAs in a chain that reuse the same A).
        * ``"lastuse"`` — read from the collector, then
          invalidate the entry (final MMA of the chain).
        * ``"discard"`` (default) — do not cache A.

        Reuse is opportunistic; hardware may reload despite the permission.
        Treat the collector strictly as a performance hint.  The source memory
        for A must not be modified while any MMA using that matrix has not
        completed, regardless of collector state.
    :type collector_op: Tcgen05MMACollectorOp, optional

    :param a_shift: When ``True``, emits the ``.ashift`` modifier.  In
        the ``.ashift`` MMA pipeline, the shift is a **post-MMA**
        operation: the current MMA reads unshifted A and produces
        ``A @ B``, then the A TMEM region is shifted for subsequent
        reads.  To observe the shift you need a follow-up MMA (or
        :func:`tcgen05_ld`) that targets the same A TMEM region.

        **A MUST be in TMEM (the ``[a-tmem]`` form).**  The PTX ISA
        defines ``.ashift`` only for
        ``tcgen05.mma.kind.ashift [d-tmem], [a-tmem], b-desc, ...``;
        there is no ``.ashift`` form that takes an SMEM descriptor for
        A. Passing ``a_shift=True`` with an SMEM-descriptor ``a`` is
        silently ignored by HW.

        **Shift semantics (per-SP, not global):** PTX wording "shifts
        rows down by 1 except the last row" refers to the last row of
        each TMEM sub-partition, not the global last row.  For M=128
        (4 SPs × 32 rows) global M-rows {31, 63, 95, 127} retain their
        original values:

        .. code-block:: text

            shifted[r] = A[r + 1]   when r % 32 != 31
            shifted[r] = A[r]       when r % 32 == 31

        Other constraints: ``M ∈ {128, 256}`` only; mutually exclusive
        with ``collector_op in {FILL, USE}`` and with ``.ws`` (warp-
        specialized) MMA variants.  ``idesc.max_shift`` does NOT control
        ``.ashift`` — that field is for the ``.ws`` variant (values
        0/1/2/3 → max shifts 0/8/16/32 rows).  For plain ``.ashift`` the
        shift is always exactly 1 row per MMA regardless of
        ``max_shift``; leave it at 0.
    :type a_shift: bool, optional
    :param scale_input_d: Immediate in ``[0, 15]``.  When set, scales the
        input accumulator as ``D *= 2**(-scale_input_d)`` before the MAC.
        Valid only for ``"f16"`` and ``"tf32"`` (PTX ISA 9.3).  The kind
        restriction and the static ``[0, 15]`` range are validated at trace
        time.
    :type scale_input_d: int, cutlass.Int64, or cutlass.Uint64, optional
    :param write_disable_mask: Per-row TMEM write-disable vector.  4-element
        ``Vector[Int32]`` for ``CTA_1`` (128 mask bits / M-rows), 8-element
        for ``CTA_2`` (256 mask bits across the collective M=256 tile).

        **Bit mapping (Layout D, CTA_1)**: bit ``i``
        of element ``v`` masks output M-row ``v * 32 + i``.  A set bit
        suppresses the TMEM write for that row, leaving it at the
        TMEM-initial value (zero after :func:`tcgen05_alloc`).

        Typical use: row-wise partial-tile handling — suppress writes to
        M-rows beyond the live fraction of the tile so they don't clobber
        accumulator rows still needed by the adjacent tile.  The element count
        (4 for ``CTA_1``, 8 for ``CTA_2``) is validated at trace time.
    :type write_disable_mask: cutlass.Vector, optional

    **Constraints:**

    * **Single-thread issue:** call inside ``if nvvm.elect_sync():``.  All
      32 warp threads issuing the intrinsic would emit 32 duplicate MMAs
      (undefined behavior / observed hangs).  For ``CTA_2``, only the
      leader CTA's elected thread issues.
    * **A/B SMEM visibility:** producer writes (TMA, ``cp.async``) must be
      ordered before the MMA via an mbarrier wait; ``tcgen05.mma`` itself
      is async with respect to generic memory but synchronous with respect
      to an arrive-on-completion mbarrier.
    * **Completion tracking:** follow the last MMA of a chain with
      :func:`tcgen05_commit` to release the A/B SMEM buffers, and with a
      commit on an accumulator mbarrier (or ``tcgen05_wait``) before the
      epilogue reads TMEM.
    * **TMEM read ordering:** after the accumulator mbarrier fires, use
      :func:`tcgen05_fence` (``BEFORE_THREAD_SYNC``) between
      :func:`tcgen05_ld` and the following :func:`barrier` / next MMA.
    * **Predication:** not supported.  ``tcgen05.mma`` has variable-length
      operand lists (``write_disable_mask``, collector ops,
      ``scale_input_d``) that require NVVM-level register allocation —
      gate the intrinsic with a surrounding ``if`` instead.

    .. code-block:: python

        # Per k-tile of a pipelined GEMM (warp 0 issues MMA):
        if warp_idx == 0:
            if nvvm.elect_sync():
                nvvm.tcgen05_mma(
                    nvvm.Tcgen05MMAKind.F16,
                    nvvm.CTAGroup.CTA_1,
                    tmem_ptr,          # D: accumulator in TMEM
                    desc_a,            # A: SMEM descriptor
                    desc_b,            # B: SMEM descriptor
                    idesc,             # Packed instr descriptor
                    k > 0,             # enable_input_d: k==0 clears, k>0 accumulates
                )

        # Multi-MMA-warp shared TMEM: the first MMA that starts a fresh
        # accumulator region must clear (enable_input_d=False); every later
        # MMA targeting the same accumulator region accumulates.

        # A-reuse across 2 back-to-back MMAs (same A, different B):
        if nvvm.elect_sync():
            nvvm.tcgen05_mma(..., collector_op=nvvm.Tcgen05MMACollectorOp.FILL)
            nvvm.tcgen05_mma(..., collector_op=nvvm.Tcgen05MMACollectorOp.LASTUSE)
    """
    _assert_tensor_mem(d, "tcgen05.mma")
    _assert_tcgen05_scale_input_d(scale_input_d, mma_kind, "tcgen05.mma")
    _assert_tcgen05_write_disable_mask(write_disable_mask, cta_group, "tcgen05.mma")
    if scale_input_d is not None:
        scale_input_d = _cutlass.Int32(scale_input_d)
    _nvvm.tcgen05_mma(
        _TCGEN05_MMA_KIND_TO_DIALECT[mma_kind],
        _CTAGROUP_TO_DIALECT[cta_group],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        a_shift=a_shift,
        scale_input_d=scale_input_d,
        write_disable_mask=write_disable_mask,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_mma_block_scale(
    mma_kind: Tcgen05MMAKind,
    cta_group: CTAGroup,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    scale_a: Array | Pointer,
    scale_b: Array | Pointer,
    *,
    scale_vec_size: _Tcgen05BlockScaleLike | None = None,
    collector_op: Tcgen05MMACollectorOp | None = None,
    a_shift: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """MMA with per-block scale factors (MXFP / NVFP block scaling).

    Emits ``tcgen05.mma.cta_group::N.{kind}.block_scale[.scale_vectorsize]``.
    Like :func:`tcgen05_mma`, but each MMA additionally multiplies blocks
    of A and B by per-block scale factors before accumulating, enabling
    MXFP8 / MXFP6 / MXFP4 / NVFP4 block-scaled formats whose dynamic range
    is otherwise too narrow for direct GEMM.  See the PTX ISA
    "Block Scaling for tcgen05.mma" section for the full scale-factor layout
    spec — the layout depends on ``scale_vec_size`` and the K-dim, and
    is dense (different from per-row or per-channel scaling).

    :param mma_kind: Top-level block-scale kind (for example ``MXF8F6F4`` for
        MXFP8/6/4 narrow formats; selects which block-scaling variants are
        legal).  Validated at trace time: must be a block-scaled kind
        (``mxf8f6f4`` / ``mxf4`` / ``mxf4nvf4``); use :func:`tcgen05_mma` for
        non-block-scaled kinds.

    :param cta_group: ``CTA_1`` or ``CTA_2`` (cluster shape (2,1,1)).
    :param d: TMEM accumulator destination.  Validated at trace time to reside
        in tensor memory (dialect operand type ``LLVM_PointerTensor``).
    :param a: A operand — SMEM descriptor (Int64) or TMEM address.
    :param b: B operand SMEM descriptor (Int64).
    :param idesc: Packed 32-bit instruction descriptor.  Build FP8/FP6/MX
        descriptors via :meth:`~cutlass.experimental.primitives.Tcgen05MxInstrDesc.build`, and FP4/NVFP4
        descriptors via :meth:`~cutlass.experimental.primitives.Tcgen05MxOmmaInstrDesc.build`.
    :param enable_input_d: Boolean — when False, ignores prior D
        contents (D = A·B·scale instead of D += A·B·scale).
    :param scale_a, scale_b: TMEM addresses of the scale-factor tiles
        for A and B respectively.  Layout depends on
        ``scale_vec_size`` — see PTX ISA.  Both are validated at trace time to
        reside in tensor memory (dialect operand type ``LLVM_PointerTensor``).
    :param scale_vec_size: ``Tcgen05MMAScaleVecSize`` — selects 1X /
        2X / 4X scale-vector packing within each block.  Different
        sizes have different K-dim compatibility tables.
    :param collector_op: A operand reuse policy (see :func:`tcgen05_mma`).

    :param a_shift: Same semantics as :func:`tcgen05_mma`.

    .. code-block:: python

        if warp == MMA_WARP:
            if nvvm.elect_sync():
                nvvm.tcgen05_mma_block_scale(
                    nvvm.Tcgen05MMAKind.MXF8F6F4,
                    nvvm.CTAGroup.CTA_1,
                    d_tmem, a_smem_desc, b_smem_desc, idesc,
                    enable_input_d=k > 0,
                    scale_a=scale_a_tmem, scale_b=scale_b_tmem,
                    scale_vec_size=nvvm.Tcgen05MMAScaleVecSize.X2,
                )
                nvvm.tcgen05_commit(empty_bar)
    """
    _assert_tcgen05_block_scale_kind(mma_kind, "tcgen05.mma.block_scale")
    _assert_tensor_mem(d, "tcgen05.mma.block_scale")
    _assert_tensor_mem(scale_a, "tcgen05.mma.block_scale")
    _assert_tensor_mem(scale_b, "tcgen05.mma.block_scale")
    # Upstream renamed scale_vec_size -> block_scale and removed a_shift from
    # the block_scale variants.
    # Keep our public signature stable; only the forwarded kwargs change.
    #
    # ``mma_kind`` may be passed as the raw NVVM ``MMABlockScaleKind`` (a
    # separate IntEnum that shares numeric values with ``Tcgen05MMAKind``).
    # Normalize via the member name so the lookup picks the correct dialect
    # enum regardless of which class the caller used.
    _mma_kind_key = mma_kind.name.lower() if hasattr(mma_kind, "name") else mma_kind
    if getattr(_nvvm_raw, "Tcgen05MMABlockScale", None) is not None:
        block_scale = _to_tcgen05_block_scale(scale_vec_size)
        _nvvm.tcgen05_mma_block_scale(
            _TCGEN05_MMA_KIND_TO_DIALECT[_mma_kind_key],
            _CTAGROUP_TO_DIALECT[cta_group],
            d,
            a,
            _cutlass.Int64(b),
            _cutlass.Int32(idesc),
            _cutlass.Boolean(enable_input_d),
            scale_a,
            scale_b,
            block_scale=block_scale,
            collector_op=_to_dialect(
                collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT
            ),
            loc=loc,
            ip=ip,
        )
        return
    scale_vec_size = _to_tcgen05_scale_vec_size(scale_vec_size)
    _nvvm.tcgen05_mma_block_scale(
        _TCGEN05_MMA_KIND_TO_DIALECT[_mma_kind_key],
        _CTAGROUP_TO_DIALECT[cta_group],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        scale_a,
        scale_b,
        scale_vec_size=scale_vec_size,
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        a_shift=a_shift,
        loc=loc,
        ip=ip,
    )



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

    .. warning::
        ``swizzle_mode=0`` (no swizzle) produces **silently wrong
        results** on SM100 for ``tcgen05.mma kind::f16``.  Always use
        ``swizzle_mode=2`` (128B XOR).  The SMEM data layout must
        match: if the tile was loaded via TMA with
        ``TensorMapSwizzle.s128b``, the hardware applied the XOR
        automatically and ``swizzle_mode=2`` is the correct
        descriptor value.

    :param start_addr: Base SMEM address of the tile **divided by 16**
        (i.e. ``smem_ptr >> 4``).  The descriptor unit is 16 bytes.
    :param leading_dim_offset: Step size of the leading dimension in units of 16 B.
        For a row-major fp16 tile with 16-byte rows: ``1`` (= 16 B / 16).
        For wider rows scale proportionally: 128-byte row → ``8``.
    :param stride_dim_offset: Size of one swizzle block in units of 16 B.
        For ``s128b`` (128B XOR, 8-row period): ``stride = 8 × row_bytes / 16``.
        Example: 128-byte rows → ``stride_dim_offset = 8 × 128 / 16 = 64``.
    :param base_offset: Additional byte offset added to the base (normally ``0``).
    :param leading_dim_mode: Leading-dimension mode flag (normally ``0`` / ``False``).
    :param swizzle_mode: SMEM swizzle mode applied during ``tcgen05.mma`` reads.

        ============  =======  ============================================
        Value         Name     Meaning
        ============  =======  ============================================
        ``0``         NONE     No swizzle — **wrong on SM100, do not use**
        ``2``         128B XOR 128-byte XOR swizzle — **required** for
                               ``tcgen05.mma kind::f16`` on SM100
        ``4``         64B XOR  64-byte XOR swizzle
        ``6``         32B XOR  32-byte XOR swizzle
        ============  =======  ============================================

    :return: Packed ``Int64`` descriptor value for use as the ``smem_desc``
        argument of :func:`tcgen05_mma`.

    Example — 128×64 fp16 A/B tile with 128B XOR swizzle::

        # Tile: M_TILE=128 rows, K_TILE=64 fp16 elements = 128 bytes per row
        # Swizzle period: 8 rows × 128 B = 1024 B (→ stride_dim_offset = 64)
        desc_a = _tcgen05_mma_smem_desc(
            smem_a_ptr >> 4,   # start_addr: base / 16
            cutlass.Int32(1),      # leading_dim_offset: 16B / 16 = 1
            cutlass.Int32(64),     # stride_dim_offset:  8 × 128B / 16 = 64
            cutlass.Int8(0),       # base_offset: 0
            cutlass.Boolean(0),    # leading_dim_mode: False
            cutlass.Int8(2),       # swizzle_mode: 2 = 128B XOR  ← REQUIRED on SM100
        )

    See also :func:`_tcgen05_mma_smem_desc_v2` for the extended descriptor form.
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


@dsl_user_op
def _tcgen05_mma_smem_desc_v2(
    start_address: int | Int32 | Uint32,
    leading_dim_offset: int | Int32 | Uint32,
    stride_dim_offset: int | Int32 | Uint32,
    descriptor_version: int | Int8 | Uint8,
    base_offset: int | Int8 | Uint8,
    leading_dim_mode: int | Boolean,
    k_segment_offset: int | Boolean,
    swizzle_type: int | Int8 | Uint8,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Build an extended ``tcgen05.mma`` SMEM descriptor.

    Like :func:`_tcgen05_mma_smem_desc` with two extra descriptor fields,
    ``descriptor_version`` and ``k_segment_offset``. Module-private; construct
    descriptors through :meth:`cutlass.experimental.primitives.Tcgen05SmemDesc.build`, the sole customer.
    All offsets are in units of 16 bytes (the descriptor granule).
    """
    return _cutlass.Int64(
        _nvvm.tcgen05_mma_smem_desc_v2(
            _cutlass.Int32(start_address),
            _cutlass.Int32(leading_dim_offset),
            _cutlass.Int32(stride_dim_offset),
            _cutlass.Int8(descriptor_version),
            _cutlass.Int8(base_offset),
            _cutlass.Boolean(leading_dim_mode),
            _cutlass.Boolean(k_segment_offset),
            _cutlass.Int8(swizzle_type),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def tcgen05_mma_sp(
    mma_kind: Tcgen05MMAKind,
    cta_group: CTAGroup,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    sparse_metadata: Array | Pointer,
    *,
    collector_op: Tcgen05MMACollectorOp | None = None,
    a_shift: bool | None = None,
    scale_input_d: int | Int64 | Uint64 | None = None,
    write_disable_mask: Vector | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a structured-sparse 5th-gen tensor-core MMA (``tcgen05.mma.sp``).

    Like :func:`tcgen05_mma`, but operand A is a structured-sparse
    ``M x (K/2)`` matrix and ``sparse_metadata`` (in TMEM) maps the compressed
    columns back to the logical K dimension.  ``D = A * B [+ D]`` accumulates
    into TMEM.  See :func:`tcgen05_mma` for the shared single-thread-issue /
    elect-safe / commit semantics, A/B descriptor construction, and the
    ``collector_op`` / ``a_shift`` / ``scale_input_d`` / ``write_disable_mask``
    parameters.

    :param mma_kind: Data-type/kind selector (see :func:`tcgen05_mma`).
    :type mma_kind: Tcgen05MMAKind
    :param cta_group: ``'CTA_1'`` or ``'CTA_2'`` (see :func:`tcgen05_mma`).
    :type cta_group: CTAGroup
    :param d: TMEM accumulator pointer.  Validated at trace time to reside in
        tensor memory (dialect operand type ``LLVM_PointerTensor``).
    :type d: cutlass.Array or cutlass.Pointer
    :param a: A operand -- SMEM descriptor (Int64) or TMEM pointer.
    :type a: cutlass.Array, cutlass.Pointer, or cutlass.Int64
    :param b: 64-bit SMEM descriptor for B.
    :type b: int, cutlass.Int64, or cutlass.Uint64
    :param idesc: Packed 32-bit instruction descriptor (sparse bit set).
    :type idesc: int, cutlass.Int32, or cutlass.Uint32
    :param enable_input_d: ``D = A*B + D`` when true, else ``D = A*B``.
    :type enable_input_d: int or cutlass.Boolean
    :param sparse_metadata: TMEM pointer to the sparsity metadata mapping the
        K/2 packed columns to the logical K dimension.  Validated at trace
        time to reside in tensor memory.
    :type sparse_metadata: cutlass.Array or cutlass.Pointer
    :param collector_op: A-operand collector policy (see :func:`tcgen05_mma`).
    :param scale_input_d: ``[0, 15]``; valid only for ``"f16"`` / ``"tf32"``
        (validated at trace time).  See :func:`tcgen05_mma`.
    :param write_disable_mask: 4-element (``CTA_1``) / 8-element (``CTA_2``)
        per-row TMEM write-disable vector (validated at trace time).
    """
    _assert_tensor_mem(d, "tcgen05.mma.sp")
    _assert_tensor_mem(sparse_metadata, "tcgen05.mma.sp")
    _assert_tcgen05_scale_input_d(scale_input_d, mma_kind, "tcgen05.mma.sp")
    _assert_tcgen05_write_disable_mask(write_disable_mask, cta_group, "tcgen05.mma.sp")
    if scale_input_d is not None:
        scale_input_d = _cutlass.Int32(scale_input_d)
    _nvvm.tcgen05_mma_sp(
        _TCGEN05_MMA_KIND_TO_DIALECT[mma_kind],
        _CTAGROUP_TO_DIALECT[cta_group],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        sparse_metadata,
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        a_shift=a_shift,
        scale_input_d=scale_input_d,
        write_disable_mask=write_disable_mask,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_mma_sp_block_scale(
    mma_kind: Tcgen05MMAKind,
    cta_group: CTAGroup,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    sparse_metadata: Array | Pointer,
    scale_a: Array | Pointer,
    scale_b: Array | Pointer,
    *,
    scale_vec_size: _Tcgen05BlockScaleLike | None = None,
    collector_op: Tcgen05MMACollectorOp | None = None,
    a_shift: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Structured-sparse MMA with per-block scale factors (``tcgen05.mma.sp.block_scale``).

    Combines the structured-sparse A path of :func:`tcgen05_mma_sp` with the
    per-block scaling of :func:`tcgen05_mma_block_scale`: A is sparse with
    ``sparse_metadata`` in TMEM, and blocks of A/B are scaled by the
    ``scale_a`` / ``scale_b`` factor tiles (also in TMEM) before accumulation.
    See :func:`tcgen05_mma_block_scale` for the block-scale descriptor /
    scale-vector details and :func:`tcgen05_mma` for the shared issue/commit
    semantics.

    :param mma_kind: Block-scale kind; validated at trace time to be a
        block-scaled kind (``mxf8f6f4`` / ``mxf4`` / ``mxf4nvf4``).
    :type mma_kind: Tcgen05MMAKind
    :param cta_group: ``'CTA_1'`` or ``'CTA_2'``.
    :type cta_group: CTAGroup
    :param d: TMEM accumulator pointer; validated to reside in tensor memory.
    :param a: A operand -- SMEM descriptor or TMEM pointer.
    :param b: 64-bit SMEM descriptor for B.
    :param idesc: Packed 32-bit instruction descriptor.
    :param enable_input_d: ``D = A*B*scale + D`` when true, else ``D = A*B*scale``.
    :param sparse_metadata: TMEM pointer to the sparsity metadata; validated to
        reside in tensor memory.
    :param scale_a, scale_b: TMEM addresses of the A/B scale-factor tiles;
        both validated at trace time to reside in tensor memory.
    :param scale_vec_size: 1X / 2X / 4X scale-vector packing
        (see :func:`tcgen05_mma_block_scale`).
    :param collector_op: A-operand collector policy (see :func:`tcgen05_mma`).
    """
    _assert_tcgen05_block_scale_kind(mma_kind, "tcgen05.mma.sp.block_scale")
    _assert_tensor_mem(d, "tcgen05.mma.sp.block_scale")
    _assert_tensor_mem(sparse_metadata, "tcgen05.mma.sp.block_scale")
    _assert_tensor_mem(scale_a, "tcgen05.mma.sp.block_scale")
    _assert_tensor_mem(scale_b, "tcgen05.mma.sp.block_scale")
    # Same upstream rename as tcgen05_mma_block_scale: scale_vec_size ->
    # block_scale, a_shift dropped.
    scale_vec_size = _to_tcgen05_scale_vec_size(scale_vec_size)
    _nvvm.tcgen05_mma_sp_block_scale(
        _TCGEN05_MMA_KIND_TO_DIALECT[mma_kind],
        _CTAGROUP_TO_DIALECT[cta_group],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        sparse_metadata,
        scale_a,
        scale_b,
        scale_vec_size=scale_vec_size,
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        a_shift=a_shift,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_mma_ws(
    mma_kind: Tcgen05MMAKind,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    *,
    collector_b_buffer: Tcgen05MMACollectorBBuffer | None = None,
    collector_op: Tcgen05MMACollectorOp | None = None,
    col_b_zero_mask: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a weight-stationary tcgen05 MMA.

    Emits ``tcgen05.mma.ws.cta_group::1``.  The instruction initiates
    ``D = A*B+D`` for a dense A matrix and uses a B-matrix collector buffer for
    weight-stationary convolution-style reuse.  A may be an SMEM descriptor or
    a TMEM pointer; B is an SMEM descriptor.  When ``enable_input_d`` is false,
    the operation computes ``D = A*B``.

    :param mma_kind: Data-type/kind selector.  Public PTX ISA 9.3 forms support
        ``F16``, ``TF32``, ``F8F6F4``, and ``INT8`` for ``tcgen05.mma.ws``.
        (The dialect's non-block-scale kind attribute rejects block-scaled
        kinds; use :func:`tcgen05_mma_block_scale` for those.)
    :type mma_kind: Tcgen05MMAKind
    :param d: TMEM accumulator destination.  Validated at trace time to reside
        in tensor memory (dialect operand type ``LLVM_PointerTensor``).
    :type d: cutlass.Array or cutlass.Pointer
    :param a: A operand as an SMEM descriptor or TMEM pointer.
    :type a: cutlass.Array, cutlass.Pointer, or cutlass.Int64
    :param b: 64-bit SMEM descriptor for B.
    :type b: int, cutlass.Int64, or cutlass.Uint64
    :param idesc: Packed 32-bit instruction descriptor.
    :type idesc: int, cutlass.Int32, or cutlass.Uint32
    :param enable_input_d: When true, accumulate into existing D; when false,
        compute ``D = A*B``.
    :type enable_input_d: int or cutlass.Boolean
    :param collector_b_buffer: Optional B collector buffer selector
        (``B0`` through ``B3``).  PTX defaults to ``B0`` with ``DISCARD`` when
        no collector usage is specified.
    :type collector_b_buffer: Tcgen05MMACollectorBBuffer, optional
    :param collector_op: Optional B collector operation: ``FILL``, ``USE``,
        ``LASTUSE``, or ``DISCARD``.
    :type collector_op: Tcgen05MMACollectorOp, optional
    :param col_b_zero_mask: Optional zero-column-mask descriptor for B columns
        that should be treated as zero regardless of SMEM contents.
    :type col_b_zero_mask: int, cutlass.Int64, or cutlass.Uint64, optional

    .. code-block:: python

        if nvvm.elect_sync():
            nvvm.tcgen05_mma_ws(
                nvvm.Tcgen05MMAKind.INT8,
                d_tmem,
                a_tmem,
                b_desc,
                idesc,
                k > 0,
                collector_b_buffer=nvvm.Tcgen05MMACollectorBBuffer.B2,
                collector_op=nvvm.Tcgen05MMACollectorOp.USE,
            )
    """
    _assert_tensor_mem(d, "tcgen05.mma.ws")
    if col_b_zero_mask is not None:
        col_b_zero_mask = _cutlass.Int64(col_b_zero_mask)
    _nvvm.tcgen05_mma_ws(
        _TCGEN05_MMA_KIND_TO_DIALECT[mma_kind],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        collector_b_buffer=_to_dialect(
            collector_b_buffer, _TCGEN05_MMA_COLLECTOR_B_BUFFER_TO_DIALECT
        ),
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        zero_col_mask=col_b_zero_mask,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_mma_ws_sp(
    mma_kind: Tcgen05MMAKind,
    d: Array | Pointer,
    a: Array | Pointer | Int64,
    b: int | Int64 | Uint64,
    idesc: int | Int32 | Uint32,
    enable_input_d: int | Boolean,
    sparse_metadata: Array | Pointer,
    *,
    collector_b_buffer: Tcgen05MMACollectorBBuffer | None = None,
    collector_op: Tcgen05MMACollectorOp | None = None,
    col_b_zero_mask: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Issue a sparse weight-stationary tcgen05 MMA.

    Emits ``tcgen05.mma.ws.sp.cta_group::1``.  The instruction initiates
    ``D = A*B+D`` where A is a structured sparse matrix packed as
    ``M x (K/2)`` and accompanied by sparse metadata in TMEM.  A may be an SMEM
    descriptor or a TMEM pointer; B is an SMEM descriptor.  When
    ``enable_input_d`` is false, the operation computes ``D = A*B``.

    :param mma_kind: Data-type/kind selector.  Public PTX ISA 9.3 forms support
        ``F16``, ``TF32``, ``F8F6F4``, and ``INT8`` for ``tcgen05.mma.ws.sp``.
    :type mma_kind: Tcgen05MMAKind
    :param d: TMEM accumulator destination.
    :type d: cutlass.Array or cutlass.Pointer
    :param a: A operand as an SMEM descriptor or TMEM pointer.
    :type a: cutlass.Array, cutlass.Pointer, or cutlass.Int64
    :param b: 64-bit SMEM descriptor for B.
    :type b: int, cutlass.Int64, or cutlass.Uint64
    :param idesc: Packed 32-bit instruction descriptor.
    :type idesc: int, cutlass.Int32, or cutlass.Uint32
    :param enable_input_d: When true, accumulate into existing D; when false,
        compute ``D = A*B``.
    :type enable_input_d: int or cutlass.Boolean
    :param sparse_metadata: TMEM address or pointer for sparse-A metadata.
    :type sparse_metadata: cutlass.Array or cutlass.Pointer
    :param collector_b_buffer: Optional B collector buffer selector
        (``B0`` through ``B3``).  PTX defaults to ``B0`` with ``DISCARD`` when
        no collector usage is specified.
    :type collector_b_buffer: Tcgen05MMACollectorBBuffer, optional
    :param collector_op: Optional B collector operation: ``FILL``, ``USE``,
        ``LASTUSE``, or ``DISCARD``.
    :type collector_op: Tcgen05MMACollectorOp, optional
    :param col_b_zero_mask: Optional zero-column-mask descriptor for B columns
        that should be treated as zero regardless of SMEM contents.
    :type col_b_zero_mask: int, cutlass.Int64, or cutlass.Uint64, optional

    .. code-block:: python

        if nvvm.elect_sync():
            nvvm.tcgen05_mma_ws_sp(
                nvvm.Tcgen05MMAKind.TF32,
                d_tmem,
                a_tmem,
                b_desc,
                idesc,
                k > 0,
                sparse_metadata_tmem,
                collector_b_buffer=nvvm.Tcgen05MMACollectorBBuffer.B1,
                collector_op=nvvm.Tcgen05MMACollectorOp.FILL,
            )
    """
    _assert_tensor_mem(d, "tcgen05.mma.ws.sp")
    _assert_tensor_mem(sparse_metadata, "tcgen05.mma.ws.sp")
    if col_b_zero_mask is not None:
        col_b_zero_mask = _cutlass.Int64(col_b_zero_mask)
    _nvvm.tcgen05_mma_ws_sp(
        _TCGEN05_MMA_KIND_TO_DIALECT[mma_kind],
        d,
        a,
        _cutlass.Int64(b),
        _cutlass.Int32(idesc),
        _cutlass.Boolean(enable_input_d),
        sparse_metadata,
        collector_b_buffer=_to_dialect(
            collector_b_buffer, _TCGEN05_MMA_COLLECTOR_B_BUFFER_TO_DIALECT
        ),
        collector_op=_to_dialect(collector_op, _TCGEN05_MMA_COLLECTOR_OP_TO_DIALECT),
        zero_col_mask=col_b_zero_mask,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_relinquish_alloc_permit(
    *,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Release the SM-level TMEM allocation permit after ``tcgen05_alloc``.

    Emits ``tcgen05.relinquish_alloc_permit.sync.aligned``.  The ``.sync.aligned``
    qualifier means this is a **warp-collective** instruction: all 32 threads
    of the warp must execute it simultaneously.

    **CTA_2 placement**: call from a warp that runs on both CTAs at a
    convergence point (e.g. warp 0 right after ``barrier_cluster_wait`` and before any
    warp-role branch that may diverge between CTAs).

    :param group: ``'CTA_1'`` (default) or ``'CTA_2'``.  See :data:`CTAGroup`.

    .. code-block:: python

        # CTA_1: inside the MMA warp, outside elect_sync (both alloc and
        # relinquish are .sync.aligned — all 32 threads must participate).
        if warp == MMA_WARP:
            nvvm.tcgen05_alloc(tmem_ptr, num_cols, group="cta_1")
            nvvm.tcgen05_relinquish_alloc_permit(group="cta_1")

        # CTA_2: from warp 0 BEFORE warp-role branches — ensures both CTAs converge
        if warp == 0:
            nvvm.tcgen05_alloc(tmem_ptr, num_cols, group="cta_2")
        nvvm.barrier_cluster_wait()
        nvvm.barrier_cta_sync()
        # Both CTAs' warp 0 reach here simultaneously → safe collective call:
        if warp == 0:
            nvvm.tcgen05_relinquish_alloc_permit(group="cta_2")
        # Only NOW diverge into warp-specialized roles (TMA / MMA / epilogue)
    """
    _nvvm_raw.tcgen05_relinquish_alloc_permit(
        group=_to_dialect(group, _CTAGROUP_TO_DIALECT), loc=loc, ip=ip
    )


@dsl_user_op
def tcgen05_shift(
    taddr: Array | Pointer,
    *,
    group: CTAGroup | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Shift TMEM rows down by one within each sub-partition (``tcgen05.shift``).

    Asynchronous instruction that shifts the 32-byte elements of the matrix at
    ``taddr`` downwards by one row across all rows except the last of each
    sub-partition.  Used to advance a sliding-window operand in TMEM (e.g. the
    A operand of a chained :func:`tcgen05_mma`).  Staged into the tensor-core
    issue queue alongside ``tcgen05.mma`` / ``tcgen05.cp``; pair with
    :func:`tcgen05_commit` (or a downstream consumer) to observe completion.

    :param taddr: TMEM base pointer of the matrix whose rows are shifted.
        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space`` (dialect operand type ``LLVM_PointerTensor``).
    :type taddr: cutlass.Array or cutlass.Pointer
    :param group: ``'CTA_1'`` (default) or ``'CTA_2'``.  Selects the
        single-CTA vs 2-CTA shift; must match the group of the other
        ``tcgen05`` ops in the kernel.  See :data:`CTAGroup`.
    :type group: CTAGroup, optional

    """
    _assert_tensor_mem(taddr, "tcgen05.shift")
    _nvvm_raw.tcgen05_shift(
        taddr, group=_to_dialect(group, _CTAGROUP_TO_DIALECT), loc=loc, ip=ip
    )


@dsl_user_op
def tcgen05_st(
    shape: Tcgen05LdStShape,
    tmem_addr: Array | Pointer,
    val: Int32 | Vector,
    *,
    unpack: bool | None = None,
    offset: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Store register data into TMEM.

    Emits ``tcgen05.st.sync.aligned.{shape}{.xN}{.unpack}.b32``.  The issuing
    warp collectively stores into TMEM; each lane supplies its own register
    slice for the warp's accessible TMEM sub-partition.  Mirror of
    :func:`tcgen05_ld`: same shape literals,
    same address encoding, same TMEM access restriction (see
    :func:`tcgen05_ld` for the canonical
    warp-position-to-lane-range table and the ``M_TILE=128`` epilogue /
    writer implications).  Read both docstrings together — :func:`tcgen05_ld`
    is the source of truth for the access table; this docstring covers
    only the store-direction differences.

    Accepts any ``Vector`` or scalar for *val*; non-``Int32`` values are
    bitcast to ``Int32`` internally (the hardware requires i32 register
    words) — no manual ``.bitcast(Int32)`` wrapping needed at the call site.

    :param shape: Store shape (PTX ``.shape1`` / ``.shape2``).  One of
        ``"16x32bx2"``, ``"16x64b"``, ``"32x32b"``, ``"16x128b"``,
        ``"16x256b"``.  Same access restriction as :func:`tcgen05_ld`.
    :type shape: Tcgen05LdStShape
    :param tmem_addr: Pointer/Array to the TMEM location;
        ``(row << 16) | col`` encoding (see :func:`tcgen05_ld` for full
        encoding details).
        Validated at trace time: must reside in tensor memory when the passed
        object exposes ``.space`` (the dialect operand type is
        ``LLVM_PointerTensor``); opaque pointers are deferred to the verifier.
    :type tmem_addr: cutlass.Array or cutlass.Pointer
    :param val: Value to store.  ``Int32`` scalar or ``Vector[any dtype]``;
        non-Int32 dtypes are auto-bitcast to ``Int32`` internally.
    :type val: cutlass.Int32 or cutlass.Vector
    :param unpack: Enable element unpacking — mirror of
        ``pack`` on :func:`tcgen05_ld`.
    :type unpack: bool, optional
    :param offset: Required (and only valid) for ``"16x32bx2"`` — column
        offset added to ``tmem_addr`` at runtime.  Must be ``None`` for all
        other shapes.
    :type offset: int or cutlass.Int64 or cutlass.Uint64, optional
    :raises ValueError: ``shape`` is not a recognized literal; ``offset``
        is set for a shape other than ``"16x32bx2"`` (or missing for
        ``"16x32bx2"``).
    :raises TypeError: ``tmem_addr`` exposes a ``.space`` that is not tensor
        memory (TMEM).

    .. code-block:: python

        # Store a vector of accumulator data back into TMEM.
        nvvm.tcgen05_st("32x32b", tmem_ptr, data_vec)
    """
    _assert_tensor_mem(tmem_addr, "tcgen05.st")
    shape_enum = _TCGEN05_LD_ST_SHAPES.get(shape)
    if shape_enum is None:
        raise ValueError(
            f"tcgen05.st: shape must be one of "
            f"{sorted(_TCGEN05_LD_ST_SHAPES)}, got {shape!r}"
        )
    if shape == "16x32bx2":
        if offset is None:
            raise ValueError(
                "tcgen05.st: offset (immHalfSplitoff) is required for '16x32bx2'"
            )
    elif offset is not None:
        raise ValueError(
            f"tcgen05.st: offset is only valid for '16x32bx2', not {shape!r}"
        )
    offset_value = None
    if offset is not None:
        offset_obj: Any = (
            offset if hasattr(offset, "ir_value") else _cutlass.Int64(offset)
        )
        offset_value = offset_obj.ir_value(loc=loc, ip=ip)
    _tmem_addr = tmem_addr.ir_value() if hasattr(tmem_addr, "ir_value") else tmem_addr
    if hasattr(val, "dtype") and val.dtype is not _cutlass.Int32:
        val = val.bitcast(_cutlass.Int32, loc=loc, ip=ip)
    _val = val.ir_value() if hasattr(val, "ir_value") else val

    # nvvm.tcgen05.st rejects vector<1xi32>; collapse to plain i32
    if isinstance(_val, Vector) and _val.numel() == 1:
        from cutlass._mlir.dialects import vector as _vector

        _val = _vector.ExtractOp(_val, [], static_position=[0], loc=loc, ip=ip).result
    _nvvm_raw.tcgen05_st(
        shape_enum,
        _tmem_addr,
        _val,
        unpack=unpack,
        offset=offset_value,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def tcgen05_wait(
    kind: Tcgen05Wait,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wait for pending TMEM load or store operations to complete.

    Emits ``tcgen05.wait::{ld|st}.sync.aligned``.  Place after
    :func:`tcgen05_ld`
    (``LOAD``) to ensure the TMEM→register transfer has finished
    before any thread reads the returned register values, or after
    :func:`tcgen05_st` (``STORE``) to ensure register→TMEM writes
    are visible before a downstream :func:`tcgen05_mma` reads them.

    :param kind: ``"load"`` or ``"store"``.

    .. code-block:: python

        # Epilogue: read accumulator from TMEM into registers
        c_vec = nvvm.tcgen05_ld(shape, tmem_addr, num=num_cols)
        nvvm.tcgen05_wait("load")
        # c_vec is now safe to use
    """
    _nvvm_raw.tcgen05_wait(_TCGEN05_WAIT_TO_DIALECT[kind], loc=loc, ip=ip)


@dsl_user_op
def tensormap_cp_fenceproxy(
    dst: Array | Pointer,
    src: Array | Pointer,
    size: int | Int32 | Uint32,
    scope: MemScope,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Copy a TMA descriptor with a proxy fence at the requested scope.

    Emits ``tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.<scope>.sync.aligned
    [dst], [src], size;``.  Copies ``size`` bytes of TMA descriptor
    data from ``src`` to ``dst`` and acts as a release fence between
    the generic and tensormap proxies, so subsequent TMA ops see the
    new descriptor at the chosen visibility scope (``cta`` / ``cluster``
    / ``gpu`` / ``sys``).

    :param dst: TMA-descriptor destination pointer / array (typically
        a constant-banked descriptor slot).
    :type dst: cutlass.Array or cutlass.Pointer
    :param src: TMA-descriptor source pointer / array.
    :type src: cutlass.Array or cutlass.Pointer
    :param size: Number of bytes to copy; the descriptor size (128 for
        standard TMA descriptors).
    :type size: int or cutlass.Int32 or cutlass.Uint32
    :param scope: Visibility scope of the release fence.
    :type scope: MemScope
    :raises ValueError: if a statically known ``size`` is not 128.

    """
    if isinstance(size, int) and size != 128:
        raise ValueError(
            f"tensormap.cp_fenceproxy: size must be 128 (the TMA descriptor size); got {size}"
        )
    _nvvm.tensormap_cp_fenceproxy(
        dst,
        src,
        _cutlass.Int32(size),
        _MEMSCOPE_TO_DIALECT[scope],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def trace_mark(
    event_type: int,
    domain: str,
    event: str,
    *,
    payload: Int32 | Int64 | None = None,
    payload_descriptor: str | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wrapper over ``nvvm.trace_mark``."""
    _nvvm.trace_mark(
        event_type,
        domain,
        event,
        payload=payload,
        payload_descriptor=payload_descriptor,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def vote_sync(
    mask: int | Int32 | Uint32,
    pred: int | Boolean,
    kind: VoteSync,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Boolean:
    """Perform a collective warp vote across masked lanes.

    Maps to ``vote.sync.{all|any|uni|ballot}`` — each participating lane
    contributes a boolean predicate and all receive a shared result.  All
    lanes named in *mask* must be actively executing the instruction
    (convergence requirement).

    **VoteSyncKind variants:**

    * ``"all"`` → ``Boolean``: ``True`` iff *every* masked lane
      set ``pred = True``.
    * ``"any"`` → ``Boolean``: ``True`` iff *at least one* masked
      lane set ``pred = True``.
    * ``"uni"`` → ``Boolean``: ``True`` iff all masked lanes cast
      the *same* vote (all-True **or** all-False).  Use to detect uniform
      control flow without requiring all lanes to be true.
    * ``"ballot"`` → ``Int32``: 32-bit bitmask where bit *i* is
      set when lane *i* set ``pred = True``.  Bit *i* is 0 for lanes not
      in *mask*.

    :param mask: 32-bit member mask; bit *i* set means lane *i* participates.
        All named lanes must execute the instruction.  Pass ``0xFFFFFFFF``
        for a full-warp vote.
    :type mask: int or cutlass.Int32 or cutlass.Uint32
    :param pred: Per-lane boolean vote input — what each lane contributes
        to the collective result.  Pass ``~pred`` to vote on the negation.
    :type pred: int or cutlass.Boolean
    :param kind: Vote mode — determines the semantics and return type.
    :type kind: VoteSync
    :return: ``Boolean`` for ``all``/``any``/``uni``; ``Int32`` bitmask for
        ``ballot``.
    :rtype: cutlass.Boolean or cutlass.Int32
    :raises ValueError: if a static *mask* does not fit in 32 bits, or if *kind*
        is not one of ``"all"``, ``"any"``, ``"uni"``, ``"ballot"``. A runtime
        (non-``int``) *mask* is not checked at trace time.

    **Constraints:**

    * All lanes named in *mask* must reach the instruction; a divergent lane
      causes the remaining lanes to stall indefinitely.
    * Available on SM30+; ``ballot`` requires SM35+.
    * This wrapper has no ``exec_pred`` argument.

    .. code-block:: python

        tx, _, _ = cute.arch.thread_idx()
        is_even = (tx % cutlass.Int32(2)) == cutlass.Int32(0)

        # all: True only when every lane voted True
        all_even = nvvm.vote_sync(0xFFFFFFFF, is_even, "all")

        # any: True when at least one lane voted True
        any_even = nvvm.vote_sync(0xFFFFFFFF, is_even, "any")

        # uni: True when all lanes agree (all-True OR all-False)
        uniform  = nvvm.vote_sync(0xFFFFFFFF, is_even, "uni")

        # ballot: bitmask of lanes that voted True (even lanes → 0x55555555)
        even_mask = nvvm.vote_sync(0xFFFFFFFF, is_even, "ballot")
    """
    _assert_mask32(mask, "vote.sync")
    _assert_vote_kind(kind, "vote.sync")
    dialect_kind = _VOTE_SYNC_TO_DIALECT[kind]
    # Detect ballot via the dialect enum so a raw-enum `kind` argument selects
    # the Int32 return as reliably as the "ballot" string / VoteSync.BALLOT.
    if dialect_kind == _VoteSyncKindDialect.ballot:
        return _cutlass.Int32(
            _nvvm.vote_sync(
                _cutlass.Int32.mlir_type,
                _cutlass.Int32(mask),
                _cutlass.Boolean(pred),
                dialect_kind,
                loc=loc,
                ip=ip,
            )
        )
    return _cutlass.Boolean(
        _nvvm.vote_sync(
            _cutlass.Boolean.mlir_type,
            _cutlass.Int32(mask),
            _cutlass.Boolean(pred),
            dialect_kind,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def wgmma_mma_async(
    results_: ir.Type,
    inouts: ir.Value,
    descriptor_a: int | Int64 | Uint64,
    descriptor_b: int | Int64 | Uint64,
    shape: ir.Attribute,
    type_a: WGMMAType,
    type_b: WGMMAType,
    type_d: WGMMAType,
    scale_d: WGMMAScaleOut,
    scale_a: WGMMAScaleIn,
    scale_b: WGMMAScaleIn,
    layout_a: MMALayout,
    layout_b: MMALayout,
    *,
    satfinite: MMAIntOverflow | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    """Wrapper over ``nvvm.wgmma_mma_async``.

    Returns an LLVM struct.  Caller provides the raw MLIR result type
    as *results_*.
    """
    return _nvvm_raw.wgmma_mma_async(
        results_,
        inouts,
        _cutlass.Int64(descriptor_a),
        _cutlass.Int64(descriptor_b),
        shape,
        _WGMMA_TYPE_TO_DIALECT[type_a],
        _WGMMA_TYPE_TO_DIALECT[type_b],
        _WGMMA_TYPE_TO_DIALECT[type_d],
        _WGMMA_SCALE_OUT_TO_DIALECT[scale_d],
        _WGMMA_SCALE_IN_TO_DIALECT[scale_a],
        _WGMMA_SCALE_IN_TO_DIALECT[scale_b],
        _MMA_LAYOUT_TO_DIALECT[layout_a],
        _MMA_LAYOUT_TO_DIALECT[layout_b],
        satfinite=_to_dialect(satfinite, _MMA_INT_OVERFLOW_TO_DIALECT),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def wmma_load(
    res: ir.Type,
    ptr: Array | Pointer,
    stride: int | Int32 | Uint32,
    m: int,
    n: int,
    k: int,
    layout: MMALayout,
    eltype: MMAType,
    frag: MMAFrag,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    """Wrapper over ``nvvm.wmma_load``.

    Returns an LLVM struct.  Caller provides the raw MLIR result type
    as *res*.
    """
    return _nvvm_raw.wmma_load(
        res,
        ptr,
        _cutlass.Int32(stride),
        m,
        n,
        k,
        _MMA_LAYOUT_TO_DIALECT[layout],
        _MMA_TYPE_TO_DIALECT[eltype],
        _MMA_FRAG_TO_DIALECT[frag],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def wmma_store(
    ptr: Array | Pointer,
    m: int,
    n: int,
    k: int,
    layout: MMALayout,
    eltype: MMAType,
    args: ir.Value,
    stride: int | Int32 | Uint32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Wrapper over ``nvvm.wmma_store``."""
    _nvvm.wmma_store(
        ptr,
        m,
        n,
        k,
        _MMA_LAYOUT_TO_DIALECT[layout],
        _MMA_TYPE_TO_DIALECT[eltype],
        args,
        _cutlass.Int32(stride),
        loc=loc,
        ip=ip,
    )


# =============================================================================
# Non-decorated functions from manual section
# =============================================================================


def clusterlaunchcontrol_query_cancel(
    query_type: ClusterLaunchControlQueryType,
    try_cancel_response: int | Int128 | Uint128,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Boolean | Int32:
    """1:1 wrapper over ``nvvm.clusterlaunchcontrol_query_cancel``.

    Returns ``Boolean`` for ``IS_CANCELED``, ``Int32`` for
    ``GET_FIRST_CTA_ID_{X,Y,Z}``.
    """
    if query_type == "is_canceled":
        return _cutlass.Boolean(
            _nvvm.clusterlaunchcontrol_query_cancel(
                _CLUSTERLAUNCHCONTROLQUERYTYPE_TO_DIALECT[query_type],
                _cutlass.Int128(try_cancel_response),
                loc=loc,
                ip=ip,
            )
        )
    return _cutlass.Int32(
        _nvvm.clusterlaunchcontrol_query_cancel(
            _CLUSTERLAUNCHCONTROLQUERYTYPE_TO_DIALECT[query_type],
            _cutlass.Int128(try_cancel_response),
            loc=loc,
            ip=ip,
        )
    )


# =============================================================================
# Generic float convert: dispatches to the typed convert.* op based on the
# runtime element type + lane count of ``src`` and the requested ``dst_dtype``,
# and verifies the combination + arguments.
# =============================================================================

#: Narrow-float families recognised by :func:`convert`.  These mirror the
#: ``_Float8Type`` / ``_Float6Type`` / ``_Float4Type`` sets the typed
#: ``convert_*`` wrappers accept, so ``convert`` does not reject a dtype the
#: wrapper layer would handle.  (The s2f6 packed form has no dtype and is
#: reached only via the explicit ``convert_*_to_s2f6x2`` wrappers.)
_CVT_F8 = (
    Float8E4M3,
    Float8E4M3B11FNUZ,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
)
_CVT_F6 = (Float6E2M3FN, Float6E3M2FN)
_CVT_F4 = (Float4E2M1FN,)


def _cvt_family(dtype: object) -> str | None:
    """Short family tag for a float dtype, or None if unrecognised."""
    if dtype == Float32:
        return "f32"
    if dtype == Float16:
        return "f16"
    if dtype == BFloat16:
        return "bf16"
    if dtype in _CVT_F8:
        return "f8"
    if dtype in _CVT_F6:
        return "f6"
    if dtype in _CVT_F4:
        return "f4"
    return None


def _cvt_reject(ctx: str, **kwargs: object) -> None:
    """Raise if any named argument is set for a conversion that ignores it."""
    bad = sorted(k for k, v in kwargs.items() if v is not None)
    if bad:
        raise ValueError(f"convert {ctx}: argument(s) {bad} are not supported here")


@dsl_user_op
def convert(
    src: Vector,
    dst_dtype: object,
    *,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    random_bits: int | Int32 | Uint32 | None = None,
    result_type: object = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Convert a packed float vector to ``dst_dtype``, dispatching on types.

    A single entry point over the typed ``convert_*`` ops: it reads the element
    type and lane count of ``src`` plus the requested ``dst_dtype`` and routes
    to the matching NVVM convert, verifying both the combination and the
    arguments.  Covers the float<->float packed conversions:

    * ``f32x2`` -> ``f16`` / ``bf16`` / ``f8`` / ``f6`` / ``f4``
    * ``f32x4`` -> ``f8`` / ``f6`` / ``f4`` (requires ``random_bits``)
    * ``f16x2`` / ``bf16x2`` -> ``f8`` / ``f6`` / ``f4``
    * ``f8x2`` / ``f6x2`` / ``f4x2`` -> ``f16``

    Exotic / non-float-float conversions (``s2f6``, scaled ``f8 -> bf16``,
    float<->integer, ``tf32``) are not routed here; call the explicit
    ``nvvm.convert_*`` wrapper for those.

    :param src: Packed source vector (e.g. ``Vector[Float32, 2]``,
        ``Vector[Float8E4M3FN, 2]``); its element type and lane count drive
        dispatch.
    :type src: Vector
    :param dst_dtype: Target element type (e.g. ``Float16``, ``Float8E4M3FN``).
    :param rnd: Rounding mode, where the matched convert accepts one.
    :param sat: Saturation mode (f8 / f16 / bf16 narrowing only).
    :param relu: Clamp negatives to zero, where supported.
    :param scale_factor: Block scale, for the scaled narrowing converts.
    :param scale_factor_kind: Scale-factor kind paired with ``scale_factor``.
    :param random_bits: Stochastic-rounding bits; required for ``f32x4``
        narrowing and optional for ``f32x2 -> f16 / bf16``.
    :param result_type: Packed return-shape override (``Int16`` /
        ``Vector[Int8, 2]``) for the narrowing converts that support it.
    :raises ValueError: the (source dtype, lane count, destination dtype)
        triple is not a supported float<->float conversion, an argument is not
        accepted by the matched convert, or ``random_bits`` is missing for an
        ``f32x4`` narrowing.

    .. note::

        Narrowing returns a **packed integer carrier** (``Int16`` /
        ``Vector[Int8, N]``), whereas widening expects a **typed** narrow
        vector (e.g. ``Vector[Float8E4M3FN, 2]``, such as one loaded from an
        FP8 tensor) and bitcasts it to the byte carrier internally.  A packed
        narrowing result is therefore not directly re-widenable: reinterpret it
        as the typed narrow vector first (``carrier.bitcast(<narrow dtype>)``).

    .. code-block:: python

        # Narrowing: f32 pair -> packed FP8x2 (an Int16 carrier).
        packed = nvvm.convert(f32x2, cutlass.Float8E4M3FN, rnd="rn", sat="satfinite")

        # Widening: a *typed* FP8x2 vector (e.g. loaded from memory) -> f16x2.
        f16x2 = nvvm.convert(fp8_vec, cutlass.Float16)
    """
    sf = _cvt_family(src.dtype)
    df = _cvt_family(dst_dtype)
    lanes = src._count

    # Widening: f8/f6/f4 x2 -> f16.  (Reverse converts are still raw bindings;
    # call them directly with the result type + the source-type discriminator.)
    if df == "f16" and lanes == 2 and sf in ("f8", "f6", "f4"):
        _cvt_reject(
            f"{sf}x2->f16",
            rnd=rnd,
            sat=sat,
            scale_factor=scale_factor,
            scale_factor_kind=scale_factor_kind,
            random_bits=random_bits,
            result_type=result_type,
        )
        raw = {
            "f8": _nvvm.convert_f8x2_to_f16x2,
            "f6": _nvvm.convert_f6x2_to_f16x2,
            "f4": _nvvm.convert_f4x2_to_f16x2,
        }[sf]
        # The op carries the packed narrow values as raw bytes (vector<2xi8>);
        # the source float type is supplied via the srcType attribute.
        src_ty = ir.TypeAttr.get(src.dtype.mlir_type)
        carrier = src.bitcast(Int8)
        return Vector[Float16, 2](
            raw(
                Vector[Float16, 2].mlir_type, carrier, src_ty, relu=relu, loc=loc, ip=ip
            )
        )

    # f32x2 -> f16 / bf16
    if sf == "f32" and lanes == 2 and df in ("f16", "bf16"):
        _cvt_reject(
            f"f32x2->{df}",
            scale_factor=scale_factor,
            scale_factor_kind=scale_factor_kind,
            result_type=result_type,
        )
        fn: Callable[..., Vector] = (
            _convert_f32x2_to_f16x2 if df == "f16" else _convert_f32x2_to_bf16x2
        )
        return fn(
            src[0],
            src[1],
            random_bits=random_bits,
            rnd=rnd,
            sat=sat,
            relu=relu,
            loc=loc,
            ip=ip,
        )

    # f32x2 / f16x2 / bf16x2 -> f8 / f6 / f4
    if sf in ("f32", "f16", "bf16") and lanes == 2 and df in ("f8", "f6", "f4"):
        _cvt_reject(f"{sf}x2 narrowing", random_bits=random_bits)
        fn = {
            ("f32", "f8"): _convert_f32x2_to_f8x2,
            ("f32", "f6"): _convert_f32x2_to_f6x2,
            ("f32", "f4"): _convert_f32x2_to_f4x2,
            ("f16", "f8"): _convert_f16x2_to_f8x2,
            ("f16", "f6"): _convert_f16x2_to_f6x2,
            ("f16", "f4"): _convert_f16x2_to_f4x2,
            ("bf16", "f8"): _convert_bf16x2_to_f8x2,
            ("bf16", "f6"): _convert_bf16x2_to_f6x2,
            ("bf16", "f4"): _convert_bf16x2_to_f4x2,
        }[(sf, df)]
        # f32x2 wrappers take two scalars; the f16x2/bf16x2 forms take one
        # packed vector.
        ops = (src[0], src[1]) if sf == "f32" else (src,)
        if df == "f4":
            # f4 wrappers have no result_type / sat; they return a packed Int8.
            _cvt_reject(f"{sf}x2->f4", sat=sat, result_type=result_type)
            return fn(
                *ops,
                dst_dtype,
                scale_factor=scale_factor,
                scale_factor_kind=scale_factor_kind,
                rnd=rnd,
                relu=relu,
                loc=loc,
                ip=ip,
            )
        rt = result_type if result_type is not None else Int16
        if df == "f6":
            _cvt_reject(f"{sf}x2->f6", sat=sat)
            return fn(
                *ops,
                dst_dtype,
                result_type=rt,
                scale_factor=scale_factor,
                scale_factor_kind=scale_factor_kind,
                rnd=rnd,
                relu=relu,
                loc=loc,
                ip=ip,
            )
        return fn(
            *ops,
            dst_dtype,
            result_type=rt,
            scale_factor=scale_factor,
            scale_factor_kind=scale_factor_kind,
            rnd=rnd,
            sat=sat,
            relu=relu,
            loc=loc,
            ip=ip,
        )

    # f32x4 -> f8 / f6 / f4
    if sf == "f32" and lanes == 4 and df in ("f8", "f6", "f4"):
        if random_bits is None:
            raise ValueError("convert f32x4 narrowing requires random_bits")
        _cvt_reject(
            "f32x4 narrowing",
            sat=sat,
            scale_factor=scale_factor,
            scale_factor_kind=scale_factor_kind,
            result_type=result_type,
        )
        fn = {
            "f8": _convert_f32x4_to_f8x4,
            "f6": _convert_f32x4_to_f6x4,
            "f4": _convert_f32x4_to_f4x4,
        }[df]
        return fn(src, random_bits, dst_dtype, relu=relu, loc=loc, ip=ip)

    raise ValueError(
        f"convert: unsupported conversion {src.dtype} x{lanes} -> {dst_dtype}. "
        "Supported: f32x2->{f16,bf16,f8,f6,f4}, f32x4->{f8,f6,f4}, "
        "f16x2/bf16x2->{f8,f6,f4}, f8x2/f6x2/f4x2->f16. Use the explicit "
        "nvvm.convert_* wrapper for s2f6 / scaled bf16 / integer / tf32."
    )


@dsl_user_op
def _convert_bf16x2_to_f4x2(
    a: Vector,
    dst_ty: _Float4Type | ir.Type,
    *,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int8:
    """Wrapper over ``nvvm.convert_bf16x2_to_f4x2``."""
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return _cutlass.Int8(
        _nvvm.convert_bf16x2_to_f4x2(
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_bf16x2_to_f6x2(
    a: Vector,
    dst_ty: _Float6Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_bf16x2_to_f6x2``.

    *result_type* selects the packed return shape: the current default
    or ``Vector[Int8, 2]`` (each lane holds one converted value).
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_bf16x2_to_f6x2(
            result_type.mlir_type,
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_bf16x2_to_f8x2(
    a: Vector,
    dst_ty: _Float8Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    relu: bool | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_bf16x2_to_f8x2``.

    *result_type* selects the packed return shape: ``Int16`` (default,
    one i16 with the two converted values packed into the high and low
    bytes) or ``Vector[Int8, 2]`` (each lane holds one converted value).
    Both shapes hold equivalent bits.
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_bf16x2_to_f8x2(
            result_type.mlir_type,
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            relu=relu,
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def _convert_f16x2_to_f4x2(
    a: Vector,
    dst_ty: _Float4Type | ir.Type,
    *,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int8:
    """Wrapper over ``nvvm.convert_f16x2_to_f4x2``."""
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return _cutlass.Int8(
        _nvvm.convert_f16x2_to_f4x2(
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f16x2_to_f6x2(
    a: Vector,
    dst_ty: _Float6Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_f16x2_to_f6x2``.

    *result_type* selects the packed return shape: the current default
    or ``Vector[Int8, 2]`` (each lane holds one converted value).
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_f16x2_to_f6x2(
            result_type.mlir_type,
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f16x2_to_f8x2(
    a: Vector,
    dst_ty: _Float8Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_f16x2_to_f8x2``.

    *result_type* selects the packed return shape: ``Int16`` (default,
    one i16 with the two converted values packed into the high and low
    bytes) or ``Vector[Int8, 2]`` (each lane holds one converted value).
    Both shapes hold equivalent bits.
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_f16x2_to_f8x2(
            result_type.mlir_type,
            a,
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x2_to_bf16x2(
    src_hi: float | Float32,
    src_lo: float | Float32,
    *,
    random_bits: int | Int32 | Uint32 | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """1:1 wrapper over ``nvvm.convert_f32x2_to_bf16x2``."""
    if random_bits is not None:
        random_bits = _cutlass.Int32(random_bits)
    return Vector[BFloat16, 2](
        _nvvm.convert_f32x2_to_bf16x2(
            Vector[BFloat16, 2].mlir_type,
            _cutlass.Float32(src_hi),
            _cutlass.Float32(src_lo),
            random_bits=random_bits,
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x2_to_f16x2(
    src_hi: float | Float32,
    src_lo: float | Float32,
    *,
    random_bits: int | Int32 | Uint32 | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """1:1 wrapper over ``nvvm.convert_f32x2_to_f16x2``."""
    if random_bits is not None:
        random_bits = _cutlass.Int32(random_bits)
    return Vector[Float16, 2](
        _nvvm.convert_f32x2_to_f16x2(
            Vector[Float16, 2].mlir_type,
            _cutlass.Float32(src_hi),
            _cutlass.Float32(src_lo),
            random_bits=random_bits,
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def _convert_f32x2_to_f4x2(
    a: float | Float32,
    b: float | Float32,
    dst_type: _Float4Type | ir.Type,
    *,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int8:
    """Wrapper over ``nvvm.convert_f32x2_to_f4x2``."""
    if hasattr(dst_type, "mlir_type"):
        dst_type = dst_type.mlir_type
    if isinstance(dst_type, ir.Type):
        dst_type = ir.TypeAttr.get(dst_type)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return _cutlass.Int8(
        _nvvm.convert_f32x2_to_f4x2(
            _cutlass.Float32(a),
            _cutlass.Float32(b),
            dst_type,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x2_to_f6x2(
    a: float | Float32,
    b: float | Float32,
    dst_ty: _Float6Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_f32x2_to_f6x2``.

    *result_type* selects the packed return shape: ``Int16`` (default,
    one i16 with the two converted values packed into the high and low
    bytes) or ``Vector[Int8, 2]`` (each lane holds one converted value).
    Both shapes hold equivalent bits.
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_f32x2_to_f6x2(
            result_type.mlir_type,
            _cutlass.Float32(a),
            _cutlass.Float32(b),
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x2_to_f8x2(
    a: float | Float32,
    b: float | Float32,
    dst_ty: _Float8Type | ir.Type,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_f32x2_to_f8x2``.

    *result_type* selects the packed return shape: ``Int16`` (default,
    one i16 with the two converted values packed into the high and low
    bytes) or ``Vector[Int8, 2]`` (each lane holds one converted value).
    Both shapes hold equivalent bits.
    """
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_f32x2_to_f8x2(
            result_type.mlir_type,
            _cutlass.Float32(a),
            _cutlass.Float32(b),
            dst_ty,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=_convert_scale_to_dialect(scale_factor_kind),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def convert_f32x2_to_s2f6x2(
    a: float | Float32,
    b: float | Float32,
    *,
    result_type: type[Int16] | type[Vector] = Int16,
    scale_factor: int | Int16 | Uint16 | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16 | Vector:
    """1:1 wrapper over ``nvvm.convert_f32x2_to_s2f6x2``.

    *result_type* selects the packed return shape: ``Int16`` (default,
    one i16 with the two converted values packed into the high and low
    bytes) or ``Vector[Int8, 2]`` (each lane holds one converted value).
    Both shapes hold equivalent bits.
    """
    _assert_min_ptx(".s2f6x2 destination type", "cvt.s2f6x2.f32", "9.1")
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return result_type(
        _nvvm.convert_f32x2_to_s2f6x2(
            result_type.mlir_type,
            _cutlass.Float32(a),
            _cutlass.Float32(b),
            scale_factor=scale_factor,
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x4_to_f4x4(
    src: Vector,
    rbits: int | Int32 | Uint32,
    dst_ty: _Float4Type | ir.Type,
    *,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16:
    """1:1 wrapper over ``nvvm.convert_f32x4_to_f4x4``."""
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    return _cutlass.Int16(
        _nvvm.convert_f32x4_to_f4x4(
            src,
            _cutlass.Int32(rbits),
            dst_ty,
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x4_to_f6x4(
    src: Vector,
    rbits: int | Int32 | Uint32,
    dst_ty: _Float6Type | ir.Type,
    *,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """1:1 wrapper over ``nvvm.convert_f32x4_to_f6x4``."""
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    return Vector[Int8, 4](
        _nvvm.convert_f32x4_to_f6x4(
            Vector[Int8, 4].mlir_type,
            src,
            _cutlass.Int32(rbits),
            dst_ty,
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def _convert_f32x4_to_f8x4(
    src: Vector,
    rbits: int | Int32 | Uint32,
    dst_ty: _Float8Type | ir.Type,
    *,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """1:1 wrapper over ``nvvm.convert_f32x4_to_f8x4``."""
    if hasattr(dst_ty, "mlir_type"):
        dst_ty = dst_ty.mlir_type
    if isinstance(dst_ty, ir.Type):
        dst_ty = ir.TypeAttr.get(dst_ty)
    return Vector[Int8, 4](
        _nvvm.convert_f32x4_to_f8x4(
            Vector[Int8, 4].mlir_type,
            src,
            _cutlass.Int32(rbits),
            dst_ty,
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def convert_float_to_integer(
    src: float | Float32,
    *,
    result_type: type[Int8] | type[Int32] = Int32,
    rnd: IntRoundingMode | None = None,
    sat: bool | None = None,
    ftz: bool | None = None,
    is_signed: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int8 | Int32:
    """1:1 wrapper over ``nvvm.convert_float_to_integer``."""
    return result_type(
        _nvvm.convert_float_to_integer(
            result_type.mlir_type,
            _cutlass.Float32(src),
            rnd=_to_dialect(rnd, _INT_ROUNDING_MODE_TO_DIALECT),
            sat=sat,
            ftz=ftz,
            is_signed=is_signed,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def convert_float_to_tf32(
    src: float | Float32,
    *,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Wrapper over ``nvvm.convert_float_to_tf32``."""
    return _cutlass.Int32(
        _nvvm.convert_float_to_tf32(
            _cutlass.Float32(src),
            rnd=_to_dialect(rnd, _FP_ROUNDING_MODE_TO_DIALECT),
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def convert_s2f6x2_to_bf16x2(
    src: Vector,
    *,
    scale_factor: int | Int16 | Uint16 | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """1:1 wrapper over ``nvvm.convert_s2f6x2_to_bf16x2``."""
    _assert_min_ptx(".s2f6x2 source type", "cvt.bf16x2.s2f6x2", "9.1")
    if scale_factor is not None:
        scale_factor = _cutlass.Int16(scale_factor)
    return Vector[BFloat16, 2](
        _nvvm.convert_s2f6x2_to_bf16x2(
            Vector[BFloat16, 2].mlir_type,
            src,
            scale_factor=scale_factor,
            sat=_to_dialect(sat, _SATURATION_MODE_TO_DIALECT),
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


def match_sync(
    thread_mask: int | Int32 | Uint32,
    val: Int32 | Int64,
    kind: MatchSync,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | tuple[Int32, Boolean]:
    """1:1 wrapper over ``nvvm.match_sync``.

    Returns ``Int32`` for ``any``, ``(Int32, Boolean)`` for ``all``.
    """
    if kind == "all":
        _i32 = ir.IntegerType.get_signless(32)
        _i1 = ir.IntegerType.get_signless(1)
        result = _nvvm.match_sync(
            _cutlass.Int32(thread_mask),
            val,
            _MATCH_SYNC_TO_DIALECT[kind],
            loc=loc,
            ip=ip,
        )
        mask = _llvm.extractvalue(_i32, result, position=[0])
        pred = _llvm.extractvalue(_i1, result, position=[1])
        return _cutlass.Int32(mask), _cutlass.Boolean(pred)
    return _cutlass.Int32(
        _nvvm.match_sync(
            _cutlass.Int32(thread_mask),
            val,
            _MATCH_SYNC_TO_DIALECT[kind],
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def redux_sync(
    val: Int32 | Float32,
    kind: ReductionKind,
    mask_and_clamp: int | Int32 | Uint32,
    *,
    abs: bool | None = None,
    nan: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Float32:
    """Reduce ``val`` across warp lanes selected by ``mask_and_clamp`` (sm_80+).

    Low-level NVVM dialect wrapper for ``redux.sync``.  All participating lanes
    receive the same result (implicit broadcast).  Prefer this over a 5-step
    butterfly shuffle loop for simple reductions.

    :param val: Each lane's input value.
    :type val: Int32 or Float32
    :param kind: Reduction operation (ADD, MIN, MAX, AND, OR, XOR, UMIN,
        UMAX, FMIN, FMAX).
    :type kind: ReductionKind
    :param mask_and_clamp: 32-bit member mask (``0xFFFFFFFF`` for all lanes).
    :type mask_and_clamp: int or Int32 or Uint32
    :param abs: Apply ``|val|`` before reducing; ``FMIN``/``FMAX`` only,
        sm_100+, defaults to None (disabled).
    :type abs: bool, optional
    :param nan: Propagate NaN to result; ``FMIN``/``FMAX`` only, sm_100+,
        defaults to None (NaN inputs are ignored).
    :type nan: bool, optional
    :return: Warp-reduced result broadcast to all participating lanes.
    :rtype: Float32 for FMIN/FMAX; Int32 for all other kinds.
    :raises ValueError: if a static *mask_and_clamp* does not fit in 32 bits, or
        if *abs* / *nan* is set for a non-FMIN/FMAX *kind*. A runtime
        (non-``int``) *mask_and_clamp* is not checked at trace time.

    .. code-block:: python

        # Per-block abs-max for MXFP8 quantization (sm_100+):
        amax = nvvm.redux_sync(gv, ReductionKind.FMAX, 0xFFFFFFFF, abs=True)
    """
    if kind in (ReductionKind.FMIN, ReductionKind.FMAX):
        return _cutlass.Float32(
            _nvvm.redux_sync(
                _cutlass.Float32(val),
                kind,
                _cutlass.Int32(mask_and_clamp),
                abs=abs,
                nan=nan,
                loc=loc,
                ip=ip,
            )
        )
    return _cutlass.Int32(
        _nvvm.redux_sync(
            _cutlass.Int32(val),
            kind,
            _cutlass.Int32(mask_and_clamp),
            abs=abs,
            nan=nan,
            loc=loc,
            ip=ip,
        )
    )


#: PTX scope token for each shared-memory window. ``SharedSpace`` is the NVVM
#: dialect enum whose ``.value`` is the integer ordinal (0/1), so interpolating
#: ``.value`` would emit the invalid ``.shared::0`` qualifier that ptxas
#: rejects with "Unknown modifier".  Map to the textual ``cta``/``cluster``
#: token the PTX ISA requires instead.
_SHARED_SPACE_PTX_TOKEN = {
    SharedSpace.shared_cta: "cta",
    SharedSpace.shared_cluster: "cluster",
}


def _shared_space_ptx(space: "SharedSpace") -> str:
    """Return the ``.shared::<scope>`` qualifier for an inline-PTX operand."""
    return f".shared::{_SHARED_SPACE_PTX_TOKEN[SharedSpace(space)]}"


@dsl_user_op
def atomicrmw(
    op: AtomicOp,
    ptr: Array | Pointer,
    a: int | float | Int32 | Uint32 | Int64 | Uint64 | Float32 | Float64,
    *,
    b: int | float | Int32 | Uint32 | Int64 | Uint64 | Float32 | Float64 | None = None,
    mem_order: MemOrder | None = None,
    syncscope: MemScope | None = None,
    space: SharedSpace | None = None,
    results: list | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Uint32 | Int64 | Uint64 | Float32 | Float64:
    """Atomic read-modify-write on a memory location.

    Emits ``atom.{op}.{mem_order}.{scope}``.  The
    op is performed atomically on ``*ptr``: the prior value is
    returned, and the new value (a function of the old value, ``a``,
    and optionally ``b``) is written back.  No data race is observable
    by other threads in ``syncscope``.

    :param op: One of :data:`AtomicOp`.  For ``"add"`` / ``"min"`` /
        ``"max"`` the wrapper picks the dialect-level FADD / UMIN / UMAX
        variant from the operand dtype: float operands pick FADD;
        unsigned-integer operands pick UMIN / UMAX; signed-integer
        operands pick the signed variant.
    :param ptr: Pointer/Array to the target memory cell.
    :param a: First operand — for ``"cas"`` this is the *expected* old
        value; for everything else the value combined with ``*ptr``.
    :param b: Second operand — only used for ``"cas"`` (the *new* value).
    :param mem_order: Memory ordering — ``"relaxed"`` / ``"acquire"`` /
        ``"release"`` / ``"acq_rel"``.
    :param syncscope: Scope across which ``mem_order`` is enforced —
        ``"cta"`` / ``"cluster"`` / ``"gpu"`` / ``"sys"``.
    :param results: Optional preallocated result list (advanced).
    :return: The old value at ``*ptr`` before the op was applied.
    :raises ValueError: if *op* is not a valid :data:`AtomicOp`, or if
        ``op="cas"`` is used without the second operand *b* (the new value).
    """
    if op == AtomicOp.CAS and b is None:
        raise ValueError(
            "atomicrmw: op='cas' requires the second operand b (the new value)"
        )
    if isinstance(a, int):
        a = _cutlass.Int32(a)
    elif isinstance(a, float):
        a = _cutlass.Float32(a)
    if isinstance(b, int):
        b = _cutlass.Int32(b)
    elif isinstance(b, float):
        b = _cutlass.Float32(b)
    if space is None:
        # Fast path: NVVM op (global memory; unchanged behaviour).
        return _nvvm.atomicrmw(
            _atomic_op_to_dialect(op, a),
            ptr,
            a,
            b=b,
            mem_order=_to_dialect(mem_order, _MEMORDER_TO_DIALECT),
            syncscope=_to_dialect(syncscope, _MEMSCOPE_TO_DIALECT),
            results=results,
            loc=loc,
            ip=ip,
        )
    # Non-global space has no NVVM op form — emit inline PTX.  The signedness
    # comes from the operand's type suffix, so ``op`` contributes only the bare
    # ``.min`` / ``.max`` / ... token.
    op_e = AtomicOp(op)
    is_cas = op_e == AtomicOp.CAS
    sem = f".{MemOrder(mem_order).value}" if mem_order is not None else ""
    scope = f".{MemScope(syncscope).value}" if syncscope is not None else ""
    space_str = _shared_space_ptx(space)
    type_suffix = f".{_atom_type_suffix(a)}"
    ptr_ir = ptr.llvm_ptr if hasattr(ptr, "llvm_ptr") else ptr
    if is_cas:
        ptx = (
            f"atom{sem}{scope}{space_str}.{op_e.value}{type_suffix}"
            " {$w0}, [{$r0}], {$r1}, {$r2};"
        )
        read_args = [ptr_ir, b, a]
    else:
        ptx = (
            f"atom{sem}{scope}{space_str}.{op_e.value}{type_suffix}"
            " {$w0}, [{$r0}], {$r1};"
        )
        read_args = [ptr_ir, a]
    return _hl_inline_ptx(
        ptx, write_only_types=[type(a)], read_only_args=read_args, loc=loc, ip=ip
    )


@dsl_user_op
def fence_proxy(
    kind: Proxy,
    *,
    space: SharedSpace | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Order writes across memory proxy domains.

    Emits ``fence.proxy.{kind}``.  The most common use case is
    ``fence_proxy("async_shared", space=SharedSpace.shared_cta)`` before a
    TMA store (``cp_async_bulk_tensor_global_shared_cta``), which
    makes thread SMEM writes visible to the TMA async-copy engine.

    Without this fence, the TMA store reads stale SMEM data because regular
    thread stores go through a different memory proxy domain than TMA
    async copies.

    :param kind: Proxy kind.  Use ``"async_shared"`` for TMA store
        fencing (SMEM to global via TMA).
    :type kind: Proxy
    :param space: Shared-memory space qualifier.  Only valid with the
        ``"async"`` / ``"async_shared"`` proxy kinds.  Use
        ``SharedSpace.shared_cta`` for CTA-local SMEM.
    :type space: SharedSpace | None
    :raises ValueError: ``space`` is supplied together with a proxy kind
        that does not accept a space qualifier (anything other than
        ``"async"`` / ``"async_shared"``).
    :raises TypeError: ``kind`` is a raw NVVM ``ProxyKind`` dialect enum; pass
        a :class:`Proxy` member or its string alias instead.

    .. code-block:: python

        # Thread writes to SMEM, then TMA stores SMEM -> global:
        nvvm.barrier_cta_sync()                       # all threads done writing SMEM
        nvvm.fence_proxy(
            "async_shared",
            space=nvvm.SharedSpace.shared_cta,
        )
        if nvvm.elect_sync():
            nvvm.cp_async_bulk_tensor_global_shared_cta(
                tma_descriptor=tma_desc,
                src_mem=smem,
                coordinates=dst_coords,
            )
            nvvm.cp_async_bulk_commit_group()
            nvvm.cp_async_bulk_wait_group(0)
    """
    # Reject raw NVVM dialect enums unconditionally
    if isinstance(kind, _ProxyKindDialect):
        raise TypeError(
            "fence.proxy: raw NVVM ProxyKind values are not accepted; pass a "
            "nvvm.Proxy member or a string alias instead"
        )
    if space is not None and kind not in _PROXY_KINDS_WITH_SPACE:
        raise ValueError(
            f"fence.proxy: space qualifier is only valid with the async "
            f'("async" / "async_shared") proxy kinds, got kind={kind!r}'
        )
    _nvvm_raw.fence_proxy(_PROXY_TO_DIALECT[kind], space=space, loc=loc, ip=ip)


@dsl_user_op
def red(
    op: ReductionOp,
    type_: ReductionType,
    a: Array | Pointer,
    b: Int32 | Int64 | Float64 | BFloat16 | Float16 | Float32 | Vector,
    *,
    mem_order: MemOrder | None = None,
    mem_scope: MemScope | None = None,
    shared_space: SharedSpace | None = None,
    cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Apply a non-returning atomic reduction to a global or shared memory cell.

    Emits the PTX ``red`` instruction family.  The value in memory at ``a`` is
    combined with operand ``b`` using ``op`` and the result is written back to
    ``a``.  Unlike :func:`atomicrmw`, this operation does not return the old
    memory value.

    Scalar reductions may target global or shared memory.  Vector reductions
    are global-memory only; the hardware guarantees atomicity independently for
    each scalar element, not for the whole vector as one transaction.  When
    ``mem_order`` is omitted PTX assumes ``.relaxed``; when ``mem_scope`` is
    omitted PTX assumes ``.gpu``.

    .. note::

        ``shared_space`` selects the explicit shared-memory PTX spelling. When
        omitted for a ``mapa``-produced shared-cluster pointer (addrspace 7),
        the wrapper selects ``SharedSpace.shared_cluster`` automatically.

    :param op: Reduction operation: ``AND``, ``OR``, ``XOR``, ``ADD``,
        ``INC``, ``DEC``, ``MIN``, or ``MAX``.
    :type op: ReductionOp
    :param type_: PTX reduction type such as ``S32``, ``U32``, ``F32``,
        ``F64``, ``F16``, ``F16X2``, ``BF16``, or ``BF16X2``.
    :type type_: ReductionType
    :param a: Pointer or Array naming the destination memory cell.
    :type a: Array or Pointer
    :param b: Value contributed to the reduction.  For vector reductions, pass
        a vector matching the PTX vector/type combination.
    :type b: Int32, Int64, Float16, BFloat16, Float32, Float64, or Vector
    :param mem_order: Optional memory ordering qualifier.  ``RELAXED`` and
        ``RELEASE`` are the PTX ``red`` semantics.
    :type mem_order: MemOrder, optional
    :param mem_scope: Optional memory scope: ``CTA``, ``CLUSTER``, ``GPU``,
        or ``SYS``.
    :type mem_scope: MemScope, optional
    :param cache_hint: Optional 64-bit L2 cache policy.  PTX permits this only
        for global memory reductions with ``.L2::cache_hint``.
    :type cache_hint: int or Int64 or Uint64, optional
    :raises ValueError: if *op* is not a valid :class:`ReductionOp` or *type_*
        is not a valid :class:`ReductionType`.

    .. code-block:: python

        # Every valid thread contributes one Int32 to a global sum.
        ptr = sum_out.iterator.raw_ptr()
        nvvm.red(
            "add",
            "s32",
            ptr,
            contribution,
            mem_order="relaxed",
            mem_scope="gpu",
        )
    """
    _assert_reduction_op(op, "red")
    _assert_reduction_type(type_, "red")
    if cache_hint is not None:
        cache_hint = _cutlass.Int64(cache_hint)
    if shared_space is None and _is_cluster_ptr(a):
        shared_space = SharedSpace.shared_cluster
    if shared_space is None:
        # Fast path: NVVM op for global and CTA-shared pointer forms.
        _nvvm.red(
            _REDUCTION_OP_TO_DIALECT[op],
            _REDUCTION_TYPE_TO_DIALECT[type_],
            a,
            b,
            mem_order=_to_dialect(mem_order, _MEMORDER_TO_DIALECT),
            mem_scope=_to_dialect(mem_scope, _MEMSCOPE_TO_DIALECT),
            cache_hint=cache_hint,
            loc=loc,
            ip=ip,
        )
        return
    # Explicit-shared-space form has no NVVM op — emit inline PTX.
    type_e = ReductionType(type_)
    sem = f".{MemOrder(mem_order).value}" if mem_order is not None else ""
    scope = f".{MemScope(mem_scope).value}" if mem_scope is not None else ""
    space = _shared_space_ptx(shared_space) if shared_space is not None else ".global"
    noftz = ".noftz" if type_e in _RED_NOFTZ_TYPES else ""
    a_ir = a.llvm_ptr if hasattr(a, "llvm_ptr") else _to_ir(a, loc, ip)
    b = _coerce_setp_val(type_e.value, b)
    # LLVM inline asm constraints accept integer carriers for 16-bit floats.
    if type_e in (ReductionType.F16, ReductionType.BF16) and hasattr(b, "bitcast"):
        b = b.bitcast(_cutlass.Int16, loc=loc, ip=ip)
    elif type_e in (ReductionType.F16X2, ReductionType.BF16X2) and hasattr(
        b, "bitcast"
    ):
        b = b.bitcast(_cutlass.Int32, loc=loc, ip=ip)
    ptx = (
        f"red{sem}{scope}{space}.{ReductionOp(op).value}{noftz}.{type_e.value}"
        f" [{{$r0}}], {{$r1}};"
    )
    if cache_hint is not None:
        ptx = ptx.rstrip(";") + ", {$r2};"
        _hl_inline_ptx(ptx, read_only_args=[a_ir, b, cache_hint], loc=loc, ip=ip)
    else:
        _hl_inline_ptx(ptx, read_only_args=[a_ir, b], loc=loc, ip=ip)


# =============================================================================
# tcgen05 SMEM -> TMEM copy, typed TMEM pointer constructors, and a PTX comment
# helper (relocated from the former gpu_ops.py; flattened into ``prims.*``).
# =============================================================================


class S2TCopyMode:
    """S2T (SMEM->TMEM) copy mode enumeration for ``prims.tcgen05_cp``.

    Combines shape and multicast into valid configurations for SMEM-to-TMEM copy.
    Each mode specifies both the data shape and the required warp broadcast pattern.

    Available modes:
    - S2T_128x256b: 128 rows x 256 bits, no multicast
    - S2T_128x128b: 128 rows x 128 bits, no multicast
    - S2T_4x256b: 4 rows x 256 bits, no multicast
    - S2T_32x128b_WARPX4: 32 rows x 128 bits, broadcast to all 4 warps
    - S2T_64x128b_WARPX2_01_23: 64 rows x 128 bits, broadcast to warp pairs (0,1)(2,3)
    - S2T_64x128b_WARPX2_02_13: 64 rows x 128 bits, broadcast to warp pairs (0,2)(1,3)
    """

    # (shape, multicast) tuples for each valid mode.
    S2T_128x256b = (Tcgen05CpShape.SHAPE_128X256B, None)
    S2T_128x128b = (Tcgen05CpShape.SHAPE_128X128B, None)
    S2T_4x256b = (Tcgen05CpShape.SHAPE_4X256B, None)
    S2T_32x128b_WARPX4 = (
        Tcgen05CpShape.SHAPE_32X128B,
        Tcgen05CpMulticast.WARPX4,
    )
    S2T_64x128b_WARPX2_01_23 = (
        Tcgen05CpShape.SHAPE_64X128B,
        Tcgen05CpMulticast.WARPX2_01_23,
    )
    S2T_64x128b_WARPX2_02_13 = (
        Tcgen05CpShape.SHAPE_64X128B,
        Tcgen05CpMulticast.WARPX2_02_13,
    )


@dsl_user_op
def make_tmem_ptr(
    tmem_addr: "int | Int32",
    dtype: type[Numeric],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Convert a TMEM address to a typed TMEM ``Array`` view (address space 6).

    :param tmem_addr: The TMEM address value (``int`` or a DSL integer).
    :param dtype: The element type for the returned view.
    :return: An ``Array`` over TMEM (address space 6).
    """
    if hasattr(tmem_addr, "ir_value"):
        tmem_addr = tmem_addr.ir_value()
    space = _AddressSpace.tmem.value
    int_to_ptr = _llvm.inttoptr(_llvm.PointerType.get(space), tmem_addr, loc=loc, ip=ip)
    return Array(int_to_ptr, dtype=dtype, addrspace=space)


@dsl_user_op
def make_tmem_ptr_from_warp_row_col(
    tmem_base: "int | Int32",
    warp: "int | Int32",
    base_col: "int | Int32",
    dtype: type[Numeric],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Build a typed TMEM ``Array`` view for TMEM/SP ``warp`` at row ``warp*32``.

    Each warp in a tcgen05 MMA group owns one sub-partition of the TMEM
    accumulator. The canonical epilogue formula

    .. code-block:: python

        tmem_sp = warp_idx % 4
        tmem_addr = (tmem_base_row + tmem_sp * 32) << 16 | base_col

    is bundled here so callers don't reassemble the bitfield by hand. For shifted
    epilogue ranges such as warps 2..5, pass ``warp_idx % 4`` rather than the
    logical epilogue rank.

    :param tmem_base: TMEM address of the accumulator base (row 0, col 0);
        bits [0:16) hold the starting column, [16:32) hold the starting row.
    :param warp: TMEM/SP index (0..3), usually ``warp_idx % 4``.
    :param base_col: Column offset within the accumulator.
    :param dtype: Element type of the returned TMEM view.
    :return: An ``Array`` over TMEM at ``(base_row + warp*32, base_col)``.
    """
    base_row = Int32(tmem_base) >> 16
    row = base_row + Int32(warp) * Int32(32)
    tmem_addr = (row << 16) | (Int32(base_col) & Int32(0xFFFF))
    return make_tmem_ptr(tmem_addr, dtype, loc=loc, ip=ip)


@dsl_user_op
def cluster_ctarank(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """Read ``%cluster_ctarank`` — this CTA's linear rank within its cluster.

    .. code-block:: python

        rank = prims.cluster_ctarank()
    """
    return _cutlass.Int32(
        _nvvm.read_ptx_sreg_cluster_ctarank(_cutlass.Int32.mlir_type, loc=loc, ip=ip)
    )


@dsl_user_op
def fence_acq_rel(
    scope: MemScope,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """``fence.acq_rel.{scope}`` — acquire-release memory fence (PTX §9.7.13.4).

    There is no NVVM dialect op for the generic acquire-release fence, so this
    emits inline PTX.

    :param scope: memory scope — ``MemScope.{CTA,CLUSTER,GPU,SYS}``.

    .. code-block:: python

        prims.fence_acq_rel(prims.MemScope.CTA)
    """
    scope = MemScope(scope)
    _hl_inline_ptx(
        f"fence.acq_rel.{scope.value};",
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_proxy_async_acquire_sync_restrict(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """``fence.proxy.async::generic.acquire.sync_restrict::shared::cluster.cluster``.

    Lowers to the ``nvvm.fence.proxy.sync_restrict`` op with ``acquire`` order;
    per its definition, ``acquire`` restricts the ordering to ``shared::cluster``
    between the generic and async proxies.
    """
    _nvvm.fence_proxy_sync_restrict(
        _MEMORDER_TO_DIALECT[MemOrder.ACQUIRE],
        from_proxy=_PROXY_TO_DIALECT[Proxy.GENERIC],
        to_proxy=_PROXY_TO_DIALECT[Proxy.ASYNC],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def fence_proxy_async_release_sync_restrict(
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """``fence.proxy.async::generic.release.sync_restrict::shared::cta.cluster``.

    Lowers to the ``nvvm.fence.proxy.sync_restrict`` op with ``release`` order;
    per its definition, ``release`` restricts the ordering to ``shared::cta``
    with cluster scope between the generic and async proxies.
    """
    _nvvm.fence_proxy_sync_restrict(
        _MEMORDER_TO_DIALECT[MemOrder.RELEASE],
        from_proxy=_PROXY_TO_DIALECT[Proxy.GENERIC],
        to_proxy=_PROXY_TO_DIALECT[Proxy.ASYNC],
        loc=loc,
        ip=ip,
    )


class CpReduceOp(StrEnum):
    """Reduction op for ``cp.reduce.async.bulk`` (non-TMA, PTX §9.7.9.25.4.2)."""

    ADD = "add"
    MIN = "min"
    MAX = "max"
    INC = "inc"
    DEC = "dec"
    AND = "and"
    OR = "or"
    XOR = "xor"


class CpReduceType(StrEnum):
    """Element type for ``cp.reduce.async.bulk`` (non-TMA, PTX §9.7.9.25.4.2)."""

    F16 = "f16"
    BF16 = "bf16"
    B32 = "b32"
    B64 = "b64"
    U32 = "u32"
    U64 = "u64"
    S32 = "s32"
    S64 = "s64"
    F32 = "f32"
    F64 = "f64"


#: ``.noftz`` is only valid with ``.add`` on ``.f16`` / ``.bf16``.
_CP_REDUCE_NOFTZ_TYPES = frozenset({CpReduceType.F16, CpReduceType.BF16})


@dsl_user_op
def cp_reduce_async_bulk_global_shared_cta(
    dst: Array | Pointer,
    src: Array | Pointer,
    size: int | Int32 | Uint32,
    *,
    op: CpReduceOp = CpReduceOp.ADD,
    type: CpReduceType = CpReduceType.BF16,
    noftz: bool = False,
    l2_cache_hint: int | Int64 | Uint64 | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """``cp.reduce.async.bulk.global.shared::cta`` — non-TMA bulk reduction.

    Asynchronously reduces *size* bytes from *src* (shared::cta) into *dst*
    (global) using *op* / *type*.  Unlike
    :func:`cp_async_bulk_tensor_reduce`, this operates on raw pointers and a
    byte count (irregular / scatter access, e.g. MoE finalize scatter-reduce).
    Uses ``bulk_group`` completion — bracket with
    :func:`cp_async_bulk_commit_group` / :func:`cp_async_bulk_wait_group`.

    There is no NVVM dialect op for this instruction, so it emits inline PTX.

    :param size: byte count, must be a multiple of 16.
    :param noftz: disable flush-to-zero; only valid with ``op=ADD`` and
        ``type`` in ``{F16, BF16}``.
    :param l2_cache_hint: optional 64-bit L2 eviction policy.
    """
    op = CpReduceOp(op)
    type = CpReduceType(type)
    _assert_shared(src, "cp.reduce.async.bulk")
    _assert_bulk_size(size, "cp.reduce.async.bulk")
    if noftz:
        if op is not CpReduceOp.ADD:
            raise ValueError(
                f"cp.reduce.async.bulk: .noftz is only valid with .add, got .{op.value}"
            )
        if type not in _CP_REDUCE_NOFTZ_TYPES:
            raise ValueError(
                "cp.reduce.async.bulk: .noftz is only valid for .f16/.bf16, "
                f"got .{type.value}"
            )
    noftz_q = ".noftz" if noftz else ""
    hint_qual = ".L2::cache_hint" if l2_cache_hint is not None else ""
    dst_addr = dst.data_ptr() if hasattr(dst, "data_ptr") else dst
    src_addr = src.data_ptr() if hasattr(src, "data_ptr") else src
    args = [dst_addr, src_addr, _cutlass.Int32(size)]
    if l2_cache_hint is not None:
        args.append(_cutlass.Int64(l2_cache_hint))
        hint_ref = ", {$r3}"
    else:
        hint_ref = ""
    _hl_inline_ptx(
        f"cp.reduce.async.bulk.global.shared::cta.bulk_group{hint_qual}"
        f".{op.value}{noftz_q}.{type.value}"
        f" [{{$r0}}], [{{$r1}}], {{$r2}}{hint_ref};",
        read_only_args=args,
        loc=loc,
        ip=ip,
    )


class CmpOp(StrEnum):
    """PTX comparison operator for ``setp`` (PTX ISA §9.7.6)."""

    EQ = "eq"
    NE = "ne"
    LT = "lt"
    LE = "le"
    GT = "gt"
    GE = "ge"
    LO = "lo"
    LS = "ls"
    HI = "hi"
    HS = "hs"
    EQU = "equ"
    NEU = "neu"
    LTU = "ltu"
    LEU = "leu"
    GTU = "gtu"
    GEU = "geu"
    NUM = "num"
    NAN = "nan"


class SetpType(StrEnum):
    """Source type suffix for ``setp`` / ``selp`` (PTX ISA §9.7.6)."""

    B16 = "b16"
    B32 = "b32"
    B64 = "b64"
    U16 = "u16"
    U32 = "u32"
    U64 = "u64"
    S16 = "s16"
    S32 = "s32"
    S64 = "s64"
    F16 = "f16"
    F32 = "f32"
    F64 = "f64"
    BF16 = "bf16"


class CvtaSpace(StrEnum):
    """Target address space for ``cvta`` (PTX ISA §9.7.9.20)."""

    GLOBAL = "global"
    SHARED = "shared"
    SHARED_CTA = "shared::cta"
    SHARED_CLUSTER = "shared::cluster"
    LOCAL = "local"
    CONST = "const"
    PARAM = "param"
    PARAM_ENTRY = "param::entry"


class CvtaSize(StrEnum):
    """Address-width qualifier for ``cvta``: ``.u32`` or ``.u64``."""

    U32 = "u32"
    U64 = "u64"


_PTX_TYPE_TO_DSL = {
    "b16": Int16,
    "b32": Int32,
    "b64": Int64,
    "u16": Uint16,
    "u32": Uint32,
    "u64": Uint64,
    "s16": Int16,
    "s32": Int32,
    "s64": Int64,
    "f16": Float16,
    "f32": Float32,
    "f64": Float64,
    "bf16": BFloat16,
}

_MOV_B32_MLIR_TYPE = {
    Int32: lambda: ir.IntegerType.get_signless(32),
    Uint32: lambda: ir.IntegerType.get_signless(32),
    Float32: lambda: ir.F32Type.get(),
}

#: PTX address-space numbers for ``cvta`` target spaces.
_CVTA_SPACE_TO_AS = {
    CvtaSpace.GLOBAL: 1,
    CvtaSpace.SHARED: 3,
    CvtaSpace.SHARED_CTA: 3,
    CvtaSpace.SHARED_CLUSTER: 7,
    CvtaSpace.LOCAL: 5,
    CvtaSpace.CONST: 4,
}
#: ``.param`` spaces have no addrspacecast and must use inline PTX.
_CVTA_INLINE_PTX_SPACES = frozenset({CvtaSpace.PARAM, CvtaSpace.PARAM_ENTRY})


def _coerce_setp_val(type_str: str, val: object) -> object:
    """Coerce a Python ``int``/``float`` to the DSL type implied by *type_str*;
    pass IR values through unchanged."""
    dsl_type = _PTX_TYPE_TO_DSL.get(type_str)
    if dsl_type is None or not isinstance(val, (int, float)):
        return val
    return dsl_type(val)


#: DSL operand type → PTX type suffix for inline ``atom`` (signedness-bearing).
_ATOM_TYPE_SUFFIX = (
    (Uint32, "u32"),
    (Int32, "s32"),
    (Uint64, "u64"),
    (Int64, "s64"),
    (Float32, "f32"),
    (Float64, "f64"),
)


def _atom_type_suffix(val: object) -> str:
    """Return the PTX ``atom`` type suffix for a DSL operand value."""
    for dsl_type, suffix in _ATOM_TYPE_SUFFIX:
        if isinstance(val, dsl_type):
            return suffix
    raise TypeError(f"atomicrmw: cannot infer PTX type suffix for {type(val)}")


@dsl_user_op
def mov_b32(
    a: int | float | Int32 | Uint32 | Float32,
    *,
    target_type: type = Int32,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32 | Uint32 | Float32:
    """``mov.b32`` — reinterpret a 32-bit value's bits as *target_type*.

    Emits an ``arith.bitcast`` (no value conversion), e.g. float bits → int
    for NaN-safe integer compares.
    """
    if isinstance(a, int):
        a = _cutlass.Int32(a)
    elif isinstance(a, float):
        a = _cutlass.Float32(a)
    mlir_target = _MOV_B32_MLIR_TYPE.get(target_type)
    if mlir_target is None:
        raise ValueError(f"mov_b32: unsupported target_type {target_type}")
    return target_type(_arith.bitcast(mlir_target(), a.ir_value(), loc=loc, ip=ip))


@dsl_user_op
def cvta_to(
    addr: Array | Pointer | Int32 | Int64 | Uint32 | Uint64,
    space: CvtaSpace,
    *,
    size: CvtaSize = CvtaSize.U64,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array | Pointer | Int32 | Int64 | Uint32 | Uint64:
    """``cvta.to.{space}`` — convert a generic address to a space-specific one.

    For ``Array`` / ``Pointer`` inputs this is an ``llvm.addrspacecast`` to the
    target space (same wrapper type returned); integer inputs round-trip through
    ``inttoptr`` / ``addrspacecast`` / ``ptrtoint``.  ``.param`` spaces have no
    addrspacecast and use inline PTX.
    """
    space = CvtaSpace(space)
    size = CvtaSize(size)
    if space in _CVTA_INLINE_PTX_SPACES:
        int_type = Int32 if size == CvtaSize.U32 else Int64
        return _hl_inline_ptx(
            f"cvta.to.{space.value}.{size.value} {{$w0}}, {{$r0}};",
            write_only_types=[int_type],
            read_only_args=[addr],
            loc=loc,
            ip=ip,
        )
    target_as = _CVTA_SPACE_TO_AS[space]
    if isinstance(addr, Array):
        dst_ptr = _llvm.addrspacecast(
            _llvm.PointerType.get(target_as), addr.ir_value(), loc=loc, ip=ip
        )
        return Array(dst_ptr, dtype=addr.dtype, addrspace=target_as)
    if isinstance(addr, Pointer):
        dst_ptr = _llvm.addrspacecast(
            _llvm.PointerType.get(target_as), addr.ir_value(), loc=loc, ip=ip
        )
        return Pointer._from_raw_ptr(dst_ptr, addr.dtype)
    int_type = (
        ir.IntegerType.get_signless(32)
        if size == CvtaSize.U32
        else ir.IntegerType.get_signless(64)
    )
    addr_ir = addr.ir_value() if hasattr(addr, "ir_value") else addr
    src_ptr = _llvm.inttoptr(_llvm.PointerType.get(0), addr_ir, loc=loc, ip=ip)
    dst_ptr = _llvm.addrspacecast(
        _llvm.PointerType.get(target_as), src_ptr, loc=loc, ip=ip
    )
    return _llvm.ptrtoint(int_type, dst_ptr, loc=loc, ip=ip)



@dsl_user_op
def mul_bf16x2(
    a: Int32,
    b: Int32,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """
    ``mul.bf16x2`` — packed bf16x2 multiply (two bf16 lanes packed in i32).
    """
    return _hl_inline_ptx(
        "mul.bf16x2 {$w0}, {$r0}, {$r1};",
        write_only_types=[Int32],
        read_only_args=[a, b],
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_f32x2_to_f8x2(
    a: float | Float32,
    b: float | Float32,
    dst_ty: object,
    *,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    sat: SaturationMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int16:
    """``cvt.{rnd}.{f8x2}.f32`` — convert an ``f32`` pair to packed ``f8x2``.

    Returns the two f8 lanes packed into an :class:`Int16`.
    """
    return _convert_f32x2_to_f8x2(
        a,
        b,
        dst_ty,
        is_pzo=is_pzo,
        scale_factor=scale_factor,
        scale_factor_kind=scale_factor_kind,
        rnd=rnd,
        sat=sat,
        relu=relu,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_f32x2_to_f4x2(
    a: float | Float32,
    b: float | Float32,
    dst_type: object,
    *,
    is_pzo: bool | None = None,
    scale_factor: int | Int16 | Uint16 | None = None,
    scale_factor_kind: ConvertScale | None = None,
    rnd: FPRoundingMode | None = None,
    relu: bool | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int32:
    """``cvt.{rnd}.{f4x2}.f32`` — convert an ``f32`` pair to packed ``f4x2``.

    Returns the packed byte in the low 8 bits of an :class:`Int32` (callers typically ``& 0xFF`` and
    shift it into a 32-bit word).
    """
    return _cutlass.Int32(
        _convert_f32x2_to_f4x2(
            a,
            b,
            dst_type,
            is_pzo=is_pzo,
            scale_factor=scale_factor,
            scale_factor_kind=scale_factor_kind,
            rnd=rnd,
            relu=relu,
            loc=loc,
            ip=ip,
        )
    )


#: Public high-level inline-PTX builder (``{$r0}`` / ``{$w0}`` named refs, DSL
#: ``write_only_types``, built-in ``@p`` predication via ``pred=``).  Distinct
#: from :data:`inline_ptx`, which is the *raw* ``nvvm.inline_ptx`` op
#: (``write_only_args`` / positional ``ptx_code``).
inline_ptx_hl = _hl_inline_ptx


__all__ = [
    "add_packed_f32x2",
    "atomicrmw",
    "auto",
    "bar_warp_sync",
    "barrier_cluster_arrive",
    "barrier_cluster_arrive_aligned",
    "barrier_cluster_arrive_relaxed",
    "barrier_cluster_arrive_relaxed_aligned",
    "barrier_cluster_wait",
    "barrier_cluster_wait_aligned",
    "barrier_cta_arrive",
    "barrier_cta_arrive_aligned",
    "barrier_cta_red",
    "barrier_cta_red_aligned",
    "barrier_cta_sync",
    "barrier_cta_sync_aligned",
    "breakpoint",
    "cluster_ctarank",
    "clusterlaunchcontrol_query_cancel",
    "clusterlaunchcontrol_try_cancel",
    "convert",
    "convert_and_pack_integer",
    "convert_bf16x2_to_s2f6x2",
    "convert_f32x2_to_s2f6x2",
    "convert_f8x2_to_bf16x2",
    "convert_float_to_integer",
    "convert_float_to_tf32",
    "convert_s2f6x2_to_bf16x2",
    "cp_async_bulk_commit_group",
    "cp_async_bulk_global_shared_cta",
    "cp_async_bulk_prefetch",
    "cp_async_bulk_shared_cluster_global",
    "cp_async_bulk_shared_cluster_shared_cta",
    "cp_async_bulk_tensor_global_shared_cta",
    "cp_async_bulk_tensor_prefetch",
    "cp_async_bulk_tensor_reduce",
    "cp_async_bulk_tensor_shared_cluster_global",
    "cp_async_bulk_tensor_shared_cta_global",
    "cp_async_bulk_wait_group",
    "cp_async_commit_group",
    "cp_async_mbarrier_arrive",
    "cp_async_shared_global",
    "cp_async_wait_group",
    "cp_reduce_async_bulk_global_shared_cta",
    "cvta_to",
    "cvt_f32x2_to_f4x2",
    "cvt_f32x2_to_f8x2",
    "cvt_packfloat",
    "cvt_packfloat_f32",
    "dot_accumulate_2way",
    "dot_accumulate_4way",
    "elect_sync",
    "exit",
    "fabs",
    "fence_acq_rel",
    "fence_mbarrier_init",
    "fence_proxy",
    "fence_proxy_acquire",
    "fence_proxy_async_acquire_sync_restrict",
    "fence_proxy_async_release_sync_restrict",
    "fence_proxy_release",
    "fence_proxy_sync_restrict",
    "fence_sc_cluster",
    "fence_sync_restrict",
    "fma_packed_f32x2",
    "fmin",
    "griddepcontrol",
    "inline_ptx",
    "inline_ptx_hl",
    "ldmatrix",
    "load_ext",
    "mapa",
    "match_sync",
    "mbarrier_arrive",
    "mbarrier_arrive_drop",
    "mbarrier_arrive_drop_expect_tx",
    "mbarrier_arrive_drop_nocomplete",
    "mbarrier_arrive_expect_tx",
    "mbarrier_arrive_nocomplete",
    "mbarrier_complete_tx",
    "mbarrier_expect_tx",
    "mbarrier_init",
    "mbarrier_inval",
    "mbarrier_test_wait",
    "mbarrier_try_wait",
    "mbarrier_try_wait_parity",
    "mbarrier_try_wait_timelimit",
    "mbarrier_wait",
    "mbarrier_wait_parity",
    "memory_barrier",
    "mma_block_scale",
    "mma_smem_desc",
    "mma_sp_block_scale",
    "mma_sp_sync",
    "mma_sync",
    "mov_b32",
    "mul",
    "mul_bf16x2",
    "mul_packed_f32x2",
    "nanosleep",
    "pmevent",
    "prefetch_l1",
    "prefetch_l2",
    "prefetch_tensormap",
    "prefetchu",
    "prmt",
    "read_sreg_hw",
    "red",
    "redux_sync",
    "setmaxregister",
    "shfl_sync",
    "st_bulk",
    "stmatrix",
    "store_ext",
    "sub_packed_f32x2",
    "tcgen05_alloc",
    "tcgen05_commit",
    "tcgen05_cp",
    "tcgen05_dealloc",
    "tcgen05_fence",
    "tcgen05_ld",
    "tcgen05_mma",
    "tcgen05_mma_block_scale",
    "tcgen05_mma_sp",
    "tcgen05_mma_sp_block_scale",
    "tcgen05_mma_ws",
    "tcgen05_mma_ws_sp",
    "tcgen05_relinquish_alloc_permit",
    "tcgen05_shift",
    "tcgen05_st",
    "tcgen05_wait",
    "tensormap_cp_fenceproxy",
    "tensormap_replace",
    "trace_mark",
    "vote_sync",
    "wgmma_commit_group_sync_aligned",
    "wgmma_fence_aligned",
    "wgmma_mma_async",
    "wgmma_wait_group_sync_aligned",
    "wmma_load",
    "wmma_mma",
    "wmma_store",
]
_OP_EXPORTS = list(__all__)

__all__ += [
    "BarrierReduction",
    "BlockScaleFormat",
    "ConvertFP4Type",
    "LdStMatrixEltType",
    "MMABlockScaleKind",
    "MMACtaCount",
    "NVVMMemorySpace",
    "ReductionKind",
    "ScaleVecSize",
    "SharedSpace",
    "SparsityFormat",
    "StateSpace",
    "TCBarParam",
    "Tcgen05LdStShape",
    "Tcgen05MMABlockScale",
    "Tcgen05MMAScaleVecSize",
    "TensormapElemtype",
    "TensormapField",
    "TensormapFillMode",
    "TensormapInterleaveLayout",
    "TensormapSwizzleAtomicity",
    "TensormapSwizzleMode",
    "TmemLayout",
]
_ENUM_EXPORTS = __all__[len(_OP_EXPORTS) :]

# Wrapper-owned ``StrEnum`` types — members ARE strings, so callers may
# pass either the enum member (``MemScope.CTA``) or the bare string
# (``"cta"``) interchangeably.
__all__ += [
    "AtomicOp",
    "BarrierRedux",
    "CTAGroup",
    "CVTPackFloat",
    "CacheLevel",
    "ClusterLaunchControlQueryType",
    "CmpOp",
    "ConvertScale",
    "CpReduceOp",
    "CpReduceType",
    "CvtaSize",
    "CvtaSpace",
    "DotAccumulateType",
    "EvictPriority",
    "FPRoundingMode",
    "GridDepAction",
    "IntRoundingMode",
    "L1EvictKind",
    "L2PrefetchSize",
    "LoadCacheModifier",
    "LoadShape",
    "LoadSrcFormat",
    "MBarrierScope",
    "MBarrierWait",
    "MMAB1Op",
    "MMAFrag",
    "MMAIntOverflow",
    "MMAKind",
    "MMALayout",
    "MMAType",
    "MatchSync",
    "MemOrder",
    "MemScope",
    "MulMode",
    "PermuteMode",
    "Proxy",
    "ReductionOp",
    "ReductionType",
    "SaturationMode",
    "SaturationModeKind",
    "SetMaxRegisterAction",
    "SetpType",
    "Shfl",
    "StoreCacheModifier",
    "StoreShape",
    "TMALoadMode",
    "TMARedux",
    "TMAStoreMode",
    "Tcgen05CpMulticast",
    "Tcgen05CpShape",
    "Tcgen05CpSrcFormat",
    "Tcgen05Fence",
    "Tcgen05MMACollectorBBuffer",
    "Tcgen05MMACollectorOp",
    "Tcgen05MMAKind",
    "Tcgen05Wait",
    "TensormapSpace",
    "VoteSync",
    "WGMMAScaleIn",
    "WGMMAScaleOut",
    "WGMMAType",
]
_STR_ENUM_EXPORTS = __all__[len(_OP_EXPORTS) + len(_ENUM_EXPORTS) :]

__all__ += ["dialect"]
__all__ += ["barrier"]  # re-exported from cutlass.cute.arch

# tcgen05 SMEM->TMEM copy mode enum + warp/row/col TMEM pointer ctor (ex-gpu_ops).
__all__ += [
    "S2TCopyMode",
    "make_tmem_ptr",
    "make_tmem_ptr_from_warp_row_col",
]
