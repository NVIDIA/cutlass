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

from typing import Optional, Sequence
from dataclasses import dataclass, field


import jax
import jax.numpy as jnp

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack as _from_dlpack
from cutlass.cute import AddressSpace
from cutlass._mlir import ir
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


@jax.tree_util.register_dataclass
@dataclass(frozen=True)
class TensorSpec:
    """Specifies the layout and metadata for a JAX array passed to a CuTe kernel.

    TensorSpec controls how a JAX array's dimensions are mapped to a cute.Tensor
    during jit lowering, including stride ordering, mode permutation, and whether
    shapes/strides are compiled as static constants.

    Attributes:
        layout: A minor-to-major stride ordering in CuTeDSL convention. ``layout[i]``
            gives the stride rank of dimension ``i``, where rank 0 means the smallest
            (innermost) stride. For example, row-major order for a 3-D tensor is
            ``(2, 1, 0)``. If ``None``, row-major is assumed. Use
            :func:`jax_to_cutlass_layout_order` to convert from JAX's major-to-minor
            convention.
        mode: A permutation that maps the stride-ordered dimensions to the mode
            positions of the resulting ``cute.Layout``. For example, ``mode=(2, 0, 1)``
            reorders an ``(M, K, L)`` layout into ``(K, L, M)`` mode order inside the
            kernel. If ``None``, modes match the natural dimension order ``(0, 1, ..., N-1)``.
        static: If ``True``, shapes and strides are compiled as static ``constexpr``
            values, which may enable additional compiler optimisations. Kernels that
            do not support static shapes will raise a compile error. Must be ``False``
            when any dimension is symbolic (e.g. under ``jax.export``).
        ptr_assumed_align: Assumed byte alignment of the tensor's data pointer.
            Overrides the default of 256 bytes. Rarely needs to change.
        divisibility: Optional per-mode divisibility hints. If a single int is passed
            divisibility will be applied to the leading (stride=1) dimension only.
    """

    # Minor-to-major stride ordering in CuTeDSL convention (layout[i] = stride rank
    # of dimension i, 0 = innermost). Defaults to row-major if None.
    layout: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # Permutation from stride-ordered dimensions to cute.Layout mode positions.
    # Defaults to identity (0, 1, ..., N-1) if None.
    mode: tuple[int, ...] | None = field(metadata=dict(static=True), default=None)
    # If True, shapes and strides are embedded as compile-time constants.
    # Must be False for symbolic/dynamic shapes (e.g. jax.export).
    static: bool = field(metadata=dict(static=True), default=None)
    # Assumed alignment (bytes) of the data pointer. Default matches XLA's 256-byte alignment.
    ptr_assumed_align: int = field(
        metadata=dict(static=True), default=DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT
    )
    # Per-mode divisibility hints.
    divisibility: tuple[int | None, ...] | int | None = field(
        metadata=dict(static=True), default=None
    )


def row_major_layout(shaped):
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


def default_tensor_mode(shaped):
    """Returns the identity mode permutation for an N-dimensional tensor.

    The mode permutation maps stride-ordered dimensions to ``cute.Layout`` mode
    positions.  The default identity ``(0, 1, ..., N-1)`` leaves the mode order
    unchanged relative to the dimension order.

    Args:
        shaped: An object with a ``.shape`` attribute, or a shape tuple/sequence.

    Returns:
        A tuple ``(0, 1, ..., N-1)`` of length N.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    return tuple(range(len(shaped)))


def default_tensor_spec(shaped) -> TensorSpec:
    """Returns a :class:`TensorSpec` with row-major layout and identity mode ordering.

    Equivalent to::

        TensorSpec(layout=(N-1, ..., 1, 0), mode=(0, 1, ..., N-1), divisibility=(D0, D1, ... DN-1))

    This is appropriate for standard row-major (C-contiguous) JAX arrays that
    do not require dimension reordering inside the kernel.

    Divisibility hints are inferred only for concrete integer dimensions.
    Symbolic dimensions always produce ``None`` for their slot; pass an
    explicit ``TensorSpec`` with ``divisibility`` set if you need alignment
    hints for symbolic shapes.

    Args:
        shaped: An object with a ``.shape`` attribute, or a shape tuple/sequence.

    Returns:
        A :class:`TensorSpec` with ``layout`` set to row-major minor-to-major order
        and ``mode`` set to the identity permutation.
    """
    if hasattr(shaped, "shape"):
        shaped = shaped.shape
    inferred = tuple(d if isinstance(d, int) else None for d in shaped)
    divisibility = inferred if any(d is not None for d in inferred) else None
    return TensorSpec(
        layout=row_major_layout(shaped),
        mode=default_tensor_mode(shaped),
        divisibility=divisibility,
    )


def _expand_divisibility(
    divisibility, order: tuple[int, ...], ndim: int
) -> tuple[int | None, ...] | None:
    """Expand a divisibility spec to a full per-dimension tuple.

    A bare ``int`` is placed at the leading-dimension slot (where
    ``order[i] == 0``, i.e. stride == 1) and ``None`` everywhere else.
    A tuple is returned unchanged.  ``None`` returns ``None``.
    """
    if divisibility is None or isinstance(divisibility, tuple):
        return divisibility
    leading = order.index(0)
    result = [None] * ndim
    result[leading] = divisibility
    return tuple(result)


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


def jax_to_cutlass_dtype(dtype):
    """Gets the corresponding cutlass dtype given a jax dtype."""
    dtype = jnp.dtype(dtype)
    if dtype not in JAX_DTYPE_TO_CUTLASS_DTYPE:
        raise ValueError(f"Jax dtype [{dtype}] has no equivalent cutlass dtype.")
    return JAX_DTYPE_TO_CUTLASS_DTYPE[dtype]


def cutlass_to_jax_dtype(dtype):
    """Gets the corresponding cutlass dtype given a jax dtype."""
    if dtype not in CUTLASS_DTYPE_TO_JAX_DTYPE:
        raise ValueError(f"Cutlass dtype [{dtype}] has no equivalent jax dtype.")
    return CUTLASS_DTYPE_TO_JAX_DTYPE[dtype]


def from_dlpack(array, assumed_align: int = DEFAULT_CUTLASS_DEVICE_BUFFER_ALIGNMENT):
    """Convert jax.Array to a DL pack tensor."""
    return _from_dlpack(array, assumed_align=assumed_align)


def _validate_permutation(name: str, perm, shape):
    if len(perm) != len(shape):
        raise ValueError(f"{name} must be same length as shape", perm, shape)
    for s in perm:
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
    5. order: Specifies the order of the shape to determine strides.
    6. mode: Specifies how to map ordered elements to the modes od a cute.Layout.
    7. static: If True, tensor shapes and strides are compiled statically.
    """

    def __init__(
        self,
        dtype,
        shape,
        mem_space,
        assumed_align,
        order=None,
        mode=None,
        static=False,
        divisibility=None,
    ):
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

        if divisibility is not None:
            divisibility = _expand_divisibility(divisibility, self.order, self.ndim)
            divisibility = tuple(divisibility)
            if len(divisibility) != len(shape):
                raise ValueError(
                    "divisibility must be same length as shape", divisibility, shape
                )
            for d in divisibility:
                if not (d is None or isinstance(d, int)):
                    raise ValueError(
                        f"divisibility entries must be None or integer, got {d!r}"
                    )
        self.divisibility = divisibility


class JaxArrayValue(JaxArray):
    """The IR representation of the JaxArray."""

    def __init__(
        self,
        ir_value,
        dtype,
        shape,
        mem_space,
        assumed_align,
        order,
        mode,
        static,
        divisibility=None,
    ):
        super().__init__(
            dtype, shape, mem_space, assumed_align, order, mode, static, divisibility
        )
        self.value = ir_value

    def __str__(self):
        return f"JaxArrayValue<{self.value}:{self.dtype}:{self.shape}:{self.order}:{self.mode}:{self.static}:{self.divisibility}>"

    def __repr__(self):
        return str(self)

    def _make_ordered_layout_dynamic_strides(
        self,
        shape,
        order: tuple[int, ...],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ):
        i32 = ir.IntegerType.get_signless(32)
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

        # Shapes are expected to be int32 so truncate to that before creating layout
        shape_i32 = tuple(arith.trunci(i32, s) for s in shape)

        # Apply per-mode divisibility assumptions so the compiler can exploit alignment.
        if self.divisibility is not None:
            assumed = []
            for s32, div_spec, static_s in zip(
                shape_i32, self.divisibility, self.shape
            ):
                if isinstance(static_s, int):
                    # Pure static shape is known even though a dynamic shape is
                    # used. We can assume the exact shape here. We keep the shape
                    # as a dynamic value to avoid breaking code that may expect
                    # a dynamic value.
                    assumed.append(cute.assume(s32, divby=static_s))
                elif div_spec is not None:
                    # Using a dynamic value so apply the div_spec if its provided.
                    assumed.append(cute.assume(s32, divby=div_spec))
                else:
                    # No divisibility specification for this shape
                    assumed.append(s32)
            shape_i32 = tuple(assumed)

        return cute.make_layout(shape_i32, stride=tuple(strides_ordered))

    def _load_dynamic_shapes(
        self,
        ffi_buffer,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ):
        i64 = ir.IntegerType.get_signless(64)
        shape_array = llvm.extractvalue(
            llvm.PointerType.get(),
            ffi_buffer,
            [1],
            loc=loc,
            ip=ip,
        )

        shape_i64 = []
        for i in range(len(self.shape)):
            r = llvm.getelementptr(
                llvm.PointerType.get(),
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
        ffi_buffer,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ):
        raw_ptr = llvm.extractvalue(
            llvm.PointerType.get(),
            ffi_buffer,
            [0],
            loc=loc,
            ip=ip,
        )
        return cute.make_ptr(
            self.dtype,
            raw_ptr,
            self.mem_space,
            assumed_align=self.assumed_align,
            loc=loc,
            ip=ip,
        )

    def get_tensor(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ):
        ffi_buffer_type = llvm.StructType.get_literal(
            [llvm.PointerType.get(), llvm.PointerType.get()]
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

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        return JaxArrayValue(
            values[0],
            self.dtype,
            self.shape,
            self.mem_space,
            self.assumed_align,
            self.order,
            self.mode,
            self.static,
            self.divisibility,
        )


class JaxTracedArray(JaxArray):
    """Represents a traced array value that is used for cute.compile.

    Traced values are not real tensors or allocated on the device.
    """

    def __str__(self):
        return f"JaxTracedArray<{self.dtype}:{self.shape}:{self.order}:{self.mode}:{self.static}:{self.divisibility}>"

    def __repr__(self):
        return str(self)

    def __get_mlir_types__(self):
        # Struct passed as opaque object.
        return [llvm.PointerType.get()]

    def __new_from_mlir_values__(self, values):
        return JaxArrayValue(
            values,
            self.dtype,
            self.shape,
            self.mem_space,
            self.assumed_align,
            self.order,
            self.mode,
            self.static,
            self.divisibility,
        )

    def __c_pointers__(self):
        return [0]


class JaxArrayList:
    """Holds list of JaxArray or JaxTracedArray.
    This class facilitates conversion of JaxTracedArray to JaxArray when crossing
    the jit boundary.
    """

    def __init__(self, arrays: Sequence[JaxArray]):
        self.arrays = tuple(arrays)

    def __getitem__(self, idx):
        return self.arrays[idx]

    def __len__(self):
        return len(self.arrays)

    def __iter__(self):
        return iter(self.arrays)

    def __c_pointers__(self):
        return [x.__c_pointers__()[0] for x in self.arrays]

    def __get_mlir_types__(self):
        return [x.__get_mlir_types__()[0] for x in self.arrays]

    def __extract_mlir_values__(self):
        return [x.__extract_mlir_values__()[0] for x in self.arrays]

    def __new_from_mlir_values__(self, values):
        return JaxArrayList(
            [x.__new_from_mlir_values__(v) for x, v in zip(self.arrays, values)]
        )
