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

from abc import ABC, abstractmethod
import ctypes
from typing import (
    TYPE_CHECKING,
    ForwardRef,
    Tuple,
    Union,
    Any,
    Type,
    List,
    Optional,
    Literal,
)
from typing_extensions import TypeIs

from cutlass.cutlass_dsl import T
from cutlass.base_dsl import typing as _base_typing
from cutlass.base_dsl.typing import (
    Numeric,
    NumericMeta,
    Integer,
    Boolean,
    Int4,
    Int8,
    Int16,
    Int32,
    Int64,
    Int128,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Float,
    Float16,
    BFloat16,
    TFloat32,
    Float32,
    Float64,
    Float8E5M2,
    Float8E4M3FN,
    Float8E4M3B11FNUZ,
    Float8E4M3,
    Float8E8M0FNU,
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float4E2M1FNx2,
    as_numeric,
)

_element_precision_width = _base_typing._element_precision_width

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
from cutlass._mlir.dialects.cute import ConstrainedIntType
from cutlass.address_space import AddressSpace

if TYPE_CHECKING:
    from cutlass.cute.core import ScaledBasis, Swizzle
    from cutlass.cute.tensor import TensorSSA
else:
    ScaledBasis = ForwardRef("ScaledBasis")


Int = Union[int, Integer]


def _as_address_space(memspace: AddressSpace | int) -> AddressSpace:
    if isinstance(memspace, AddressSpace):
        return memspace
    if isinstance(memspace, bool):
        raise TypeError("expects mem_space to be an AddressSpace, not bool")
    value = getattr(memspace, "value", memspace)
    try:
        return AddressSpace(int(value))
    except (TypeError, ValueError):
        raise TypeError(
            f"expects mem_space to be an AddressSpace, but got {memspace}"
        ) from None


def _to_mlir_address_space(memspace: AddressSpace | int) -> _cute_ir.AddressSpace:
    return _cute_ir.AddressSpace(int(_as_address_space(memspace)))


class SymInt:
    r"""A symbolic integer for runtime-bound dimensions of an AOT-compiled
    ``@cute.jit`` function.

    A ``SymInt`` stands in for a Python ``int`` at compile-tracing time —
    its concrete value is bound only at kernel launch.  Use it when a
    tensor shape, loop bound, or scalar argument varies launch-to-launch
    but the compiler still needs to know enough about its structure to
    emit aligned vector ops, strength-reduce ``%``/``//``, or skip
    tail-loop prologues.

    The preferred way to construct a ``SymInt`` is via the
    :func:`sym_int32` / :func:`sym_int64` convenience constructors:

    .. code-block:: python

        # In compile():
        sym_n = cute.sym_int64(divisibility=16)         # "N is mul of 16"

        # In the @cute.jit signature, declare the matching arg type:
        @cute.jit
        def _host(..., num_k_tiles: Int64):
            ...

    :param width: Bit width of the integer at runtime — ``32`` or ``64``.
        Use 64 for tensor shape dims (M, N, K, batch) that may exceed 2 G;
        32 for small counts.
    :param divisibility: **Hard contract** on the runtime value — the
        compiler is free to assume the value is always a multiple of
        ``divisibility`` and may emit aligned vector stores,
        strength-reduce ``%`` / ``//`` against the divisor, and drop
        tail-loop prologues based on it.  **Violating the contract at
        runtime is undefined behaviour** and typically surfaces as
        ``cudaErrorMisalignedAddress`` (a sticky CUDA error that poisons
        the worker's CUDA context) or silently wrong results.  The
        TVM-FFI runtime adapter does not validate divisibility (the JAX
        adapter does, see ``cutlass/jax/primitive.py``); kernels that
        want a friendly Python-side error on the TVM-FFI path should
        ``raise ValueError(...)`` in their ``run()`` wrapper *in
        addition to* the SymInt declaration.  The default ``1`` means
        no constraint.
    :param symbol: Human-readable name for the variable, e.g. ``"M"``.
        Appears in IR dumps and compile-time error messages.

    **Common patterns**

    Pick the divisibility that matches the kernel's actual contract on
    each dim — declare neither more nor less than what the codegen
    relies on:

    .. code-block:: python

        # Contiguous output dim — declare the alignment the epilogue's
        # vector store depends on (32 B / sizeof(dtype) elements):
        sym_n = cute.sym_int64(divisibility=32 // (out_dtype.width // 8))

        # K dim — must be a multiple of the K-tile so the K-loop is exact:
        sym_k = cute.sym_int64(divisibility=mma_tiler_mnk[2])

        # M dim — no compile-time constraint when the kernel masks
        # ``if row < M`` at runtime:
        sym_m = cute.sym_int64()

    .. note::

        ``divisibility`` is the kernel's hard contract, not a hint.
        Don't *over-promise*: declaring ``divisibility=128`` when the
        kernel only needs 16-byte alignment will reject more shapes
        than necessary.  Don't *under-promise*: declaring
        ``divisibility=1`` when the epilogue assumes 32 B alignment
        will silently fault on non-conforming inputs.

    .. seealso::

        :func:`sym_int32`, :func:`sym_int64` — convenience constructors.

    """

    def __init__(
        self,
        width: Literal[32, 64] = 32,
        *,
        divisibility: int = 1,
        symbol: str | None = None,
    ) -> None:
        if width not in [32, 64]:
            raise ValueError(f"Unsupported width: {width}")

        self._width = width
        self._divisibility = divisibility
        self._symbol = symbol

    def __hash__(self) -> int:
        return hash((self._width, self._divisibility, self._symbol))

    @property
    def width(self) -> int:
        return self._width

    @property
    def divisibility(self) -> int:
        return self._divisibility

    @property
    def symbol(self) -> str | None:
        return self._symbol

    def __str__(self) -> str:
        prefix = "" if self._symbol is None else self._symbol + " "
        if self._width == 32:
            return f"{prefix}?{{div={self._divisibility}}}"
        else:
            return f"{prefix}?{{i{self._width} div={self._divisibility}}}"

    def __repr__(self) -> str:
        return self.__str__()

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, SymInt):
            return False

        return all(
            [
                self._width == other._width,
                self._divisibility == other._divisibility,
                self._symbol == other._symbol,
            ]
        )

    def __mod__(self, other: "int | SymInt") -> "SymInt | int":
        if isinstance(other, int):
            other_div, result_width = other, self._width
        elif isinstance(other, SymInt):
            other_div, result_width = (
                other._divisibility,
                max(self._width, other._width),
            )
        else:
            return NotImplemented

        if self._divisibility % other_div == 0:
            return 0
        else:
            from math import gcd

            return SymInt(result_width, divisibility=gcd(self._divisibility, other_div))

    def __rmod__(self, other: int) -> int:
        """int % SymInt: check if the int conforms to this SymInt's divisibility"""
        if isinstance(other, int):
            return other % self._divisibility
        return NotImplemented

    def __mul__(self, other: "int | SymInt") -> "SymInt":
        if isinstance(other, int):
            return SymInt(self._width, divisibility=self._divisibility * other)
        elif isinstance(other, SymInt):
            return SymInt(
                width=max(self._width, other._width),
                divisibility=self._divisibility * other._divisibility,
            )
        else:
            return NotImplemented

    def __rmul__(self, other: "int | SymInt") -> "SymInt":
        return self.__mul__(other)

    def __floordiv__(self, other: "int | SymInt") -> "SymInt":
        """SymInt // int | SymInt: floor-divide a symbolic integer.

        The result is always a fresh ``SymInt`` (the quotient is symbolic
        since ``self`` is).  Its divisibility is only as strong as can be
        *proven* from the divisibility contract:

        * ``self // k`` (``k`` an ``int``): if ``self``'s divisibility is a
          multiple of ``k`` the division is exact on the contract, so the
          quotient is a multiple of ``divisibility // k``.  Otherwise nothing
          is provable and the result advertises ``divisibility=1``.
        * ``self // other`` (``other`` a ``SymInt``): ``other``'s runtime
          value is only known to be *some* multiple of its divisibility, so
          the quotient's alignment is not provable — ``divisibility=1``.
        """
        if isinstance(other, int):
            if other == 0:
                raise ZeroDivisionError("integer division or modulo by zero")
            result_width = self._width
            if self._divisibility % other == 0:
                return SymInt(result_width, divisibility=self._divisibility // other)
            return SymInt(result_width, divisibility=1)
        elif isinstance(other, SymInt):
            return SymInt(width=max(self._width, other._width), divisibility=1)
        else:
            return NotImplemented

    def __c_pointers__(self) -> List[int | None]:
        return [ctypes.c_void_p(0).value]

    def __get_mlir_types__(self) -> List[ir.Type]:
        res_ty = ir.Type.parse(
            f'!cute.int_tuple<"?{{i{self.width} div={self.divisibility}}}">'
        )
        return [res_ty]

    def __new_from_mlir_values__(self, values: List[ir.Value]) -> "SymInt":
        from .core import IntValue

        if self.width == 32:
            return Int32(IntValue(values[0]))  # type: ignore[return-value]
        elif self.width == 64:
            return Int64(IntValue(values[0]))  # type: ignore[return-value]
        else:
            assert False, f"Unsupported width: {self.width}"
            return self

def sym_int(
    width: Literal[32, 64] = 32, *, divisibility: int = 1, symbol: str | None = None
) -> SymInt:
    r"""Construct a :class:`SymInt` of the given width.

    :param width: Bit width — ``32`` or ``64``.
    :param divisibility: Hard divisibility contract on the runtime value;
        see :class:`SymInt`.
    :param symbol: Optional human-readable name for IR dumps.
    :returns: A :class:`SymInt` instance.

    .. seealso::

        :class:`SymInt`, :func:`sym_int32`, :func:`sym_int64`.
    """
    return SymInt(width, divisibility=divisibility, symbol=symbol)


def sym_int32(divisibility: int = 1, symbol: str | None = None) -> SymInt:
    r"""Construct a 32-bit :class:`SymInt`.

    :param divisibility: Hard divisibility contract on the runtime value;
        see :class:`SymInt`.
    :param symbol: Optional human-readable name for IR dumps.
    :returns: A 32-bit :class:`SymInt` instance.

    .. seealso::

        :class:`SymInt` for the full divisibility contract.
    """
    return sym_int(32, divisibility=divisibility, symbol=symbol)


def sym_int64(divisibility: int = 1, symbol: str | None = None) -> SymInt:
    r"""Construct a 64-bit :class:`SymInt`.

    Standard choice for tensor shape dimensions (M, N, K, batch).

    :param divisibility: Hard divisibility contract on the runtime value;
        see :class:`SymInt`.
    :param symbol: Optional human-readable name for IR dumps.
    :returns: A 64-bit :class:`SymInt` instance.

    **Common usage**

    .. code-block:: python

        # Contiguous output dim — declare the alignment the epilogue's
        # vector store depends on (32 B / sizeof(dtype) elements):
        sym_n = cute.sym_int64(divisibility=32 // (out_dtype.width // 8))

        # K dim — must be a multiple of the K-tile so the K-loop is exact:
        sym_k = cute.sym_int64(divisibility=mma_tiler_mnk[2])

        # M dim — no compile-time constraint when the kernel masks
        # ``if row < M`` at runtime:
        sym_m = cute.sym_int64()

    .. seealso::

        :class:`SymInt` for the full divisibility contract.

    """
    return sym_int(64, divisibility=divisibility, symbol=symbol)


IntTuple = Union[Int, Tuple["IntTuple", ...]]
Shape = Union[Int, Tuple["Shape", ...]]
Stride = Union[Int, ScaledBasis, Tuple["Stride", ...]]
Coord = Union[Int, None, Tuple["Coord", ...]]


class Layout(ir.Value):
    def __init__(self, op_result: ir.Value) -> None:
        super().__init__(op_result)

    @abstractmethod
    def get_hier_coord(
        self,
        idx: Int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Coord:
        """Return the (hierarchical) ND logical coordinate corresponding to the linear index"""
        ...

    @property
    @abstractmethod
    def shape(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Shape:
        """Implemented by subclasses."""
        ...

    @property
    @abstractmethod
    def stride(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Stride:
        """Implemented by subclasses."""
        ...


class ComposedLayout(ABC):
    r"""ComposedLayout represents the functional composition of layouts in CuTe.

    **Formally:**

    .. math::

        R(c) := (inner \circ offset \circ outer)(c) := inner(offset + outer(c))

    where:

        - inner: The inner layout or swizzle that is applied last
        - offset: An integer tuple representing a coordinate offset
        - outer: The outer layout that is applied first

    This composition allows for complex transformations of coordinates and indices,
    enabling operations like tiling, partitioning, and reshaping of data.

    :ivar inner: The inner layout or swizzle component
    :ivar offset: The coordinate offset applied between inner and outer layouts
    :ivar outer: The outer layout component
    :ivar max_alignment: The maximum alignment of the composed layout

    **Examples:**

    .. code-block:: python

        # Create a composed layout with inner layout, offset, and outer layout

        # inner layout: (4, 8):(1, 4)
        inner_layout = make_layout((4, 8))

        offset = (0, 0)

        # outer layout: (2, 2):(1@0, 1@1)
        outer_layout = make_layout((2, 2), stride=(1 * E(0), 1 * E(1)))

        # composed layout: (inner o offset o outer)
        composed = make_composed_layout(inner_layout, offset, outer_layout)

        # Accessing components of the composed layout
        inner = composed.inner
        offset = composed.offset
        outer = composed.outer

        # map coordinate (0, 1) to linear index
        #  - outer(0, 1) = (0, 1)
        #  - offset + outer(0, 1) = (0, 1)
        #  - inner(0, 1) = 0 * 1 + 1 * 4 = 4
        idx = crd2idx((0, 1), composed)

        # Composition is used in many tiling operations
        # For example, in logical_product, raked_product, and blocked_product
    """

    @property
    @abstractmethod
    def type(self) -> ir.Type: ...

    @property
    @abstractmethod
    def is_normal(self) -> bool: ...

    @property
    @abstractmethod
    def inner(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[Layout, "Swizzle"]: ...

    @property
    @abstractmethod
    def offset(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> IntTuple: ...

    @property
    @abstractmethod
    def outer(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Layout: ...

    @property
    @abstractmethod
    def shape(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Shape: ...

    @abstractmethod
    def __call__(
        self,
        coord: Coord,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> IntTuple: ...


Tile = Union[Int, None, Layout, Tuple["Tile", ...]]
Tiler = Union[Shape, Layout, Tile]


# XTuple is super set of above types
XTuple = Union[Any, Tuple["XTuple", ...]]


class Pointer(ABC):
    """
    Abstract base class for CuTe jit function and runtime _Pointer.
    """

    value: ir.Value

    @property
    def type(self) -> ir.Type:
        """The MLIR type of this pointer. Implemented by subclasses."""
        raise NotImplementedError

    @property
    def value_type(self) -> Type[Numeric]:
        return self.dtype

    @property
    def dtype(self) -> Type[Numeric]:  # type: ignore[empty-body]
        """Implemented by subclasses."""
        ...

    @property
    def memspace(self) -> AddressSpace:  # type: ignore[empty-body]
        """The memory address space of this pointer. Implemented by subclasses."""
        ...

    @property
    def max_alignment(self) -> int:
        """Maximum alignment of this pointer in bytes. Implemented by subclasses."""
        raise NotImplementedError

    @property
    def alignment(self) -> int:
        """Alignment of this pointer in bytes (post-swizzle). Implemented by subclasses."""
        raise NotImplementedError

    @property
    def llvm_ptr(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        """Get the LLVM pointer representation. Implemented by subclasses."""
        raise NotImplementedError

    def to_llvm_ptr(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        """Get the LLVM pointer representation (loc/ip propagated). Implemented by subclasses."""
        raise NotImplementedError

    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        return self.to_llvm_ptr(loc=loc, ip=ip)

    def toint(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Numeric:
        """Convert pointer to integer. Implemented by subclasses."""
        raise NotImplementedError

    def align(self, min_align: int) -> "Pointer":  # type: ignore[empty-body]
        """Implemented by subclasses."""
        ...

    def __add__(  # type: ignore[empty-body]
        self,
        other: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Pointer":
        """Implemented by subclasses."""
        ...

    def __get_mlir_types__(self) -> List[ir.Type]:  # type: ignore[empty-body]
        """Implemented by subclasses."""
        ...

    def __extract_mlir_values__(self) -> List[ir.Value]:  # type: ignore[empty-body]
        """Implemented by subclasses."""
        ...

    def __new_from_mlir_values__(self, values: List[ir.Value]) -> "Pointer":  # type: ignore[empty-body]
        """Implemented by subclasses."""
        ...


class TypedTensor:
    r"""A compile-time type descriptor for a statically-typed CuTe tensor.

    ``TypedTensor`` captures the element type, shape, stride, memory space, and
    pointer alignment of a tensor at compile time.

    The preferred way to construct a ``TypedTensor`` is via the ``Tensor``
    subscript syntax:

    .. code-block:: python

        # equivalent to TypedTensor(cutlass.Float32, (16,), (1,))
        ty = Tensor[cutlass.Float32, (16,), (1,)]

        @cute.jit
        def kernel(a: Tensor[cutlass.Float32, (16,), (1,)]):
            ...

    :param dtype: Element type of the tensor
    :param shape: Static shape of the tensor
    :param stride: Static stride of the tensor
    :param memspace: Memory space of the underlying pointer.  Defaults to
        ``AddressSpace.generic``.
    :param assumed_align: Assumed byte alignment of the pointer.

    **Runtime type checking**

    Use :meth:`isinstance` to check whether a live ``Tensor`` value matches
    this descriptor:

    .. code-block:: python

        tt = TypedTensor(cutlass.Float32, (16,), (1,), AddressSpace.gmem)

        @cute.jit
        def kernel(a: cute.Tensor):
            if tt.isinstance(a):
                ...
    """

    def __init__(
        self,
        dtype: Type[Numeric],
        shape: Shape,
        stride: Stride,
        memspace: AddressSpace = AddressSpace.generic,
        assumed_align: int | None = None,
    ):
        self._dtype = dtype
        self._shape = shape
        self._stride = stride
        self._memspace = _as_address_space(memspace)
        self._assumed_align = assumed_align
        if assumed_align is None:
            # use the bytes width of the element dtype. The alignment is at least one byte align.
            self._assumed_align = (self._dtype.width + 7) // 8

    @property
    def element_type(self) -> Type[Numeric]:
        return self._dtype

    @element_type.setter
    def element_type(self, new_type: Type[Numeric]) -> None:
        # TypedTensor is a compile-time type descriptor that's intentionally
        # read-only.
        raise NotImplementedError

    @property
    def shape(self) -> Shape:
        return self._shape

    @property
    def stride(self) -> Stride:
        return self._stride

    @property
    def memspace(self) -> AddressSpace:
        return self._memspace

    @property
    def assumed_align(self) -> int | None:
        return self._assumed_align

    def isinstance(self, other: object) -> bool:
        if not isinstance(other, Tensor):
            return False  # pragma: no cover
        mlir_type = other.__extract_mlir_values__()[0].type  # type: ignore[attr-defined]
        return mlir_type == self.mlir_type

    @property
    def mlir_type(self) -> ir.Type:
        shape_ty = _cute_ir.ShapeType.get_from_x_tuple(ir.Context.current, self._shape)
        stride_ty = _cute_ir.StrideType.get_from_x_tuple(
            ir.Context.current, self._stride
        )
        layout_ty = _cute_ir.LayoutType.get(shape_ty, stride_ty)

        # Boolean types are stored as i8 in memory
        elem_type = T.i8() if self._dtype.width == 1 else self._dtype.mlir_type
        ptr_ty = _cute_ir.PtrType.get(
            elem_type, _to_mlir_address_space(self._memspace), self._assumed_align
        )

        return _cute_ir.MemRefType.get(ptr_ty, layout_ty)

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [self.mlir_type]

    def __str__(self) -> str:
        return f"Tensor<{self._dtype}, {self._shape}, {self._stride}>"


class Tensor(ABC):
    r"""Abstract base class for Tensor representations in CuTe DSL.

    A CuTe Tensor is iterator with layout. A tensor evaluates the layout by mapping a
    coordinate to the codomain, offsets the iterator accordingly, and dereferences
    the result to obtain the tensor's value.

    **Formally:**

    .. math::

        T(c) = (E \circ L)(c) = *(E + L(c))

    where

        - :math:`E` is the iterator/engine
        - :math:`L` is the layout

    **Notes:**

        - The tensor supports both direct element access via coordinates and slicing operations
        - Load/store operations are only supported for specific memory spaces (rmem, smem, gmem, generic)
        - For composed layouts, stride information is not directly accessible
        - Dynamic layouts do not support vector load/store operations

    **Examples:**

    Create tensor from torch.tensor with Host Runtime:

    .. code-block:: python

        import torch
        from cutlass.cute.runtime import from_dlpack

        mA = from_dlpack(torch.tensor([1, 3, 5], dtype=torch.int32))
        print(mA.shape)   # (3,)
        print(mA.stride)  # (1,)
        print(mA.layout)  # (3,):(1,)

    Define JIT function:

    .. code-block:: python

        @cute.jit
        def add(a: Tensor, b: Tensor, res: Tensor):
            res.store(a.load() + b.load())

    Call JIT function from python:

    .. code-block:: python

        import torch
        a = torch.tensor([1, 3, 5], dtype=torch.int32)
        b = torch.tensor([2, 4, 6], dtype=torch.int32)
        c = torch.zeros([3], dtype=torch.int32)
        mA = from_dlpack(a)
        mB = from_dlpack(b)
        mC = from_dlpack(c)
        add(mA, mB, mC)
        print(c)  # tensor([3, 7, 11], dtype=torch.int32)
    """

    value: ir.Value

    def __class_getitem__(cls, args: tuple) -> TypedTensor:
        return TypedTensor(*args)

    @abstractmethod
    def __str__(self) -> str: ...

    @abstractmethod
    def __getitem__(
        self, idx: Union[Int, slice, Coord, Tuple]
    ) -> Union["Tensor", ir.Value, IntTuple]: ...

    @abstractmethod
    def __setitem__(
        self, idx: Union[Int, slice, Coord, Tuple], value: Union[Numeric, ir.Value]
    ) -> None: ...

    @property
    @abstractmethod
    def element_type(self) -> Type[Numeric]: ...

    @element_type.setter
    def element_type(self, new_type: Type[Numeric]) -> None:
        """Implemented by subclasses."""
        raise NotImplementedError

    @property
    @abstractmethod
    def dtype(self) -> Type[Numeric]:
        """The element data type. Implemented by subclasses."""
        raise NotImplementedError

    @property
    @abstractmethod
    def memspace(self) -> AddressSpace: ...

    @property
    @abstractmethod
    def iterator(self) -> Union[Pointer, IntTuple]: ...

    @property
    @abstractmethod
    def leading_dim(self) -> Union[int, Tuple[int, ...], None]:
        """Get the leading dimension of this Tensor
        (first mode from left to right with stride==1, shape!=1)

        :return: The leading dimension index or indices
        :rtype: int or tuple or None

        The return value depends on the tensor's stride pattern:
        * If a single leading dimension is found, returns an integer index
        * If nested leading dimensions are found, returns a tuple of indices
        * If no leading dimension is found, returns None
        """
        ...

    @property
    def layout(self) -> Union[Layout, "ComposedLayout"]:
        """Implemented by subclasses."""
        raise NotImplementedError

    @property
    @abstractmethod
    def shape(self) -> Shape: ...

    @property
    @abstractmethod
    def stride(self) -> Stride: ...

    @property
    def dynamic_shapes_mask(self) -> Tuple[int, ...]:
        """Implemented by subclasses."""
        raise NotImplementedError

    @property
    def dynamic_strides_mask(self) -> Tuple[int, ...]:
        """Implemented by subclasses."""
        raise NotImplementedError

    def load(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "TensorSSA":
        """Implemented by subclasses."""
        raise NotImplementedError

    def store(
        self,
        data: "TensorSSA",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Implemented by subclasses."""
        raise NotImplementedError

    def mark_layout_dynamic(self, leading_dim: Optional[int] = None) -> "Tensor":
        """Implemented by subclasses."""
        raise NotImplementedError

    def mark_compact_shape_dynamic(
        self,
        mode: int,
        stride_order: Optional[tuple[int, ...]] = None,
        divisibility: int = 1,
    ) -> "Tensor":
        """Implemented by subclasses."""
        raise NotImplementedError

    @abstractmethod
    def fill(self, value: Numeric) -> None: ...


def is_integer(a: object) -> bool:
    """Check if an object is static integer or dynamic integer"""
    return isinstance(a, (int, Integer)) or (
        isinstance(a, ir.Value)
        and isinstance(a.type, (ir.IntegerType, ConstrainedIntType))
    )


def is_int_tuple(a: object) -> bool:
    if isinstance(a, tuple):
        return all([is_int_tuple(x) for x in a])
    else:
        return is_integer(a)


def is_int_tuple_type(t: object) -> TypeIs[Type[IntTuple]]:
    """Check whether a type slot equals the IntTuple typing alias object.

    Why this helper exists (instead of inlining ``t is IntTuple``):
    mypy cannot narrow on ``t is IntTuple`` directly — IntTuple is a
    typing.Union alias object, not a class, so mypy's ``is`` / ``is not``
    narrowing rules don't apply. Wrapping the identity check in a function
    annotated with ``TypeIs[Type[IntTuple]]`` tells mypy how to narrow on
    both branches:
      * True  -> ``t`` is ``Type[IntTuple]``
      * False -> ``t`` is the input type minus ``Type[IntTuple]``

    Typical use: narrow ``Tensor.element_type``'s
    ``Union[Type[Numeric], Type[IntTuple]]`` to ``Type[Numeric]`` via
    ``assert not is_int_tuple_type(elem_type)``.

    Requires ``typing_extensions >= 4.10.0`` (PEP 742, which introduced
    ``TypeIs``). On Python < 3.13, ``TypeIs`` only lives in
    ``typing_extensions``; on Python >= 3.13 it is also in stdlib
    ``typing`` but we import from ``typing_extensions`` for back-compat.

    """
    return t is IntTuple


__all__ = [
    "SymInt",
    "sym_int",
    "sym_int32",
    "sym_int64",
    "Numeric",
    "NumericMeta",
    "Integer",
    "Boolean",
    "Int4",
    "Int8",
    "Int16",
    "Int32",
    "Int64",
    "Int128",
    "Uint8",
    "Uint16",
    "Uint32",
    "Uint64",
    "Float",
    "Float16",
    "BFloat16",
    "TFloat32",
    "Float32",
    "Float64",
    "Float8E5M2",
    "Float8E4M3FN",
    "Float8E4M3B11FNUZ",
    "Float8E4M3",
    "Float8E8M0FNU",
    "Float4E2M1FN",
    "Float6E2M3FN",
    "Float6E3M2FN",
    "Float4E2M1FNx2",
    "IntTuple",
    "ScaledBasis",
    "Coord",
    "Shape",
    "Stride",
    "Layout",
    "ComposedLayout",
    "Pointer",
    "Tensor",
    "TypedTensor",
    "Tile",
    "Tiler",
    "XTuple",
    "as_numeric",
    "is_integer",
    "is_int_tuple",
    "is_int_tuple_type",
]
