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

"""The ``Array`` type, its internal ``_ArrayImpl`` implementation, and the
low-level memory/MLIR helpers they share with the ``Pointer``.

This module also hosts the memory-attribute StrEnums, the
scalar/gep/print/global MLIR helpers, the alignment/address-space helpers, the
pointer/array factory hooks, and the global ``llvm.load``/``llvm.store``
subword-float legalization monkey-patch (which fires at import time). All of
these are shared by ``_ArrayImpl`` here and by ``_PointerImpl`` in ``DSL``;
keeping them in this one ``base_dsl`` module (below ``cutlass.cute``) lets both
import them without a cycle. It MUST NOT import ``cutlass.cute`` at load time.

``from __future__ import annotations`` makes the ``cute.Tensor`` / ``cute.Pointer``
annotations lazy strings, so this module does NOT need ``cutlass.cute`` at load
time. The handful of runtime sites that actually touch cute (tensor/pointer
init + verification) do a function-local ``import cutlass.cute as cute``.
"""

from __future__ import annotations

# Python import
import sys
from dataclasses import dataclass, field
from types import EllipsisType
from typing import (
    Generic,
    NoReturn,
    Tuple,
    Union,
    Type,
    Optional,
    TypeVar,
    Any,
    Callable,
    TYPE_CHECKING,
    TypeAlias,
    cast,
)
from enum import IntEnum

# ``enum.StrEnum`` landed in Python 3.11.  ``backports.strenum`` is a drop-in for
# 3.10; the conditional keeps DSL compatible with the ``>=3.10`` floor.
if TYPE_CHECKING:
    # ``backports.strenum`` (the 3.10 runtime import below) ships no type
    # information, so to a type checker its ``StrEnum`` is ``Any``, which would
    # erase the enum semantics of every subclass defined here. Give the checker
    # a real ``str``-based enum base instead.
    from enum import Enum

    class StrEnum(str, Enum): ...
elif sys.version_info >= (3, 11):
    from enum import StrEnum
else:
    from backports.strenum import StrEnum

# MLIR imports (low-level bindings — safe below cute)
from .._mlir import ir
from .._mlir.dialects import llvm, arith, gpu, vector
from .._mlir_helpers import dsl_user_op
from .._mlir_helpers.lru_cache_ir import lru_cache_ir
from .._mlir_helpers import arith as arith_helper
from .._mlir_helpers.vector import Vector
from .common import DSLUserCodeError
from .typing import (
    Numeric,
    NumericMeta,
    Int32,
    Int64,
    Boolean,
    Float32,
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E4M3,
    Float8E4M3FN,
    Float8E4M3B11FNUZ,
    Float8E5M2,
    Float8E8M0FNU,
    # Shared pointer/memory infrastructure — canonical definitions live in
    # base_dsl/typing.py (master relocated them alongside ``Pointer``). Import
    # them so ``cutlass.Pointer`` and ``cutlass.Array`` share one path.
    AddressSpace,
    _normalize_address_space,
    _gep,
    MLIR_DYNAMIC_INDEX,
)
from .utils.logger import log

if TYPE_CHECKING:
    # Annotation-only imports. These names are deliberately imported
    # function-locally at runtime (this module sits below ``cutlass.cute`` and
    # must not import it at load time), so the checker needs them here to
    # resolve the string annotations that reference them.
    import cutlass.cute as cute
    from .typing import Pointer


# =============================================================================
# Memory-attribute StrEnums (PTX-documented). Defined here (not imported from
# base_dsl/typing, where they are ``Literal`` type-aliases) because _ArrayImpl
# uses the enum members, e.g. ``MemOrdering.NOT_ATOMIC``.
# =============================================================================


class MemOrdering(StrEnum):
    """Memory ordering for atomic operations.

    Controls how memory operations are ordered with respect to other operations.
    Maps to LLVM AtomicOrdering.

    Reference: PTX ISA - Memory Consistency Model
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#memory-consistency-model
    """

    NOT_ATOMIC = "not_atomic"  # Regular (non-atomic) memory access
    MONOTONIC = "monotonic"  # Atomic but no ordering guarantees (.relaxed in PTX)
    ACQUIRE = "acquire"  # Prevents reordering of reads after this (.acquire in PTX)
    RELEASE = "release"  # Prevents reordering of writes before this (.release in PTX)
    ACQ_REL = "acq_rel"  # Both acquire and release semantics (.acq_rel in PTX)
    SEQ_CST = "seq_cst"


class MemScope(StrEnum):
    """Memory scope for memory operations.

    Controls which threads observe the memory operation effects.
    Used for loads, stores, atomics, and memory barriers.

    Reference: PTX ISA - Scope
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#scope

    PTX scope qualifiers:
        .cta      - Threads within the same CTA (thread block)
        .cluster  - Threads within the same cluster
        .gpu      - All threads on the same GPU device
        .sys      - All threads in the system (including host CPU)
    """

    CTA = "cta"  # .cta - Thread block scope (all threads in same CTA)
    CLUSTER = "cluster"  # .cluster - Cluster scope (all threads in same cluster)
    GPU = "gpu"  # .gpu - Device scope (all threads on same GPU)
    SYS = "sys"


class SharedSpace(StrEnum):
    """Shared memory space qualifier.

    Specifies the scope of shared memory access.

    Reference: PTX ISA - Shared Memory
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#shared-state-space
    """

    CTA = "cta"  # .shared::cta - Shared memory within CTA
    CLUSTER = "cluster"  # .shared::cluster - Distributed shared memory across cluster

    # Aliases for backward compatibility
    shared_cta = "cta"
    shared_cluster = "cluster"


class LoadCacheModifier(StrEnum):
    """Cache operation modifier for load instructions.

    Controls L1/L2 cache behavior for memory loads.

    Reference: PTX ISA - Cache Operators
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#cache-operators

    PTX cache operators for ld:
        .ca - Cache at all levels (L1 and L2), default
        .cg - Cache at global level (L2 only, bypass L1)
        .cs - Cache streaming (likely accessed once, evict first)
        .lu - Last use (hint data won't be needed again)
        .cv - Cache volatile (don't cache, always fetch from memory)
    """

    CA = "ca"  # .ca - Cache at all levels (default)
    CG = "cg"  # .cg - Cache global (L2 only)
    CS = "cs"  # .cs - Cache streaming
    LU = "lu"  # .lu - Last use
    CV = "cv"


class StoreCacheModifier(StrEnum):
    """Cache operation modifier for store instructions.

    Controls L1/L2 cache behavior for memory stores.

    Reference: PTX ISA - Cache Operators
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#cache-operators

    PTX cache operators for st:
        .wb - Write-back (cache at all levels), default
        .cg - Cache at global level (L2 only, bypass L1)
        .cs - Cache streaming (likely accessed once)
        .wt - Write-through (write to memory immediately)
    """

    WB = "wb"  # .wb - Write-back (default)
    CG = "cg"  # .cg - Cache global (L2 only)
    CS = "cs"  # .cs - Cache streaming
    WT = "wt"


class EvictPriority(StrEnum):
    """Eviction priority hint for cache lines.

    Controls the priority of cache line eviction.

    Reference: PTX ISA - Cache Eviction Priority
    """

    FIRST = "first"  # Evict first (highest priority to evict)
    LAST = "last"  # Evict last (lowest priority to evict)
    NORMAL = "normal"  # Normal eviction priority
    UNCHANGED = "unchanged"  # Don't change eviction priority
    NOALLOCATE = "noallocate"  # Don't allocate cache line
    NORMAL_DEMOTE = "normal_demote"
    NORMAL_NEAR = "normal_near"
    FIRST_NEAR = "first_near"
    LAST_NEAR = "last_near"
    NORMAL_DEMOTE_NEAR = "normal_demote_near"


class L2PrefetchSize(StrEnum):
    """L2 cache prefetch size hint.

    Specifies the prefetch granularity for L2 cache operations.

    Reference: PTX ISA - Data Movement Instructions
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#data-movement-and-conversion-instructions-prefetch-prefetchu
    """

    SIZE_64B = "size_64b"  # 64-byte prefetch
    SIZE_128B = "size_128b"  # 128-byte prefetch
    SIZE_256B = "size_256b"


class L1EvictKind(StrEnum):
    """L1 cache eviction priority hint.

    Controls the eviction policy for L1 cache lines.  Members match the
    5-member subset of :class:`EvictPriority` that the L1 path supports
    (the L2 path adds the sm_90+ ``*_demote`` / ``*_near`` variants).

    Reference: PTX ISA - Cache Eviction Priority
    https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#cache-eviction-priority
    """

    NORMAL = "normal"  # Normal eviction priority
    FIRST = "first"  # Evict this line first (low priority)
    LAST = "last"  # Evict this line last (high priority)
    NOALLOCATE = "noallocate"  # Don't allocate cache line
    UNCHANGED = "unchanged"


DSLGenericType = TypeVar("DSLGenericType")
Index = Union[
    int,
    Int32,
    Int64,
    slice,
    Tuple[Union[int, Int32, Int64, slice, EllipsisType], ...],
]

# Type alias for MLIR IR values
DSLIRValue: TypeAlias = ir.Value

# Scalar index for load/store operations - single int or tuple of ints for multi-dim
ScalarIndex = Union[int, "Int32", "Int64", Tuple[Union[int, "Int32", "Int64"], ...]]

# Single source of truth for subword float types.
# The LLVM dialect's type compatibility check (isCompatibleImpl in LLVMTypes.cpp)
# only accepts BFloat16, Float16, Float32, Float64, Float80, Float128, and
# PPCFP128 as compatible floating-point types. All other float types (fp8/fp6/fp4)
# fall through to Default(false), causing op creation to fail for scalar values.
# See: https://github.com/llvm/llvm-project/blob/3fdec1c9f9/mlir/lib/Dialect/LLVMIR/IR/LLVMTypes.cpp#L766-L819
# The monkey-patched llvm.load/llvm.store below bitcast to/from integer
# types to work around this.
_SUBWORD_FLOAT_TYPES = [
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E4M3,
    Float8E4M3FN,
    Float8E4M3B11FNUZ,
    Float8E5M2,
    Float8E8M0FNU,
]

# Pre-compute the set of bitwidths that need legalization
_SUBWORD_FLOAT_WIDTHS = frozenset(t.width for t in _SUBWORD_FLOAT_TYPES)


def _get_legalized_int_type(mlir_type: ir.Type) -> ir.Type | None:
    """If mlir_type is a scalar subword float, return the matching integer type.

    Uses ir.FloatType.isinstance() + width check against _SUBWORD_FLOAT_WIDTHS.
    Returns None if not a subword float.
    """
    if ir.FloatType.isinstance(mlir_type):
        width = ir.FloatType(mlir_type).width
        if width in _SUBWORD_FLOAT_WIDTHS:
            return ir.IntegerType.get_signless(width)
    return None


# Save original functions before monkey-patching
_orig_llvm_load = llvm.load
_orig_llvm_store = llvm.store


def _legalized_llvm_load(
    result_type: ir.Type, addr: ir.Value, **kwargs: Any
) -> ir.Value:
    """llvm.load with auto-legalization for scalar subword float types.

    Vector types pass through untouched (handled by the C++ legalize-llvm-types pass).
    """
    if not ir.VectorType.isinstance(result_type):
        int_type = _get_legalized_int_type(result_type)
        if int_type is not None:
            result = _orig_llvm_load(int_type, addr, **kwargs)
            loc = kwargs.get("loc")
            ip = kwargs.get("ip")
            return arith.bitcast(result_type, result, loc=loc, ip=ip)
    return _orig_llvm_load(result_type, addr, **kwargs)


def _legalized_llvm_store(value: ir.Value, addr: ir.Value, **kwargs: Any) -> ir.Value:
    """llvm.store with auto-legalization for scalar subword float types.

    Vector types pass through untouched (handled by the C++ legalize-llvm-types pass).
    """
    if not ir.VectorType.isinstance(value.type):
        int_type = _get_legalized_int_type(value.type)
        if int_type is not None:
            loc = kwargs.get("loc")
            ip = kwargs.get("ip")
            value = arith.bitcast(int_type, value, loc=loc, ip=ip)
    return _orig_llvm_store(value, addr, **kwargs)


# Monkey-patch: override llvm.load/llvm.store globally so ALL call sites
# (in this file, typing.py, and any future code) auto-legalize subword floats.
llvm.load = _legalized_llvm_load
llvm.store = _legalized_llvm_store


# =============================================================================
# MLIR Utility Functions
# =============================================================================


def is_static_scalar(value: Any) -> bool:
    return isinstance(value, (int, float, bool))


def is_scalar(value: Any) -> bool:
    return is_static_scalar(value) or isinstance(
        value, (arith_helper.ArithValue, Numeric)
    )


def scalar_to_ir_value(
    scalar: Union[int, float, bool, arith_helper.ArithValue, Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> DSLIRValue:
    if is_static_scalar(scalar):
        return arith_helper.const(scalar, loc=loc, ip=ip)
    elif isinstance(scalar, arith_helper.ArithValue):
        return scalar
    elif isinstance(scalar, Numeric):
        return scalar.ir_value(loc=loc, ip=ip)
    else:
        raise ValueError(f"Expected scalar value, got {scalar}")


# =============================================================================
# print_runtime - Cross-platform printf implementation
# =============================================================================


@lru_cache_ir()
def _is_gpu_context() -> bool:
    """Check if we're currently in a GPU context (inside a kernel)."""
    ip = ir.InsertionPoint.current
    block = ip.block
    op = block.owner
    while op is not None:
        op_name = str(op.name)
        if op_name in ("cuda.kernel", "gpu.func", "gpu.module"):
            return True
        if op_name in ("builtin.module", "func.func"):
            return False
        # Try parent_op first (for regions), then parent (for nes
        # ted ops)
        parent = getattr(op, "parent_op", None) or getattr(op, "parent", None)
        op = parent
    return False


def _get_module_op() -> ir.Operation:
    """Get the parent module operation from current insertion point."""
    ip = ir.InsertionPoint.current
    block = ip.block
    op = block.owner
    while op is not None:
        if str(op.name) == "builtin.module":
            return op
        op = op.parent
    raise RuntimeError("Could not find parent module")


def _get_gpu_module_op() -> ir.Operation:
    """Walk up from the current insertion point to find the enclosing gpu.module.

    Constant- and global-memory symbols emitted from inside a kernel body
    must live at gpu.module scope, not at builtin.module scope, so that the
    GPU code generator places them in the produced cubin.

    Raises RuntimeError if the current insertion point is not inside a gpu.module
    (which means the caller is not inside a kernel body).
    """
    ip = ir.InsertionPoint.current
    block = ip.block
    op = block.owner
    while op is not None:
        if str(op.name) == "gpu.module":
            return op
        parent = getattr(op, "parent_op", None) or getattr(op, "parent", None)
        op = parent
    raise RuntimeError(
        "No enclosing gpu.module found. allocate_memory_constant/global must be "
        "called from inside a @cute.kernel body."
    )


def _find_existing_global(
    gpu_module_op: ir.Operation, name: str
) -> ir.Operation | None:
    """Return the existing llvm.mlir.global op named `name` inside the gpu.module,
    or None if no such global exists.
    """
    body = gpu_module_op.regions[0].blocks[0]
    for op in body:
        if str(op.name) != "llvm.mlir.global":
            continue
        if "sym_name" not in op.attributes:
            continue
        sym_name = str(op.attributes["sym_name"]).strip('"')
        if sym_name == name:
            return op
    return None


def _get_unique_global_name(gpu_module_op: ir.Operation, prefix: str) -> str:
    """Pick a fresh symbol name with the given prefix that does not collide with
    any existing symbol inside the gpu.module body. Mirrors the pattern used
    by _get_unique_format_global_name() for printf format strings.
    """
    existing: set[str] = set()
    for op in gpu_module_op.regions[0].blocks[0]:
        if "sym_name" in op.attributes:
            existing.add(str(op.attributes["sym_name"]).strip('"'))
    counter = 0
    while True:
        candidate = f"{prefix}_{counter}"
        if candidate not in existing:
            return candidate
        counter += 1


def _global_signature(op: ir.Operation) -> tuple:
    """Extract a (global_type, addrspace, alignment) signature tuple from an
    existing llvm.mlir.global op for compatibility checking on reuse."""
    type_str = (
        str(op.attributes["global_type"]) if "global_type" in op.attributes else None
    )
    addrspace = None
    if "addr_space" in op.attributes:
        addrspace = int(str(op.attributes["addr_space"]).split(":")[0].strip())
    alignment = None
    if "alignment" in op.attributes:
        alignment = int(str(op.attributes["alignment"]).split(":")[0].strip())
    return (type_str, addrspace, alignment)


def _build_init_value_attr(
    init: Any,
    dtype: Any,
    shape: tuple,
    is_wrapped_array: bool,
    llvm_elem_type: ir.Type,
) -> ir.Attribute:
    """Build an MLIR attribute carrying ``init`` as the inline initializer
    for an llvm.mlir.global of element type ``llvm_elem_type`` (and DSL dtype
    ``dtype``, shape ``shape``).

    For scalar globals (single element, unwrapped), returns IntegerAttr or
    FloatAttr. For array globals, returns DenseElementsAttr backed by a
    matching numpy buffer.
    """
    import numpy as np

    if not is_wrapped_array:
        # Scalar global: accept a single Python number or 1-element iterable.
        if isinstance(init, (bool, int, float)):
            v = init
        else:
            try:
                seq = list(init)
            except TypeError as exc:
                raise TypeError(
                    f"unsupported init type for scalar global: {type(init).__name__}"
                ) from exc
            if len(seq) != 1:
                raise ValueError(f"scalar init expected 1 element, got {len(seq)}")
            v = seq[0]
        elem_mlir = llvm_elem_type
        if isinstance(elem_mlir, ir.IntegerType):
            return ir.IntegerAttr.get(elem_mlir, int(v))
        if isinstance(elem_mlir, (ir.F16Type, ir.F32Type, ir.F64Type, ir.BF16Type)):
            return ir.FloatAttr.get(elem_mlir, float(v))
        raise TypeError(f"init not supported for scalar element type {elem_mlir}")

    # Array global: convert init to a contiguous numpy buffer matching the
    # requested dtype/shape, then wrap as DenseElementsAttr over a matching
    # tensor type. The LLVM dialect translator accepts a tensor-typed
    # DenseElementsAttr as the value for a !llvm.array<...> global.
    # NumericMeta exposes numpy_dtype as a metaclass property, so it is
    # accessed directly on the dtype class (not type(dtype)).
    np_dtype = getattr(dtype, "numpy_dtype", None)
    if np_dtype is None:
        raise TypeError(f"dtype {dtype} has no numpy_dtype; cannot build inline init.")
    arr = np.asarray(init, dtype=np_dtype)
    if arr.shape != tuple(shape):
        raise ValueError(
            f"init shape {arr.shape} does not match global shape {tuple(shape)}"
        )
    tensor_ty = ir.RankedTensorType.get(list(shape), dtype.mlir_type)
    return ir.DenseElementsAttr.get(arr, type=tensor_ty)


def _get_or_declare_constant_global(
    name: str | None,
    llvm_elem_type: ir.Type,
    addrspace: int,
    *,
    alignment: int,
    constant: bool = False,
    storage: str = "internal",
    init: Any = None,
    init_dtype: Any = None,
    init_shape: tuple = (),
    init_is_wrapped_array: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[ir.Value, str]:
    """Find or declare an llvm.mlir.global symbol in the enclosing gpu.module
    and return ``(addressof_result, resolved_name)``.

    ``storage``:
      - "internal": the symbol is defined in this compilation unit. With
        ``init`` provided, the value is embedded as an MLIR attribute; without
        it, the global is zero-initialized via an init region with
        ``llvm.mlir.zero``.
      - "extern": the symbol is defined elsewhere; emits a declaration only.
        Requires an explicit ``name`` and rejects ``init``.

    On reuse, the existing global's signature is compared with the requested
    one; mismatch is a RuntimeError. ``init`` is ignored on reuse (the first
    declaration wins).
    """
    if storage == "extern" and init is not None:
        raise ValueError(
            f"global '{name}': init data is not allowed for storage='extern'"
        )
    if storage == "extern" and not name:
        raise ValueError(
            "storage='extern' requires an explicit `name` — "
            "the symbol must already exist in another compilation unit"
        )

    gpu_module = _get_gpu_module_op()

    type_str = str(llvm_elem_type)

    # Compose the requested signature; both forms must match on reuse.
    requested_type_str = type_str
    requested_addrspace = int(addrspace)
    requested_alignment = int(alignment)

    assert name is not None

    existing = _find_existing_global(gpu_module, name)
    if existing is not None:
        ex_type, ex_as, ex_align = _global_signature(existing)
        if (
            ex_type != requested_type_str
            or ex_as != requested_addrspace
            or (ex_align is not None and ex_align != requested_alignment)
        ):
            raise RuntimeError(
                f"global symbol '{name}' redeclared with incompatible signature: "
                f"existing=(type={ex_type}, addrspace={ex_as}, align={ex_align}); "
                f"new=(type={requested_type_str}, addrspace={requested_addrspace}, "
                f"align={requested_alignment})"
            )
    else:
        # Insert at the start of the gpu.module body (before any cuda.kernel
        # functions) so the symbol is visible to all kernels.
        gpu_module_body = gpu_module.regions[0].blocks[0]
        linkage_attr = ir.Attribute.parse("#llvm.linkage<external>")
        value_attr = None
        if init is not None and storage == "internal":
            value_attr = _build_init_value_attr(
                init, init_dtype, init_shape, init_is_wrapped_array, llvm_elem_type
            )
        with ir.InsertionPoint.at_block_begin(gpu_module_body):
            global_op = llvm.GlobalOp(
                sym_name=name,
                global_type=llvm_elem_type,
                linkage=linkage_attr,
                constant=constant,
                addr_space=requested_addrspace,
                alignment=requested_alignment,
                value=value_attr,
            )
            if storage == "internal" and value_attr is None:
                # Zero-initialized definition. Add an initializer region with
                # llvm.mlir.zero (works for any LLVM type — scalar, array,
                # struct, nested combinations).
                init_region = global_op.regions[0]
                init_block = init_region.blocks.append()
                with ir.InsertionPoint(init_block):
                    zero_val = llvm.mlir_zero(llvm_elem_type)
                    llvm.return_(arg=zero_val)
            elif storage == "extern":
                # Declaration only — leave the initializer region empty.
                pass
            elif storage not in ("internal", "extern"):
                raise ValueError(
                    f"storage must be 'internal' or 'extern', got {storage!r}"
                )

    # Emit addressof at the current insertion point.
    ptr_type = llvm.PointerType.get(requested_addrspace)
    addr_op = llvm.AddressOfOp(ptr_type, name, loc=loc, ip=ip)
    return addr_op.result, name


def _get_or_declare_printf(module_op: ir.Operation) -> str:
    """Get or declare the printf function in the module."""
    printf_name = "printf"

    # Check if printf is already declared
    for op in module_op.regions[0].blocks[0]:
        if str(op.name) == "llvm.func":
            if "sym_name" in op.attributes:
                name = str(op.attributes["sym_name"]).strip('"')
                if name == printf_name:
                    return printf_name

    # Declare printf: i32 printf(ptr, ...) - variadic
    func_type = ir.Type.parse("!llvm.func<i32 (!llvm.ptr, ...)>")

    with ir.InsertionPoint.at_block_begin(module_op.regions[0].blocks[0]):
        func_op = llvm.func(
            printf_name,
            function_type=ir.TypeAttr.get(func_type),
        )
        func_op.attributes["llvm.linkage"] = ir.StringAttr.get("external")

    return printf_name


def _get_unique_format_global_name(module_op: ir.Operation) -> str:
    """Get a unique global name for a format string (thread-safe)."""
    # Collect existing symbol names in the module
    existing_symbols: set[str] = set()
    for op in module_op.regions[0].blocks[0]:
        if "sym_name" in op.attributes:
            name = str(op.attributes["sym_name"]).strip('"')
            existing_symbols.add(name)

    # Find unique name by incrementing counter
    counter = 0
    while True:
        symbol = f"printfFormat_{counter}"
        if symbol not in existing_symbols:
            return symbol
        counter += 1


def _create_format_string_global(module_op: ir.Operation, format_str: str) -> str:
    """Create a global constant for the format string, return symbol name."""
    symbol = _get_unique_format_global_name(module_op)

    # Add null terminator
    str_with_null = format_str + "\0"
    str_len = len(str_with_null)

    # Create global using llvm.GlobalOp
    module_body = module_op.regions[0].blocks[0]
    with ir.InsertionPoint(module_body):
        llvm.GlobalOp(
            sym_name=symbol,
            global_type=ir.Type.parse(f"!llvm.array<{str_len} x i8>"),
            linkage=ir.Attribute.parse("#llvm.linkage<internal>"),
            constant=True,
            value=ir.StringAttr.get(str_with_null),
        )

    return symbol


def _get_format_string_ptr(
    symbol: str,
    str_len: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> DSLIRValue:
    """Get pointer to the first character of a global format string."""
    ptr_type = ir.Type.parse("!llvm.ptr")
    array_type = ir.Type.parse(f"!llvm.array<{str_len} x i8>")

    # Get address of global
    global_ptr = llvm.AddressOfOp(ptr_type, symbol, loc=loc, ip=ip)

    # GEP to get pointer to first element: getelementptr [N x i8], ptr, 0, 0
    return _gep(
        global_ptr.result,
        array_type,
        static_indices=[0, 0],
        loc=loc,
        ip=ip,
    )


# Exotic float types that cannot be directly printed (need upcast to Float32)
_UNPRINTABLE_FLOAT_TYPES = (
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E4M3,
    Float8E4M3FN,
    Float8E4M3B11FNUZ,
    Float8E5M2,
    Float8E8M0FNU,
)


def _to_ir_value(
    arg: object,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> DSLIRValue:
    """Convert argument to MLIR Value, extracting from DSL types if needed.

    Handles:
    - DSLIRValue: pass through
    - DSL types with .ir_value(): extract the MLIR value
    - Python bool: convert to i1 constant
    - Python int: convert to i32 constant
    - Python float: convert to f32 constant

    Raises:
        TypeError: If the argument is an exotic float type (Float4, Float6, Float8)
            that cannot be directly printed. Suggests upcasting to Float32.
    """
    # Check for exotic float types that cannot be directly printed
    if isinstance(arg, _UNPRINTABLE_FLOAT_TYPES):
        raise TypeError(
            f"Cannot print {type(arg).__name__} directly. "
            f"Please upcast to Float32 first, e.g.: Float32(value)"
        )

    result: DSLIRValue | None = None

    if isinstance(arg, DSLIRValue):  # type: ignore[misc]  # ir.Value is an untyped MLIR binding
        result = arg
    elif hasattr(arg, "ir_value"):
        result = arg.ir_value()
    # Handle Python primitive types using DSL types
    elif isinstance(arg, bool):
        result = Boolean(arg, loc=loc, ip=ip).ir_value()
    elif isinstance(arg, int):
        result = Int32(arg, loc=loc, ip=ip).ir_value()
    elif isinstance(arg, float):
        result = Float32(arg, loc=loc, ip=ip).ir_value()
    else:
        raise TypeError(
            f"print_runtime argument must be a printable value like Int32, Float32, "
            f"Boolean, or Python bool/int/float, got {type(arg).__name__}"
        )

    return result


def _get_printf_format_specifier(mlir_type: ir.Type) -> str:
    """Get the printf format specifier for a given MLIR type.

    Args:
        mlir_type: The MLIR type of the value

    Returns:
        The printf format specifier (e.g. "%d", "%f", "%llu")

    Raises:
        TypeError: If the type is not supported for printing
    """
    if ir.IndexType.isinstance(mlir_type):
        return "%llu"
    if ir.IntegerType.isinstance(mlir_type):
        width = ir.IntegerType(mlir_type).width
        if width == 64:
            return "%lld"
        elif width == 32:
            return "%d"
        elif width == 16:
            return "%hd"
        elif width == 8:
            return "%hhd"
        elif width == 1:
            return "%d"  # bool as int
        else:
            return "%d"  # fallback
    if ir.F64Type.isinstance(mlir_type):
        return "%f"
    if ir.F32Type.isinstance(mlir_type):
        return "%f"
    if ir.F16Type.isinstance(mlir_type):
        return "%f"
    if ir.BF16Type.isinstance(mlir_type):
        return "%f"
    # Check for pointer types (string representation check)
    type_str = str(mlir_type)
    if "ptr" in type_str.lower():
        return "%p"
    raise TypeError(
        f"Cannot determine printf format specifier for type {mlir_type}. "
        f"Supported types: integers (i1-i64), floats (f16, bf16, f32, f64), "
        f"index, pointers."
    )


def _print_runtime_impl(
    fmt: str,
    *args: object,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Implementation of print_runtime.

    Uses gpu.printf for GPU context and llvm.call @printf for CPU context.
    Format string uses Python-style {} placeholders which are converted to
    C-style format specifiers based on argument types.

    Args:
        fmt: Format string with {} placeholders (Python f-string style)
        *args: Values to print (MLIR Values or DSL types)
    """
    # Convert all args to IR values
    ir_args = [_to_ir_value(arg, loc=loc, ip=ip) for arg in args]

    # Build format specifiers from argument types and replace {} placeholders
    type_formats = [_get_printf_format_specifier(arg.type) for arg in ir_args]
    c_fmt = fmt.format(*type_formats)

    if _is_gpu_context():
        # GPU: use gpu.printf (unpack args - gpu.printf takes *args, not a list)
        gpu.printf(c_fmt, *ir_args, loc=loc, ip=ip)
    else:
        # CPU: lower to llvm.call @printf
        module_op = _get_module_op()

        # Ensure printf is declared
        _get_or_declare_printf(module_op)

        # Create format string global (use c_fmt with proper specifiers)
        format_str_with_null = c_fmt + "\0"
        str_len = len(format_str_with_null)
        symbol = _create_format_string_global(module_op, c_fmt)

        # Get pointer to format string
        fmt_ptr = _get_format_string_ptr(symbol, str_len, loc=loc, ip=ip)

        # Promote float types to f64 (C variadic convention)
        promoted_args: list[DSLIRValue] = []
        for ir_val in ir_args:
            arg_type = ir_val.type
            # Promote f16, bf16, f32 to f64
            type_str = str(arg_type)
            if type_str in ("f16", "bf16", "f32"):
                promoted = arith.ExtFOp(ir.F64Type.get(), ir_val, loc=loc, ip=ip)
                promoted_args.append(promoted.result)
            else:
                promoted_args.append(ir_val)

        # Call printf(fmt_ptr, args...)
        # printf is variadic, so we need to specify var_callee_type
        call_args = [fmt_ptr] + promoted_args
        printf_type = ir.Type.parse("!llvm.func<i32 (!llvm.ptr, ...)>")
        llvm.call(
            result=ir.IntegerType.get_signless(32),
            callee="printf",
            callee_operands=call_args,
            var_callee_type=ir.TypeAttr.get(printf_type),
            op_bundle_sizes=[],
            op_bundle_operands=[],
            loc=loc,
            ip=ip,
        )


# =============================================================================
# Helper functions
# =============================================================================


def _is_subword_float(dtype: type[Numeric]) -> bool:
    """Check if dtype is a Float4/Float6/Float8 type (stored as i8 internally)."""
    return dtype in _SUBWORD_FLOAT_TYPES


def _print_1d_runtime(
    arr: Union["Vector", "_ArrayImpl"],
    shape: tuple[int, ...],
    max_elements: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Print 1D array/vector contents."""
    size = int(shape[0])
    max_print = min(size, max_elements)
    # Vectors don't have a space property (always in registers)
    space_str = "register" if isinstance(arr, Vector) else str(arr.space.name).lower()
    fmt = f"Array[%d][Space={space_str}]: ["
    _print_runtime_impl(fmt, Int32(size), loc=loc, ip=ip)
    for i in range(max_print):
        value = arr[Int32(i)]
        if i == 0:
            _print_runtime_impl("%.1f", value, loc=loc, ip=ip)
        else:
            _print_runtime_impl(", %.1f", value, loc=loc, ip=ip)
    if size > max_elements:
        _print_runtime_impl(", ...]", loc=loc, ip=ip)
    else:
        _print_runtime_impl("]", loc=loc, ip=ip)
    _print_runtime_impl("\n", loc=loc, ip=ip)


def _print_2d_runtime(
    arr: "Vector | _ArrayImpl",
    shape: tuple[int, ...],
    max_elements: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Print 2D array/vector contents."""
    rows, cols = int(shape[0]), int(shape[1])
    max_r, max_c = min(rows, max_elements), min(cols, max_elements)

    _print_runtime_impl("Array[%dx%d]:\n", Int32(rows), Int32(cols), loc=loc, ip=ip)
    for i in range(max_r):
        _print_runtime_impl(" [%d]: [", Int32(i), loc=loc, ip=ip)
        for j in range(max_c):
            value = arr[Int32(i), Int32(j)]
            if j > 0:
                _print_runtime_impl(", ", loc=loc, ip=ip)
            _print_runtime_impl("%.1f", value, loc=loc, ip=ip)
        if cols > max_c:
            _print_runtime_impl(", ...]\n", loc=loc, ip=ip)
        else:
            _print_runtime_impl("]\n", loc=loc, ip=ip)
    if rows > max_r:
        _print_runtime_impl(" ...\n", loc=loc, ip=ip)


def _print_3d_runtime(
    arr: "Vector | _ArrayImpl",
    shape: tuple[int, ...],
    max_elements: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Print 3D array/vector contents."""
    d0, d1, d2 = int(shape[0]), int(shape[1]), int(shape[2])
    m0, m1, m2 = min(d0, max_elements), min(d1, max_elements), min(d2, max_elements)

    _print_runtime_impl(
        "Array[%dx%dx%d]:\n", Int32(d0), Int32(d1), Int32(d2), loc=loc, ip=ip
    )
    for i in range(m0):
        _print_runtime_impl(" [%d]:\n", Int32(i), loc=loc, ip=ip)
        for j in range(m1):
            _print_runtime_impl("  [%d,%d]: [", Int32(i), Int32(j), loc=loc, ip=ip)
            for k in range(m2):
                value = arr[Int32(i), Int32(j), Int32(k)]
                if k > 0:
                    _print_runtime_impl(", ", loc=loc, ip=ip)
                _print_runtime_impl("%.1f", value, loc=loc, ip=ip)
            if d2 > m2:
                _print_runtime_impl(", ...]\n", loc=loc, ip=ip)
            else:
                _print_runtime_impl("]\n", loc=loc, ip=ip)
        if d1 > m1:
            _print_runtime_impl("  ...\n", loc=loc, ip=ip)
    if d0 > m0:
        _print_runtime_impl(" ...\n", loc=loc, ip=ip)
    _print_runtime_impl("\n", loc=loc, ip=ip)


def _print_runtime(
    arr: "Vector | _ArrayImpl",
    shape: tuple[int, ...],
    max_elements: int = 8,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Print array/vector contents for any dimensionality up to 3D.

    Dispatches to the appropriate 1D/2D/3D printer based on the shape.
    Shared by both Vector and Array print_runtime methods.

    Args:
        arr: The Vector or Array to print.
        shape: The shape tuple of the array/vector.
        max_elements: Maximum elements to print per dimension.
    """
    ndim = len(shape)
    if ndim == 1:
        _print_1d_runtime(arr, shape, max_elements, loc=loc, ip=ip)
    elif ndim == 2:
        _print_2d_runtime(arr, shape, max_elements, loc=loc, ip=ip)
    elif ndim == 3:
        _print_3d_runtime(arr, shape, max_elements, loc=loc, ip=ip)
    else:
        raise NotImplementedError(f"print_runtime supports up to 3D, got {ndim}D")


# =============================================================================
# Shared alignment / address-space helpers (used by _PointerImpl + _ArrayImpl)
# =============================================================================


def _resolve_alignment(default_align: int, alignment: int | None) -> int:
    """Resolve a one-time alignment override against an impl's default alignment.

    Shared by _PointerImpl and _ArrayImpl so the two reuse this logic without an
    inheritance relationship.
    """
    return alignment if alignment is not None else default_align


def _addrspacecast_base(
    base: ir.Value,
    addrspace: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """Address-space-cast a raw llvm pointer value; returns the new pointer value.

    Shared low-level helper for the _PointerImpl/_ArrayImpl address-space casts.
    """
    return llvm.addrspacecast(llvm.PointerType.get(addrspace), base, loc=loc, ip=ip)


# =============================================================================
# Factory hooks
# =============================================================================

def _make_pointer_from_raw(value: ir.Value, dtype: type[Numeric] | None) -> "Pointer":
    """Build a ``cutlass.Pointer`` from a raw MLIR pointer value.

    ``Pointer`` lives in ``base_dsl.typing`` (same layer), so it is imported
    lazily here to avoid an intra-base_dsl import cycle at module load time.
    """
    from .typing import Pointer

    return Pointer._from_raw_ptr(value, dtype)


def _compute_row_major_strides(shape: tuple[int, ...]) -> tuple[int, ...]:
    """Compute row-major strides for ``cutlass.Array`` logical indexing."""
    if not shape:
        return ()

    strides = [1] * len(shape)
    for i in range(len(shape) - 2, -1, -1):
        strides[i] = strides[i + 1] * shape[i + 1]
    return tuple(strides)


_array_factory = None


def register_array_factory(fn: Callable[..., Any]) -> None:
    """Register the ``_Array_factory_dispatch`` allocator.

    Called by ``DSL.typing`` at import time.
    """
    global _array_factory
    _array_factory = fn


def _allocate_memory_shared(
    dtype: Type[Numeric],
    shape: tuple[int, ...] | int,
    alignment: int,
    bounds_check: bool,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> "Array":
    """Allocate CTA shared memory for ``cutlass.Array(..., space=smem)``."""
    from cutlass.utils import SmemAllocator

    norm_shape = (shape,) if isinstance(shape, int) else tuple(shape)
    num_elements = 1
    for extent in norm_shape:
        num_elements *= extent

    element_width_bits = dtype.width if dtype is not Boolean else 8
    if num_elements * element_width_bits % 8 != 0:
        raise ValueError("invalid allocation that is not byte-aligned")

    ptr = SmemAllocator().allocate_array(
        dtype,
        num_elements,
        byte_alignment=alignment,
        loc=loc,
        ip=ip,
    )
    return Array(
        ptr,
        shape=norm_shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=AddressSpace.smem.value,
        alignment=alignment,
    )


def _allocate_memory_local(
    dtype: Type[Numeric],
    shape: tuple[int, ...] | int,
    alignment: int | None,
    bounds_check: bool,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> "Array":
    """Allocate thread-local scratch for ``cutlass.Array(..., space=rmem)``."""
    norm_shape = (shape,) if isinstance(shape, int) else tuple(shape)

    if _is_gpu_context():
        import cutlass.cute as cute

        # ``cute.make_rmem_tensor(shape)`` defaults to CuTe's compact
        # left-most layout.  ``cutlass.Array`` presents row-major flat indexing
        # semantics, so allocate with an explicit row-major layout.  This keeps
        # a vector slice of the innermost dimension physically contiguous, e.g.
        # ``arr.subview((i, j, k, l, 0))[0:4]``.
        layout = cute.make_layout(
            norm_shape, stride=_compute_row_major_strides(norm_shape)
        )
        tensor = cute.make_rmem_tensor(layout, dtype, loc=loc, ip=ip)
        return Array(
            tensor,
            shape=norm_shape,
            bounds_check=bounds_check,
            addrspace=AddressSpace.rmem.value,
            alignment=alignment,
        )

    num_elements = 1
    for extent in norm_shape:
        num_elements *= extent

    if alignment is None:
        alignment = max(1, dtype.width // 8)
    ptr_type = llvm.PointerType.get(AddressSpace.generic.value)
    size_val = Int32(num_elements).ir_value(loc=loc, ip=ip)
    alloca_ptr = llvm.alloca(
        ptr_type, size_val, dtype.mlir_type, alignment=alignment, loc=loc, ip=ip
    )
    return Array(
        alloca_ptr,
        shape=norm_shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=AddressSpace.generic.value,
        alignment=alignment,
    )


def _make_array_via_factory(
    dtype: object,
    shape: Tuple[int, ...] | int | None,
    space: AddressSpace | int,
    kwargs: dict[str, Any],
) -> "Array":
    """Allocate an Array through cutlass-owned or registered backends.

    Host-side rmem/generic scratch is owned directly by this module because
    ``Array`` is a cutlass type. Other allocation spaces still route through
    the registered backend.
    """
    space = _normalize_address_space(space)
    if not isinstance(dtype, type) or not issubclass(dtype, Numeric):
        raise TypeError(
            "cutlass.Array(dtype, shape, space=...) expects a cutlass "
            f"numeric type, got {dtype!r}."
        )

    try:
        in_gpu_ctx = _is_gpu_context()
        in_mlir_ctx = True
    except Exception:
        in_gpu_ctx = False
        in_mlir_ctx = False

    if in_mlir_ctx and space in (
        AddressSpace.rmem,
        AddressSpace.generic,
    ):
        if shape is None:
            raise ValueError(
                f"cutlass.Array(space={space.name}) requires an explicit shape."
            )
        remaining = set(kwargs) - {"alignment", "bounds_check", "loc", "ip"}
        if remaining:
            raise TypeError(
                f"keyword argument(s) {sorted(remaining)} are not valid for "
                f"space={space.name}. Valid kwargs: ['alignment', 'bounds_check']"
            )
        return _allocate_memory_local(
            dtype,
            shape,
            kwargs.get("alignment"),
            kwargs.get("bounds_check", False),
            loc=kwargs.get("loc"),
            ip=kwargs.get("ip"),
        )

    if space is AddressSpace.smem:
        if not in_mlir_ctx:
            raise ValueError(
                f"space={space.name} is only valid inside @cute.kernel. "
                "Move this allocation into the kernel body."
            )
        if shape is None:
            raise ValueError(
                f"cutlass.Array(space={space.name}) requires an explicit shape."
            )
        remaining = set(kwargs) - {"alignment", "bounds_check", "loc", "ip"}
        if remaining:
            raise TypeError(
                f"keyword argument(s) {sorted(remaining)} are not valid for "
                f"space={space.name}. Valid kwargs: ['alignment', 'bounds_check']"
            )
        alignment = kwargs.get("alignment", 4)
        bounds_check = kwargs.get("bounds_check", False)
        return _allocate_memory_shared(
            dtype,
            shape,
            alignment,
            bounds_check,
            loc=kwargs.get("loc"),
            ip=kwargs.get("ip"),
        )

    if _array_factory is None:
        raise RuntimeError(
            "no array allocation backend registered for this cutlass.Array "
            "space and context."
        )
    return _array_factory(dtype, shape, space, kwargs)


# =============================================================================
# _ArrayImpl - Memory-backed array implementation
# =============================================================================


class _ArrayImpl(Generic[DSLGenericType]):
    """
    Internal implementation of Array. Do not use directly.

    This class contains all the implementation details for Array, including
    MLIR/LLVM operations, offset/GEP, and DSL infrastructure. Shares low-level
    memory helpers with _PointerImpl via module free functions (it does not
    inherit from it). Use the Array class for the public API.
    """

    # Instance attributes (set in __init__ / the various _init_* helpers and the
    # __new__-based copy constructors). Declared here so the checker sees a
    # single type for each despite the ``= None`` placeholder assignments. The
    # base/MLIR-value attributes hold untyped MLIR bindings, hence ``Any``.
    _bounds_check: bool
    _base: ir.Value
    _original_base: ir.Value
    _dtype: Type[Numeric] | None
    _mlir_type: ir.Type
    _addrspace: int
    _user_alignment: int | None
    _shape: Tuple[int, ...] | None
    _strides: Tuple[int, ...] | None

    # =========================================================================
    # DSL Infrastructure (required for code generation)
    # =========================================================================

    def __extract_mlir_values__(self) -> list:
        return [self._base]

    def __extract_mlir_attributes__(self) -> list:
        """Return MLIR attributes for this array argument."""
        return [ir.DictAttr.get({})]

    def __new_from_mlir_values__(self, values: list) -> "_ArrayImpl[DSLGenericType]":
        """Create a new _ArrayImpl from MLIR values, preserving current properties."""
        new_base = values[0]
        log().info(
            f"_ArrayImpl.__new_from_mlir_values__: new_base={type(new_base).__name__}, "
            f"dtype={self._dtype}, shape={self._shape}, addrspace={self._addrspace}"
        )

        new_impl = _ArrayImpl.__new__(_ArrayImpl)
        new_impl._bounds_check = self._bounds_check
        new_impl._size_layout = self._size_layout
        new_impl._shape = self._shape
        new_impl._strides = self._strides
        new_impl._dtype = self._dtype
        new_impl._mlir_type = self._mlir_type
        new_impl._addrspace = self._addrspace
        new_impl._alignment = self._alignment  # Preserve alignment
        new_impl._base = new_base
        new_impl._original_base = new_base

        new_impl._verify()
        return new_impl

    # =========================================================================
    # Alignment (Array carries alignment; Pointer does not)
    # =========================================================================

    _alignment: int | None = None  # Alignment in bytes (None = use element size)

    @property
    def align(self) -> int:
        """Memory alignment in bytes for load/store operations.

        Array carries alignment from its allocation or source tensor.
        Falls back to element size if not set.

        Returns:
            Alignment in bytes (always >= 1).
        """
        if self._alignment is not None:
            return self._alignment
        return self._elem_align()

    # =========================================================================
    # Shared low-level ops (own copies; _ArrayImpl no longer inherits _PointerImpl)
    # =========================================================================

    def _effective_alignment(self, alignment: int | None) -> int:
        """Resolve a one-time alignment override against ``self.align``."""
        return _resolve_alignment(self.align, alignment)

    def _elem_align(self) -> int:
        """Natural per-element alignment in bytes (always >= 1)."""
        assert self._dtype is not None
        return max(1, self._dtype.width // 8)

    def _make_scalar_ir(self, value: object) -> DSLIRValue:
        """Coerce ``value`` to this array's element dtype and return its IR value.

        The element-dtype constructor accepts DSL scalars, Python numbers and
        raw MLIR values; its annotated signature is narrower than that runtime
        contract, so the dynamically-typed ``value`` is passed through here.
        """
        assert self._dtype is not None
        return self._dtype(value).ir_value()  # type: ignore[arg-type]

    @staticmethod
    def _as_gep_index(start: object) -> Union[Int32, Int64]:
        """Normalize a slice-start value into a GEP-compatible scalar index."""
        if isinstance(start, (Int32, Int64)):
            return start
        if isinstance(start, int):
            return Int32(start)
        raise TypeError(
            f"Unsupported slice start type for vector access: {type(start).__name__}"
        )

    def _addrspacecast(
        self,
        addrspace: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "_ArrayImpl[DSLGenericType]":
        """Address-space-cast this array's base pointer; returns a new _ArrayImpl."""
        res_ptr = _addrspacecast_base(self._base, addrspace, loc=loc, ip=ip)
        new_impl = _ArrayImpl.__new__(_ArrayImpl)
        new_impl._bounds_check = self._bounds_check
        new_impl._size_layout = self._size_layout
        new_impl._shape = self._shape
        new_impl._strides = self._strides
        new_impl._dtype = self._dtype
        new_impl._mlir_type = self._mlir_type
        new_impl._addrspace = addrspace
        new_impl._alignment = self._alignment
        new_impl._base = res_ptr
        new_impl._original_base = res_ptr
        return new_impl

    # =========================================================================
    # Initialization
    # =========================================================================

    def __init__(
        self,
        base: Union["cute.Tensor", ir.OpResult],
        *,
        dtype: Type[Numeric] | None = None,
        addrspace: int | None = None,
        shape: Tuple[int, ...] | None = (1,),
        strides: Tuple[int, ...] | None = None,
        bounds_check: bool = False,
        alignment: int | None = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Initialize an Array.

        Args:
            base: Source data - can be cute.Tensor, cute.Pointer, or MLIR value.
            dtype: Element type (e.g., Float32). Required for raw MLIR values.
            addrspace: Address space override (default: infer from source).
            shape: Array shape (default: (1,) for scalar pointer).
            strides: Custom strides (default: row-major computed from shape).
            bounds_check: Enable bounds checking on access.
            alignment: Memory alignment in bytes. Alignment priority:
                1. This parameter (if provided) - highest priority
                2. From cute.Tensor/cute.Pointer (if created from those)
                3. Element size in bytes (default fallback)

        Note:
            All load/store operations use the alignment set here. There is no
            way to override alignment on individual operations.
        """
        log().info(
            f"_ArrayImpl.__init__: base={type(base).__name__}, dtype={dtype}, "
            f"addrspace={addrspace}, shape={shape}, strides={strides}"
        )
        self._bounds_check = bounds_check
        self._size_layout = None
        self._original_base = None
        self._base = None
        self._dtype = dtype
        self._mlir_type = None
        self._addrspace = addrspace if addrspace is not None else 0
        # Store user-provided alignment - this takes priority over source alignment
        self._user_alignment = alignment

        self._shape = tuple(shape) if shape is not None else None
        if self._shape is not None and strides is None:
            self._strides = self._compute_strides(self._shape)
        elif strides is not None:
            self._strides = tuple(strides)
        else:
            self._strides = None

        log().info(
            "_ArrayImpl.__init__: shape=%s, strides=%s, dtype=%s, alignment=%s",
            self._shape,
            self._strides,
            self._dtype,
            self._user_alignment,
        )

        self._init_regular_pointer(base, addrspace)

        # Set final alignment: user-provided takes priority over source alignment
        if self._user_alignment is not None:
            self._alignment = self._user_alignment
        # else _alignment may have been set by _init_from_cute_tensor etc.

        self._verify()

    # =========================================================================
    # Regular Pointer Initialization
    # =========================================================================

    def _init_from_cute_tensor(
        self, base: "cute.Tensor", addrspace: int | None
    ) -> None:
        # ``cute.Tensor.iterator`` is typed ``Union[Pointer, IntTuple]``; a memory
        # tensor (the only kind this path handles) always carries a ``Pointer``,
        # which is what exposes ``llvm_ptr``/``max_alignment``.
        iterator = cast("cute.Pointer", base.iterator)
        log().info(
            "_ArrayImpl._init_from_cute_tensor: shape=%s, "
            "stride=%s, element_type=%s, "
            "memspace=%s, addrspace=%s, iterator.llvm_ptr=%s, iterator.max_alignment=%s",
            base.shape,
            base.stride,
            base.element_type,
            base.memspace,
            addrspace,
            iterator.llvm_ptr,
            iterator.max_alignment,
        )

        self._shape = cast("tuple[int, ...]", base.shape)
        self._strides = cast("tuple[int, ...]", base.stride)

        if self._dtype is None:
            self._dtype = base.element_type
            self._mlir_type = base.element_type.mlir_type

        if addrspace is None:
            self._addrspace = base.memspace

        self._base = iterator.llvm_ptr
        self._original_base = self._base
        # Set alignment from tensor (may be overridden by user alignment later)
        self._alignment = iterator.max_alignment

    def _init_from_pointer(
        self, base: "cute.Pointer | Pointer | Int64 | Int32", addrspace: int | None
    ) -> None:
        import cutlass.cute as cute
        from .typing import Pointer

        log().info(
            f"_ArrayImpl._init_from_pointer: dtype={base.dtype}, addrspace={addrspace}"
        )
        if self._dtype is None:
            self._dtype = base.dtype

        # Always set mlir_type from dtype
        self._mlir_type = self._dtype.mlir_type

        if isinstance(base, cute.Pointer):
            log().info("cute.Pointer")
            if addrspace is None:
                self._addrspace = base.memspace.value
            self._base = base.llvm_ptr
            self._original_base = self._base
        elif isinstance(base, Pointer):
            log().info("cutlass.Pointer")
            if addrspace is None:
                self._addrspace = base.memspace.value
            self._base = ir.Value(base)
            self._original_base = self._base
        elif isinstance(base, (Int64, Int32)):
            log().info("Int64 or Int32")
            if addrspace is None:
                self._addrspace = AddressSpace.generic.value
            else:
                self._addrspace = addrspace
            log().info(f"self._addrspace={self._addrspace}")
            ptr_type = llvm.PointerType.get(self._addrspace)
            log().info(f"ptr_type={ptr_type}")
            self._base = llvm.inttoptr(ptr_type, base.ir_value())
            self._original_base = self._base
        else:
            raise ValueError(f"Unsupported base type for _ArrayImpl: {type(base)}")

    def _init_from_mlir_value(self, base: ir.OpResult) -> None:
        log().info(
            f"_ArrayImpl._init_from_mlir_value: base.type={base.type}, "
            f"self._dtype={self._dtype}"
        )

        if self._dtype is None:
            raise ValueError(
                "dtype must be provided when creating Array from raw MLIR value. "
                "Example: Array(mlir_val, dtype=Float32)"
            )

        self._mlir_type = self._dtype.mlir_type
        self._base = base
        self._original_base = base

    def _init_regular_pointer(self, base: object, addrspace: int | None) -> None:
        import cutlass.cute as cute
        from .typing import Pointer

        log().info(
            f"_ArrayImpl._init_regular_pointer: base={type(base).__name__}, "
            f"addrspace={addrspace}, self._dtype={self._dtype}"
        )

        if isinstance(base, cute.Tensor):
            self._init_from_cute_tensor(base, addrspace)
        elif isinstance(base, (cute.Pointer, Pointer, Int64, Int32)):
            self._init_from_pointer(base, addrspace)
        elif hasattr(base, "type"):
            self._init_from_mlir_value(base)
        else:
            raise ValueError(
                f"Unsupported base type for Array: {type(base).__name__}. "
                f"Expected: cute.Tensor, cute.Pointer, or MLIR value"
            )

    # =========================================================================
    # Verification
    # =========================================================================

    def _verify(self) -> None:
        import cutlass.cute as cute

        base_type = type(self._base).__name__ if self._base else None
        log().info(
            f"_ArrayImpl._verify: dtype={self._dtype}, mlir_type={self._mlir_type}, "
            f"base={base_type}, "
            f"shape={self._shape}, strides={self._strides}, addrspace={self._addrspace}"
        )
        if self._base is None:
            raise ValueError("Array base must be set after initialization")

        if hasattr(self._base, "type") and not isinstance(self._base, cute.Tensor):
            self._verify_mlir_value_pointer()
        else:
            self._verify_tensor_pointer()

        if self._shape is not None and self._strides is not None:
            if len(self._shape) != len(self._strides):
                raise ValueError(
                    f"Shape and strides must have the same length. "
                    f"shape={self._shape} (len={len(self._shape)}), "
                    f"strides={self._strides} (len={len(self._strides)})"
                )

    def _verify_tensor_pointer(self) -> None:
        if self._dtype is None:
            raise ValueError(
                "Array from cute.Tensor must have dtype set. "
                "This should be set automatically from tensor.element_type. "
                "dtype must be a NumericMeta type (e.g., Int32, Float16)"
            )

        if not isinstance(self._dtype, NumericMeta):
            raise ValueError(
                f"Array dtype must be a NumericMeta type, "
                f"got {type(self._dtype)}: {self._dtype}"
            )

        if not hasattr(self, "_mlir_type") or self._mlir_type is None:
            raise ValueError(
                "Array from cute.Tensor must have mlir_type set. "
                "This should be set automatically from tensor.element_type.mlir_type"
            )

        if not isinstance(self._mlir_type, ir.Type):
            raise ValueError(
                f"mlir_type must be an MLIR Type, got {type(self._mlir_type)}"
            )

        if self._mlir_type != self._dtype.mlir_type:
            raise ValueError(
                f"mlir_type ({self._mlir_type}) does not match dtype.mlir_type "
                f"({self._dtype.mlir_type})"
            )

        if not hasattr(self._base, "type"):
            raise ValueError(
                f"Array base must be an MLIR value with 'type' attribute, "
                f"got {type(self._base)}"
            )

        if self._shape is None:
            raise ValueError(
                "Array from cute.Tensor must have shape set. "
                "This should be set automatically from tensor.shape"
            )

        if self._strides is None:
            raise ValueError(
                "Array from cute.Tensor must have strides set. "
                "This should be set automatically from tensor.stride"
            )

    def _verify_mlir_value_pointer(self) -> None:
        if not hasattr(self._base, "type"):
            raise ValueError(
                f"MLIR value pointer base must be an MLIR value with 'type' attribute, "
                f"got {type(self._base)}"
            )

        if not hasattr(self, "_mlir_type") or self._mlir_type is None:
            raise ValueError(
                "MLIR value pointer must have mlir_type set. "
                "This should be set when creating the pointer from an MLIR value"
            )

        if not isinstance(self._mlir_type, ir.Type):
            raise ValueError(
                f"mlir_type must be an MLIR Type, got {type(self._mlir_type)}"
            )

        if self._dtype is not None:
            if not isinstance(self._dtype, NumericMeta):
                raise ValueError(
                    f"Array dtype must be a NumericMeta type, "
                    f"got {type(self._dtype)}: {self._dtype}"
                )
            if (
                not _is_subword_float(self._dtype)
                and self._mlir_type != self._dtype.mlir_type
            ):
                raise ValueError(
                    f"mlir_type ({self._mlir_type}) does not match dtype.mlir_type "
                    f"({self._dtype.mlir_type})"
                )

    # =========================================================================
    # Utility Methods
    # =========================================================================

    @staticmethod
    def _compute_strides(shape: Tuple[int, ...]) -> Tuple[int, ...]:
        """Compute row-major strides for the given shape."""
        return _compute_row_major_strides(shape)

    def _gep(
        self,
        *indices: Union[int, Int32, Int64],
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "_ArrayImpl[DSLGenericType]":
        """Compute pointer offset using LLVM GEP."""
        base_type = self._base.type if hasattr(self._base, "type") else "N/A"
        log().info(
            "_ArrayImpl._gep: indices=%s, shape=%s, "
            "strides=%s, dtype=%s, "
            "mlir_type=%s, base.type=%s",
            indices,
            self._shape,
            self._strides,
            self._dtype,
            self._mlir_type,
            base_type,
        )
        if self._strides is not None and len(indices) > 1:
            # Multi-index case: compute linear offset from strides
            if len(indices) != len(self._strides):
                raise ValueError(
                    f"Number of indices ({len(indices)}) doesn't match "
                    f"number of dimensions ({len(self._strides)})"
                )

            linear_offset = 0

            # Use 64-bit arithmetic for global memory (addrspace 0 or 1),
            # 32-bit for shared/local/constant memory
            is_64bit_addrspace = self._addrspace in (0, 1)
            for idx, stride in zip(indices, self._strides):
                if isinstance(idx, int):
                    if is_64bit_addrspace:
                        term = Int64(idx) * Int64(stride)
                    else:
                        term = Int32(idx) * Int32(stride)
                else:
                    if is_64bit_addrspace:
                        term = Int64(stride) * Int64(idx)
                    else:
                        term = Int32(stride) * idx

                if linear_offset is None:
                    linear_offset = term
                else:
                    linear_offset = linear_offset + term

            indices = (linear_offset,)

        static_indices = [
            i if isinstance(i, int) else MLIR_DYNAMIC_INDEX for i in indices
        ]
        dyn_indices = [i.ir_value() for i in indices if not isinstance(i, int)]

        new_addr = _gep(
            self._base,
            self._mlir_type,
            static_indices=static_indices,
            dynamic_indices=dyn_indices,
            loc=loc,
            ip=ip,
        )

        new_impl = _ArrayImpl.__new__(_ArrayImpl)
        new_impl._bounds_check = self._bounds_check
        new_impl._size_layout = self._size_layout
        new_impl._shape = self._shape
        new_impl._strides = self._strides
        new_impl._dtype = self._dtype
        new_impl._mlir_type = self._mlir_type
        new_impl._addrspace = self._addrspace
        new_impl._alignment = None
        new_impl._base = new_addr
        new_impl._original_base = new_addr

        new_impl._verify()
        return new_impl

    def _subpointer_from_index(
        self,
        idx_tuple: Tuple,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "_ArrayImpl[DSLGenericType]":
        """Create a subarray view from indexing with slices.

        For arr[i, :] on shape (V, H): returns Array with shape (H,)
        For arr[:, j] on shape (V, H): returns Array with shape (V,)
        For arr[i, j]: returns scalar (handled elsewhere)

        Slices (`:`) preserve that dimension, integers collapse it.
        """
        if self._shape is None or self._strides is None:
            # Fall back to simple GEP for arrays without shape info
            start_indices = []
            for idx in idx_tuple:
                if isinstance(idx, slice):
                    start = 0 if idx.start is None else idx.start
                    start_indices.append(start)
                elif isinstance(idx, (int, Int32, Int64)):
                    start_indices.append(idx)
                else:
                    raise TypeError(f"Unsupported index type in slice: {type(idx)}")
            if start_indices:
                if len(start_indices) == 1:
                    return self._gep(start_indices[0], loc=loc, ip=ip)
                return self._gep(*start_indices, loc=loc, ip=ip)
            return self

        # Compute new shape, strides, and linear offset
        new_shape = []
        new_strides = []
        linear_offset: Union[int, Int32, Int64] = 0

        for dim_idx, idx in enumerate(idx_tuple):
            if dim_idx >= len(self._shape):
                raise IndexError(
                    f"Too many indices for array with {len(self._shape)} dimensions"
                )

            dim_size = self._shape[dim_idx]
            dim_stride = self._strides[dim_idx]

            if isinstance(idx, slice):
                # Slice preserves dimension
                start = 0 if idx.start is None else idx.start
                stop = dim_size if idx.stop is None else idx.stop

                # Compute new dimension size
                if isinstance(start, int) and isinstance(stop, int):
                    new_dim_size = stop - start
                else:
                    # Dynamic slice - keep original size for now
                    new_dim_size = dim_size

                new_shape.append(new_dim_size)
                new_strides.append(dim_stride)

                # Add to linear offset
                if isinstance(start, int):
                    linear_offset += start * dim_stride
                elif isinstance(start, Int64):
                    if isinstance(linear_offset, (int, Int32)):
                        linear_offset = Int64(linear_offset)
                    linear_offset = linear_offset + start * Int64(dim_stride)
                elif isinstance(start, Int32):
                    if isinstance(linear_offset, int):
                        linear_offset = Int32(linear_offset)
                    linear_offset = linear_offset + start * Int32(dim_stride)

            elif isinstance(idx, (int, Int32, Int64)):
                # Integer index collapses dimension
                if isinstance(idx, int):
                    linear_offset += idx * dim_stride
                elif isinstance(idx, Int64):
                    if isinstance(linear_offset, (int, Int32)):
                        linear_offset = Int64(linear_offset)
                    linear_offset = linear_offset + idx * Int64(dim_stride)
                else:
                    if isinstance(linear_offset, int):
                        linear_offset = Int32(linear_offset)
                    linear_offset = linear_offset + idx * Int32(dim_stride)
                # Don't add to new_shape/new_strides - dimension is collapsed

            else:
                raise TypeError(f"Unsupported index type: {type(idx)}")

        # Add remaining dimensions that weren't indexed
        for dim_idx in range(len(idx_tuple), len(self._shape)):
            new_shape.append(self._shape[dim_idx])
            new_strides.append(self._strides[dim_idx])

        # Compute new pointer
        if isinstance(linear_offset, int):
            if linear_offset == 0:
                new_base = self._base
            else:
                new_base = _gep(
                    self._base,
                    self._mlir_type,
                    static_indices=[linear_offset],
                    loc=loc,
                    ip=ip,
                )
        else:
            # Dynamic offset
            new_base = _gep(
                self._base,
                self._mlir_type,
                static_indices=[MLIR_DYNAMIC_INDEX],
                dynamic_indices=[linear_offset.ir_value()],
                loc=loc,
                ip=ip,
            )

        # Create new ArrayImpl with updated shape
        new_impl = _ArrayImpl.__new__(_ArrayImpl)
        new_impl._bounds_check = self._bounds_check
        new_impl._size_layout = self._size_layout
        new_impl._shape = tuple(new_shape) if new_shape else (1,)
        new_impl._strides = tuple(new_strides) if new_strides else (1,)
        new_impl._dtype = self._dtype
        new_impl._mlir_type = self._mlir_type
        new_impl._addrspace = self._addrspace
        new_impl._alignment = None
        new_impl._base = new_base
        new_impl._original_base = new_base

        return new_impl

    def _address_space_str(self) -> str:
        return str(self.space)

    # =========================================================================
    # Public Properties (accessed via Array wrapper)
    # =========================================================================

    @property
    def dtype(self) -> Type[Numeric] | None:
        """The DSL element type (e.g., Float32, Int32)."""
        return self._dtype

    @property
    def shape(self) -> Tuple[int, ...] | None:
        """The shape of the array."""
        return self._shape

    @property
    def strides(self) -> Tuple[int, ...] | None:
        """The strides for each dimension."""
        return self._strides

    def ir_value(self) -> ir.OpResult:
        """Get underlying MLIR pointer value (internal DSL use)."""
        arr = self._gep(0)
        return arr._base

    @property
    def mlir_type(self) -> ir.Type:
        """The MLIR element type."""
        return self._mlir_type

    @property
    def space(self) -> AddressSpace:
        """The memory space."""
        try:
            return AddressSpace(self._addrspace)
        except ValueError:
            # Unknown address space, return as GENERIC
            return AddressSpace.generic

    # =========================================================================
    # Indexing Operations
    # =========================================================================

    def _parse_multidim_slice(self, idx: Index) -> tuple[tuple, slice | None]:
        """Parse multi-dimensional index to extract prefix indices and trailing slice.

        Supports:
            - arr[row, col:count] -> ((row,), slice(col, count))
            - arr[i, j, k, start:count] -> ((i, j, k), slice(start, count))

        Args:
            idx: Index which may be a tuple with scalar indices and a trailing slice.

        Returns:
            Tuple of (prefix_indices, slice_or_none).
        """
        if not isinstance(idx, tuple):
            return (), None

        elements = list(idx)

        # Check if last element is a slice
        if elements and isinstance(elements[-1], slice):
            slice_idx = elements[-1]
            prefix = tuple(elements[:-1])
            return prefix, slice_idx

        return (), None

    def __getitem__(
        self,
        idx: Index,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[DSLGenericType, "Vector", "_ArrayImpl[DSLGenericType]"]:
        """Load value(s) from the array.

        Alignment is determined by the array's `align` property, which is set
        when the array is created. See `align` property for alignment sources.

        Returns:
            - Scalar DSL type for single element access (arr[i])
            - Vector for slice access (arr[start:count]) - REGISTER
            - _ArrayImpl for open-ended slices (arr[start:]) - memory view

        Example:
            val = arr[5]           # scalar load
            vec = arr[offset:8]    # vector load into registers
            view = arr[start:]     # memory view (no copy)
        """
        log().info(
            f"_ArrayImpl.__getitem__: idx={idx}, "
            f"dtype={self._dtype}, shape={self._shape}"
        )
        assert self._dtype is not None
        if isinstance(idx, slice):
            if idx.start is not None and idx.stop is not None and idx.step is None:
                # arr[start:count] - load vector into registers, return Vector
                if not isinstance(idx.stop, int):
                    raise TypeError(
                        f"Vector count must be a Python int, "
                        f"got {type(idx.stop).__name__}. "
                        f"Use arr[start:count] where count is a constant."
                    )
                count = idx.stop
                if count <= 0:
                    raise ValueError(f"Invalid vector count: {count}")
                ptr = self._gep(idx.start, loc=loc, ip=ip)
                vec_type = ir.VectorType.get([count], self._mlir_type)
                # Alignment contract: the vectorized slice load claims the array's own
                # alignment (`self.align`) so it can lower to a single wide (e.g. 128-bit)
                # transaction. This assumes `start` keeps the offset as-aligned as the base
                # -- which holds whenever `start` is a multiple of `count` (the common
                # thread-strided `arr[tid*V : V]` pattern). For an arbitrarily-offset slice
                # that breaks that, pass an explicit alignment via the `arr[start:count, align]`
                # form instead of relying on the base alignment here.
                vec_val = llvm.load(
                    vec_type, ptr._base, alignment=self.align, loc=loc, ip=ip
                )
                # Unwrap if result got wrapped by value caster
                if hasattr(vec_val, "ir_value"):
                    vec_val = vec_val.ir_value()

                # Return Vector (REGISTER)
                return Vector(vec_val, dtype=self._dtype, loc=loc, ip=ip)

            # Open-ended slice: arr[start:] - return memory view
            return self._subpointer_from_index((idx,), loc=loc, ip=ip)

        if isinstance(idx, (int, Int32, Int64)):
            # Single element access - return scalar DSL type
            ptr = self._gep(idx, loc=loc, ip=ip)
            elem_align = self._elem_align()
            val = llvm.load(
                self._mlir_type, ptr._base, alignment=elem_align, loc=loc, ip=ip
            )
            return cast("DSLGenericType", self._dtype(val, loc=loc, ip=ip))

        if isinstance(idx, tuple):
            # Check for alignment suffix: arr[..., alignment]
            # If last element is an int and there's at least one slice, it's alignment
            alignment = self.align
            idx_without_align: Any = idx
            if (
                len(idx) >= 2
                and isinstance(idx[-1], int)
                and any(isinstance(i, slice) for i in idx[:-1])
            ):
                alignment = idx[-1]
                idx_without_align = idx[:-1]
                # If only one element left, unwrap it
                if len(idx_without_align) == 1:
                    idx_without_align = idx_without_align[0]

            # Handle unwrapped single slice case: arr[start:count, alignment]
            if isinstance(idx_without_align, slice):
                if (
                    idx_without_align.start is not None
                    and idx_without_align.stop is not None
                    and idx_without_align.step is None
                ):
                    if not isinstance(idx_without_align.stop, int):
                        raise TypeError(
                            f"Vector count must be a Python int, "
                            f"got {type(idx_without_align.stop).__name__}."
                        )
                    count = idx_without_align.stop
                    if count <= 0:
                        raise ValueError(f"Invalid vector count: {count}")
                    ptr = self._gep(
                        self._as_gep_index(idx_without_align.start), loc=loc, ip=ip
                    )
                    vec_type = ir.VectorType.get([count], self._mlir_type)
                    vec_val = llvm.load(
                        vec_type, ptr._base, alignment=alignment, loc=loc, ip=ip
                    )
                    # Unwrap if result got wrapped by value caster
                    if hasattr(vec_val, "ir_value"):
                        vec_val = vec_val.ir_value()
                    return Vector(vec_val, dtype=self._dtype, loc=loc, ip=ip)

            # Check for multi-dimensional vector load: arr[row, col:count] or arr[row, col:count, align]
            parse_idx = (
                idx_without_align
                if isinstance(idx_without_align, tuple)
                else (idx_without_align,)
            )
            prefix_indices, slice_idx = self._parse_multidim_slice(parse_idx)
            if slice_idx is not None:
                # Multi-dimensional case: arr[i, j, start:count]
                if (
                    slice_idx.start is not None
                    and slice_idx.stop is not None
                    and slice_idx.step is None
                ):
                    if not isinstance(slice_idx.stop, int):
                        raise TypeError(
                            f"Vector count must be a Python int, "
                            f"got {type(slice_idx.stop).__name__}."
                        )
                    count = slice_idx.stop
                    if count <= 0:
                        raise ValueError(f"Invalid vector count: {count}")
                    # Compute pointer: first apply prefix indices, then slice start
                    if prefix_indices:
                        prefix_ptr = self._gep(*prefix_indices, loc=loc, ip=ip)
                        ptr = prefix_ptr._gep(
                            self._as_gep_index(slice_idx.start), loc=loc, ip=ip
                        )
                    else:
                        ptr = self._gep(
                            self._as_gep_index(slice_idx.start), loc=loc, ip=ip
                        )
                    vec_type = ir.VectorType.get([count], self._mlir_type)
                    vec_val = llvm.load(
                        vec_type, ptr._base, alignment=alignment, loc=loc, ip=ip
                    )
                    # Unwrap if result got wrapped by value caster
                    if hasattr(vec_val, "ir_value"):
                        vec_val = vec_val.ir_value()
                    return Vector(vec_val, dtype=self._dtype, loc=loc, ip=ip)
                # Open-ended multi-dim slice - return memory view
                return self._subpointer_from_index(
                    idx_without_align
                    if isinstance(idx_without_align, tuple)
                    else (idx_without_align,),
                    loc=loc,
                    ip=ip,
                )

            if any(isinstance(i, slice) for i in idx):
                # Tuple with slices - return memory view
                return self._subpointer_from_index(idx, loc=loc, ip=ip)
            # Multi-dimensional index - return scalar DSL type
            ptr = self._gep(
                *cast("tuple[int | Int32 | Int64, ...]", idx), loc=loc, ip=ip
            )
            elem_align = self._elem_align()
            val = llvm.load(
                self._mlir_type, ptr._base, alignment=elem_align, loc=loc, ip=ip
            )
            return cast("DSLGenericType", self._dtype(val, loc=loc, ip=ip))

        raise TypeError(f"Unsupported index type: {type(idx)}")

    def __setitem__(
        self,
        idx: Index,
        value: DSLGenericType,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Store value(s) to the array.

        Alignment is determined by the array's `align` property, which is set
        when the array is created. See `align` property for alignment sources.

        Args:
            idx: Index or slice specifying where to store.
            value: Value to store (scalar, tuple, or Vector).

        Example:
            arr[5] = Float32(1.0)              # scalar store
            arr[offset:8] = vec                # vector store
            arr[offset:4] = (1.0, 2.0, 3.0, 4.0)  # tuple store
        """
        log().info(
            f"_ArrayImpl.__setitem__: idx={idx}, "
            f"value_type={type(value).__name__}, dtype={self._dtype}, "
            f"shape={self._shape}"
        )

        # Reject lists - use tuples instead for literal sequences
        if isinstance(value, list):
            raise TypeError(
                "Cannot assign a list to array. Use a tuple instead: "
                "arr[start:count] = (v0, v1, ...) instead of arr[...] = [...]"
            )

        # Handle Vector: extract vector value and store directly
        if isinstance(value, Vector):
            # Check for alignment suffix: arr[..., alignment] = vec
            # If last element is an int and there's at least one slice, it's alignment
            alignment = self.align
            idx_without_align: Any = idx
            if (
                isinstance(idx, tuple)
                and len(idx) >= 2
                and isinstance(idx[-1], int)
                and any(isinstance(i, slice) for i in idx[:-1])
            ):
                alignment = idx[-1]
                idx_without_align = idx[:-1]
                # If only one element left, unwrap it
                if len(idx_without_align) == 1:
                    idx_without_align = idx_without_align[0]

            # Handle unwrapped single slice case: arr[start:count, alignment] = vec
            if isinstance(idx_without_align, slice):
                if (
                    idx_without_align.start is None
                    or idx_without_align.stop is None
                    or idx_without_align.step is not None
                ):
                    raise TypeError(
                        "Vector assignment requires arr[start:count] = vec syntax"
                    )
                count = idx_without_align.stop
                if not isinstance(count, int):
                    raise TypeError(
                        f"Vector count must be a Python int, got {type(count).__name__}."
                    )
                if value._count != count:
                    raise TypeError(
                        f"Vector length ({value._count}) must match slice count ({count})"
                    )
                ptr = self._gep(self._as_gep_index(idx_without_align.start))
                # Vector inherits from DSLIRValue, so IS the value
                llvm.store(value, ptr._base, alignment=alignment)
                return

            # Check for multi-dimensional slice: arr[row, col:count] or arr[row, col:count, align] = vec
            parse_idx = (
                idx_without_align
                if isinstance(idx_without_align, tuple)
                else (idx_without_align,)
            )
            prefix_indices, slice_idx = self._parse_multidim_slice(parse_idx)
            if slice_idx is not None:
                # Multi-dimensional case: arr[i, j, start:count] = vec
                if (
                    slice_idx.start is None
                    or slice_idx.stop is None
                    or slice_idx.step is not None
                ):
                    raise TypeError(
                        "Vector assignment requires arr[..., start:count] = vec syntax"
                    )
                count = slice_idx.stop
                if not isinstance(count, int):
                    raise TypeError(
                        f"Vector count must be a Python int, got {type(count).__name__}."
                    )
                if value._count != count:
                    raise TypeError(
                        f"Vector length ({value._count}) must match slice count ({count})"
                    )
                # Compute pointer: first apply prefix indices, then slice start
                if prefix_indices:
                    # Use _gep with prefix indices to get row pointer
                    prefix_ptr = self._gep(*prefix_indices)
                    # Then apply slice start offset
                    ptr = prefix_ptr._gep(self._as_gep_index(slice_idx.start))
                else:
                    ptr = self._gep(self._as_gep_index(slice_idx.start))
                # Vector inherits from DSLIRValue, so IS the value
                llvm.store(value, ptr._base, alignment=alignment)
                return

            # Not a valid slice pattern for Vector
            raise TypeError(
                "Vector assignment requires slice indexing. "
                "Use arr[start:count] = vector_impl or "
                "arr[row, col:count] = vector_impl"
            )

        # Handle tuples: convert to vector and store
        if isinstance(value, tuple):
            if not isinstance(idx, slice):
                raise TypeError(
                    "Tuple assignment requires slice indexing. "
                    "Use arr[start:count] = (v0, v1, ...)"
                )
            if idx.start is None or idx.stop is None or idx.step is not None:
                raise TypeError(
                    "Tuple assignment requires arr[start:count] = (values,) syntax"
                )
            count = idx.stop
            if not isinstance(count, int):
                raise TypeError(
                    f"Vector count must be a Python int, got {type(count).__name__}. "
                    f"Use arr[start:count] = (values,) where count is constant."
                )
            if len(value) != count:
                raise TypeError(
                    f"Tuple length ({len(value)}) must match slice count ({count})"
                )
            # Create vector from tuple elements using vector.from_elements
            vec_type = ir.VectorType.get([count], self._mlir_type)
            elements = [self._make_scalar_ir(v) for v in value]
            ir_value = vector.from_elements(vec_type, elements)

            start = idx.start if isinstance(idx.start, Int32) else Int32(idx.start)
            ptr = self._gep(start)
            elem_align = self._elem_align()
            llvm.store(ir_value, ptr._base, alignment=elem_align)
            return

        # Convert value to IR value for scalar/vector assignment
        if hasattr(value, "type"):
            # Raw MLIR value - convert through DSL type to ensure proper type coercion
            # (e.g., extend i32 to i64 when storing into Int64 array)
            ir_value = self._make_scalar_ir(value)
        else:
            ir_value = self._make_scalar_ir(value)

        if isinstance(idx, slice):
            if idx.start is not None and idx.stop is not None and idx.step is None:
                if not isinstance(idx.stop, int):
                    raise TypeError(
                        f"Vector count must be a Python int, "
                        f"got {type(idx.stop).__name__}. "
                        f"Use arr[start:count] = vec where count is constant."
                    )
                count = idx.stop
                start = idx.start if isinstance(idx.start, Int32) else Int32(idx.start)
                ptr = self._gep(start)

                vec_type = ir.VectorType.get([count], self._mlir_type)
                if not ir.VectorType.isinstance(ir_value.type):
                    # Broadcast scalar to vector
                    ir_value = vector.broadcast(vec_type, ir_value)

                elem_align = self._elem_align()
                llvm.store(ir_value, ptr._base, alignment=elem_align)
                return
            raise TypeError(
                "Cannot store to open-ended slice (use arr[start:count] = vec)"
            )

        if isinstance(idx, (int, Int32, Int64)):
            ptr = self._gep(idx)
            elem_align = self._elem_align()
            llvm.store(ir_value, ptr._base, alignment=elem_align)
            return

        if isinstance(idx, tuple):
            if any(isinstance(i, slice) for i in idx):
                raise TypeError("Cannot store to a sliced array view")
            ptr = self._gep(*cast("tuple[int | Int32 | Int64, ...]", idx))
            elem_align = self._elem_align()
            llvm.store(ir_value, ptr._base, alignment=elem_align)
            return

        raise TypeError(f"Unsupported index type for store: {type(idx)}")

    # =========================================================================
    # Explicit Load/Store
    # =========================================================================

    def load(
        self,
        idx: "ScalarIndex" = 0,
        vector_size: int | None = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        is_invariant: bool = False,
        is_invariant_group: bool = False,
        ordering: MemOrdering = MemOrdering.NOT_ATOMIC,
        syncscope: MemScope | None = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> DSLGenericType:
        """Load value(s) from the array at specified index.

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.load(5)
                 - Tuple for multi-dim: arr.load((i, j, k))
            vector_size: If specified, load this many elements as a vector.
            alignment: One-time alignment override in bytes. If None, uses the
                array's default alignment (self.align). This does NOT change
                the array's stored alignment.
            is_volatile: Whether load is volatile (prevents optimization).
            is_nontemporal: Hint that data won't be reused soon (streaming).
            is_invariant: Whether loaded value is known to be invariant.
            is_invariant_group: Whether to group invariant loads.
            ordering: Atomic memory ordering semantics.
            syncscope: Synchronization scope for atomic operations.
        """
        # Get pointer to the element at idx (supports multi-dim tuple)
        if isinstance(idx, tuple):
            ptr = self._gep(*idx)._base
        elif isinstance(idx, int) and idx == 0:
            ptr = self._base
        else:
            ptr = self._gep(idx)._base

        effective_alignment = self._effective_alignment(alignment)

        # Determine result type
        if vector_size is None:
            result_type = self._mlir_type
        else:
            result_type = ir.VectorType.get([vector_size], self._mlir_type)

        # Build load with memory attributes
        result = llvm.load(
            result_type,
            ptr,
            alignment=effective_alignment,
            volatile_=is_volatile,
            nontemporal=is_nontemporal if is_nontemporal else None,
            invariant=is_invariant,
            invariant_group=is_invariant_group,
            ordering=ordering.value if ordering != MemOrdering.NOT_ATOMIC else None,
            syncscope=syncscope.value if syncscope else None,
            loc=loc,
            ip=ip,
        )
        return result

    def store(
        self,
        value: DSLGenericType,
        idx: "ScalarIndex" = 0,
        vector_size: int | None = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        ordering: MemOrdering = MemOrdering.NOT_ATOMIC,
        syncscope: MemScope | None = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Store value(s) to the array at specified index.

        Args:
            value: Value to store (scalar, tuple, or vector).
            idx: Starting index. Can be:
                 - Single int/Int32: arr.store(val, 5)
                 - Tuple for multi-dim: arr.store(val, (i, j, k))
            vector_size: Expected vector size (optional, inferred from tuple length).
            alignment: One-time alignment override in bytes. If None, uses the
                array's default alignment (self.align). This does NOT change
                the array's stored alignment.
            is_volatile: Whether store is volatile (prevents optimization).
            is_nontemporal: Hint that data won't be reused soon (streaming).
            ordering: Atomic memory ordering semantics.
            syncscope: Synchronization scope for atomic operations.
        """
        # Reject lists - use tuples as values (not to be confused with idx tuple)
        if isinstance(value, list):
            raise TypeError(
                "Cannot store a list. Use a tuple instead: "
                "arr.store((v0, v1, ...), idx) instead of arr.store([...], idx)"
            )

        # Get pointer to the element at idx (supports multi-dim tuple)
        if isinstance(idx, tuple):
            ptr = self._gep(*idx)._base
        elif isinstance(idx, int) and idx == 0:
            ptr = self._base
        else:
            ptr = self._gep(idx)._base

        effective_alignment = self._effective_alignment(alignment)

        # Handle tuples: convert to vector and store
        if isinstance(value, tuple):
            count = len(value)
            if vector_size is not None and vector_size != count:
                raise TypeError(
                    f"Tuple length ({count}) must match vector_size ({vector_size})"
                )
            vec_type = ir.VectorType.get([count], self._mlir_type)
            elements = [self._make_scalar_ir(v) for v in value]
            ir_value = vector.from_elements(vec_type, elements, loc=loc, ip=ip)
        elif hasattr(value, "ir_value"):
            ir_value = value.ir_value()
        elif hasattr(value, "type"):
            # Check if it needs type coercion for vector store
            if vector_size is not None:
                vec_type = ir.VectorType.get([vector_size], self._mlir_type)
                if not ir.VectorType.isinstance(value.type):
                    # Splat scalar to vector
                    scalar_val = self._make_scalar_ir(value)
                    ir_value = vector.broadcast(vec_type, scalar_val, loc=loc, ip=ip)
                else:
                    ir_value = value
            else:
                ir_value = self._make_scalar_ir(value)
        else:
            ir_value = self._make_scalar_ir(value)

        llvm.store(
            ir_value,
            ptr,
            alignment=effective_alignment,
            volatile_=is_volatile,
            nontemporal=is_nontemporal if is_nontemporal else None,
            ordering=ordering.value if ordering != MemOrdering.NOT_ATOMIC else None,
            syncscope=syncscope.value if syncscope else None,
            loc=loc,
            ip=ip,
        )

    # =========================================================================
    # Masked Load/Store
    # =========================================================================

    def masked_load(
        self,
        idx: "ScalarIndex",
        count: int,
        mask: Union["Vector", "_ArrayImpl"],
        default: Optional[DSLGenericType] = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """
        Load elements from memory with a mask.

        Elements where the mask is True are loaded from memory.
        Elements where the mask is False use the default value (or are undefined).

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.masked_load(5, ...)
                 - Tuple for multi-dim: arr.masked_load((i, j, k), ...)
            count: Number of elements to load
            mask: Boolean vector (Array or Vector with i1 elements)
            default: Default value for masked-out lanes (optional)
            alignment: One-time alignment override in bytes. If None, uses the
                array's default alignment (self.align). This does NOT change
                the array's stored alignment.
            is_volatile: Whether load is volatile (prevents optimization)
            is_nontemporal: Hint that data won't be reused soon (streaming)

        Returns:
            Vector containing the loaded (and default) values.

        Example:
            mask = indices < valid_count
            data = arr.masked_load(0, 4, mask, default=Float16(0))
        """
        log().info(
            f"_ArrayImpl.masked_load: idx={idx}, count={count}, dtype={self._dtype}"
        )

        # Get pointer at idx (supports multi-dim tuple)
        if isinstance(idx, tuple):
            ptr = self._gep(*idx)
        elif isinstance(idx, int) and idx == 0:
            ptr = self
        else:
            ptr = self._gep(idx)

        effective_alignment = self._effective_alignment(alignment)

        # Get mask IR value - must be a boolean Array or Vector
        if isinstance(mask, Vector):
            # Vector inherits from DSLIRValue, so IS the value
            mask_val = mask
        elif isinstance(mask, _ArrayImpl):
            # Load each boolean and build vector<N x i1>
            # Booleans are stored as individual bytes, so we can't do a packed vector load
            i1_type = ir.IntegerType.get_signless(1)
            mask_vec_type = ir.VectorType.get([count], i1_type)
            mask_scalars = []
            for i in range(count):
                elem_ptr = mask._gep(i)
                elem_val = llvm.load(i1_type, elem_ptr._base, loc=loc, ip=ip)
                mask_scalars.append(elem_val)
            mask_val = vector.from_elements(mask_vec_type, mask_scalars, loc=loc, ip=ip)
        else:
            raise TypeError(f"mask must be a boolean Array or Vector, got {type(mask)}")

        # Prepare pass_thru
        vec_type = ir.VectorType.get([count], self._mlir_type)
        if default is not None:
            if hasattr(default, "ir_value"):
                default_scalar = default.ir_value()
            else:
                default_scalar = self._make_scalar_ir(default)
            pass_thru = vector.broadcast(vec_type, default_scalar, loc=loc, ip=ip)
        else:
            pass_thru = None

        # Call masked load intrinsic
        # Note: LLVM masked_load doesn't support volatile/nontemporal directly,
        # but we document them for future extensions or alternative implementations
        result = llvm.intr_masked_load(
            vec_type,
            ptr._base,
            mask_val,
            effective_alignment,
            pass_thru=pass_thru,
            loc=loc,
            ip=ip,
        )
        # Unwrap if result got wrapped by value caster
        if hasattr(result, "ir_value"):
            result = result.ir_value()

        return Vector(result, dtype=self._dtype)

    def masked_store(
        self,
        idx: "ScalarIndex",
        value: Union["Vector", "_ArrayImpl"],
        mask: Union["Vector", "_ArrayImpl"],
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Store elements to memory with a mask.

        Only elements where the mask is True are written to memory.
        Elements where the mask is False are not modified.

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.masked_store(5, ...)
                 - Tuple for multi-dim: arr.masked_store((i, j, k), ...)
            value: Vector of values to store (Vector)
            mask: Boolean vector (Array or Vector with i1 elements)
            alignment: One-time alignment override in bytes. If None, uses the
                array's default alignment (self.align). This does NOT change
                the array's stored alignment.
            is_volatile: Whether store is volatile (prevents optimization)
            is_nontemporal: Hint that data won't be reused soon (streaming)

        Example:
            arr.masked_store(0, data, mask)
        """
        log().info(f"_ArrayImpl.masked_store: idx={idx}, dtype={self._dtype}")

        # Get pointer at idx (supports multi-dim tuple)
        if isinstance(idx, tuple):
            ptr = self._gep(*idx)
        elif isinstance(idx, int) and idx == 0:
            ptr = self
        else:
            ptr = self._gep(idx)

        effective_alignment = self._effective_alignment(alignment)

        # Get value IR - Vector inherits from DSLIRValue, so IS the value
        if isinstance(value, Vector):
            value_ir = value
        elif hasattr(value, "ir_value"):
            value_ir = value.ir_value()
        else:
            raise TypeError(
                f"value must be Vector or have ir_value(), got {type(value)}"
            )

        # Get vector count from value
        value_vec_type = ir.VectorType(value_ir.type)
        count = value_vec_type.shape[0]

        # Get mask IR value - must be a boolean Array or Vector
        if isinstance(mask, Vector):
            # Vector inherits from DSLIRValue, so IS the value
            mask_val = mask
        elif isinstance(mask, _ArrayImpl):
            # Load each boolean and build vector<N x i1>
            # Booleans are stored as individual bytes, so we can't do a packed vector load
            i1_type = ir.IntegerType.get_signless(1)
            mask_vec_type = ir.VectorType.get([count], i1_type)
            mask_scalars = []
            for i in range(count):
                elem_ptr = mask._gep(i)
                elem_val = llvm.load(i1_type, elem_ptr._base, loc=loc, ip=ip)
                mask_scalars.append(elem_val)
            mask_val = vector.from_elements(mask_vec_type, mask_scalars, loc=loc, ip=ip)
        else:
            raise TypeError(f"mask must be a boolean Array or Vector, got {type(mask)}")

        # Call masked store intrinsic
        # Note: LLVM masked_store doesn't support volatile/nontemporal directly,
        # but we document them for future extensions or alternative implementations
        llvm.intr_masked_store(
            value_ir,
            ptr._base,
            mask_val,
            effective_alignment,
            loc=loc,
            ip=ip,
        )

    # =========================================================================
    # Debugging
    # =========================================================================

    def print_runtime(
        self,
        max_elements: int = 8,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Print the contents of the array (for debugging).

        Works on both CPU (@jit) and GPU (@kernel) contexts.
        Supports 1D, 2D, and 3D arrays.

        Args:
            max_elements: Maximum elements to print per dimension (default 8).
        """
        if self._shape is None:
            raise ValueError("Cannot print array: shape is not set")

        _print_runtime(self, self._shape, max_elements, loc=loc, ip=ip)

    def __repr__(self) -> str:
        addr_space = self._address_space_str()
        shape_str = f", shape={self._shape}" if self._shape is not None else ""
        return (
            f"Array(dtype={self._dtype}, address_space={addr_space}{shape_str}"
            f", alignment={self.align})"
        )


# =============================================================================
# Array Type - Mutable on memory
# =============================================================================


@dataclass(frozen=True, eq=False)
class Array(Generic[DSLGenericType]):
    """A GPU memory reference with shape, strides, and element type information.

    Array is the primary data structure for working with GPU memory in DSL.
    It provides a NumPy-like interface for accessing and manipulating data in
    local, shared, or global GPU memory.

    Creating Arrays
    ---------------
    The unified factory ``cutlass.Array(dtype, shape, space=...)`` selects the
    right allocator from ``space=`` and the call scope:

        # Kernel-body allocations:
        smem  = cutlass.Array(cutlass.Float16, (128, 64),
                          space=cutlass.AddressSpace.smem, alignment=128)
        scratch = cutlass.Array(cutlass.Float32, 8)              # default space=cutlass.AddressSpace.rmem
        local = cutlass.Array(cutlass.Float32, 8, space=cutlass.AddressSpace.rmem)  # same

        # Module scope (returns a global Array handle):
        WEIGHTS = cutlass.Array(cutlass.Float32, 1024,
                            space=cutlass.AddressSpace.gmem,
                            name="weights", init=data)

    Equivalent forms using the ``space=`` parameter:

        # Local memory (default) - uses cute.memref.alloca, entry-block hoisted
        local_arr = cutlass.Array(cutlass.Float32, 8)
        local_2d = cutlass.Array(cutlass.Float32, (4, 4))

        # Shared memory - accessible by all threads in a block
        shared_arr = cutlass.Array(cutlass.Float32, 256, space=cutlass.AddressSpace.smem, alignment=128)

        # From existing tensor/pointer
        arr = cutlass.make_array_view(tensor)

    Indexing and Slicing
    --------------------
    Arrays support flexible indexing for both reading and writing:

        # Single element access
        val = arr[i]           # Load element at index i
        arr[i] = 1.0           # Store 1.0 at index i

        # Multi-dimensional indexing
        val = arr[i, j]        # Load from 2D array
        arr[i, j] = val        # Store to 2D array

        # Vector operations with slices (arr[start:count])
        arr[0:4] = (1.0, 2.0, 3.0, 4.0)    # Store 4 elements as vector
        arr[4:4] = some_vector              # Store vector at offset 4

        # Aligned vector operations (arr[start:count, alignment])
        alignment = cutlass.align(16)           # 16-byte alignment for 8 x f16
        vec = arr[offset:8, alignment]      # Load with explicit alignment
        arr[offset:8, alignment] = vec      # Store with explicit alignment

    Alignment Hints
    ---------------
    By default, vector loads/stores use element alignment (e.g., 2 bytes for f16).
    When you know the address is better aligned, use explicit alignment for
    better performance (enables wider memory transactions):

        # Without alignment hint: alignment = 2 (element size for f16)
        vec = arr[offset:8]

        # With alignment hint: alignment = 16 (vector size: 8 * 2 bytes)
        alignment = cutlass.align(8 * 2)  # vec_size * sizeof(f16)
        vec = arr[offset:8, alignment]
        arr[offset:8, alignment] = vec

    Note: User must ensure the address is actually aligned. Incorrect alignment
    hints cause undefined behavior.

    Tuple Assignment
    ----------------
    Tuples are converted to vectors for efficient SIMD operations:

        arr = cutlass.Array(cutlass.Float32, 8)
        arr[0:4] = (1.0, 2.0, 3.0, 4.0)      # Stores 4 floats as vector
        arr[4:4] = constexpr_tuple          # Constexpr tuples work too

    Note: Lists are NOT supported - use tuples for literal sequences.

    Offset Views
    ------------
    Array is a memory handle; arithmetic operators are disabled (they raise
    DSLUserCodeError). Use the explicit offset API instead:

        sub = arr.subview(4)   # Sub-Array offset by 4 elements
        ptr = arr.data_ptr(4)  # Raw Pointer at element offset 4

    Explicit Load/Store
    -------------------
    For clarity or when working with pointers:

        val = arr.load(0)              # Load from index 0
        val = arr.load(0, 4)           # Load 4 elements as vector
        arr.store(1.0, 0)              # Store scalar at index 0
        arr.store((1.0, 2.0, 3.0), 4)  # Store tuple as vector at index 4

    Properties
    ----------
    - dtype: Element type (Float32, Int32, etc.)
    - shape: Tuple of dimensions, e.g., (32, 32)
    - strides: Memory strides for each dimension
    - space: Memory space (cutlass.AddressSpace.rmem, smem, gmem, cmem)

    Memory Spaces
    -------------
    - cutlass.AddressSpace.rmem: Thread-private stack memory (per-thread)
    - cutlass.AddressSpace.smem: Block-wide on-chip memory (fast, limited size)
    - cutlass.AddressSpace.gmem: Device-wide DRAM (large, high latency)
    - cutlass.AddressSpace.cmem: Read-only cached memory

    Examples
    --------
    Basic local array usage:

        @kernel
        def my_kernel():
            # Allocate 8 floats in register memory (default)
            arr = cutlass.Array(cutlass.Float32, 8)

            # Initialize with tuple (vectorized store)
            arr[0:4] = (1.0, 2.0, 3.0, 4.0)
            arr[4:4] = (5.0, 6.0, 7.0, 8.0)

            # Element access
            arr[0] = arr[0] + cutlass.Float32(1.0)

    Shared memory for thread cooperation:

        @kernel
        def reduce_kernel():
            # Allocate shared tile
            tile = cutlass.Array(cutlass.Float32, (32, 32), space=cutlass.AddressSpace.smem)
            tx, ty, _ = cute.arch.thread_idx()

            # Each thread writes its element
            tile[tx, ty] = compute_value(tx, ty)

            prims.nvvm.barrier_cta_sync(0)  # Synchronize threads

            # Now threads can read each other's values
            neighbor = tile[(tx + 1) % 32, ty]

    Pointer arithmetic for manual offset:

        @kernel
        def strided_access():
            arr = cutlass.Array(cutlass.Float32, 64)

            # Process in groups of 8
            for i in cutlass.range(8):
                ptr = arr + (i * 8)  # Offset to group start
                ptr.store((0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0), 0)
    """

    _impl: _ArrayImpl[DSLGenericType] = field(repr=False)

    # =========================================================================
    # Construction
    # =========================================================================

    def __new__(
        cls,
        base: object = None,
        shape: Tuple[int, ...] | int | None = None,
        *,
        _impl: _ArrayImpl[DSLGenericType] | None = None,
        dtype: Type[Numeric] | None = None,
        **kwargs: Any,
    ) -> "Array[DSLGenericType]":
        """Create an Array from an _impl, raw MLIR value, or factory call.

        Three modes:

        1. **Factory mode** — ``cutlass.Array(dtype, shape)`` or
           ``cutlass.Array(dtype, shape, space=...)``:
           routes to the registered array factory.  When ``base`` is a DSL
           dtype class and no ``space=`` is given, defaults to
           ``space=AddressSpace.rmem`` inside ``@cute.kernel``.

        2. **Internal mode** — ``Array(_impl=impl)``: wraps an existing
           ``_ArrayImpl`` instance.  Used by ``_from_impl`` and the MLIR
           value re-pack path.

        3. **Raw MLIR mode** — ``Array(mlir_value, shape=..., dtype=...,
           addrspace=...)``: wraps a raw MLIR pointer value into a new
           ``_ArrayImpl``.  Used by the internal allocator implementations
           (``_allocate_memory_smem``, ``_allocate_memory_rmem`` etc.).

        Args:
            base: Raw MLIR pointer (mode 3), DSL dtype class (mode 1, when
                ``space=`` is passed), or ``None`` (mode 2).
            shape: Allocation shape — tuple of ints or a single int.
                Positional in factory mode; keyword in raw MLIR mode.
            _impl: Internal implementation instance (mode 2).
            dtype: Element type for raw MLIR mode.
            **kwargs: Additional arguments.  ``space=`` triggers factory
                mode; everything else is forwarded to ``_ArrayImpl``.

        Raises:
            ValueError: If the call doesn't match one of the three modes.
        """
        # ---- Mode 1: factory dispatch (``space=`` is the discriminator) ----
        if "space" not in kwargs and isinstance(base, type) and hasattr(base, "width"):
            kwargs = dict(kwargs)
            kwargs["space"] = AddressSpace.rmem
        if "space" in kwargs:
            space = kwargs.pop("space")
            factory_dtype = base if base is not None else dtype
            factory_shape = shape
            return _make_array_via_factory(factory_dtype, factory_shape, space, kwargs)

        # ---- Mode 2: _impl is provided directly ----------------------------
        if _impl is not None:
            instance = object.__new__(cls)
            object.__setattr__(instance, "_impl", _impl)
            return instance

        # ---- Mode 3: raw MLIR value ----------------------------------------
        if base is not None:
            # Check for unsupported base types
            if isinstance(base, (int, float, str, bool)):
                raise ValueError(
                    f"Unsupported base type: {type(base).__name__}. "
                    "Array requires an MLIR pointer value. "
                    "Use cutlass.Array(dtype, shape) for register memory or "
                    "cutlass.Array(dtype, shape, space=cutlass.AddressSpace.rmem) for PTX local memory."
                )

            # Normalize an ``int`` shape to a 1-tuple — matches the documented
            # ``shape: int`` support and ``cutlass.Array(ptr, shape=N)`` as the
            # replacement for the old ``make_array_view_from_pointer``.
            if isinstance(shape, int):
                shape = (shape,)
            # Create _ArrayImpl from the raw value
            impl: _ArrayImpl[Any] = _ArrayImpl(
                base, dtype=dtype, shape=cast("Tuple[int, ...] | None", shape), **kwargs
            )
            instance = object.__new__(cls)
            object.__setattr__(instance, "_impl", impl)
            return instance

        raise ValueError(
            "Array requires either _impl or base argument. "
            "Use cutlass.Array(dtype, shape, space=...) instead."
        )

    def __init__(
        self,
        base: object = None,
        shape: Tuple[int, ...] | int | None = None,
        *,
        _impl: _ArrayImpl[DSLGenericType] | None = None,
        dtype: Type[Numeric] | None = None,
        **kwargs: Any,
    ) -> None:
        """No-op init - all initialization is done in __new__ for frozen dataclass."""
        # __new__ already set up self._impl, nothing to do here
        pass

    @classmethod
    def _from_impl(cls, impl: _ArrayImpl[DSLGenericType]) -> "Array[DSLGenericType]":
        """Internal: Create Array from an existing _ArrayImpl."""
        return cls(_impl=impl)

    # =========================================================================
    # DSL Infrastructure
    # =========================================================================

    def __extract_mlir_values__(self) -> list:
        return self._impl.__extract_mlir_values__()

    def __extract_mlir_attributes__(self) -> list:
        return self._impl.__extract_mlir_attributes__()

    def __new_from_mlir_values__(self, values: list) -> "Array[DSLGenericType]":
        new_impl = self._impl.__new_from_mlir_values__(values)
        return Array(_impl=new_impl)

    # =========================================================================
    # Indexing Operations
    # =========================================================================

    @dsl_user_op
    def __getitem__(
        self,
        idx: Index,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[DSLGenericType, "Vector", "Array[DSLGenericType]"]:
        """Load value(s) from the array.

        Args:
            idx: Index can be:
                - int or Int32: Single element access (arr[i])
                - tuple: Multi-dimensional access (arr[i, j])
                - slice: Vector load (arr[start:count])

        Returns:
            Single value for scalar index, Vector for slices, Array for views.

        Note:
            arr[start:count] returns Vector (register-backed values).

        Examples:
            val = arr[0]        # Load first element
            val = arr[i, j]     # Load from 2D array
            vec = arr[0:4]      # Load 4 elements as Vector
        """
        result = self._impl.__getitem__(idx, loc=loc, ip=ip)  # type: ignore[call-arg]
        # Result is automatically Vector (= Vector) or _ArrayImpl
        if isinstance(result, _ArrayImpl):
            return Array._from_impl(result)
        return result

    @dsl_user_op
    def __setitem__(
        self,
        idx: Index,
        value: DSLGenericType,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Store value(s) to the array.

        Args:
            idx: Index can be:
                - int or Int32: Single element store (arr[i] = v)
                - tuple: Multi-dimensional store (arr[i, j] = v)
                - slice: Vector store (arr[start:count] = vec)
            value: Value to store. Can be:
                - Scalar: cutlass.Float32(1.0) or Python literal 1.0
                - Tuple: (1.0, 2.0, 3.0, 4.0) - converted to vector
                - Vector: arr[0:4] = some_vector
                - Array: arr[0:4] = other_arr[0:4]

        Note:
            Lists are NOT supported - use tuples for sequences.

        Examples:
            arr[0] = 1.0                      # Store scalar
            arr[i, j] = val                   # Store to 2D position
            arr[0:4] = src[0:4]               # Copy 4 elements (efficient)
            arr[0:4] = (1.0, 2.0, 3.0, 4.0)   # Store tuple as vector
        """
        if self._impl._addrspace == AddressSpace.cmem.value:
            raise TypeError(
                "Cannot store to an Array in CONSTANT memory space. "
                "Constant memory is read-only from device code; "
                "use allocate_memory_global if you need a writable global."
            )
        # For Array, unwrap to get implementation; Vector IS the implementation
        store_value: Any = value._impl if isinstance(value, Array) else value
        # Explicit dunder call threads loc/ip through; mypy restricts keyword
        # args on __setitem__ calls even though the method declares them.
        self._impl.__setitem__(idx, store_value, loc=loc, ip=ip)  # type: ignore[call-arg]

    # =========================================================================
    # Arithmetic operators (intentionally disabled)
    # =========================================================================
    #
    # ``Array`` is a *memory handle*: it always wraps an ``_ArrayImpl`` (a typed
    # pointer into smem/local/global memory), never a register ``Vector``.
    # Slicing or loading (``arr[a:b]`` / ``arr.load()``) returns a ``Vector``,
    # and all element-wise vector math lives on that ``Vector`` type. The only
    # arithmetic these operators ever did was pointer-offset arithmetic
    # (``arr + n`` -> ``_gep(n)``), which was too easily confused with
    # element-wise addition. Every arithmetic operator therefore raises a
    # ``DSLUserCodeError`` that points at the explicit replacement APIs
    # (``subview`` / ``data_ptr``). See the offset-arithmetic migration that
    # moved every ``arr + n`` call-site to ``arr.subview(n)``.

    @staticmethod
    def _arithmetic_disabled(op: str) -> NoReturn:
        raise DSLUserCodeError(
            f"`Array` does not support the `{op}` operator. `Array` is a memory "
            f"handle (a typed pointer), not a numeric value. Pointer-offset "
            f"arithmetic on an Array was removed because it is too easily "
            f"confused with element-wise vector math.",
            suggestion=[
                "Sub-Array at an element offset:    arr.subview(n)",
                "Raw Pointer at an element offset:  arr.data_ptr(n)",
                "Element-wise math: load a Vector first, e.g. arr[a:b] or arr.load(...)",
            ],
        )

    def __add__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("+")

    def __radd__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("+")

    def __sub__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("-")

    def __rsub__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("-")

    def __iadd__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("+=")

    def __isub__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("-=")

    def __mul__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("*")

    def __rmul__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("*")

    def __truediv__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("/")

    def __rtruediv__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("/")

    def __floordiv__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("//")

    def __mod__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("%")

    def __pow__(self, other: object) -> NoReturn:
        Array._arithmetic_disabled("**")

    def __neg__(self) -> NoReturn:
        Array._arithmetic_disabled("unary -")

    # =========================================================================
    # Explicit Load/Store
    # =========================================================================

    @dsl_user_op
    def load(
        self,
        idx: int | Int32 | tuple[int | Int32, ...] = 0,
        vector_size: int | None = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        is_invariant: bool = False,
        is_invariant_group: bool = False,
        ordering: MemOrdering = MemOrdering.NOT_ATOMIC,
        syncscope: MemScope | None = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[DSLGenericType, "Vector"]:
        """Load value(s) from the array at the specified index.

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.load(5)
                 - Tuple for multi-dim: arr.load((i, j, k))
            vector_size: If specified, load this many elements as a Vector.
                         If None, load a single scalar element.
            alignment: Memory alignment in bytes (None = natural alignment).
            is_volatile: Whether load is volatile (prevents optimization).
            is_nontemporal: Hint that data won't be reused soon (streaming).
            is_invariant: Whether loaded value is known to be invariant.
            is_invariant_group: Whether to group invariant loads.
            ordering: Atomic memory ordering semantics.
            syncscope: Synchronization scope for atomic operations.

        Returns:
            Single value if vector_size is None, otherwise a Vector.

        Examples:
            arr = cutlass.Array(cutlass.Float32, 8)

            # Scalar load
            val = arr.load()         # Load arr[0]
            val = arr.load(3)        # Load arr[3]

            # Vector load
            vec = arr.load(0, 4)     # Load 4 elements starting at index 0
            vec = arr.load(4, 4)     # Load 4 elements starting at index 4

            # Multi-dimensional indexing
            arr2d = cutlass.make_array_view(tensor_2d)
            val = arr2d.load((i, j))  # Load at row i, column j

            # With alignment and streaming hint
            vec = arr.load(0, 4, alignment=16, is_nontemporal=True)
        """
        result = self._impl.load(
            idx,
            vector_size,
            alignment=alignment,
            is_volatile=is_volatile,
            is_nontemporal=is_nontemporal,
            is_invariant=is_invariant,
            is_invariant_group=is_invariant_group,
            ordering=ordering,
            syncscope=syncscope,
            loc=loc,
            ip=ip,
        )
        # Result is already Vector (= Vector) for vector loads
        return result

    @dsl_user_op
    def store(
        self,
        value: Union[DSLGenericType, "Vector"],
        idx: int | Int32 | tuple[int | Int32, ...] = 0,
        vector_size: int | None = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        ordering: MemOrdering = MemOrdering.NOT_ATOMIC,
        syncscope: MemScope | None = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Store value(s) to the array at the specified index.

        Args:
            value: Value to store. Can be:
                   - Scalar: 1.0, cutlass.Float32(1.0)
                   - Vector: A Vector of values
                   - Tuple: (1.0, 2.0, 3.0, 4.0) - stored as vector
            idx: Starting index. Can be:
                 - Single int/Int32: arr.store(val, 5)
                 - Tuple for multi-dim: arr.store(val, (i, j, k))
            vector_size: Expected vector size (optional, inferred from tuple length).
            alignment: Memory alignment in bytes (None = natural alignment).
            is_volatile: Whether store is volatile (prevents optimization).
            is_nontemporal: Hint that data won't be reused soon (streaming).
            ordering: Atomic memory ordering semantics.
            syncscope: Synchronization scope for atomic operations.

        Note: Lists are NOT supported - use tuples for sequences.

        Examples:
            arr = cutlass.Array(cutlass.Float32, 8)

            # Scalar store
            arr.store(1.0)           # Store 1.0 at arr[0]
            arr.store(2.0, 3)        # Store 2.0 at arr[3]

            # Vector store with tuple
            arr.store((1.0, 2.0, 3.0, 4.0), 0)    # Store 4 floats at arr[0:4]
            arr.store((5.0, 6.0, 7.0, 8.0), 4)    # Store 4 floats at arr[4:8]

            # Multi-dimensional indexing
            arr2d = cutlass.make_array_view(tensor_2d)
            arr2d.store(5.0, (i, j))  # Store at row i, column j

            # With streaming hint
            arr.store((1.0, 2.0, 3.0, 4.0), 0, is_nontemporal=True)
        """
        # Vector = Vector, no unwrapping needed
        self._impl.store(
            value,
            idx,
            vector_size,
            alignment=alignment,
            is_volatile=is_volatile,
            is_nontemporal=is_nontemporal,
            ordering=ordering,
            syncscope=syncscope,
            loc=loc,
            ip=ip,
        )

    # =========================================================================
    # Masked Operations
    # =========================================================================

    @dsl_user_op
    def masked_load(
        self,
        idx: int | Int32 | tuple[int | Int32, ...],
        count: int,
        mask: Union["Array", "Vector"],
        default: Optional[DSLGenericType] = None,
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Load elements with a mask.

        Elements where mask is True are loaded from memory.
        Elements where mask is False use the default value (or are undefined).

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.masked_load(5, ...)
                 - Tuple for multi-dim: arr.masked_load((i, j, k), ...)
            count: Number of elements to load
            mask: Boolean Vector or Array (i1 elements)
            default: Default value for masked-out lanes (optional)
            alignment: Memory alignment in bytes (None = natural alignment)
            is_volatile: Whether load is volatile (prevents optimization)
            is_nontemporal: Hint that data won't be reused soon (streaming)

        Returns:
            Vector containing the loaded values.

        Example:
            # Create mask from comparison
            indices = ...  # Vector of indices
            mask = indices < valid_count

            # Load with mask
            data = arr.masked_load(0, 4, mask, default=Float16(0))

            # Multi-dimensional with mask
            data = arr2d.masked_load((row, 0), 8, mask, default=Float16(0))
        """
        # ``Array`` masks unwrap to their ``_ArrayImpl``; ``Vector`` masks pass
        # through (the impl accepts ``Vector | _ArrayImpl``). A ``Vector`` has no
        # ``_impl``, so it must not be unwrapped.
        mask_arg = mask._impl if isinstance(mask, Array) else mask

        result = self._impl.masked_load(
            idx,
            count,
            mask_arg,
            default,
            alignment=alignment,
            is_volatile=is_volatile,
            is_nontemporal=is_nontemporal,
            loc=loc,
            ip=ip,
        )
        # Result is already Vector (= Vector)
        return result

    @dsl_user_op
    def masked_store(
        self,
        idx: int | Int32 | tuple[int | Int32, ...],
        value: Union["Array[DSLGenericType]", "Vector"],
        mask: Union["Array", "Vector"],
        *,
        alignment: int | None = None,
        is_volatile: bool = False,
        is_nontemporal: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Store elements with a mask.

        Only elements where mask is True are written to memory.
        Elements where mask is False are not modified.

        Args:
            idx: Starting index. Can be:
                 - Single int/Int32: arr.masked_store(5, ...)
                 - Tuple for multi-dim: arr.masked_store((i, j, k), ...)
            value: Vector or Array of values to store
            mask: Boolean Vector or Array (i1 elements)
            alignment: Memory alignment in bytes (None = natural alignment)
            is_volatile: Whether store is volatile (prevents optimization)
            is_nontemporal: Hint that data won't be reused soon (streaming)

        Example:
            # Store only valid elements
            arr.masked_store(0, data, mask)

            # Multi-dimensional with mask
            arr2d.masked_store((row, 0), data, mask)
        """
        # Array values/masks unwrap to their ``_ArrayImpl``; Vectors pass through.
        value_arg = value._impl if isinstance(value, Array) else value
        mask_arg = mask._impl if isinstance(mask, Array) else mask

        self._impl.masked_store(
            idx,
            value_arg,
            mask_arg,
            alignment=alignment,
            is_volatile=is_volatile,
            is_nontemporal=is_nontemporal,
            loc=loc,
            ip=ip,
        )

    # =========================================================================
    # Memory space cast
    # =========================================================================

    @dsl_user_op
    def tospace(
        self,
        # The body reads ``space.value``, so a concrete ``AddressSpace`` is
        # required here (a bare int has no ``.value``).
        space: AddressSpace,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Array":
        """
        Convert the array to a different memory space.
        """
        if space.value == self._impl.space.value:
            return self
        if self._impl.space.value != 0 and space.value != 0:
            raise ValueError(
                "tospace does not allow casting from non-generic memory space to "
                "another non-generic memory space"
            )
        result = self._impl._addrspacecast(space.value, loc=loc, ip=ip)
        new_impl = self._impl.__new_from_mlir_values__([result._base])
        new_impl._addrspace = space.value
        return Array._from_impl(new_impl)

    # =========================================================================
    # Debugging
    # =========================================================================

    @dsl_user_op
    def print_runtime(
        self,
        max_elements: int = 16,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Print array contents at runtime (for debugging).

        Inserts a print statement into the generated kernel that will
        display array contents when the kernel executes.

        Args:
            max_elements: Maximum number of elements to print (default: 16).

        Example:
            arr = cutlass.Array(cutlass.Float32, 8)
            arr[0:4] = (1.0, 2.0, 3.0, 4.0)
            arr.print_runtime()  # Prints: [1.0, 2.0, 3.0, 4.0, ...]
        """
        self._impl.print_runtime(max_elements, loc=loc, ip=ip)

    def __repr__(self) -> str:
        """Return string representation of the Array."""
        return repr(self._impl)

    def __iter__(self) -> NoReturn:
        """Arrays are not directly iterable.

        Raises:
            TypeError: Always raised. Use range(len(array)) instead.
        """
        raise TypeError(
            "cutlass.Array is not iterable for now. Possible to implement if needed. "
            "Please use range(len(array)) to iterate."
        )

    # =========================================================================
    # Properties
    # =========================================================================

    @property
    def dtype(self) -> Type[Numeric] | None:
        """Element data type (e.g., Float32, Int32, Float16)."""
        return self._impl.dtype

    @property
    def shape(self) -> Tuple[int, ...] | None:
        """Array dimensions as tuple, e.g., (32, 32) for 2D array."""
        return self._impl.shape

    @property
    def strides(self) -> Tuple[int, ...] | None:
        """Memory strides for each dimension (in elements)."""
        return getattr(self._impl, "strides", (1,))

    def ir_value(self) -> DSLIRValue:
        """Get underlying MLIR value (internal DSL use).

        For memory-backed Arrays: returns the base pointer.
        For register-backed Arrays: returns the vector SSA value.
        """
        return self._impl.ir_value()

    @property
    def space(self) -> AddressSpace:
        """Memory space where the array data resides.

        Values:
            cutlass.AddressSpace.generic: Generic address space
            cutlass.AddressSpace.gmem: Device DRAM (large, slower)
            cutlass.AddressSpace.smem: Per-block on-chip memory (fast)
            cutlass.AddressSpace.cmem: Read-only cached memory
            cutlass.AddressSpace.rmem: Per-thread stack memory
            cutlass.AddressSpace.tmem: Tensor memory (sm_100+, TMEM)
            cutlass.AddressSpace.dsmem: Distributed shared memory (cross-CTA)

        Example:
            arr = cutlass.Array(Float32, 8)
            arr.space  # cutlass.AddressSpace.rmem

            shared_arr = cutlass.Array(Float32, 16, space=cutlass.AddressSpace.smem)
            shared_arr.space  # cutlass.AddressSpace.smem
        """
        return self._impl.space

    @property
    def align(self) -> int:
        """Default alignment in bytes for load/store operations.

        Array carries alignment from its allocation or source tensor.
        This is used as the default when load/store is called without
        an explicit ``alignment`` parameter. Individual load/store calls
        can override it per-operation.

        Alignment source priority:
            1. User-provided alignment in allocation (highest priority)
            2. Alignment from cute.Tensor (if created from one)
            3. Element size in bytes (default fallback)

        Example:
            arr = cutlass.Array(Float32, 8)
            arr.align  # 4 (sizeof(float32))

            arr = cutlass.Array(Float32, 8, space=cutlass.AddressSpace.smem, alignment=16)
            arr.align  # 16

        Returns:
            Alignment in bytes (always >= 1).
        """
        return self._impl.align

    @dsl_user_op
    def data_ptr(
        self,
        idx: Union[int, Int32, tuple] = 0,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Pointer":
        """Get a Pointer to the element ``arr[idx]`` of this array.

        Returns a Pointer (which supports pointer arithmetic and ops like
        ``mbarrier_init``, ``prefetch``, TMA copy, etc.). The index follows the
        same rule as ``arr[idx]`` / ``load(idx)``:

        - single ``int`` / ``Int32``: flat linear element index;
        - ``tuple``: per-dimension coordinates, resolved through the array's
          strides (multi-dimensional addressing).

        Args:
            idx: Element index (default: 0). A single int/Int32 is a flat
                linear index; a tuple ``(i, j, ...)`` is stride-aware
                multi-dimensional addressing. Dynamic (Int32) indices allowed.

        Returns:
            Pointer to the array element at ``idx``.

        Example:
            arr = cutlass.Array(cutlass.Float32, (16, 16), space=cutlass.AddressSpace.smem)
            ptr = arr.data_ptr()          # Pointer to arr[0]
            ptr = arr.data_ptr(8)         # Pointer to flat element arr[8]
            ptr = arr.data_ptr((i, j))    # Pointer to arr[i, j] (stride-aware)
            ptr = arr.data_ptr(n)         # dynamic flat index (n: Int32)
        """
        impl = self._impl
        if isinstance(idx, tuple):
            # Multi-dimensional: stride-aware, mirrors arr[i, j] / load((i, j)).
            ptr = impl._gep(*idx)._base
        elif isinstance(idx, int) and idx == 0:
            ptr = impl._base
        else:
            # Flat single index, mirrors arr[n] / load(n).
            ptr = impl._gep(idx)._base
        return _make_pointer_from_raw(ptr, impl._dtype)

    @dsl_user_op
    def subview(
        self,
        idx: Union[int, Int32, tuple] = 0,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Array[DSLGenericType]":
        """Return an Array viewing this array's memory from element ``idx`` onward.

        The result is a full ``Array`` (same dtype, space, and shape) with its
        base advanced to element ``idx`` -- you can index, slice, and
        ``load``/``store`` on it. ``idx`` follows the same rule as ``arr[idx]``:
        a single int/Int32 is a flat linear index; a tuple ``(i, j, ...)`` is
        stride-aware multi-dimensional addressing.

        Use ``subview`` to get an *offset Array*; use :meth:`data_ptr` to get a
        raw ``Pointer`` (e.g. for mbarrier/TMA). ``arr.subview(n)`` is the
        explicit, named form of the open-ended slice ``arr[n:]``.

        Example:
            row = weights.subview(vocab_idx * hidden_size)  # still an Array
            vec = row[0:8, cutlass.align(16)]                   # Array vector-load works
        """
        impl = self._impl
        if isinstance(idx, int) and idx == 0:
            return self
        new_impl = impl._gep(*idx) if isinstance(idx, tuple) else impl._gep(idx)
        return Array._from_impl(new_impl)


@dsl_user_op
def make_array_view(
    tensor: cute.Tensor,
    *,
    dtype: Optional[Type[Numeric]] = None,
    bounds_check: bool = False,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Create an :class:`Array` reference from an existing tensor (no allocation).

    Wraps an existing memory region as an ``Array`` for multi-dimensional
    indexed access. Valid inside ``@cute.kernel``. Lives next to
    :class:`Array`; exposed publicly as ``cutlass.make_array_view``.

    .. note::
        For kernel **entry parameters**, prefer annotating the parameter as
        ``cutlass.Array`` directly instead of taking a ``cute.Tensor`` and
        wrapping it here — tensors (including ``from_dlpack`` results)
        auto-marshal to ``cutlass.Array`` params at the launch boundary.
        Reserve this helper for tensors that only materialize *inside* the
        traced function (slices, ``cute.make_tensor`` results, recasts).

    To build an ``Array`` view directly over a pointer, call
    ``cutlass.Array(pointer, shape=..., dtype=...)`` (no dedicated helper needed).

    :param tensor: The source ``cute.Tensor`` to wrap. Its layout must be flat
        (non-nested) — ``Array`` indexes a flat ``shape``/``stride``, so a
        hierarchical/nested layout is rejected rather than silently mis-indexed.
    :param dtype: Override element type (default: derived from tensor).
    :param bounds_check: Enable runtime bounds checking (default: False).
    :returns: An ``Array`` referencing the tensor's memory.
    """
    import cutlass.cute as cute

    if not isinstance(tensor, cute.Tensor):
        raise TypeError(
            f"make_array_view expects cute.Tensor, got {type(tensor).__name__}"
        )

    # Array uses a flat shape/stride; a nested (hierarchical) layout would be
    # silently mis-indexed, so reject it explicitly.
    if cute.depth(tensor.layout) > 1:
        raise ValueError(
            f"make_array_view does not support nested/hierarchical layouts "
            f"(got layout {tensor.layout}); coalesce/flatten the tensor first."
        )

    return Array(
        tensor,
        dtype=dtype,
        bounds_check=bounds_check,
        loc=loc,
        ip=ip,
    )
