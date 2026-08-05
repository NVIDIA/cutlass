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
the SMEM/RMEM/local allocators, the ``_GlobalVariable`` cubin-static handle, and
``_Array_factory_dispatch`` (registered with ``base_dsl.register_array_factory`` from
``cutlass.experimental.primitives.__init__``).
"""

from functools import reduce
import inspect
import operator
import re
import uuid
from typing import Any, Sequence, Type, Literal

from cutlass import Pointer
from cutlass.base_dsl.typing import Array, _normalize_address_space

from cutlass.base_dsl.array import (
    _compute_row_major_strides,
    _get_or_declare_constant_global,
    _is_gpu_context,
)

# CuTe DSL imports
import cutlass
from cutlass import dsl_user_op
import cutlass.cute as cute
from cutlass.base_dsl.typing import Boolean, Numeric

# ``cutlass.utils`` is imported lazily inside ``_get_smem_allocator()`` (it loads
# after ``cutlass.cute``; a module-level reference can deadlock during init).
from cutlass.cutlass_dsl import CutlassBaseDSL

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


def _get_smem_allocator() -> "cutlass.utils.SmemAllocator":
    """Get shared memory allocator, reusing existing one if available.

    This function ensures a single SmemAllocator is used within a kernel context:
    1. If an allocator already exists (user-created or from previous call), reuse it
    2. If not, create a new one - SmemAllocator.__init__() auto-registers via
       track_smem_allocator(), so subsequent calls will find it

    This fixes the issue where mixing cutlass.utils.SmemAllocator() with
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
    import cutlass.utils  # deferred; see module-level note on the import block

    allocator = cutlass.utils.SmemAllocator()
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
# Static GPU globals: constant memory and global memory
# =============================================================================


def _allocate_named_global(
    dtype: Type[Numeric],
    shape: tuple[int, ...] | int,
    addrspace: int,
    *,
    name: str | None,
    alignment: int | None,
    storage: Literal["internal", "extern"],
    constant: bool,
    init: object | None,
    bounds_check: bool,
    loc: ir.Location | None,
    ip: ir.InsertionPoint | None,
) -> Array:
    """Shared body for allocate_memory_constant/global.

    Emits a single llvm.mlir.global into the enclosing gpu.module (deduped by
    name with a signature check on reuse — anonymous globals do not dedup),
    addresses-of it at the call site, and wraps the resulting !llvm.ptr in a
    cutlass.Array carrying the right addrspace so downstream Array operations see
    the correct memory space.
    """
    if isinstance(shape, int):
        shape = (shape,)

    num_elements = reduce(operator.mul, shape, 1)
    if num_elements <= 0:
        raise ValueError(f"shape must be positive; got {shape}")

    element_width_bits = dtype.width if dtype is not Boolean else 8
    total_bits = num_elements * element_width_bits
    if total_bits % 8 != 0:
        raise ValueError(
            f"global '{name}': {num_elements} elements of {dtype} "
            f"({element_width_bits} bits each) is not byte-aligned"
        )

    if alignment is None:
        alignment = max(1, dtype.width // 8)

    # Build the LLVM payload type: scalar for shape=(1,) / single element,
    # otherwise wrap in nested !llvm.array<...>.
    mlir_elem_type = dtype.mlir_type
    is_wrapped_array = num_elements > 1 or len(shape) > 1
    payload_type = mlir_elem_type
    if is_wrapped_array:
        # Wrap from innermost to outermost so shape=(M, N) becomes
        # !llvm.array<M x !llvm.array<N x T>>.
        payload_type = mlir_elem_type
        for n in reversed(shape):
            payload_type = ir.Type.parse(f"!llvm.array<{n} x {payload_type}>")

    addr_val, _resolved_name = _get_or_declare_constant_global(
        name,
        payload_type,
        addrspace,
        alignment=alignment,
        constant=constant,
        storage=storage,
        init=init,
        init_dtype=dtype,
        init_shape=shape,
        init_is_wrapped_array=is_wrapped_array,
        loc=loc,
        ip=ip,
    )

    return Array(
        addr_val,
        shape=shape,
        dtype=dtype,
        bounds_check=bounds_check,
        addrspace=addrspace,
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

# Kwargs accepted by ``GlobalVariable.__init__``.  ``loc`` / ``ip`` are
# accepted but unused — ``GlobalVariable`` construction emits no MLIR.
_GLOBAL_CONSTANT_VALID_KWARGS = frozenset(
    ("name", "init", "extern", "readonly", "alignment", "loc", "ip")
)


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

    :param dtype: CUTLASS numeric type for the allocation.
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


# =============================================================================
# Module-scope handle for static cubin globals (host-init friendly).
# =============================================================================
#
# A GlobalVariable is pure Python metadata describing a named static cubin
# buffer.  Construction emits no MLIR.  The handle is usable in two contexts:
#
#   1. Inside @cute.kernel: ``WEIGHTS[tx]`` (read) and, for writable spaces,
#      ``WEIGHTS[tx] = v`` (store) lazily emit the matching
#      ``llvm.mlir.global`` into the enclosing gpu.module and return a
#      ``cutlass.Array`` view in the matching ``AddressSpace``.
#
#   2. From eager Python (post-compile): a host write-to-symbol helper
#      (``compiled_fn, WEIGHTS, src``) resolves the global against the cubin's
#      loaded ``cudaLibrary_t`` via ``cudaLibraryGetGlobal`` and copies bytes
#      in via ``cudaMemcpy``.
#
# The two orthogonal axes:
#
#     addrspace= : where the bytes physically live
#         cutlass.AddressSpace.gmem    -> .global  (host- and device-mutable)
#         cutlass.AddressSpace.cmem  -> .const   (host-mutable, device-read-only)
#
#     init=      : whether the value is a compile-time literal
#         init=None    -> LLVM `constant` flag is False; loads respect any
#                         runtime writes (cuMemcpyToSymbol observable).
#         init=values  -> LLVM `constant` flag is True; the optimizer is
#                         told the value never changes and may fold loads
#                         to the literal.  Use for baked-in lookup tables
#                         that you NEVER overwrite from host.
#
# =============================================================================


class _GlobalVariable:
    """Module-scope handle for a static cubin variable.

    Construction is pure Python; declaration into MLIR happens lazily on
    first kernel-side use via ``WEIGHTS[idx]``.

    :param dtype: Element CUTLASS numeric type (``cutlass.Float32`` etc.).
    :param shape: Element-count tuple.  ``(N,)`` is canonical 1-D.
    :param name: PTX identifier for the global.  Used by
        ``cudaLibraryGetGlobal`` at host-upload time, so it must be a stable
        C identifier.  If omitted the constructor generates a unique
        ``cutedsl_const_sym_<n>`` / ``cutedsl_global_sym_<n>`` name.
    :param alignment: Bytes; defaults to ``dtype.width // 8``.
    :param init: Compile-time literal.  Presence of ``init`` flips the LLVM
        ``constant`` keyword on, which lets the optimizer fold loads to the
        literal — DO NOT pair with ``write_to_symbol`` if you expect the
        host upload to be observable.  Omit ``init`` for the standard
        host-init flow.
    :param addrspace: :class:`AddressSpace` member (or its int value).
        Default is ``GLOBAL``.  Only ``GLOBAL`` and ``CONSTANT`` are valid
        for static cubin variables.
    :param extern: ``False`` (default) — this cubin defines the body.
        ``True`` — declaration only; the body lives in another cubin or in
        C++ code linked into this cubin.  Extern requires an explicit
        ``name`` (you can't auto-name something that already exists) and
        rejects ``init=`` (the body is elsewhere).  ``write_to_symbol``
        rejects extern handles since the storage isn't ours to update.
    :param readonly: ``False`` (default) — the global is host-mutable; an
        ``init=`` provides default values that ``write_to_symbol`` may
        later overwrite (the standard CUDA C++ ``__constant__ float arr[N]
        = {…};`` pattern).  ``True`` — the LLVM ``constant`` keyword is
        emitted; the optimizer is free to fold all loads to ``init`` and
        any later ``write_to_symbol`` will silently not be observed.  Use
        for compile-time-baked literal tables only.  Requires ``init``.
    """

    # ---- Class-level constants/helpers ------------------------------------

    # Valid PTX identifier pattern (used to validate explicit ``name=`` args).
    _NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

    @staticmethod
    def _auto_name(addrspace_int: int) -> str:
        """Generate a fresh ``cutedsl_<kind>_sym_<hex>`` name when the user
        didn't pass one.  No global state; uniqueness comes from a
        UUID4-derived suffix (48 bits → collision-free for any realistic
        workload).
        """
        kind = "const" if addrspace_int == int(cutlass.AddressSpace.cmem) else "global"
        return f"cutedsl_{kind}_sym_{uuid.uuid4().hex[:12]}"

    __slots__ = (
        "name",
        "dtype",
        "shape",
        "alignment",
        "is_extern",
        "readonly",
        "_addrspace",
        "init",
    )

    name: str
    dtype: Type[Numeric]
    shape: "tuple[int, ...]"
    alignment: int
    is_extern: bool
    readonly: bool
    _addrspace: int
    init: "Numeric | Sequence | object | None"

    def __init__(
        self,
        dtype: Type[Numeric],
        shape: "tuple[int, ...] | int" = (),
        *,
        name: str | None = None,
        alignment: int | None = None,
        init: "Numeric | Sequence | object | None" = None,
        addrspace: "cutlass.AddressSpace | int | None" = None,
        extern: bool = False,
        readonly: bool = False,
    ) -> None:
        # ---- shape ------------------------------------------------------
        # Default shape=() means "scalar" (num_elements == 1).  Wrap an
        # int into a 1-D tuple; otherwise normalise to a tuple of ints.
        if isinstance(shape, int):
            shape = (shape,)
        else:
            shape = tuple(shape)
        # Empty tuple = scalar — allowed.  Non-empty must be all positive ints.
        if any((not isinstance(d, int)) or d <= 0 for d in shape):
            raise ValueError(f"shape must be positive ints; got {shape!r}")

        # ---- addrspace (resolve first, needed for auto-name) ------------
        if addrspace is None:
            addrspace = cutlass.AddressSpace.gmem
        # AddressSpace is an IntEnum; int() works on either an enum member
        # or a plain int.
        addrspace_int = int(addrspace)
        _allowed = (int(cutlass.AddressSpace.cmem), int(cutlass.AddressSpace.gmem))
        if addrspace_int not in _allowed:
            raise ValueError(
                f"GlobalVariable addrspace must be CONSTANT (4) or GLOBAL (1); "
                f"got {addrspace_int}.  Use cutlass.Array(space=cutlass.AddressSpace.smem) or "
                f"cutlass.Array(space=cutlass.AddressSpace.rmem) for per-launch scratch."
            )

        # ---- name (extern requires explicit; internal auto-generates) ---
        extern = bool(extern)
        if name is None:
            if extern:
                raise ValueError(
                    "GlobalVariable(extern=True) requires an explicit `name` "
                    "— the symbol must already exist in another cubin (or in "
                    "C++ code linked against this cubin)."
                )
            name = _GlobalVariable._auto_name(addrspace_int)
        elif not isinstance(name, str) or not _GlobalVariable._NAME_RE.match(name):
            raise ValueError(
                f"GlobalVariable name must match {_GlobalVariable._NAME_RE.pattern!r}; "
                f"got {name!r}"
            )

        if extern and init is not None:
            raise ValueError(
                f"GlobalVariable {name!r}: extern=True cannot have init= — "
                f"the variable's body lives in a different cubin."
            )
        if readonly and init is None and not extern:
            # readonly=True asserts immutability everywhere — without an
            # init, there's nothing for the optimizer to fold loads to,
            # which makes the variable functionally useless (every read
            # would be undef).  Reject early with a clear message.
            raise ValueError(
                f"GlobalVariable {name!r}: readonly=True requires an init= "
                f"value (the optimizer needs a literal to fold loads to)."
            )

        # ---- dtype ------------------------------------------------------
        if not isinstance(dtype, type) or not hasattr(dtype, "width"):
            raise TypeError(f"dtype must be a cutlass.Numeric subclass; got {dtype!r}")

        elem_width_bits = dtype.width if dtype is not Boolean else 8
        num_elements = reduce(operator.mul, shape, 1)
        if (num_elements * elem_width_bits) % 8 != 0:
            raise ValueError(
                f"GlobalVariable {name!r}: {num_elements} elements of "
                f"{dtype} ({elem_width_bits} bits each) is not byte-aligned"
            )

        # ---- alignment --------------------------------------------------
        if alignment is None:
            alignment = max(1, dtype.width // 8)
        if (
            not isinstance(alignment, int)
            or alignment <= 0
            or (alignment & (alignment - 1))
        ):
            raise ValueError(
                f"alignment must be a positive power of two; got {alignment!r}"
            )

        # __slots__ + frozen-by-convention: store via object.__setattr__.
        object.__setattr__(self, "name", name)
        object.__setattr__(self, "dtype", dtype)
        object.__setattr__(self, "shape", shape)
        object.__setattr__(self, "alignment", alignment)
        object.__setattr__(self, "is_extern", extern)
        object.__setattr__(self, "readonly", bool(readonly))
        object.__setattr__(self, "_addrspace", addrspace_int)
        object.__setattr__(self, "init", init)

    def __setattr__(self, key: str, value: object) -> None:
        raise AttributeError(f"GlobalVariable is immutable; cannot set {key!r}")

    def __repr__(self) -> str:
        kind = "extern" if self.is_extern else "internal"
        return (
            f"GlobalVariable(name={self.name!r}, dtype={self.dtype.__name__}, "
            f"shape={self.shape}, alignment={self.alignment}, "
            f"storage={kind!r}, addrspace={self._addrspace}, "
            f"init={'<set>' if self.init is not None else None}, "
            f"readonly={self.readonly})"
        )

    # ---- public introspection ---------------------------------------------

    @property
    def num_elements(self) -> int:
        return reduce(operator.mul, self.shape, 1)

    @property
    def nbytes(self) -> int:
        elem_width_bits = self.dtype.width if self.dtype is not Boolean else 8
        return (self.num_elements * elem_width_bits) // 8

    @property
    def addrspace(self) -> int:
        return self._addrspace

    # ---- Device-side use ---------------------------------------------------

    def _materialize(
        self,
        *,
        bounds_check: bool = False,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Array:
        """Emit the global declaration (if needed) and return a kernel-side
        ``cutlass.Array`` view.

        Must be called inside a tracing context (a ``@cute.kernel`` body or
        any other gpu.module-rooted IR context). Multiple calls in the same
        kernel re-emit ``llvm.mlir.addressof`` (cheap; LLVM CSE folds);
        the underlying ``llvm.mlir.global`` is deduped by name.

        Private — users should index the handle directly: ``WEIGHTS[idx]``.
        """
        # Pre-flight: GlobalVariable indexing requires a live MLIR tracing
        # context (the global decl is emitted into the enclosing gpu.module
        # at first use).  Without that, the underlying MLIR builder errors
        # with a generic "needs a Context" message that doesn't tell the
        # user what they actually did wrong.  Catch it up-front.
        try:
            ir.InsertionPoint.current  # type: ignore[attr-defined]
        except (RuntimeError, ValueError):
            raise RuntimeError(
                f"GlobalVariable {self.name!r}: indexing is only valid "
                f"inside an `@cute.kernel` / `@cute.jit` body during MLIR "
                f"tracing.  To read or write the bytes from host Python, "
                f"use `cutlass.write_to_symbol(compiled_fn, sym, src)` after "
                f"`cute.compile(...)`."
            ) from None
        return _allocate_named_global(
            self.dtype,
            self.shape,
            addrspace=self._addrspace,
            name=self.name,
            alignment=self.alignment,
            # _get_or_declare_constant_global takes the literal storage
            # string; map our bool back.
            storage="extern" if self.is_extern else "internal",
            # LLVM `constant` flag: only set when readonly=True (compile-time baked
            # literal).  CONSTANT addrspace is device-read-only by PTX ABI, but the
            # host can still update the symbol via write_to_symbol(); adding the LLVM
            # constant keyword would make those updates unobservable to the compiler.
            constant=self.readonly,
            init=self.init,
            bounds_check=bounds_check,
            loc=loc,
            ip=ip,
        )

    def __getitem__(self, idx: object) -> Any:
        """``WEIGHTS[tx]`` lazily emits the addressof + load."""
        return self._materialize()[idx]

    def __setitem__(self, idx: object, value: object) -> None:
        """``COUNTER[tx] = v`` lazily emits the addressof + store.

        Stores into a CONSTANT-addrspace Symbol are rejected by the
        underlying Array (constant memory is read-only on device).
        """
        self._materialize()[idx] = value

    def print_runtime(
        self,
        max_elements: int = 16,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        """Print array contents at runtime; delegates to the materialized Array."""
        self._materialize(loc=loc, ip=ip).print_runtime(max_elements, loc=loc, ip=ip)

    def subview(
        self,
        idx: int | ir.Value = 0,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Array:
        """Offset Array view: ``global_handle.subview(n)`` → Array from element ``n``.

        Replaces the now-disabled ``global_handle + n`` pointer arithmetic;
        delegates to the materialized global Array's :meth:`Array.subview`.
        """
        return self._materialize(loc=loc, ip=ip).subview(idx, loc=loc, ip=ip)

    def data_ptr(
        self,
        idx: int | ir.Value = 0,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Pointer:
        """Pointer to element ``idx``: ``global_handle.data_ptr(n)`` → Pointer.

        Delegates to the materialized global Array's :meth:`Array.data_ptr`.
        """
        return self._materialize(loc=loc, ip=ip).data_ptr(idx, loc=loc, ip=ip)

    def __add__(self, other: object) -> Array:
        """Pointer arithmetic: global_handle + offset → Array at that offset."""
        return self._materialize() + other

    def __radd__(self, other: object) -> Array:
        return other + self._materialize()

    def __sub__(self, other: object) -> Array:
        """Pointer arithmetic: global_handle - offset → Array at that offset."""
        return self._materialize() - other
