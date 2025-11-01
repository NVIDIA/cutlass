# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from abc import ABC, abstractmethod
from typing import ForwardRef, Tuple, Union, Any, Type, List, Optional

from cutlass.base_dsl.typing import *

from cutlass._mlir import ir
from cutlass._mlir.dialects.cute import AddressSpace, ConstrainedIntType


Int = Union[int, Integer]


ScaledBasis = ForwardRef("ScaledBasis")

IntTuple = Union[Int, Tuple["IntTuple", ...]]
Shape = Union[Int, Tuple["Shape", ...]]
Stride = Union[Int, ScaledBasis, Tuple["Stride", ...]]
Coord = Union[Int, None, Tuple["Coord", ...]]


class Layout(ir.Value):
    def __init__(self, op_result):
        super().__init__(op_result)

    def __str__(self) -> str: ...

    def get_hier_coord(self, idx) -> Coord:
        """Return the (hierarchical) ND logical coordinate corresponding to the linear index"""
        ...

    @property
    def shape(self, *, loc=None, ip=None) -> Shape: ...

    @property
    def stride(self, *, loc=None, ip=None) -> Stride: ...


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
    def inner(self, *, loc=None, ip=None): ...

    @property
    @abstractmethod
    def offset(self, *, loc=None, ip=None) -> IntTuple: ...

    @property
    @abstractmethod
    def outer(self, *, loc=None, ip=None) -> Layout: ...

    @property
    @abstractmethod
    def shape(self, *, loc=None, ip=None): ...

    @abstractmethod
    def __call__(self, coord: Coord, loc=None, ip=None) -> IntTuple: ...


Tile = Union[Int, None, Layout, Tuple["Tile", ...]]
Tiler = Union[Shape, Layout, Tile]


# XTuple is super set of above types
XTuple = Union[Any, Tuple["XTuple", ...]]


class Pointer(ABC):
    """
    Abstract base class for CuTe jit function and runtime _Pointer
    """

    @property
    def value_type(self) -> Type[Numeric]:
        return self.dtype

    @property
    def dtype(self) -> Type[Numeric]: ...

    def align(self, min_align: int) -> "Pointer": ...

    def __add__(self, other: int, *, loc=None, ip=None) -> "Pointer": ...

    def __get_mlir_types__(self) -> List[ir.Type]: ...

    def __extract_mlir_values__(self) -> List[ir.Value]: ...

    def __new_from_mlir_values__(self, values) -> "Pointer": ...


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

    @abstractmethod
    def __str__(self) -> str: ...

    @abstractmethod
    def __getitem__(self, idx) -> Union["Tensor", ir.Value, IntTuple]: ...

    @abstractmethod
    def __setitem__(self, idx, value): ...

    @property
    @abstractmethod
    def element_type(self) -> Union[Type[Numeric], Type[IntTuple]]: ...

    @element_type.setter
    def element_type(self, new_type): ...

    @property
    @abstractmethod
    def memspace(self) -> AddressSpace: ...

    @property
    @abstractmethod
    def iterator(self) -> Union[Pointer, IntTuple]: ...

    @property
    def layout(self) -> Union[Layout, "ComposedLayout"]: ...

    @property
    def shape(self) -> Shape: ...

    @property
    def stride(self) -> Stride: ...

    def load(self, *, loc=None, ip=None) -> "TensorSSA": ...

    def store(self, data: "TensorSSA", *, loc=None, ip=None): ...

    def mark_layout_dynamic(self, leading_dim: Optional[int] = None) -> "Tensor": ...

    def mark_compact_shape_dynamic(
        self,
        mode: int,
        stride_order: Optional[tuple[int, ...]] = None,
        divisibility: int = 1,
    ) -> "Tensor": ...

    @abstractmethod
    def fill(self, value: Numeric) -> None: ...


def is_integer(a) -> bool:
    """Check if an object is static integer or dynamic integer"""
    return isinstance(a, (int, Integer)) or (
        isinstance(a, ir.Value)
        and isinstance(a.type, (ir.IntegerType, ConstrainedIntType))
    )


def is_int_tuple(a) -> bool:
    if isinstance(a, tuple):
        return all([is_int_tuple(x) for x in a])
    else:
        return is_integer(a)


__all__ = [
    "Coord",
    "Numeric",
    "Integer",
    "Boolean",
    "Int4",
    "Int8",
    "Int16",
    "Int32",
    "Int64",
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
    "IntTuple",
    "Layout",
    "Pointer",
    "Shape",
    "Stride",
    "Tensor",
    "Tile",
    "Tiler",
    "XTuple",
    "is_integer",
    "is_int_tuple",
]
