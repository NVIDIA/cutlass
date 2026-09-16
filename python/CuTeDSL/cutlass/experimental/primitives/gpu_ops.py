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

"""``cutlass.experimental.primitives.gpu_ops`` -- the ``cutlass.Array`` allocation backend.

Owns the memory-allocation surface behind ``cutlass.Array(dtype, shape, space=...)``:
the SMEM/RMEM/local allocators and ``_Array_factory_dispatch`` (registered with
``base_dsl.register_array_factory`` from ``cutlass.experimental.primitives.__init__``).

The ``gmem``/``cmem`` cubin-static handle (``_GlobalVariable``) lives in
``base_dsl.array`` next to ``Array`` itself, because ``cutlass.experimental`` is
not imported in public releases and those spaces are public ``cutlass.Array``
API. It is re-exported here so this module's dispatch table stays complete.
"""

from functools import reduce
import inspect
import operator
from typing import Type

from cutlass.base_dsl.typing import Array, _normalize_address_space

from cutlass.base_dsl.array import (  # noqa: F401  (re-exports, see module docstring)
    _compute_row_major_strides,
    _is_gpu_context,
    # Cubin-static globals (gmem/cmem) — canonical definitions live in
    # base_dsl.array; re-exported so `gpu_ops._GlobalVariable` keeps working.
    _GlobalVariable,
    _allocate_named_global,
    _GLOBAL_CONSTANT_VALID_KWARGS,
)

# CuTe DSL imports
import cutlass
from cutlass import dsl_user_op
import cutlass.cute as cute
from cutlass.base_dsl.typing import Boolean, Numeric
from cutlass.cutlass_dsl import CutlassBaseDSL
from cutlass.memory.smem import SmemAllocator

# MLIR imports
from cutlass._mlir import ir
from cutlass.cutlass_dsl import T
from cutlass._mlir.dialects import builtin as builtin
from cutlass._mlir.dialects import llvm as llvm
from cutlass._mlir.dialects import gpu as gpu
from cutlass._mlir.dialects import nvvm as nvvm
from cutlass._mlir.dialects import nvgpu as nvgpu
from cutlass._mlir.dialects import vector as vector
import cutlass._mlir.dialects.cute as _cute_ir


def _get_smem_allocator() -> "cutlass.memory.SmemAllocator":
    """Get shared memory allocator, reusing existing one if available.

    This function ensures a single SmemAllocator is used within a kernel context:
    1. If an allocator already exists (user-created or from previous call), reuse it
    2. If not, create a new one - SmemAllocator.__init__() auto-registers via
       track_smem_allocator(), so subsequent calls will find it

    This fixes the issue where mixing cutlass.memory.SmemAllocator() with
    cutlass.Array(..., space=cutlass.AddressSpace.smem) would cause overlapping allocations because
    each created independent allocators starting from offset 0.
    """
    dsl_obj = None
    caller = inspect.currentframe()
    frame = caller.f_back if caller is not None else None
    while frame:
        obj = frame.f_locals.get("self", None)
        if obj and isinstance(obj, CutlassBaseDSL):
            # Check for existing allocator (user-created or from a previous call)
            if obj._smem_usage_tracker is not None:
                allocator, _ = obj._smem_usage_tracker
                return allocator
            dsl_obj = obj
            break
        frame = frame.f_back

    # No existing allocator - create new one and register it in the DSL
    # context so subsequent calls reuse it (prevents overlapping allocations).
    allocator = SmemAllocator()
    if dsl_obj is not None:
        dsl_obj._set_smem_tracking(allocator, lambda a: a.smem_size)
    return allocator


# =============================================================================
# Memory Allocation APIs
# =============================================================================
#
# _allocate_memory_shared  - Shared memory (smem), internal implementation called by
#                            cutlass.Array(space=SHARED)
# _allocate_memory_local   - Local memory, internal implementation called by
#                            cutlass.Array(space=LOCAL/GENERIC):
#                            - GPU kernel: cute.memref.alloca (rmem address space)
#                            - Host code: llvm.alloca (generic address space)
#
# =============================================================================


def _allocate_memory_shared(
    dtype: Type[Numeric],
    shape: tuple[int, ...] | int = 1,
    alignment: int = 4,
    bounds_check: bool = False,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """
    Internal: allocate shared memory with the specified type and shape.

    Called by ``cutlass.Array(dtype, shape, space=cutlass.AddressSpace.smem, ...)``.
    Do not call directly — use ``cutlass.Array`` with ``space=cutlass.AddressSpace.smem``.

    Shared memory is allocated per CTA.  The returned ``Array`` names the
    executing CTA's instance of that allocation; all threads in that CTA can
    access the same instance.  In a cluster launch, every CTA in the cluster
    gets its own instance with the same shape and layout.  Peer CTAs can address
    another CTA's instance through the ``.shared::cluster`` window, for example
    by mapping the same CTA-local offset with :func:`~nvvm.mapa`.

    This per-CTA ownership matters for footprint calculations.  Allocating
    ``shape=(N,)`` reserves ``N * sizeof(dtype)`` bytes in each CTA, so a cluster
    with ``C`` CTAs reserves ``C * N * sizeof(dtype)`` bytes across the cluster.
    If only one root CTA needs a large mailbox, the other CTAs still reserve the
    same mailbox unless the algorithm is changed to use a smaller per-CTA
    allocation.

    **When is ``alignment`` required?** Match it to the downstream
    consumer; the default 4 B is fine only for plain compute scratch.
    Missing a stricter alignment does NOT raise at compile time — the
    allocation succeeds, the kernel often appears to run, and the
    failure shows up as silent UB / wrong output at runtime.

    +----------------------+--------------------------------------------+
    | ``alignment=``       | Use when the buffer is …                   |
    +======================+============================================+
    | ``128``              | a TMA destination                          |
    |                      | (``cp_async_bulk_tensor_shared_{cta,      |
    |                      | cluster}_global``), a tcgen05 MMA A/B      |
    |                      | operand (the base used by                  |
    |                      | :meth:`~cutlass.experimental.primitives.Tcgen05SmemDesc.build`), or
    |                      | the target of                              |
    |                      | ``load_swizzled`` / ``store_swizzled``.    |
    |                      | Any swizzle mode                           |
    |                      | (``s32b`` / ``s64b`` / ``s128b``) also     |
    |                      | requires 128-byte base alignment.          |
    +----------------------+--------------------------------------------+
    | ``8``                | an ``Int64`` mbarrier array — the          |
    |                      | 64-bit mbarrier state object requires      |
    |                      | 8-byte alignment; :func:`~nvvm.mbarrier_   |
    |                      | init` will reject under-aligned pointers.  |
    +----------------------+--------------------------------------------+
    | ``4`` (default)      | plain compute scratch, per-warp reduction  |
    |                      | buffers, small ``Int32`` / ``Float32``     |
    |                      | allocations that are never TMA / MMA /     |
    |                      | swizzle targets.                           |
    +----------------------+--------------------------------------------+

    :param dtype: The element type (e.g. ``Float32``, ``Int32``).
    :type dtype: Type[Numeric]
    :param shape: The dimensions of the array — tuple for multi-D, or a
        single ``int`` for 1-D.
    :type shape: tuple[int, ...] or int
    :param alignment: Memory alignment in bytes (default ``4``).  Raise
        to ``128`` for TMA / MMA / swizzled tiles; raise to ``8`` for
        ``Int64`` mbarrier arrays.  See the table above.
    :type alignment: int
    :param bounds_check: Enable runtime bounds checking
        (default ``False``).
    :type bounds_check: bool
    :return: An :class:`~cutlass.Array` referencing the allocated shared
        memory region.
    :rtype: cutlass.Array

    .. code-block:: python

        # Tile that feeds TMA or tcgen05.mma — 128-byte aligned.
        tile = cutlass.Array(cutlass.Float16, (128, 64), space=cutlass.AddressSpace.smem, alignment=128)
        # Mbarrier array — 8-byte aligned.
        mbar = cutlass.Array(cutlass.Int64, STAGES, space=cutlass.AddressSpace.smem, alignment=8)
        # Plain scratch — default 4-byte alignment is fine.
        scratch = cutlass.Array(cutlass.Float32, (NUM_WARPS,), space=cutlass.AddressSpace.smem)
        # Cluster launches still allocate this scratch once per CTA.  Use mapa
        # to address the corresponding scratch in a peer CTA when needed.
        # peer_rank is the target CTA rank in the cluster, from cluster indexing.
        peer_scratch = nvvm.mapa(scratch.data_ptr(), peer_rank)
    """
    # Normalize shape to tuple
    if isinstance(shape, int):
        shape = (shape,)

    # Calculate total number of elements
    num_elements = reduce(operator.mul, shape, 1)

    # Handle sub-byte data types (e.g., Int4, Float4, Float6) and Boolean special case
    # Boolean is treated as 8 bits (1 byte) in CUTLASS
    element_width_bits = dtype.width if dtype is not Boolean else 8

    # Calculate total size in bits first, then convert to bytes
    total_bits = num_elements * element_width_bits
    if total_bits % 8 != 0:
        raise ValueError(
            f"Allocation of {num_elements} elements of {dtype} "
            f"({element_width_bits} bits each) "
            f"results in {total_bits} bits, which is not byte-aligned. "
            f"Please adjust the number of elements to ensure byte alignment."
        )
    num_bytes = total_bits // 8

    # Allocate shared memory with proper alignment
    allocator = _get_smem_allocator()
    ptr = allocator.allocate(num_bytes, alignment, loc=loc, ip=ip)
    ptr = cute.recast_ptr(ptr, dtype=dtype, loc=loc, ip=ip)

    # Extract LLVM pointer from cute.Pointer using unrealized_conversion_cast
    addrspace = cutlass.AddressSpace.smem.value
    llvm_ptr_ty = llvm.PointerType.get(addrspace)
    cast_result = builtin.unrealized_conversion_cast([llvm_ptr_ty], [ptr.value])

    # Create and return Array with proper shape and metadata
    return Array(
        cast_result,
        shape=shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=addrspace,
    )


def _allocate_memory_generic(
    dtype: Type[Numeric],
    shape: tuple[int, ...],
    alignment: int,
    bounds_check: bool,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Internal: Allocate using llvm.alloca (generic address space)."""
    # Calculate total number of elements
    num_elements = reduce(operator.mul, shape, 1)

    # Get MLIR types
    mlir_elem_type = dtype.mlir_type
    addrspace = cutlass.AddressSpace.generic.value
    ptr_type = llvm.PointerType.get(addrspace)

    # Create size value
    size_val = cutlass.Int32(num_elements).ir_value()

    # Allocate using llvm.alloca
    alloca_ptr = llvm.alloca(ptr_type, size_val, mlir_elem_type, alignment=alignment)

    # Create and return Array with proper shape and metadata
    return Array(
        alloca_ptr,
        shape=shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=addrspace,
    )


def _make_array_rmem_layout_type(shape: tuple[int, ...]) -> ir.Type:
    """Build a row-major rmem layout type for ``cutlass.Array`` allocations."""
    shape_ty = _cute_ir.ShapeType.get_from_x_tuple(ir.Context.current, shape)
    stride_ty = _cute_ir.StrideType.get_from_x_tuple(
        ir.Context.current, _compute_row_major_strides(shape)
    )
    return _cute_ir.LayoutType.get(shape_ty, stride_ty)


def _allocate_memory_rmem(
    dtype: Type[Numeric],
    shape: tuple[int, ...],
    alignment: int,
    bounds_check: bool,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Internal: Allocate using cute.memref.alloca (rmem address space)."""
    # Get MLIR element type (Boolean stored as i8)
    mlir_elem_type = T.i8() if dtype is Boolean else dtype.mlir_type

    # Create LayoutType directly from shape/stride (no SSA ops needed for static
    # layouts). ``cutlass.Array`` exposes row-major indexing semantics, while a
    # bare cute LayoutType.get(shape) infers compact left-most stride.
    layout_ty = _make_array_rmem_layout_type(shape)

    # Create cute.ptr type with rmem (register memory) address space
    ptr_ty = _cute_ir.PtrType.get(mlir_elem_type, cutlass.AddressSpace.rmem, alignment)

    # Create cute.memref type
    memref_ty = _cute_ir.MemRefType.get(ptr_ty, layout_ty)

    # Allocate using cute.memref.alloca
    memref = _cute_ir.memref_alloca(memref_ty, loc=loc, ip=ip)

    # Extract the iterator (cute.ptr) from the memref
    # The value caster wraps memref_alloca result in _Tensor which provides .iterator
    cute_ptr = memref.iterator
    cute_ptr_val = cute_ptr.value if hasattr(cute_ptr, "value") else cute_ptr

    # Convert cute.ptr to LLVM pointer for Array compatibility
    # Use ptrtoint + inttoptr because this is the supported lowering path
    # Convert cute.ptr to generic LLVM pointer (address space 0).
    intptr = _cute_ir.ptrtoint(T.i64(), cute_ptr_val, loc=loc, ip=ip)
    addrspace = cutlass.AddressSpace.generic.value
    llvm_ptr = llvm.inttoptr(llvm.PointerType.get(addrspace), intptr, loc=loc, ip=ip)

    # Create and return Array with proper shape and metadata
    return Array(
        llvm_ptr,
        shape=shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=addrspace,
    )


def _allocate_memory_local(
    dtype: Type[Numeric],
    shape: tuple[int, ...] | int = 1,
    alignment: int | None = None,
    bounds_check: bool = False,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Array:
    """Internal: allocate thread-private memory via ``llvm.alloca``.

    Called by ``cutlass.Array(dtype, shape, space=cutlass.AddressSpace.rmem, ...)`` in
    host (``@cute.jit``) context.  In kernel context, the factory routes
    LOCAL/GENERIC directly to ``_allocate_memory_rmem`` (bypassing this
    function).  Do not call directly — use ``cutlass.Array`` with
    ``space=cutlass.AddressSpace.rmem``.
    """
    # Normalize shape to tuple
    if isinstance(shape, int):
        shape = (shape,)

    # Default alignment to element size (minimum 1 byte)
    if alignment is None:
        alignment = max(1, dtype.width // 8)

    # Auto-dispatch based on context
    if _is_gpu_context():
        return _allocate_memory_rmem(
            dtype, shape, alignment, bounds_check, loc=loc, ip=ip
        )
    else:
        return _allocate_memory_generic(
            dtype, shape, alignment, bounds_check, loc=loc, ip=ip
        )


# =============================================================================
# Unified ``cutlass.Array(dtype, shape, space=...)`` factory dispatch.
# =============================================================================
#
# The user-facing ``cutlass.Array`` class exposes a factory mode triggered by a
# ``space=`` keyword.  This file owns the dispatch table: ``Array.__new__``
# routes here when ``space=`` is present.
#
# Two scopes, four spaces (kernel):
#
#   * Kernel scope (inside a tracing ``@cute.kernel`` body):
#       LOCAL     -> ``_allocate_memory_rmem`` (cute.memref.alloca → ptrtoint →
#                    inttoptr → !llvm.ptr; entry-block hoisted; requires
#                    constexpr shape; default when no ``space=`` is given).
#       GENERIC   -> same as LOCAL in kernel.
#       SHARED    -> ``_allocate_memory_shared``
#       GLOBAL / CONSTANT  -> rejected; use module scope.
#       TENSOR / SHARED_CLUSTER -> rejected; no ``cutlass.Array(...)`` path yet.
#
#   * Module scope (no live MLIR context — typically a module-level
#     assignment ``WEIGHTS = cutlass.Array(..., space=...)``):
#       GLOBAL    -> ``GlobalVariable(addrspace=GLOBAL, ...)``
#       CONSTANT  -> ``GlobalVariable(addrspace=CONSTANT, ...)``
#       SHARED / LOCAL  -> rejected; per-launch scratch only makes sense
#                          inside ``@cute.kernel``.
#
# Valid kwargs are scope-dependent and validated up front so that typos
# (e.g. ``alignement=128``) fail with a clear error instead of a confusing
# ``TypeError`` from a downstream call.
# =============================================================================


# Kwargs accepted by ``_allocate_memory_shared`` / ``_allocate_memory_local``.
# ``loc`` / ``ip`` are infrastructure plumbing and intentionally kept out of
# the user-visible error message (see ``_check_factory_kwargs``).
_SMEM_LMEM_VALID_KWARGS = frozenset(("alignment", "bounds_check", "loc", "ip"))


def _check_factory_kwargs(
    space: "cutlass.AddressSpace",
    kwargs: dict,
    valid: frozenset,
) -> None:
    """Reject unknown kwargs early with a scope-specific error.

    ``loc`` / ``ip`` are part of the ``valid`` set so users can pass them
    through, but they are hidden from the error message — they are an
    internal MLIR plumbing detail.
    """
    remaining = set(kwargs) - valid
    if remaining:
        user_visible = sorted(valid - {"loc", "ip"})
        raise TypeError(
            f"keyword argument(s) {sorted(remaining)} are not valid for "
            f"space={space.name}. Valid kwargs: {user_visible}"
        )


@dsl_user_op
def _Array_factory_dispatch(
    dtype: Type[Numeric],
    shape: "tuple[int, ...] | int | None",
    space: "cutlass.AddressSpace | int",
    kwargs: dict,
    *,
    loc: ir.Location | None = None,
) -> "Array | _GlobalVariable":
    """Route ``cutlass.Array(dtype, shape, space=...)`` to the right allocator.

    Called from :meth:`Array.__new__` whenever the user passes ``space=``.
    The dispatch table is intentionally explicit: each (scope, space) pair
    either resolves to one downstream call or is rejected with a clear
    message pointing the user at the right alternative.

    :param dtype: cutlass numeric type for the allocation.
    :param shape: Tuple-of-ints or single int.  Forwarded as-is — each
        downstream allocator normalises shape on its own.
    :param space: Raw ``space=`` argument; normalised here via
        :func:`_normalize_address_space`.
    :param kwargs: Remaining ``Array(...)`` kwargs.  The relevant
        downstream-specific subset is validated against the scope before
        being forwarded.
    :return: Either a :class:`cutlass.Array` (kernel scope) or a
        :class:`GlobalVariable` (module scope).
    """
    if loc is not None and "loc" not in kwargs:
        kwargs["loc"] = loc

    if isinstance(space, int) and not isinstance(space, cutlass.AddressSpace):
        raise TypeError(
            "cutlass.Array(..., space=...) expects a cutlass.AddressSpace "
            f"member, not raw int {space!r}."
        )
    space = _normalize_address_space(space)

    # Detect whether we are inside a live MLIR tracing context.
    # - in_mlir_ctx=True, in_gpu_ctx=True:  inside @cute.kernel
    # - in_mlir_ctx=True, in_gpu_ctx=False: inside @cute.jit (host code)
    # - in_mlir_ctx=False:                  module scope (no active tracing)
    try:
        in_gpu_ctx = _is_gpu_context()
        in_mlir_ctx = True
    except Exception:
        in_gpu_ctx = False
        in_mlir_ctx = False

    # GLOBAL / CONSTANT are always cubin statics — pure Python handle,
    # usable inside or outside a kernel body.
    if space is cutlass.AddressSpace.gmem or space is cutlass.AddressSpace.cmem:
        _check_factory_kwargs(space, kwargs, _GLOBAL_CONSTANT_VALID_KWARGS)
        kwargs.pop("loc", None)
        kwargs.pop("ip", None)
        gv_shape = () if shape is None else shape
        return _GlobalVariable(dtype, gv_shape, addrspace=space, **kwargs)

    # SHARED: always routes through _allocate_memory_shared, which uses
    # _get_smem_allocator() (Python frame inspection) to find the SmemAllocator.
    # This is reliable across all compilation flows including
    # cute.compile(no_arg_kernel) where _is_gpu_context() returns False.
    if space is cutlass.AddressSpace.smem:
        if not in_mlir_ctx:
            raise ValueError(
                f"space={space.name} is only valid inside @cute.kernel. "
                "Move this allocation into the kernel body."
            )
        _check_factory_kwargs(space, kwargs, _SMEM_LMEM_VALID_KWARGS)
        if shape is None:
            raise ValueError(
                f"cutlass.Array(space={space.name}) requires an explicit shape."
            )
        loc = kwargs.pop("loc", None)
        ip = kwargs.pop("ip", None)
        return _allocate_memory_shared(dtype, shape, loc=loc, ip=ip, **kwargs)

    if in_gpu_ctx:
        # ---- Kernel scope ---------------------------------------------------
        if space is cutlass.AddressSpace.rmem or space is cutlass.AddressSpace.generic:
            _check_factory_kwargs(space, kwargs, _SMEM_LMEM_VALID_KWARGS)
            if shape is None:
                raise ValueError(
                    f"cutlass.Array(space={space.name}) requires an explicit shape."
                )
            norm_shape = (shape,) if isinstance(shape, int) else tuple(shape)
            if not all(isinstance(s, int) for s in norm_shape):
                raise ValueError(
                    f"cutlass.Array(space={space.name}) requires a compile-time "
                    "constant shape inside @cute.kernel."
                )
            alignment = kwargs.pop("alignment", max(1, dtype.width // 8))
            bounds_check = kwargs.pop("bounds_check", False)
            loc = kwargs.pop("loc", None)
            ip = kwargs.pop("ip", None)
            return _allocate_memory_rmem(
                dtype, norm_shape, alignment, bounds_check, loc=loc, ip=ip
            )

        # TENSOR / SHARED_CLUSTER are valid AddressSpace values but have no
        # cutlass.Array(...) factory path (TMEM via tcgen05; cluster SMEM via
        # dedicated allocator).
        raise ValueError(
            f"space={space.name} not supported via cutlass.Array(). "
            f"Use the dedicated API (tcgen05 / cluster SMEM)."
        )

    if in_mlir_ctx:
        # ---- Host scope (inside @cute.jit, not inside a kernel) -------------
        # LOCAL / GENERIC: llvm.alloca — dynamic size OK on the host side.
        if space is cutlass.AddressSpace.rmem or space is cutlass.AddressSpace.generic:
            _check_factory_kwargs(space, kwargs, _SMEM_LMEM_VALID_KWARGS)
            if shape is None:
                raise ValueError(
                    f"cutlass.Array(space={space.name}) requires an explicit shape."
                )
            loc = kwargs.pop("loc", None)
            ip = kwargs.pop("ip", None)
            return _allocate_memory_local(dtype, shape, loc=loc, ip=ip, **kwargs)

        raise ValueError(
            f"space={space.name} not supported via cutlass.Array() in host context."
        )

    # ---- Module scope (no active MLIR tracing context) ----------------------
    if space is cutlass.AddressSpace.rmem:
        raise ValueError(
            f"space={space.name} is only valid inside @cute.kernel. "
            f"Move this allocation into the kernel body."
        )

    raise ValueError(
        f"space={space.name} not supported via cutlass.Array() at module scope."
    )
