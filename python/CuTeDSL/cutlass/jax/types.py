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

from dataclasses import dataclass, field
from numbers import Integral
from typing import Any, Sequence


import jax
import jax.numpy as jnp

import cutlass
import cutlass.cute as cute
from cutlass.cute.core import IntValue
from cutlass.cute.runtime import from_dlpack as _from_dlpack
from cutlass._mlir import ir
from cutlass import AddressSpace
from cutlass._mlir.dialects import llvm, arith

JAX_DTYPE_TO_CUTLASS_DTYPE = {
    jnp.bool.dtype: cutlass.Boolean,
    jnp.int4.dtype: cutlass.Int4,
    jnp.int8.dtype: cutlass.Int8,
    jnp.int16.dtype: cutlass.Int16,
    jnp.int32.dtype: cutlass.Int32,
    jnp.int64.dtype: cutlass.Int64,
    jnp.uint8.dtype: cutlass.Uint8,
    jnp.uint16.dtype: cutlass.Uint16,
    jnp.uint32.dtype: cutlass.Uint32,
    jnp.uint64.dtype: cutlass.Uint64,
    jnp.bfloat16.dtype: cutlass.BFloat16,
    jnp.float16.dtype: cutlass.Float16,
    jnp.float32.dtype: cutlass.Float32,
    jnp.float64.dtype: cutlass.Float64,
    jnp.float8_e8m0fnu.dtype: cutlass.Float8E8M0FNU,
    jnp.float8_e5m2.dtype: cutlass.Float8E5M2,
    jnp.float8_e4m3.dtype: cutlass.Float8E4M3,
    jnp.float8_e4m3fn.dtype: cutlass.Float8E4M3FN,
    jnp.float8_e4m3b11fnuz.dtype: cutlass.Float8E4M3B11FNUZ,
    jnp.float4_e2m1fn.dtype: cutlass.Float4E2M1FN,
}
CUTLASS_DTYPE_TO_JAX_DTYPE = {
    value: key for key, value in JAX_DTYPE_TO_CUTLASS_DTYPE.items()
}

DEFAULT_CUTLASS_DEVICE_MEMSPACE = AddressSpace.gmem
DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT = 256
_CUTE_XLA_FFI_BUFFER_ALIGNMENT = 8


def _llvm_pointer_type(address_space: AddressSpace = AddressSpace.generic) -> ir.Type:
    return llvm.PointerType.get(int(address_space))


@jax.tree_util.register_dataclass
@dataclass(frozen=True)
class TensorSpec:
    """Specifies the layout and metadata for a JAX array passed to a CuTe kernel.

    TensorSpec controls how a JAX array's input dimensions are mapped to a
    ``cute.Tensor`` during jit lowering, including compact stride ordering,
    mode permutation, and whether shapes/strides are compiled as static
    constants. The JAX bridge models tensors as compact layouts: runtime
    strides are derived from runtime shapes using ``layout`` order rather than
    loaded from a strided view descriptor.

    A useful way to choose a spec is to separate physical storage from logical
    kernel modes:

    1. First choose the public JAX array shape and its compact physical memory
       order. If the buffer is a standard row-major JAX array, leave
       ``layout=None``. ``cutlass_call`` will constrain the FFI operand/result
       to row-major physical layout, matching the CuTe tensor strides that are
       built from the default.
    2. Then use ``mode`` only when the kernel should see those input dimensions
       in a different logical order. ``mode`` is applied after the compact
       layout is built; it is not a request for JAX/XLA to transpose data.

    For example, a row-major JAX buffer shaped ``(expert_count, N, K)`` can be
    presented to a kernel expecting logical ``(N, K, expert_count)`` with
    ``TensorSpec(mode=(1, 2, 0))``. No explicit ``layout`` is needed because the
    physical buffer is still ordinary row-major, and the FFI call will be
    constrained accordingly. Use ``layout`` only when the compact physical
    stride order itself differs from the default row-major order, such as a
    column-major compact buffer.

    Attributes:
        layout: A minor-to-major stride ordering in CuTeDSL convention. ``layout[i]``
            gives the compact physical stride rank of input dimension ``i``,
            where rank 0 means the smallest (innermost) stride. For example,
            row-major order for a 3-D tensor is ``(2, 1, 0)``. If ``None``,
            row-major is assumed. Use :func:`jax_to_cutlass_layout_order` to
            convert from JAX's major-to-minor convention. ``layout`` does not
            change which logical mode a dimension represents; combine it with
            ``mode`` when physical order and kernel-logical order differ.
        mode: A permutation applied after the compact layout is constructed. It
            selects input dimensions into the mode positions seen by the kernel.
            For example, ``mode=(2, 0, 1)`` presents an input shaped
            ``(M, K, L)`` to the kernel as logical ``(L, M, K)``. If ``None``,
            modes match the natural input-dimension order ``(0, 1, ..., N-1)``.
            ``mode`` changes the tensor layout object seen by CuTe code but
            does not materialize a transpose or change the underlying buffer.
        static: If ``True``, shapes and strides are compiled as static ``constexpr``
            values, which may enable additional compiler optimisations. Kernels that
            do not support static shapes will raise a compile error. Must be ``False``
            when any dimension is symbolic (e.g. under ``jax.export``).
        ptr_assumed_align: Assumed byte alignment of the tensor's data pointer.
            Overrides the default of 256 bytes. Rarely needs to change.
        divisibility: Optional divisibility hints for input dimensions, in the
            same order as the JAX array shape and before any ``mode`` reordering.
            Positive hints constrain dynamic shape values and are propagated
            through compact stride construction: a stride inherits the product
            of the divisibilities for dimensions with lower stride rank.  When
            the JAX shape dimension is concrete, explicit hints must divide the
            concrete extent. Positive explicit hints take precedence over
            inferred concrete extents. If a single int is passed, it is applied
            to the leading compact dimension only, where ``layout[i] == 0``.
    """

    # Minor-to-major stride ordering in CuTeDSL convention (layout[i] = stride rank
    # of dimension i, 0 = innermost). Defaults to row-major if None.
    layout: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # Permutation from input dimensions to cute.Layout mode positions.
    # Defaults to identity (0, 1, ..., N-1) if None.
    mode: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # If True, shapes and strides are embedded as compile-time constants.
    # Must be False for symbolic/dynamic shapes (e.g. jax.export).
    static: bool | None = field(metadata=dict(static=True), default=None)
    # Assumed alignment (bytes) of the data pointer. Default matches XLA's 256-byte alignment.
    ptr_assumed_align: int = field(
        metadata=dict(static=True), default=DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT
    )
    # Per-input-dimension divisibility hints, before mode reordering.
    divisibility: tuple[int | None, ...] | int | None = field(
        metadata=dict(static=True), default=None
    )


def row_major_layout(shaped: Any) -> tuple[int, ...]:
    """Returns the CuTeDSL minor-to-major stride ordering for a row-major (C-contiguous) tensor.

    In CuTeDSL convention, ``layout[i]`` is the stride rank of dimension ``i``,
    where rank 0 denotes the innermost (stride-1) dimension.  Row-major means the
    last dimension is innermost, so the result is ``(N-1, N-2, ..., 1, 0)`` for an
    N-dimensional tensor.

    Example::

        row_major_layout((M, K, N))  # → (2, 1, 0)

    Args:
        shaped: An object with a ``.shape`` attribute, or a shape tuple/sequence.

    Returns:
        A tuple of length N representing the minor-to-major ordering.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return tuple(reversed(range(len(shaped))))


def default_tensor_mode(shaped: Any) -> tuple[int, ...]:
    """Returns the identity mode permutation for an N-dimensional tensor.

    The mode permutation maps JAX input dimensions to ``cute.Layout`` mode
    positions after the compact layout has been constructed. The default
    identity ``(0, 1, ..., N-1)`` leaves the mode order unchanged relative to
    the JAX shape order.

    Args:
        shaped: An object with a ``.shape`` attribute, or a shape tuple/sequence.

    Returns:
        A tuple ``(0, 1, ..., N-1)`` of length N.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return tuple(range(len(shaped)))


def default_tensor_spec(shaped: Any) -> TensorSpec:
    """Returns a :class:`TensorSpec` with row-major layout and identity mode ordering.

    Equivalent to::

        TensorSpec(layout=(N-1, ..., 1, 0), mode=(0, 1, ..., N-1), divisibility=(D0, D1, ... DN-1))

    This is appropriate for standard row-major (C-contiguous) JAX arrays that
    do not require dimension reordering inside the kernel. The resulting JAX
    CuTe tensor is treated as compact: strides are derived from shapes using the
    row-major layout order.

    If the JAX buffer is row-major but the kernel expects a different logical
    mode order, use an explicit :class:`TensorSpec` with ``mode`` set and leave
    ``layout`` unset. ``cutlass_call`` still constrains the FFI buffer to
    row-major layout in this case. For example, ``TensorSpec(mode=(1, 2, 0))``
    maps a physical ``(L, M, K)`` row-major input to a logical ``(M, K, L)``
    tensor.

    Divisibility hints are inferred only for positive concrete integer input
    dimensions. Symbolic and zero-sized dimensions produce ``None`` for their
    slot; pass an explicit ``TensorSpec`` with ``divisibility`` set if you need
    alignment hints for symbolic shapes or want a weaker explicit constraint
    than the concrete extent. Explicit constraints are checked against concrete
    extents when they are available.

    Args:
        shaped: An object with a ``.shape`` attribute, or a shape tuple/sequence.

    Returns:
        A :class:`TensorSpec` with ``layout`` set to row-major minor-to-major order
        and ``mode`` set to the identity permutation.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    inferred = tuple(_infer_concrete_dim_divisibility(d) for d in shaped)
    divisibility = inferred if any(d is not None for d in inferred) else None
    return TensorSpec(
        layout=row_major_layout(shaped),
        mode=default_tensor_mode(shaped),
        divisibility=divisibility,
    )


def _expand_divisibility(
    divisibility: tuple[int | None, ...] | int | None,
    order: tuple[int, ...],
    ndim: int,
) -> tuple[int | None, ...] | None:
    """Expand a divisibility spec to a full per-input-dimension tuple.

    A bare ``int`` is placed at the leading-dimension slot (where
    ``order[i] == 0``, i.e. stride == 1) and ``None`` everywhere else.
    A tuple is already in JAX input-dimension order and is returned unchanged.
    ``None`` returns ``None``.
    """
    if divisibility is None or isinstance(divisibility, tuple):
        return divisibility
    leading = order.index(0)
    result: list[int | None] = [None] * ndim
    result[leading] = divisibility
    return tuple(result)


def _is_integral(value: Any) -> bool:
    """Return True for integer-like values, excluding ``bool``."""
    return isinstance(value, Integral) and not isinstance(value, bool)


def _infer_concrete_dim_divisibility(dim: Any) -> int | None:
    """Infer a valid divisibility contract from a concrete shape dimension."""
    if not _is_integral(dim):
        return None
    dim = int(dim)
    if dim <= 0:
        return None
    return dim


def _validate_divisibility_entry(value: Any, dim_idx: int) -> int | None:
    if value is None:
        return None
    if not _is_integral(value):
        raise ValueError(
            f"divisibility entry for dimension {dim_idx} must be None or a positive integer, got {value!r}"
        )
    value = int(value)
    if value <= 0:
        raise ValueError(
            f"divisibility entry for dimension {dim_idx} must be positive, got {value}"
        )
    return value


def _check_divisibility_matches_concrete_shape(
    dim: Any, divby: int, dim_idx: int
) -> None:
    if not _is_integral(dim):
        return
    dim = int(dim)
    if dim % divby != 0:
        raise ValueError(
            f"divisibility entry {divby} for dimension {dim_idx} does not divide concrete shape dimension {dim}"
        )


def _normalize_divisibility(
    divisibility: tuple[int | None, ...] | int | None,
    order: tuple[int, ...],
    shape: Sequence[Any],
) -> tuple[int | None, ...] | None:
    """Validate and expand a divisibility spec in input-dimension order.

    A scalar spec follows ``mark_compact_shape_dynamic`` shorthand: it applies
    to the compact stride-1 dimension before any ``TensorSpec.mode`` reordering.
    Tuple specs already name input dimensions directly.
    """
    expanded = _expand_divisibility(divisibility, order, len(shape))
    if expanded is None:
        return None
    if len(expanded) != len(shape):
        raise ValueError("divisibility must be same length as shape", expanded, shape)

    normalized = []
    for dim_idx, (dim, entry) in enumerate(zip(shape, expanded)):
        entry = _validate_divisibility_entry(entry, dim_idx)
        if entry is not None:
            _check_divisibility_matches_concrete_shape(dim, entry, dim_idx)
        normalized.append(entry)
    return tuple(normalized)


def cutlass_to_jax_layout_order(
    layout: Sequence[int] | None,
) -> Sequence[int] | None:
    """Converts a CuTeDSL layout order (minor-to-major) to JAX layout order (major-to-minor).

    CuTeDSL uses minor-to-major ordering: ``layout[i]`` is the stride rank of
    dimension ``i`` (0 = innermost).  JAX uses major-to-minor ordering: position
    ``j`` in the result is the dimension index of the ``j``-th outermost axis.

    Example::

        cutlass_to_jax_layout_order((2, 1, 0))  # row-major → (0, 1, 2)
        cutlass_to_jax_layout_order((0, 1, 2))  # col-major → (2, 1, 0)

    Args:
        layout: Minor-to-major stride permutation, or ``None`` (returned unchanged).

    Returns:
        Major-to-minor axis permutation compatible with ``jax.Array.layout``, or ``None``.
    """
    if layout is None:
        return None
    return tuple(sorted(range(len(layout)), key=lambda i: layout[i], reverse=True))


def jax_to_cutlass_layout_order(
    layout: Sequence[int] | None,
) -> Sequence[int] | None:
    """Converts a JAX layout order (major-to-minor) to CuTeDSL layout order (minor-to-major).

    JAX uses major-to-minor ordering: position ``j`` is the dimension index of the
    ``j``-th outermost axis.  CuTeDSL uses minor-to-major ordering: ``layout[i]``
    is the stride rank of dimension ``i`` (0 = innermost).

    This is the inverse of :func:`cutlass_to_jax_layout_order`.

    Example::

        jax_to_cutlass_layout_order((0, 1, 2))  # row-major → (2, 1, 0)
        jax_to_cutlass_layout_order((2, 1, 0))  # col-major → (0, 1, 2)

    Args:
        layout: Major-to-minor axis permutation, or ``None`` (returned unchanged).

    Returns:
        Minor-to-major stride permutation for use as :attr:`TensorSpec.layout`, or ``None``.
    """
    if layout is None:
        return None
    inv = [0] * len(layout)
    for i, p in enumerate(layout):
        inv[p] = len(layout) - 1 - i
    return tuple(inv)


def jax_to_cutlass_dtype(dtype: Any) -> Any:
    """Gets the corresponding cutlass dtype given a jax dtype."""
    dtype = jnp.dtype(dtype)
    if dtype not in JAX_DTYPE_TO_CUTLASS_DTYPE:
        raise ValueError(f"Jax dtype [{dtype}] has no equivalent cutlass dtype.")
    return JAX_DTYPE_TO_CUTLASS_DTYPE[dtype]


def cutlass_to_jax_dtype(dtype: Any) -> Any:
    """Gets the corresponding cutlass dtype given a jax dtype."""
    if dtype not in CUTLASS_DTYPE_TO_JAX_DTYPE:
        raise ValueError(f"Cutlass dtype [{dtype}] has no equivalent jax dtype.")
    return CUTLASS_DTYPE_TO_JAX_DTYPE[dtype]


def from_dlpack(
    array: Any, assumed_align: int = DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT
) -> Any:
    """Convert jax.Array to a DL pack tensor."""
    return _from_dlpack(array, assumed_align=assumed_align)


def _assume_divisible_int(
    value: Any,
    divby: int,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Any:
    """Attach a divisibility assumption to an integer value without narrowing it."""
    if divby <= 1:
        return value
    return cute.assume(IntValue(value, loc=loc, ip=ip), divby=divby, loc=loc, ip=ip)


def _infer_dim_divisibility(
    shape: Sequence[Any],
    divisibility: tuple[int | None, ...] | None,
) -> tuple[int, ...]:
    """Infer per-dimension divisibility from explicit hints and concrete extents.

    ``divisibility`` must be ``None`` or have one entry per shape dimension.
    Explicit hints are hard contracts. ``None`` entries inherit a positive
    concrete extent when available and otherwise fall back to 1.
    Raises:
        ValueError: If explicit divisibility has a different length than shape,
            contains invalid entries, or contradicts a concrete shape dimension.
    """
    if divisibility is None:
        divisibility = (None,) * len(shape)
    elif len(divisibility) != len(shape):
        raise ValueError(
            "divisibility must be same length as shape",
            divisibility,
            shape,
        )

    result = []
    for dim_idx, (div_spec, static_s) in enumerate(zip(divisibility, shape)):
        if div_spec is not None:
            div_spec = _validate_divisibility_entry(div_spec, dim_idx)
            assert div_spec is not None
            _check_divisibility_matches_concrete_shape(static_s, div_spec, dim_idx)
            result.append(div_spec)
        else:
            result.append(_infer_concrete_dim_divisibility(static_s) or 1)
    return tuple(result)


def _validate_permutation(name: str, perm: Sequence[int], shape: Sequence[Any]) -> None:
    if len(perm) != len(shape):
        raise ValueError(f"{name} must be same length as shape", perm, shape)
    for s in perm:
        if not _is_integral(s):
            raise ValueError(f"Invalid non-integer index {s!r} in {name}", perm)
        s = int(s)
        if s < 0 or s >= len(shape):
            raise ValueError(f"Invalid index {s} in {name}", perm, shape)
    if len(set(perm)) != len(perm):
        raise ValueError(f"{name} has duplicate indices", perm)


class JaxArray:
    """Base class for JaxArray argument type.

    JaxArray provides glue between XLA/JAX FFI tensors and cute.Tensor.

    The following fields/properties provide control over the conversion
    to cute.Tensor as part of jax.jit lowering. These properties are
    constexpr and compiled into the kernel.

    1. dtype: The tensor data type defined by the jax array.
    2. shape: The tensor shape defined at jit tracing time. This shape
              can be concrete or symbolic in the case of jax.export.
    3. mem_space: The memory space of the tensor. Defaults to gmem.
    4. assumed_align: The alignment of the tensor. Defaults to XLA alignment.
    5. order: Specifies the compact physical stride order of the shape.
    6. mode: Specifies how to map input dimensions to the logical modes seen by
       the kernel after the compact layout is constructed.
    7. static: If True, tensor shapes and strides are compiled statically.
    8. divisibility: Optional divisibility hints in input-dimension order.
    """

    def __init__(
        self,
        dtype: type,
        shape: Sequence[int | Any],
        mem_space: AddressSpace,
        assumed_align: int,
        order: tuple[int, ...] | None = None,
        mode: tuple[int, ...] | None = None,
        static: bool = False,
        divisibility: tuple[int | None, ...] | int | None = None,
    ) -> None:
        self.dtype = dtype
        self.shape = tuple(shape)
        self.ndim = len(self.shape)
        self.mem_space = mem_space
        self.assumed_align = assumed_align

        if order is None:
            order = row_major_layout(shape)
        if mode is None:
            mode = default_tensor_mode(shape)

        _validate_permutation("order", order, shape)
        _validate_permutation("mode", mode, shape)

        self.order = tuple(order)
        self.mode = tuple(mode)

        if any([jax.export.is_symbolic_dim(s) for s in self.shape]) and static:
            raise ValueError(
                f"{self.shape} contains one or more symbolic dimensions requires static=False"
            )
        self.static = static

        self.divisibility = _normalize_divisibility(
            divisibility, self.order, self.shape
        )


class JaxArrayValue(JaxArray):
    """The IR representation of a :class:`JaxArray`.

    Array metadata is copied at construction so the IR value remains an
    independent snapshot if its source placeholder is later mutated.
    """

    def __init__(
        self,
        ir_value: ir.Value,
        jax_array: JaxArray,
    ) -> None:
        super().__init__(
            jax_array.dtype,
            jax_array.shape,
            jax_array.mem_space,
            jax_array.assumed_align,
            jax_array.order,
            jax_array.mode,
            jax_array.static,
            jax_array.divisibility,
        )
        self.value = ir_value

    def __str__(self) -> str:
        return f"JaxArrayValue<{self.value}:{self.dtype}:{self.shape}:{self.order}:{self.mode}:{self.static}:{self.divisibility}>"

    def __repr__(self) -> str:
        return str(self)

    def _make_ordered_layout_dynamic_strides(
        self,
        shape: tuple[ir.Value, ...],
        order: tuple[int, ...],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> ir.Value:
        i32 = ir.IntegerType.get_signless(32)

        # Track the divisibility available for each input dimension. Explicit
        # positive hints win; otherwise concrete dimensions contribute their
        # known extent even when the caller did not provide divisibility.
        dim_divisibility = _infer_dim_divisibility(self.shape, self.divisibility)

        pairs = sorted(zip(shape, order), key=lambda x: x[1])

        # Compute strides for each element in order.
        strides = [1]  # static 1 for leading
        if len(shape) > 1:
            strides.append(pairs[0][0])
        for i in range(len(pairs) - 2):
            strides.append(arith.muli(pairs[i + 1][0], strides[-1]))

        # Apply the order to strides
        strides_ordered = []
        for i in range(len(shape)):
            strides_ordered.append(strides[order[i]])

        # A compact stride is the product of all dimensions with a lower stride
        # order, so it inherits the product of their divisibility.
        stride_divisibility = []
        for dim_order in order:
            divby = 1
            for other_dim, other_order in enumerate(order):
                if other_order < dim_order:
                    divby *= dim_divisibility[other_dim]
            stride_divisibility.append(divby)

        strides_ordered = [
            _assume_divisible_int(s, divby, loc=loc, ip=ip)
            for s, divby in zip(strides_ordered, stride_divisibility)
        ]

        # Shapes are expected to be int32 so truncate to that before creating layout
        shape_i32 = tuple(arith.trunci(i32, s) for s in shape)
        shape_i32 = tuple(
            _assume_divisible_int(s, divby, loc=loc, ip=ip)
            for s, divby in zip(shape_i32, dim_divisibility)
        )

        return cute.make_layout(shape_i32, stride=tuple(strides_ordered))

    def _load_dynamic_shapes(
        self,
        ffi_buffer: ir.Value,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> tuple[ir.Value, ...]:
        i64 = ir.IntegerType.get_signless(64)
        shape_array = llvm.extractvalue(
            _llvm_pointer_type(),
            ffi_buffer,
            [1],
            loc=loc,
            ip=ip,
        )

        shape_i64 = []
        for i in range(len(self.shape)):
            r = llvm.getelementptr(
                _llvm_pointer_type(),
                shape_array,
                [],
                no_wrap_flags=0,
                raw_constant_indices=ir.DenseI32ArrayAttr.get([i]),
                elem_type=i64,
                loc=loc,
                ip=ip,
            )
            shape_i64.append(llvm.load(i64, r, loc=loc, ip=ip))

        return tuple(shape_i64)

    def _load_pointer(
        self,
        ffi_buffer: ir.Value,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> ir.Value:
        data_ptr = llvm.extractvalue(
            _llvm_pointer_type(),
            ffi_buffer,
            [0],
            loc=loc,
            ip=ip,
        )
        if self.mem_space != AddressSpace.generic:
            data_ptr = llvm.addrspacecast(
                _llvm_pointer_type(self.mem_space), data_ptr, loc=loc, ip=ip
            )
        return cute.make_ptr(
            self.dtype,
            data_ptr,
            self.mem_space,
            assumed_align=self.assumed_align,
            loc=loc,
            ip=ip,
        )

    def get_tensor(
        self, *, loc: ir.Location | None = None, ip: ir.InsertionPoint | None = None
    ) -> ir.Value:
        ffi_buffer_type = llvm.StructType.get_literal(
            [_llvm_pointer_type(), _llvm_pointer_type()]
        )

        ffi_buffer = llvm.load(ffi_buffer_type, self.value, loc=loc, ip=ip)
        pointer = self._load_pointer(ffi_buffer)

        if self.static:
            shape = tuple(self.shape)
            layout = cute.make_ordered_layout(shape, order=self.order, loc=loc, ip=ip)
        else:
            shape = self._load_dynamic_shapes(ffi_buffer)
            layout = self._make_ordered_layout_dynamic_strides(
                shape, self.order, loc=loc, ip=ip
            )

        # Apply mode order
        if self.mode is not None:
            layout = cute.select(layout, self.mode, loc=loc, ip=ip)

        return cute.make_tensor(pointer, layout, loc=loc, ip=ip)

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return [self.value]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "JaxArrayValue":
        """Reconstruct this array from exactly one MLIR descriptor pointer."""
        if len(values) != 1:
            raise ValueError(
                "JaxArrayValue reconstruction requires exactly one MLIR value; "
                f"got {len(values)}."
            )
        return JaxArrayValue(values[0], self)


class JaxTracedArray(cute.Pointer):
    """Host-side JAX buffer placeholder used by ``cute.compile``.

    XLA passes each FFI buffer descriptor as a generic pointer. ``dtype``,
    ``memspace``, and ``alignment`` describe that ABI pointer. The contained
    :class:`JaxArray` describes the typed, aligned device pointer loaded from
    the descriptor.

    Inside the traced function, :meth:`__new_from_mlir_values__` replaces this
    placeholder with a :class:`JaxArrayValue`, so pointer operations are never
    exposed on the host placeholder itself.
    """

    def __init__(self, jax_array: JaxArray) -> None:
        self._jax_array = jax_array
        self._ffi_buffer_pointer = cute.runtime.nullptr(
            cutlass.Int8,
            AddressSpace.generic,
            assumed_align=_CUTE_XLA_FFI_BUFFER_ALIGNMENT,
        )

    def __str__(self) -> str:
        array = self._jax_array
        return f"JaxTracedArray<{array.dtype}:{array.shape}:{array.order}:{array.mode}:{array.static}:{array.divisibility}>"

    def __repr__(self) -> str:
        return str(self)

    @property
    def dtype(self) -> type:
        """The element type of the generic XLA FFI descriptor pointer."""
        return cutlass.Int8

    @property
    def memspace(self) -> AddressSpace:
        """The address space of the XLA FFI descriptor pointer."""
        return AddressSpace.generic

    @property
    def alignment(self) -> int:
        """The alignment encoded in the descriptor pointer's CuTe type."""
        return _CUTE_XLA_FFI_BUFFER_ALIGNMENT

    @property
    def max_alignment(self) -> int:
        return self.alignment

    @property
    def type(self) -> ir.Type:
        return self.__get_mlir_types__()[0]

    def __get_mlir_types__(self) -> list[ir.Type]:
        return self._ffi_buffer_pointer.__get_mlir_types__()  # type: ignore[attr-defined]

    def __c_pointers__(self) -> list[int]:
        return self._ffi_buffer_pointer.__c_pointers__()  # type: ignore[attr-defined]

    def __new_from_mlir_values__(self, values: list[object]) -> JaxArrayValue:
        if len(values) != 1:
            raise ValueError(
                "JaxTracedArray reconstruction requires exactly one MLIR value; "
                f"got {len(values)}."
            )

        descriptor = values[0]
        if not isinstance(descriptor, cute.Pointer):
            raise TypeError(
                "JaxTracedArray reconstruction requires a cute.Pointer, "
                f"got {type(descriptor).__name__}."
            )

        return JaxArrayValue(descriptor.to_llvm_ptr(), self._jax_array)
