# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
This module provides MLIR Vector Dialect helper classes.
"""

import array
import builtins
from collections.abc import Sequence
from typing import TYPE_CHECKING, Any, Literal, Optional, Type, Union, cast

from .._mlir import ir
from .._mlir.extras import types as T
from .._mlir.dialects import arith, vector, llvm
from .op import dsl_user_op
from .arith import (
    ArithValue,
    _cast,
    const,
    cvtf,
    element_type,
    fptoi,
    int_to_int,
    itofp,
)

if TYPE_CHECKING:
    from ..base_dsl.typing import Int32, Numeric

# =============================================================================
# Vector Type - Immutable on registers
# =============================================================================


@ir.register_value_caster(ir.VectorType.static_typeid)
class Vector(ArithValue):
    """Wrap an MLIR ``vector<NxTy>`` register value with DSL type information.

    Provides element extraction (``vec[i]`` / ``vec[a:b]``), element-wise
    arithmetic (``+``, ``-``, ``*``, ``/``), type conversion (:meth:`to`),
    and bit-reinterpretation (:meth:`bitcast`) on top of a raw MLIR vector.

    Vectors live entirely in registers — they carry no memory address and do
    not support in-place element assignment.

    Registered as the MLIR value caster for :class:`ir.VectorType`, so any
    op that returns a vector automatically produces a ``Vector`` instance.

    :param v: Underlying MLIR vector value.
    :type v: ir.Value
    :param dtype: DSL element type (e.g. ``Float32``, ``Int32``).
        Inferred from the MLIR element type when omitted.
    :type dtype: type, optional
    """

    _dtype: Type["Numeric"]
    _mlir_type: ir.Type
    _shape: "tuple[int, ...]"

    # Cache parameterized subclasses so ``Vector[T, N] is Vector[T, N]``.
    _parameterized_cache: "dict[tuple, type]" = {}

    @classmethod
    def __class_getitem__(cls, params: "tuple[type, int | tuple[int, ...]]") -> type:
        """Return a parameterized Vector subclass with a ``mlir_type`` descriptor.

        ``Vector[Int32, 4].mlir_type`` returns ``vector<4xi32>`` and
        ``Vector[Float32, (4, 8)].mlir_type`` returns ``vector<4x8xf32>``,
        matching the dual type-descriptor / value-constructor pattern of
        scalar types like ``Int32``.  Follows the same approach as
        ``Pointer.__class_getitem__``.
        """
        element_type, shape = params

        from ..base_dsl.typing import Numeric

        if not (isinstance(element_type, type) and issubclass(element_type, Numeric)):
            raise TypeError(
                f"Vector element type must be a Numeric type (Integer or Float), "
                f"got {element_type!r}"
            )
        if isinstance(shape, int):
            shape = (shape,)
        shape = tuple(shape)
        if not shape or any(d <= 0 for d in shape):
            raise ValueError(
                f"Vector shape dimensions must be positive integers, got {shape}"
            )
        key = (cls, element_type, shape)
        if key not in cls._parameterized_cache:
            shape_str = "x".join(str(d) for d in shape)

            class _Parameterized(cls):  # type: ignore[valid-type, misc]
                """Vector subclass with an ``mlir_type`` type descriptor."""

                class mlir_type:  # noqa: N801
                    def __get__(
                        self, obj: object, objtype: Optional[type] = None
                    ) -> ir.Type:
                        return ir.VectorType.get(list(shape), element_type.mlir_type)  # type: ignore[arg-type, attr-defined]

                mlir_type = mlir_type()  # type: ignore[misc, assignment]

                @staticmethod
                def __get_mlir_types__() -> list:
                    """Return MLIR types list — compatible with FFI ``_to_mlir_types``."""
                    return [ir.VectorType.get(list(shape), element_type.mlir_type)]  # type: ignore[arg-type, attr-defined]

                @staticmethod
                def isinstance(value: object) -> bool:
                    """Check if an ``ir.Value`` matches this parameterized vector type."""
                    if not builtins.isinstance(value, ir.Value):
                        return False
                    ty = value.type
                    if not builtins.isinstance(ty, ir.VectorType):
                        return False
                    return (
                        list(ty.shape) == list(shape)  # type: ignore[arg-type]
                        and ty.element_type == element_type.mlir_type  # type: ignore[attr-defined]
                    )

            _Parameterized.__name__ = f"Vector[{element_type.__name__}, {shape_str}]"
            _Parameterized.__qualname__ = _Parameterized.__name__
            cls._parameterized_cache[key] = _Parameterized
        return cls._parameterized_cache[key]

    def __init__(
        self,
        v: "ir.Value",
        *,
        dtype: "Type[Numeric] | None" = None,
        loc: "ir.Location | None" = None,
        ip: "ir.InsertionPoint | None" = None,
    ) -> None:
        # Derive signedness from dtype for ArithValue base
        signed = getattr(dtype, "signed", None)
        super().__init__(v, signed, loc=loc, ip=ip)

        # Infer dtype from MLIR element type if not provided
        if dtype is None:
            from ..base_dsl.common import DSLRuntimeError
            from ..base_dsl.typing import Numeric

            try:
                dtype = Numeric.from_mlir_type(self.type.element_type)
            except DSLRuntimeError as exc:
                try:
                    llvm.PointerType(self.type.element_type)
                except Exception:
                    raise exc from None
                dtype = None
        # Pointer element vectors are transient lowering values; numeric vector
        # APIs still require a Numeric dtype and will fail if used on them.
        self._dtype = cast("Type[Numeric]", dtype)
        self._mlir_type = (
            dtype.mlir_type if dtype is not None else self.type.element_type
        )

        # Shape is always derived from MLIR vector type
        self._shape = tuple(self.type.shape)

    @staticmethod
    @dsl_user_op
    def from_elements(
        scalars: tuple,
        dtype: Type["Numeric"],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Vector":
        """Build a 1-D ``Vector`` from a tuple of scalar values."""
        if len(scalars) == 0:
            raise ValueError("Vector.from_elements requires at least one element")
        elem_ty = dtype.mlir_type
        elements = [_value_to_ir_value(s, elem_ty, loc=loc, ip=ip) for s in scalars]
        vec_type = ir.VectorType.get([len(scalars)], elem_ty)
        ir_val = vector.from_elements(vec_type, elements, loc=loc, ip=ip)
        return Vector(ir_val, dtype=dtype, loc=loc, ip=ip)

    # =========================================================================
    # DSL Infrastructure
    # =========================================================================

    def __extract_mlir_values__(self) -> list:
        return [self]

    def __extract_mlir_attributes__(self) -> list:
        return [ir.DictAttr.get({})]

    def __new_from_mlir_values__(self, values: list) -> "Vector":
        return self._wrap_like(values[0])

    def _wrap_like(self, result_ir: "ir.Value") -> "Vector":
        """Construct a new instance of the same type from a result IR value.

        Subclasses (e.g., :class:`TensorSSA`) override to preserve their own
        metadata (CuTe nested shape, layout). The math foundation uses this
        for polymorphic result wrapping so a math op on a TensorSSA returns
        a TensorSSA, not a Vector.
        """
        return type(self)(result_ir, dtype=self._dtype)

    def _wrap_result(
        self,
        result_ir: "ir.Value",
        *,
        dtype: "type | None" = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Construct a result wrapper, optionally with a different dtype."""
        return type(self)(
            result_ir,
            dtype=self._dtype if dtype is None else dtype,
            loc=loc,
            ip=ip,
        )

    def with_signedness(self, signed: Union[bool, None]) -> "Vector":
        """Override ArithValue.with_signedness for keyword-only __init__."""
        new_vec = self._wrap_like(self)
        elem_ty = self.type.element_type
        new_vec.signed = (
            signed
            and ir.IntegerType.isinstance(elem_ty)
            and ir.IntegerType(elem_ty).width > 1
        )
        return new_vec

    # =========================================================================
    # Properties
    # =========================================================================

    @property
    def dtype(self) -> Type["Numeric"]:
        """The DSL element type (e.g., Float32, Int32)."""
        return self._dtype

    @property
    def shape(self) -> "tuple[int, ...]":
        """The logical shape of the vector array (1D, 2D, or 3D)."""
        return self._shape

    @property
    def _count(self) -> int:
        """Total number of elements (product of shape dimensions)."""
        result = 1
        for dim in self._shape:
            result *= dim
        return result

    def numel(self) -> int:
        """Total number of elements (product of all shape dimensions)."""
        return self._count

    @staticmethod
    def _normalize_static_slice(
        idx: slice,
        extent: int,
        *,
        error_context: str,
    ) -> "tuple[int, int, int, list[int]]":
        """Normalize a Python slice and reject unsupported empty/reverse forms."""
        if not all(
            isinstance(v, int) or v is None for v in (idx.start, idx.stop, idx.step)
        ):
            context = f" {error_context}" if error_context else ""
            raise TypeError(
                f"Vector slice indices must be static ints{context}; "
                f"got start={idx.start}, stop={idx.stop}, step={idx.step}"
            )
        try:
            start, stop, step = idx.indices(extent)
        except ValueError as exc:
            raise ValueError("Vector slices require a non-zero step") from exc
        if step <= 0:
            raise ValueError("Vector slices require a positive step")

        positions = list(range(start, stop, step))
        if not positions:
            raise IndexError("Empty vector slices are not supported")
        if any(pos < 0 or pos >= extent for pos in positions):
            raise IndexError(
                f"Vector slice produced out-of-bounds indices {positions} "
                f"for extent {extent}"
            )
        return start, stop, step, positions

    # Vector has no memory space - it's always in registers
    # The space property is intentionally not exposed on Vector

    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        """Return the underlying MLIR vector value."""
        return self

    # =========================================================================
    # Indexing Operations
    # =========================================================================

    def _compute_linear_index(
        self,
        indices: "tuple[Union[int, Int32], ...]",  # type: ignore[name-defined]
    ) -> "Union[int, Int32]":  # type: ignore[name-defined]
        """Compute linear index from multi-dimensional indices (row-major order)."""
        if len(indices) != len(self._shape):
            raise IndexError(
                f"Expected {len(self._shape)} indices for shape {self._shape}, "
                f"got {len(indices)}"
            )

        # Check if all indices are static (Python ints)
        all_static = all(isinstance(i, int) for i in indices)

        if all_static:
            # Static computation
            linear = 0
            stride = 1
            for i in range(len(self._shape) - 1, -1, -1):
                linear += indices[i] * stride
                stride *= self._shape[i]
            return linear
        else:
            from ..base_dsl.typing import Int32

            # Dynamic computation using Int32 arithmetic
            linear = Int32(0)  # type: ignore[assignment]
            stride = 1
            for i in range(len(self._shape) - 1, -1, -1):
                idx = indices[i] if isinstance(indices[i], Int32) else Int32(indices[i])
                linear = linear + idx * Int32(stride)
                stride *= self._shape[i]
            return linear

    def __getitem__(
        self,
        idx: "Union[int, Int32, tuple, slice]",  # type: ignore[name-defined]
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> object:
        """Extract an element or a contiguous sub-vector.

        Supports three indexing modes:

        * **Scalar index** — returns a single DSL scalar value::

            elem = vec[i]          # static int or Int32

        * **1-D slice** — all bounds must be static Python ``int``s::

            sub = vec[start:stop]        # stride defaults to 1
            sub = vec[start:stop:stride] # explicit stride

        * **Multi-dimensional slice** — one entry per dimension, all bounds
          must be static ``int``s.  An integer in a multi-dim slice is treated
          as a size-1 slice (the dimension is kept)::

            sub = mat[r0:r1, c0:c1]   # 2-D: rows r0:r1, cols c0:c1
            sub = mat[:, c0:c1]       # 2-D: all rows, cols c0:c1
            sub = mat[0, c0:c1]       # 2-D: row 0 (size 1), cols c0:c1

        Slices use ``vector.extract_strided_slice`` internally; dynamic
        (MLIR-value) slice bounds are **not** supported.

        :param idx: Element index (int or Int32), a slice, or a tuple of
            ints/slices for multi-dimensional access.
        :type idx: int or Int32 or tuple or slice
        :return: A scalar DSL value (for element indexing) or a new
            :class:`Vector` (for slice indexing).
        :rtype: Numeric or Vector
        :raises TypeError: If slice bounds are not static Python ints.
        :raises IndexError: If the number of dimensions in a multi-dim index
            does not match :attr:`shape`.
        """
        from ..base_dsl.utils.logger import log

        # Slice → extract_strided_slice (step==1) or vector.shuffle (step>1)
        if isinstance(idx, slice):
            if len(self._shape) != 1:
                raise TypeError(
                    "Use per-dimension indexing for multi-dimensional vectors, "
                    "e.g. vec[a:b, :]"
                )
            start, _stop, step, positions = self._normalize_static_slice(
                idx, self._count, error_context=""
            )
            size = len(positions)
            result_ty = ir.VectorType.get([size], self._mlir_type)
            if step == 1:
                result = vector.extract_strided_slice(
                    result_ty, self, [start], [size], [step], loc=loc, ip=ip
                )
            else:
                # vector.extract_strided_slice requires stride==1; use shuffle instead
                result = vector.shuffle(self, self, positions, loc=loc, ip=ip)
            return self._wrap_result(result, loc=loc, ip=ip)

        # Multi-dimensional slice: tuple containing at least one slice object
        if isinstance(idx, tuple) and any(isinstance(i, slice) for i in idx):
            if len(idx) != len(self._shape):
                raise IndexError(
                    f"Expected {len(self._shape)} indices for shape {self._shape}, "
                    f"got {len(idx)}"
                )
            offsets: "list[int]" = []
            sizes: "list[int]" = []
            strides: "list[int]" = []
            for dim, (i, dim_size) in enumerate(zip(idx, self._shape)):
                if isinstance(i, slice):
                    start, _stop, step, positions = self._normalize_static_slice(
                        i, dim_size, error_context=f"in dimension {dim}"
                    )
                    if step != 1:
                        raise NotImplementedError(
                            f"Multi-dimensional strided slice (step={step}) is not supported; "
                            "use step=1 for multi-dimensional slices"
                        )
                    offsets.append(start)
                    sizes.append(len(positions))
                    strides.append(1)
                elif isinstance(i, int):
                    # Integer index: treated as a size-1 slice (rank is preserved)
                    if i < 0:
                        i += dim_size
                    if i < 0 or i >= dim_size:
                        raise IndexError(
                            f"Vector index {i} out of bounds for dimension {dim} "
                            f"with size {dim_size}"
                        )
                    offsets.append(i)
                    sizes.append(1)
                    strides.append(1)
                else:
                    raise TypeError(
                        f"Vector multi-dimensional slice: dimension {dim} index must be "
                        f"a static int or slice, got {type(i).__name__}"
                    )
            result_ty = ir.VectorType.get(sizes, self._mlir_type)
            result = vector.extract_strided_slice(
                result_ty, self, offsets, sizes, strides, loc=loc, ip=ip
            )
            return self._wrap_result(result, loc=loc, ip=ip)

        # Normalize to tuple
        if not isinstance(idx, tuple):
            indices = (idx,)
        else:
            indices = idx

        if len(indices) != len(self._shape):
            raise IndexError(
                f"Expected {len(self._shape)} indices for shape {self._shape}, "
                f"got {len(indices)}"
            )

        if all(isinstance(i, int) for i in indices):
            static_indices: "list[int]" = []
            for dim, (i, dim_size) in enumerate(zip(indices, self._shape)):
                if i < 0:
                    i += dim_size
                if i < 0 or i >= dim_size:
                    raise IndexError(
                        f"Vector index {i} out of bounds for dimension {dim} "
                        f"with size {dim_size}"
                    )
                static_indices.append(i)
            log().info(
                f"Vector.__getitem__: idx={idx}, static={static_indices}, "
                f"dtype={self._dtype}, shape={self._shape}"
            )
            elem = vector.extract(self, [], static_indices, loc=loc, ip=ip)
        else:
            if len(self._shape) != 1:
                raise NotImplementedError(
                    "Dynamic Vector indexing is currently only supported for 1-D vectors"
                )
            linear_idx = self._compute_linear_index(indices)
            log().info(
                f"Vector.__getitem__: idx={idx}, linear={linear_idx}, "
                f"dtype={self._dtype}, shape={self._shape}"
            )
            if isinstance(linear_idx, int):
                from ..base_dsl.typing import Int32

                linear_idx = Int32(linear_idx)
            elem = llvm.extractelement(self, linear_idx.ir_value(), loc=loc, ip=ip)

        return self._dtype(elem)

    @dsl_user_op
    def to_elements(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "tuple[Numeric, ...]":
        """Extract every vector lane as scalar DSL values.

        This is useful when a vectorized operation should define many scalar
        SSA values that are then consumed independently.
        """
        raw_elements = vector.to_elements(self.ir_value(loc=loc, ip=ip))
        if self._count == 1 and not isinstance(raw_elements, Sequence):
            raw_elements = (raw_elements,)
        return tuple(self._dtype(elem, loc=loc, ip=ip) for elem in raw_elements)

    def __setitem__(
        self,
        idx: "Union[int, Int32, tuple]",  # type: ignore[name-defined]
        value: object,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Vector element assignment is not supported.

        Vectors are immutable register values. Use one of these alternatives:

        1. Use a frontend memory-backed tensor or array abstraction for
           mutable storage.

        2. Use full() to create vectors with initial values:
           vec = cute.full((4,), 1.0, dtype=cutlass.Float32).to_vector()
        """
        raise TypeError(
            "Vector is immutable. Element assignment (vec[i] = value) is not supported. "
        )

    # =========================================================================
    # Arithmetic Operations
    # =========================================================================

    def _is_float_type(self) -> bool:
        """Check if this vector contains floating-point elements."""
        return self._dtype.is_float

    # Arithmetic operators delegate to ArithValue and wrap results with the
    # same concrete Vector subclass.

    def to(
        self,
        dtype: "type",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Convert the vector elements to a different numeric type.

        :param dtype: Target DSL element type (e.g. ``Float16``, ``Int32``).
        :type dtype: Type[Numeric]
        :return: A new :class:`Vector` with the same shape and elements cast
            to ``dtype``.
        :rtype: Vector
        :raises TypeError: If ``dtype`` is not a subclass of ``Numeric``.

        Example::

            vec_f32 = cute.full((4,), 1.5, dtype=cutlass.Float32).to_vector()
            vec_i32 = vec_f32.to(cutlass.Int32)    # fp → int truncation
            vec_f16 = vec_f32.to(cutlass.Float16)  # fp32 → fp16 narrowing
        """
        from inspect import isclass
        from ..base_dsl.typing import Numeric, Integer

        if dtype is ir.Value:
            return self

        if not isclass(dtype) or not issubclass(dtype, Numeric):
            raise TypeError(f"dtype must be a type of Numeric, but got {type(dtype)}")

        src_dtype = self._dtype
        if src_dtype == dtype:
            return self

        # maybe_downcast handles narrow precision types, with_signedness sets signedness
        src = self.maybe_downcast().with_signedness(self.signed)

        if src_dtype.is_float and dtype.is_float:
            res_vect = cvtf(src, dtype.mlir_type, loc=loc, ip=ip)
        elif src_dtype.is_float and issubclass(dtype, Integer):
            res_vect = fptoi(src, dtype.signed, dtype.mlir_type, loc=loc, ip=ip)
        elif issubclass(src_dtype, Integer) and dtype.is_float:
            res_vect = itofp(src, src_dtype.signed, dtype.mlir_type, loc=loc, ip=ip)
        else:
            res_vect = int_to_int(src, dtype, loc=loc, ip=ip)

        return self._wrap_result(res_vect, dtype=dtype, loc=loc, ip=ip)

    @dsl_user_op
    def bitcast(
        self,
        dtype: "type",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Reinterpret the vector bits as a different element type.

        The total bit width is preserved; the element count adjusts
        proportionally.  For example, ``vector<4xi32>`` bitcast to
        ``Float16`` yields ``vector<8xf16>`` (4 × 32 = 8 × 16 bits).

        :param dtype: Target DSL element type (e.g. ``Float32``, ``Float16``).
        :type dtype: Type[Numeric]
        :return: A new :class:`Vector` with bits reinterpreted as ``dtype``.
        :rtype: Vector
        :raises TypeError: If ``dtype`` is not a subclass of ``Numeric``.
        """
        from inspect import isclass
        from ..base_dsl.typing import Numeric

        if not isclass(dtype) or not issubclass(dtype, Numeric):
            raise TypeError(f"dtype must be a Numeric type, but got {dtype}")
        if dtype is self._dtype:
            return self
        total_bits = self._count * self._dtype.width
        if total_bits % dtype.width != 0:
            raise ValueError(
                f"Cannot bitcast {self.type} to {dtype}: "
                "total bit width must match exactly"
            )
        new_count = total_bits // dtype.width
        target_vec_ty = T.vector(new_count, dtype.mlir_type)
        res_vec = vector.bitcast(target_vec_ty, self, loc=loc, ip=ip)
        return self._wrap_result(res_vec, dtype=dtype, loc=loc, ip=ip)

    def _broadcast_scalar_operand(
        self,
        other: Any,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        """If *other* is a runtime scalar, splat it to this Vector's shape.

        Python ``int`` / ``float`` / ``bool`` literals pass through
        (``_binary_op`` will coerce via ``const`` with self.type, which
        already produces a vector-shaped constant).  Runtime scalar
        ``ArithValue`` / ``Numeric`` values don't: they retain their 0-dim
        MLIR type and the arith dialect rejects `arith.mulf(vec, scalar)`.
        Broadcast them via ``vector.broadcast`` so ``vec +/-/*/÷ scalar``
        behaves like a full-vector splat of that scalar.
        """
        if isinstance(other, (int, float, bool)):
            return other
        # Normalise to ir.Value — Numeric wrappers expose .ir_value(); bare
        # ir.Value / ArithValue already is one.
        if hasattr(other, "ir_value"):
            scalar_ir = other.ir_value(loc=loc, ip=ip)
        else:
            scalar_ir = other
        # Runtime Vector operand — already shape-matched; leave alone.
        if isinstance(scalar_ir.type, ir.VectorType):
            return other
        # Runtime scalar — element type must match the Vector's element type
        # before `vector.broadcast`, otherwise the op verifier rejects the
        # splat (``result.elementType != operand.type``). Cast first when the
        # runtime scalar was produced at a different precision (e.g. a
        # Float32 constant into an fp16 Vector, or an Int32 index into an
        # Int64 Vector). `_cast` is a no-op when types already match.
        vec_elem = self.type.element_type
        if scalar_ir.type != vec_elem:
            scalar_ir = _cast(vec_elem, scalar_ir, loc=loc, ip=ip)
        splat = vector.broadcast(self.type, scalar_ir, loc=loc, ip=ip)
        return self._wrap_like(splat)

    @dsl_user_op
    def __add__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__add__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __radd__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__radd__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __sub__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__sub__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __rsub__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__rsub__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __mul__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__mul__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __rmul__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__rmul__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __truediv__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__truediv__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    @dsl_user_op
    def __rtruediv__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        other = self._broadcast_scalar_operand(other, loc=loc, ip=ip)
        result = super().__rtruediv__(other, loc=loc, ip=ip)
        return self._wrap_like(result)

    # =========================================================================
    # Reduction — vector.reduction wrapper
    # =========================================================================

    _REDUCE_KINDS = {
        "add": lambda self: vector.CombiningKind.ADD,
        "mul": lambda self: vector.CombiningKind.MUL,
        "min": lambda self: (
            vector.CombiningKind.MINNUMF
            if self._is_float_type()
            else (
                vector.CombiningKind.MINSI
                if getattr(self._dtype, "signed", True)
                else vector.CombiningKind.MINUI
            )
        ),
        "max": lambda self: (
            vector.CombiningKind.MAXNUMF
            if self._is_float_type()
            else (
                vector.CombiningKind.MAXSI
                if getattr(self._dtype, "signed", True)
                else vector.CombiningKind.MAXUI
            )
        ),
    }

    @dsl_user_op
    def reduce(
        self,
        op: Literal["add", "mul", "min", "max"] = "add",
        *,
        dim: Optional[Union[int, list[int]]] = None,
        acc: Any = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        """Reduce the vector using the specified combining operation.

        When ``dim`` is ``None`` (default), reduces **all** dimensions to a
        scalar via ``vector.reduction``.  When ``dim`` is an int or list of
        ints, reduces only those dimensions via ``vector.multi_reduction``,
        returning a lower-rank :class:`Vector`.

        :param op: Reduction operation — one of ``"add"``, ``"mul"``,
            ``"min"``, ``"max"``.  For ``"min"``/``"max"`` the combining
            kind adapts automatically to the element type (float vs signed
            vs unsigned integer).
        :param dim: Dimension(s) to reduce.  ``None`` reduces all dims to a
            scalar.  An int or list of ints reduces only those dims.
        :param acc: Optional accumulator.  For scalar reduction a scalar value;
            for multi-dim reduction a vector matching the result shape.
        :return: Scalar (when ``dim is None``) or :class:`Vector` (when
            ``dim`` is specified).

        Examples:

            .. code-block:: python

                v = cute.full((4,), 3.0, dtype=cutlass.Float32).to_vector()
                v.reduce("add")          # 12.0  (scalar)

                m = cute.full((4, 8), 1.0, dtype=cutlass.Float32).to_vector()
                m.reduce("add", dim=1)   # vector<4xf32>, each element = 8.0
                m.reduce("add", dim=0)   # vector<8xf32>, each element = 4.0

        .. note::

            This method operates on a ``Vector`` value. If a higher-level API
            in a downstream library returns a different SSA wrapper with its
            own ``reduce(...)`` method and a different signature, call that
            library's ``.to_vector()`` (or equivalent) to get a plain
            ``Vector`` first so this 1-arg form applies.

        .. note::

            ``Vector.reduce`` builds an MLIR ``vector.reduction`` over the
            elements of one register vector. It is not the warp-collective
            ``nvvm.redux_sync`` API. If a backend or target-specific
            lowering maps a reduction to PTX ``redux.sync``, PTX legality still
            applies: integer/bitwise ``redux.sync`` forms require ``sm_80`` or
            higher, while ``redux.sync`` ``.f32`` min/max support was added in
            PTX ISA 8.6 and is limited to ``sm_100a`` plus the ``sm_100f``
            family support added in PTX ISA 8.8. For examples that must remain
            portable to generic ``sm_120`` targets, prefer an explicit scalar
            fold or shuffle tree for ``Float32`` min/max instead of relying on
            a lowering that may choose ``redux.sync.f32``.
        """
        kind_fn = self._REDUCE_KINDS.get(op)
        if kind_fn is None:
            raise ValueError(
                f"Unknown reduction op {op!r}. "
                f"Expected one of: {', '.join(sorted(self._REDUCE_KINDS))}"
            )
        kind = kind_fn(self)
        vec_ty = ir.VectorType(self.type)
        elem_ty = vec_ty.element_type

        ndim = len(vec_ty.shape)

        if dim is None and ndim == 1:
            # 1-D full reduction to scalar — wrap in _dtype so type info is preserved
            raw = vector.reduction(elem_ty, kind, self, acc=acc, loc=loc, ip=ip)
            return self._dtype(raw)

        # Multi-dimension reduction
        if dim is None:
            # Reduce all dims for N-D vector
            reduction_dims = list(range(ndim))
        else:
            reduction_dims = [dim] if isinstance(dim, int) else list(dim)
            if not reduction_dims:
                raise ValueError("Reduction dims must be non-empty")
            if len(set(reduction_dims)) != len(reduction_dims):
                raise ValueError(f"Reduction dims must be unique, got {reduction_dims}")
        for d in reduction_dims:
            if d < 0 or d >= ndim:
                raise ValueError(f"Reduction dim {d} out of range for {ndim}-D vector")

        # Compute result shape and build accumulator
        result_shape = [
            s for i, s in enumerate(vec_ty.shape) if i not in reduction_dims
        ]
        if not result_shape:
            # All dims reduced on N-D vector — reduce to 1-D first, then scalar
            # Keep dim 0 to get a 1-D vector via multi_reduction
            partial_dims = list(range(1, ndim))
            partial_shape = [vec_ty.shape[0]]
            partial_acc_ty = ir.VectorType.get(partial_shape, elem_ty)
            init_map = {
                "add": 0.0 if self._is_float_type() else 0,
                "mul": 1.0 if self._is_float_type() else 1,
            }
            if op in init_map:
                p_init = init_map[op]
            else:
                import math

                if self._is_float_type():
                    p_init = math.inf if op == "min" else -math.inf
                else:
                    width = self._dtype.width
                    signed = getattr(self._dtype, "signed", True)
                    if op == "min":
                        p_init = (1 << (width - 1)) - 1 if signed else (1 << width) - 1
                    else:
                        p_init = -(1 << (width - 1)) if signed else 0
            p_scalar = arith.constant(elem_ty, p_init, loc=loc, ip=ip)
            p_acc = vector.broadcast(partial_acc_ty, p_scalar, loc=loc, ip=ip)
            vec_1d = vector.multi_reduction(
                kind, self, acc=p_acc, reduction_dims=partial_dims, loc=loc, ip=ip
            )
            raw = vector.reduction(elem_ty, kind, vec_1d, acc=acc, loc=loc, ip=ip)
            return self._dtype(raw)

        if acc is None:
            # Build identity accumulator for the result shape
            init_map = {
                "add": 0.0 if self._is_float_type() else 0,
                "mul": 1.0 if self._is_float_type() else 1,
            }
            if op in init_map:
                init_val = init_map[op]
            else:
                # For min/max, use the first slice as initial value —
                # MLIR requires an acc, so broadcast a neutral constant.
                # Use extreme values: for float min → +inf, max → -inf
                import math

                if self._is_float_type():
                    init_val = math.inf if op == "min" else -math.inf
                else:
                    # Integer: use max/min representable value
                    width = self._dtype.width
                    signed = getattr(self._dtype, "signed", True)
                    if op == "min":
                        init_val = (
                            (1 << (width - 1)) - 1 if signed else (1 << width) - 1
                        )
                    else:  # max
                        init_val = -(1 << (width - 1)) if signed else 0

            acc_ty = ir.VectorType.get(result_shape, elem_ty)
            init_scalar = arith.constant(elem_ty, init_val, loc=loc, ip=ip)
            acc = vector.broadcast(acc_ty, init_scalar, loc=loc, ip=ip)

        result = vector.multi_reduction(
            kind, self, acc=acc, reduction_dims=reduction_dims, loc=loc, ip=ip
        )
        return self._wrap_result(result, loc=loc, ip=ip)


def _shape_tuple(shape: Union[int, Sequence[int]]) -> tuple[int, ...]:
    if isinstance(shape, int):
        shape = (shape,)
    return tuple(shape)


def _scalar_to_ir_value(
    scalar: object,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    from ..base_dsl.typing import Numeric

    if isinstance(scalar, Numeric):
        return scalar.ir_value(loc=loc, ip=ip)
    if isinstance(scalar, ArithValue):
        return scalar.ir_value(loc=loc, ip=ip)
    if isinstance(scalar, ir.Value):
        return scalar
    if isinstance(scalar, (int, float, bool)):
        return const(scalar, loc=loc, ip=ip)
    raise ValueError(f"Expected scalar value, got {scalar}")


def _value_to_ir_value(
    value: object,
    elem_type: ir.Type,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    from ..base_dsl.typing import Numeric

    if isinstance(value, (int, float, bool)):
        return const(value, elem_type, loc=loc, ip=ip)

    if isinstance(value, Numeric):
        value = value.ir_value(loc=loc, ip=ip)
    elif isinstance(value, ArithValue):
        value = value.ir_value(loc=loc, ip=ip)

    if isinstance(value, ir.Value):
        if value.type != elem_type:
            value = _cast(elem_type, value, loc=loc, ip=ip)
        return value

    raise NotImplementedError(
        f"Expected a Python scalar, Numeric, ArithValue, or ir.Value, "
        f"got {type(value).__name__!r}"
    )


def _infer_element_type(value: object) -> ir.Type:
    from ..base_dsl.typing import Numeric

    if isinstance(value, float):
        return T.f32()
    if isinstance(value, bool):
        return T.bool()
    if isinstance(value, int):
        return T.i32()
    if isinstance(value, Numeric):
        return value.dtype.mlir_type
    if isinstance(value, (ArithValue, ir.Value)):
        return element_type(value.type)
    raise NotImplementedError(
        f"Cannot infer element type from value of type {type(value).__name__!r}"
    )


@dsl_user_op
def create_mask(
    shape: Sequence[int],
    dim_sizes: Sequence[Union[int, "Numeric"]],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Create a boolean ``Vector`` mask for ``shape`` and dynamic bounds.

    ``mask[i]`` is true when each index is less than the corresponding
    exclusive bound in ``dim_sizes``. For a keep-through-last-valid pattern,
    pass ``last_valid + 1``.
    """
    if not isinstance(dim_sizes, Sequence):
        raise TypeError("dim_sizes must be a sequence of integers")

    shape = _shape_tuple(shape)
    dim_size_values = [_scalar_to_ir_value(s, loc=loc, ip=ip) for s in dim_sizes]
    bool_ty = T.bool()
    res_ty = ir.VectorType.get(list(shape), element_type=bool_ty)
    i64_ty = ir.IntegerType.get_signless(64)

    def _cast_bound_to_i64(s: ir.Value) -> ir.Value:
        if ir.IntegerType.isinstance(s.type):
            width = ir.IntegerType(s.type).width
            if width == 64:
                return s
            if width > 64:
                return arith.trunci(i64_ty, s, loc=loc, ip=ip)
            if getattr(s, "signed", True) is False:
                return arith.extui(i64_ty, s, loc=loc, ip=ip)
            return arith.extsi(i64_ty, s, loc=loc, ip=ip)
        if ir.IndexType.isinstance(s.type):
            return arith.index_cast(i64_ty, s, loc=loc, ip=ip)
        raise TypeError(
            f"Mask dimension sizes must be integer or index values, got {s.type}"
        )

    def _build_1d_mask(n: int, s: ir.Value) -> ir.Value:
        s = _cast_bound_to_i64(s)
        iota_ty = ir.VectorType.get([n], element_type=i64_ty)
        iota_attr = ir.DenseElementsAttr.get(
            array.array("q", list(range(n))), type=iota_ty
        )
        iota = arith.constant(iota_ty, iota_attr, loc=loc, ip=ip)
        splat_ty = ir.VectorType.get([n], element_type=i64_ty)
        dim_splat = vector.broadcast(splat_ty, s, loc=loc, ip=ip)
        return arith.cmpi(arith.CmpIPredicate.slt, iota, dim_splat, loc=loc, ip=ip)

    if len(shape) == 1:
        mask = _build_1d_mask(shape[0], dim_size_values[0])
    elif len(shape) == 2:
        m, n = shape
        col_mask = _build_1d_mask(n, dim_size_values[1])
        col_bc_ty = ir.VectorType.get([m, n], element_type=bool_ty)
        col_bc = vector.broadcast(col_bc_ty, col_mask, loc=loc, ip=ip)

        d0 = _cast_bound_to_i64(dim_size_values[0])

        d0_bc_ty = ir.VectorType.get([m, n], element_type=i64_ty)
        d0_bc = vector.broadcast(d0_bc_ty, d0, loc=loc, ip=ip)
        row_indices = []
        for row in range(m):
            row_indices.extend([row] * n)
        row_iota_2d_ty = ir.VectorType.get([m, n], element_type=i64_ty)
        row_iota_2d_attr = ir.DenseElementsAttr.get(
            array.array("q", row_indices), type=row_iota_2d_ty
        )
        row_iota_2d = arith.constant(row_iota_2d_ty, row_iota_2d_attr, loc=loc, ip=ip)
        row_bc = arith.cmpi(arith.CmpIPredicate.slt, row_iota_2d, d0_bc, loc=loc, ip=ip)
        mask = arith.andi(row_bc, col_bc, loc=loc, ip=ip)
    else:
        index_ty = T.index()
        dim_size_indices = [
            arith.index_cast(index_ty, s, loc=loc, ip=ip)
            if not ir.IndexType.isinstance(s.type)
            else s
            for s in dim_size_values
        ]
        mask = vector.create_mask(res_ty, dim_size_indices, loc=loc, ip=ip)
    return mask


@dsl_user_op
def broadcast_to(
    src: Union["Numeric", Vector, int, float, bool, ir.Value],
    target_shape: Sequence[int],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Broadcast a scalar or narrower ``Vector`` to ``target_shape``."""
    from ..base_dsl.typing import Numeric

    target_shape = _shape_tuple(target_shape)
    if isinstance(src, (int, float, bool)):
        elem_type = _infer_element_type(src)
        src = const(src, elem_type, loc=loc, ip=ip)
    elif isinstance(src, Numeric):
        src = src.ir_value(loc=loc, ip=ip)
        elem_type = element_type(src.type)
    elif isinstance(src, Vector):
        elem_type = src.dtype.mlir_type
    elif isinstance(src, ArithValue):
        elem_type = element_type(src.type)
        src = src.ir_value(loc=loc, ip=ip)
    elif isinstance(src, ir.Value):
        elem_type = element_type(src.type)
    else:
        raise NotImplementedError(
            f"broadcast_to does not support src of type {type(src).__name__!r}"
        )

    target_type = T.vector(*target_shape, elem_type)
    return vector.broadcast(target_type, src, loc=loc, ip=ip)


@dsl_user_op
def full(
    shape: Sequence[int],
    fill_value: Union["Numeric", int, float, bool, ir.Value],
    dtype: Optional[Type["Numeric"]] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return a new ``Vector`` of ``shape`` filled with ``fill_value``."""
    shape = _shape_tuple(shape)
    elem_type = _infer_element_type(fill_value) if dtype is None else dtype.mlir_type
    fill_val = _value_to_ir_value(fill_value, elem_type, loc=loc, ip=ip)
    res_type = T.vector(*shape, elem_type)
    return vector.broadcast(res_type, fill_val, loc=loc, ip=ip)


@dsl_user_op
def full_like(
    a: Vector,
    fill_value: Union["Numeric", int, float, bool, ir.Value],
    dtype: Optional[Type["Numeric"]] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return a ``Vector`` filled with ``fill_value`` and shaped like ``a``."""
    return full(a.shape, fill_value, dtype or a.dtype, loc=loc, ip=ip)


@dsl_user_op
def zeros_like(
    a: Vector,
    dtype: Optional[Type["Numeric"]] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return a zero-filled ``Vector`` with the same shape as ``a``."""
    return full_like(a, 0, dtype or a.dtype, loc=loc, ip=ip)


@dsl_user_op
def ones_like(
    a: Vector,
    dtype: Optional[Type["Numeric"]] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return a one-filled ``Vector`` with the same shape as ``a``."""
    return full_like(a, 1, dtype or a.dtype, loc=loc, ip=ip)


@dsl_user_op
def empty_like(
    a: Vector,
    dtype: Optional[Type["Numeric"]] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return an uninitialized ``Vector`` shaped like ``a``.

    This currently returns zeros until the DSL has a distinct undef/poison
    helper for register vectors.
    """
    return full_like(a, 0, dtype or a.dtype, loc=loc, ip=ip)


@dsl_user_op
def where(
    cond: Vector,
    x: Union[Vector, "Numeric", int, float, bool, ir.Value],
    y: Union[Vector, "Numeric", int, float, bool, ir.Value],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Return elements chosen from ``x`` or ``y`` depending on ``cond``."""
    result_dtype = None
    if isinstance(x, Vector):
        result_dtype = x.dtype
    elif isinstance(y, Vector):
        result_dtype = y.dtype

    def _promote(v: object) -> object:
        if isinstance(v, Vector):
            return v
        if isinstance(v, (int, float, bool)):
            return full(cond.shape, v, result_dtype, loc=loc, ip=ip)
        return broadcast_to(v, cond.shape, loc=loc, ip=ip)

    return arith.select(cond, _promote(x), _promote(y), loc=loc, ip=ip)


@dsl_user_op
def any_(
    x: Vector,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> "Numeric":
    """Return true if any vector element is non-zero."""
    from ..base_dsl.typing import Boolean

    zeros = zeros_like(x, loc=loc, ip=ip)
    is_true = x != zeros
    return Boolean(
        vector.reduction(T.bool(), vector.CombiningKind.OR, is_true, loc=loc, ip=ip)
    )


@dsl_user_op
def all_(
    x: Vector,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> "Numeric":
    """Return true if every vector element is non-zero."""
    from ..base_dsl.typing import Boolean

    zeros = zeros_like(x, loc=loc, ip=ip)
    is_true = x != zeros
    return Boolean(
        vector.reduction(T.bool(), vector.CombiningKind.AND, is_true, loc=loc, ip=ip)
    )


@dsl_user_op
def outerproduct(
    a: Vector,
    b: Vector,
    acc: Optional[Vector] = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Vector:
    """Rank-1 outer product of two 1-D vectors with optional accumulation."""
    if len(a.shape) != 1:
        raise ValueError(f"'a' must be 1-D, got shape {a.shape}")
    if len(b.shape) != 1:
        raise ValueError(f"'b' must be 1-D, got shape {b.shape}")

    result_type = ir.VectorType.get([a.shape[0], b.shape[0]], element_type(a.type))
    return vector.outerproduct(
        result_type,
        a,
        b,
        acc=acc,
        kind=vector.CombiningKind.ADD if acc is not None else None,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def print_nd_vector(
    src: Vector,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Print the contents of an N-D ``Vector`` at runtime.

    Device-side debug printf: each thread that reaches this call emits
    its own line. Intended for correctness investigation, **not** for
    production kernels: device ``printf`` serialises across the warp
    and adds a large fixed overhead per call.

    :param src: Vector to print. N-D shapes are reshaped to 1-D
        column-major internally, then printed via ``cute.print_tensor``.
    :type src: Vector

    :sync-class: Per-thread debug printf. Every thread that reaches
        this call emits one line. Output from different threads
        interleaves non-deterministically.
    :elect-safe: **Yes**. Wrap in ``if nvvm.elect_sync():`` to get one
        line per warp instead of 32; wrap in ``if tid == 0:`` for one
        line per CTA.
    :device: All CUDA architectures.
    :side-effects: writes to stdout via device ``printf``. Per-call
        latency is large and serialises the warp; remove before
        benchmarking or shipping.
    """
    from .. import cute
    from ..cute import tensor

    size = 1
    for dim in src.shape:
        size *= dim

    tmp = vector.shape_cast(
        ir.VectorType.get([size], src.dtype.mlir_type), src, loc=loc, ip=ip
    )
    tmp = tensor._row2col(tmp, shape=tuple(src.shape), loc=loc, ip=ip)
    tmp = tensor.TensorSSA(tmp, tuple(src.shape), src.dtype, loc=loc, ip=ip)

    cute.print_tensor(tmp, loc=loc, ip=ip)
