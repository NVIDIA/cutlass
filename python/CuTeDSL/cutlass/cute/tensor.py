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

from typing import Optional, Union, Type, Tuple, overload
from typing_extensions import deprecated
from inspect import isclass
import operator

from cutlass.cutlass_dsl import (
    dsl_user_op,
    lru_cache_ir,
    T,
    cutlass_arith,
    _binary_op_type_promote,
    CuTeDSL,
)
from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
from cutlass._mlir.dialects.cute import ReductionOp as ReductionOp
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir.dialects import vector, arith

from .core import (
    _unpack_x_tuple,
    _pack_int_tuple,
    _pack_coord,
    _pack_shape,
    _ComposedLayout,
    _ComposedLayoutWithInnerFunc,
    is_static,
    is_weakly_congruent,
    rank,
    append,
    depth,
    flatten,
    has_underscore,
    make_layout,
    slice_,
    crd2idx,
    size,
    leading_dim,
    recast_ptr,
    recast_layout,
)

from .typing import (
    IntTuple,
    Coord,
    Shape,
    Stride,
    Pointer,
    Layout,
    ComposedLayout,
    Tensor,
    AddressSpace,
    is_integer,
    is_int_tuple,
    as_numeric,
)
from .typing import (
    Numeric,
    Integer,
    Boolean,
    Int4,
    Uint8,
    Int8,
    Int32,
    Float4E2M1FN,
    Float8E4M3,
    Float16,
    Float32,
    BFloat16,
)
from .tuple import transform_leaf, product, product_like, flatten_to_tuple
from .arch import cvt_i8_bf16_intrinsic, cvt_i4_bf16_intrinsic, cvt_f4e2m1_f16_intrinsic, cvt_f8e4m3_f16_intrinsic


@ir.register_value_caster(_cute_ir.MemRefType.get_static_typeid(), replace=True)
@ir.register_value_caster(_cute_ir.CoordTensorType.get_static_typeid(), replace=True)
@ir.register_value_caster(
    _cute_nvgpu_ir.SmemDescViewType.get_static_typeid(), replace=True
)
class _Tensor(Tensor):
    r"""Builtin Tensor Type as an IR value supporting standard iterator and layout..

    :param value: The MLIR operation result value to initialize the tensor with
    :type value: ir.Value
    :param dtype: The user specified data type of the tensor elements. It could be \
        different from the underlying dtype in the iterator. The default is None.
    :type dtype: Type[Numeric], optional
    :param loc: The source location for the operation, defaults to None
    :type loc: Location, optional
    :param ip: The insertion point for the operation, defaults to None
    :type ip: InsertionPoint, optional

    **Examples:**

    .. code-block:: python

        # Create a tensor with shape (4,8) in row-major layout
        tensor = make_tensor(ptr, make_layout(shape=(4,8), stride=(8,1)))

        # Access individual element
        val = tensor[0, 0]    # or val = tensor[(0, 0)]

        # Slice operation - get first column
        subtensor = tensor[None, 0]  # or subtensor = tensor[(None, 0)]
    """

    @dsl_user_op
    def __init__(
        self, value, dtype: Optional[Type[Numeric]] = None, *, loc=None, ip=None
    ):
        self._dtype = dtype
        if isinstance(value, ir.Value):
            self.value = value
        elif isinstance(value, _Tensor):
            self.value = value.value
        elif isinstance(value, _Tensor):
            self.value = value.value
        else:
            raise TypeError(f"Expected ir.Value or _Tensor, got {type(value)}")

        # Set iterator
        iter_val = _cute_ir.get_iter(self.value, loc=loc, ip=ip)
        if isinstance(iter_val, Pointer):
            self._iterator = iter_val
        elif isinstance(iter_val.type, _cute_ir.IntTupleType):
            self._iterator = _unpack_x_tuple(iter_val)
        elif isinstance(iter_val, ir.Value):
            # Example: SMEM descriptor iterator, not well supported today
            self._iterator = iter_val
        else:
            raise TypeError(f"unsupported iterator type, got {type(iter_val)}")

        # Set dtype
        if self._dtype is None:
            if is_int_tuple(self.iterator):
                self._dtype = IntTuple
            elif isinstance(self.iterator, Pointer):
                self._dtype = self.iterator.value_type
            elif isinstance(self.type, _cute_nvgpu_ir.SmemDescViewType):
                # SmemDescViewType do not need dtype
                self._dtype = None
            else:
                raise TypeError(f"unsupported iterator type, got {type(self.iterator)}")

    def __str__(self):
        from .core import pretty_str

        return f"tensor<{pretty_str(self.iterator)} o {pretty_str(self.layout)}>"

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        # Only expecting single value of _Tensor or ir.Value
        # In this context, a _Tensor instance is an encapsulated ir.Value which is automatically created
        # by value caster for MemRef/CoordTensor/SmemDescView typed values
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        assert isinstance(values[0], (_Tensor, ir.Value)), (
            f"Expected _Tensor or ir.Value, but got {type(values[0])}"
        )
        return _Tensor(
            values[0] if isinstance(values[0], ir.Value) else values[0].value,
            dtype=self.element_type,
        )

    # Cheat to let `Type(_Tensor())` to return cute.Tensor
    @property
    def __class__(self) -> Type[Tensor]:
        return Tensor

    # Make it behave as if it inherited from ir.Value
    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    @dsl_user_op
    def __getitem__(
        self, crd: Coord, *, loc=None, ip=None
    ) -> Union[Tensor, Numeric, IntTuple]:
        """Access or slice tensor elements using coordinates.

        This method implements
        * tensor evaluation T(c) = *(E + L(c)) when `c` is a coordinate without slicing, or
        * tensor slicing operations T(c) = make_tensor(E + L(c), slice(L, c))
        where E is the iterator/engine and L is the layout

        :param crd: Coordinate or slice specification for accessing tensor elements
        :type crd: Coord
        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: Tensor element value or sliced subtensor
        :rtype: Union[Tensor, ir.Value, IntTuple]

        :raises ValueError: If coordinate access is invalid for the tensor layout

        **Examples:**

        .. code-block:: python

            # Create a tensor with pointer iterator
            ptr = make_ptr(cutlass.Float32, 0, cutlass.AddressSpace.gmem)
            layout = make_layout((64, 128))  # leftmost mode is major
            tensor = make_tensor(ptr, layout)  # Tensor using pointer iterator

            # Direct element access loads from memory
            val = tensor[0]  # Loads element at offset 0
            val = tensor[1]  # Loads element at offset 4 (4bytes per Float32)
            val = tensor[(0, 1)]  # Loads element at offset 64

            # Create a coord tensor
            layout = make_layout((64, 128), stride=(1 * E(0), 1 * E(1)))
            tensor = make_tensor((128, 128), layout)

            # Direct element access
            val = tensor[0]  # Returns (128, 128)
            val = tensor[(0, 1)]  # Returns (128, 129)

            # Slice access
            sliced = view[(3, None)]  # Returns tensor slice

        .. note::
            Sub-byte types like Float4E2M1FN and Float6E3M2FN are not supported for scalar
            dereference operations. Attempting to set individual elements of tensors with
            these element types will result in errors.

        **Examples:**

        .. code-block:: python

            # Unsupported operations with sub-byte types:
            ptr = make_ptr(cutlass.Float4E2M1FN, 0, cutlass.AddressSpace.gmem)
            tensor = make_tensor(ptr, layout)
            # The following will raise an error:
            val = tensor[0]  # Error: sub-byte scalar dereference not supported

            # Similarly for other sub-byte types:
            ptr = make_ptr(cutlass.Float6E3M2FN, 0, cutlass.AddressSpace.gmem)
            tensor = make_tensor(ptr, layout)
            val = tensor[0]  # Error: sub-byte scalar dereference not supported
        """
        if has_underscore(crd):
            return slice_(self, crd, loc=loc, ip=ip)
        elif isinstance(self.type, _cute_ir.CoordTensorType):
            res = _cute_ir.get_iter(
                slice_(self, crd, loc=loc, ip=ip).value, loc=loc, ip=ip
            )
            return _unpack_x_tuple(res, loc=loc, ip=ip)
        else:
            self._check_can_load_store()
            self._check_can_dereference()

            crd_val = _pack_coord(crd, loc=loc, ip=ip)
            data_val = _cute_ir.memref_load(self.value, crd_val, loc=loc, ip=ip)
            return self.element_type(data_val)

    def _cvt_to_dest(self, data: Union["TensorSSA", Numeric], *, loc=None, ip=None):
        orig_dtype = data.dtype
        # Implicit upcast to wider type
        if (
            data.dtype.is_same_kind(self.element_type)
            and self.element_type.width >= data.dtype.width
        ):
            data = data.to(self.element_type, loc=loc, ip=ip)  # type: ignore

        if data.dtype.width != self.element_type.width:
            raise ValueError(
                f"Type mismatch, store {orig_dtype} (-> {data.dtype}) "
                f"to Tensor with element type {self.element_type}"
            )

        if data.dtype is Boolean and self.element_type is Boolean:
            # Boolean Numeric and Boolean TensorSSA both hold i1 value, but we need int8 value store to memory
            val = data.ir_value_int8(loc=loc, ip=ip)
        else:
            val = data.ir_value(loc=loc, ip=ip)
        return val

    @dsl_user_op
    def __setitem__(
        self,
        crd: Coord,
        data: Union[int, float, ir.Value, Numeric, "TensorSSA"],
        *,
        loc=None,
        ip=None,
    ) -> None:
        """Set tensor elements at specified coordinates.

        Assigns values to tensor elements through direct coordinate access or slice assignment.
        For slice assignment, the value must be a TensorSSA with matching shape.

        :param crd: Coordinate or slice specification for tensor element assignment
        :type crd: Coord
        :param data: Value to assign - can be scalar or TensorSSA for slice assignment
        :type data: Union[int, float, ir.Value, Numeric, TensorSSA]
        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]

        :raises ValueError: If tensor type doesn't support load/store operations
        :raises ValueError: If slice assignment value is not a TensorSSA
        :raises ValueError: If value type doesn't match tensor element type
        :raises NotImplementedError: If value type is not supported

        .. note::
            Sub-byte types like Float4E2M1FN and Float6E3M2FN are not supported for scalar
            dereference operations. Attempting to set individual elements of tensors with
            these element types will result in errors.

        **Examples:**

        .. code-block:: python

            # Unsupported operations with sub-byte types:
            ptr = make_ptr(cutlass.Float4E2M1FN, 0, cutlass.AddressSpace.gmem)
            tensor = make_tensor(ptr, layout)
            # The following will raise an error:
            tensor[0] = 1.0  # Error: sub-byte scalar dereference not supported

            # Similarly for other sub-byte types:
            ptr = make_ptr(cutlass.Float6E3M2FN, 0, cutlass.AddressSpace.gmem)
            tensor = make_tensor(ptr, layout)
            tensor[0] = 0.5  # Error: sub-byte scalar dereference not supported
        """
        self._check_can_load_store()

        # convert scalar type
        if not has_underscore(crd):
            self._check_can_dereference()
            # First, convert ir.Value to Numeric
            if isinstance(data, ir.Value):
                data = as_numeric(data)
            elif isinstance(data, (int, float, bool)):
                data = as_numeric(data)

            if not isinstance(data, Numeric):
                raise ValueError(f"unsupported data type: {type(data)}")

            # Implicit upcast to wider type
            val = self._cvt_to_dest(data, loc=loc, ip=ip)
            if val.type != self.type.value_type:
                raise ValueError(
                    f"type mismatch, store {val.type} to {self.element_type}"
                )

            crd_val = _pack_coord(crd, loc=loc, ip=ip)
            _cute_ir.memref_store(self.value, crd_val, val, loc=loc, ip=ip)
        else:
            if not isinstance(data, TensorSSA):
                raise ValueError(f"Expected TensorSSA, but got {data}")

            self.__getitem__(crd, loc=loc, ip=ip).store(data, loc=loc, ip=ip)  # type: ignore

    @property
    def __class__(self) -> Type[Tensor]:
        return Tensor

    # Make it behave as if it inherited from ir.Value
    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    @property
    @lru_cache_ir()
    def iterator(self) -> Union[Pointer, IntTuple]:
        return self._iterator

    @property
    @dsl_user_op
    @lru_cache_ir()
    def layout(self, *, loc=None, ip=None) -> Layout:
        return _cute_ir.get_layout(self.value, loc=loc, ip=ip)

    @property
    @lru_cache_ir()
    def shape(self) -> Shape:
        return self.layout.shape

    @property
    @lru_cache_ir()
    def stride(self) -> Stride:
        if isinstance(self.layout.type, _cute_ir.ComposedLayoutType):
            raise ValueError("can't get stride from composed layout")
        return self.layout.stride

    @property
    def leading_dim(self) -> Union[int, Tuple[int], None]:
        """Get the leading dimension of this Tensor.

        :return: The index or indices of the first mode (from left to right) with stride 1
        :rtype: Union[int, Tuple[int], None]
        :returns:
            - int: Single leading dimension index if found
            - Tuple[int]: Tuple of indices for nested leading dimensions
            - None: If no leading dimension is found

        :postcondition: ``get(self.stride(), mode=self.leading_dim()) == 1 if self.leading_dim() != None else True``
        """
        return leading_dim(self.shape, self.stride)

    @property
    @lru_cache_ir()
    def element_type(self) -> Union[Type[Numeric], Type[IntTuple]]:
        return self._dtype

    @property
    @lru_cache_ir()
    def memspace(self) -> AddressSpace:
        if isinstance(self.iterator, Pointer):
            return self.iterator.memspace

        raise ValueError(f"{self} doesn't have memspace")

    @dsl_user_op
    def load(self, *, loc=None, ip=None) -> "TensorSSA":
        """Load tensor elements as a vector.

        Loads all elements of the tensor into a vector representation, assuming the tensor
        has a static shape and is in a memory space that supports load operations.

        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: Vector representation of tensor elements
        :rtype: TensorSSA

        :raises ValueError: If tensor has dynamic layout
        :raises ValueError: If tensor memory space doesn't support load operations
        """
        from .core import is_static

        if not is_static(self.shape):
            raise ValueError("dynamic layout doesn't support load")

        self._check_can_load_store()

        res_vect = _cute_ir.memref_load_vec(self.value, loc=loc, ip=ip)
        if self.element_type is Boolean:
            assert res_vect.type.element_type == T.i8(), (
                f"Boolean tensor must be stored as i8 in memory, but got {res_vect.type.element_type}"
            )
            zeros = full_like(self, 0, Int8, loc=loc, ip=ip)
            res_vect = arith.cmpi(
                arith.CmpIPredicate.ne, res_vect, zeros, loc=loc, ip=ip
            )
        return TensorSSA(res_vect, self.shape, self.element_type)

    @dsl_user_op
    def store(self, data: "TensorSSA", *, loc=None, ip=None):
        """Store vector data into tensor.

        Stores vector data into the tensor, assuming matching shapes and a memory space
        that supports store operations.

        :param data: Vector data to store into tensor
        :type data: TensorSSA
        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]

        :raises ValueError: If tensor has dynamic layout
        :raises ValueError: If tensor memory space doesn't support store operations
        :raises ValueError: If data shape doesn't match tensor shape
        """
        if not isinstance(data, TensorSSA):
            raise ValueError(f"Expected TensorSSA, but got {type(data)}")

        if not is_static(self.shape):
            raise ValueError("Dynamic layout doesn't support vectorized store")

        self._check_can_load_store()

        n_elems = size(self.shape, loc=loc, ip=ip)
        if n_elems != size(data.shape, loc=loc, ip=ip):
            raise ValueError(
                f"lhs and rhs must have the same shape, but got {self.shape} and {data.shape}"
            )

        elem_mlir_type = cutlass_arith.element_type(data.dtype.mlir_type)
        if cutlass_arith.is_narrow_precision(elem_mlir_type):
            if elem_mlir_type.width * n_elems % 32 != 0:
                raise ValueError(
                    f"narrow precision type must be 32-bit aligned vector, but got {elem_mlir_type} with {n_elems} elements"
                )

        # Implicit upcast to wider type
        new_data = self._cvt_to_dest(data, loc=loc, ip=ip)

        return _cute_ir.memref_store_vec(new_data, self.value, loc=loc, ip=ip)

    @dsl_user_op
    def fill(self, value: Numeric, *, loc=None, ip=None) -> None:
        """Fill tensor with a constant value.

        Fills all elements of the tensor with the specified value, assuming static size
        and supported memory space.

        :param value: Value to fill tensor with
        :type value: Union[int, float]
        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]

        :raises NotImplementedError: If tensor has dynamic size

        **Examples:**

        .. code-block:: python

            # Create tensor from numpy array
            b = np.random.randn(4, 8).astype(np.float32)
            tensor = from_dlpack(b)

            # Fill tensor with constant value
            tensor.fill(0.5)  # All elements become 0.5
        """
        self._check_can_load_store()

        sz = size(self, loc=loc, ip=ip)
        if type(sz) is not int:
            raise NotImplementedError(f"dynamic size is not supported: {self.type}")

        # Should we cast to destination type even with narrow cast?
        dst_type = self.element_type
        scalar_val = dst_type(value, loc=loc, ip=ip)
        vect_val = full(
            self.shape, fill_value=scalar_val, dtype=dst_type, loc=loc, ip=ip
        )
        self.store(vect_val, loc=loc, ip=ip)

    def _check_can_load_store(self):
        if not isinstance(self.type, _cute_ir.MemRefType) or self.memspace not in (
            AddressSpace.rmem,
            AddressSpace.smem,
            AddressSpace.gmem,
            AddressSpace.generic,
        ):
            raise ValueError(f"{self} doesn't support load and store")

        if self.type.is_swizzled:
            raise NotImplementedError(
                f"load & store swizzled memory is not supported yet: {self}"
            )

    def _check_can_dereference(self):
        # Check for sub-byte types and raise error if needed
        if self.element_type.width % 8 != 0 and self.element_type is not Boolean:
            raise ValueError(
                f"Sub-byte scalar dereference not supported for type {self.element_type}"
            )


#
# Tensor API
#


@dsl_user_op
def make_tensor(
    iterator, layout: Union[Shape, Layout, ComposedLayout], *, loc=None, ip=None
) -> Tensor:
    """Creates a tensor by composing an engine (iterator/pointer) with a layout.

    A tensor is defined as T = E ∘ L, where E is an engine (array, pointer, or counting iterator)
    and L is a layout that maps logical coordinates to physical offsets. The tensor
    evaluates coordinates by applying the layout mapping and dereferencing the engine
    at the resulting offset.

    :param iterator: Engine component that provides data access capabilities. Can be:
                    - A pointer (Pointer type)
                    - An integer or integer tuple for coordinate tensors
                    - A shared memory descriptor (SmemDescType)
    :type iterator: Union[Pointer, IntTuple, ir.Value]
    :param layout: Layout component that defines the mapping from logical coordinates to
                  physical offsets. Can be:
                  - A shape tuple that will be converted to a layout
                  - A Layout object
                  - A ComposedLayout object (must be a normal layout)
    :type layout: Union[Shape, Layout, ComposedLayout]
    :param loc: Source location for MLIR operation tracking, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for MLIR operation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A tensor object representing the composition E ∘ L
    :rtype: Tensor

    :raises TypeError: If iterator type is not a supported type
    :raises ValueError: If layout is a composed layout with customized inner functions

    **Examples:**

    .. code-block:: python

        # Create a tensor with row-major layout from a pointer
        ptr = make_ptr(Float32, base_ptr, AddressSpace.gmem)
        layout = make_layout((64, 128), stride=(128, 1))
        tensor = make_tensor(ptr, layout)

        # Create a tensor with hierarchical layout in shared memory
        smem_ptr = make_ptr(Float16, base_ptr, AddressSpace.smem)
        layout = make_layout(((128, 8), (1, 4, 1)), stride=((32, 1), (0, 8, 4096)))
        tensor = make_tensor(smem_ptr, layout)

        # Create a coordinate tensor
        layout = make_layout(2, stride=16 * E(0))
        tensor = make_tensor(5, layout)  # coordinate tensor with iterator starting at 5

    Notes:
        - The engine (iterator) must support random access operations
        - Common engine types include raw pointers, arrays, and random-access iterators
        - The layout defines both the shape (logical dimensions) and stride (physical mapping)
        - Supports both direct coordinate evaluation T(c) and partial evaluation (slicing)
        - ComposedLayouts must be "normal" layouts (no inner functions)
        - For coordinate tensors, the iterator is converted to a counting sequence
    """
    if isinstance(layout, _ComposedLayoutWithInnerFunc):
        raise ValueError(
            "CuTe DSL tensor does not support composed layouts with inner functions: {layout}"
        )

    if not isinstance(layout, (Layout, ComposedLayout)):
        layout = make_layout(layout, loc=loc, ip=ip)
    # Automatic decay to normal layout
    elif isinstance(layout, ComposedLayout) and layout.is_normal:
        layout = layout.outer

    res_ty = None
    if is_integer(iterator) or isinstance(iterator, tuple):
        iterator = _pack_int_tuple(iterator, loc=loc, ip=ip)
        res_ty = _cute_ir.CoordTensorType.get(iterator.type, layout.type)
    elif isinstance(iterator, Pointer):
        iterator = iterator.value
        res_ty = _cute_ir.MemRefType.get(iterator.type, layout.type)
    elif isinstance(iterator, ir.Value) and isinstance(
        iterator.type, _cute_nvgpu_ir.SmemDescType
    ):
        res_ty = _cute_nvgpu_ir.SmemDescViewType.get(layout.type)
    else:
        raise TypeError(f"unsupported iterator type, got {type(iterator)}")

    if isinstance(layout, _ComposedLayout):
        layout = layout.value
    return _cute_ir.make_view(
        result=res_ty, iter=iterator, layout=layout, loc=loc, ip=ip
    )


@dsl_user_op
def make_identity_tensor(shape: Shape, *, loc=None, ip=None) -> Tensor:
    """Creates an identity tensor with the given shape.

    An identity tensor maps each coordinate to itself, effectively creating a counting
    sequence within the shape's bounds. This is useful for generating coordinate indices
    or creating reference tensors for layout transformations.

    :param shape: The shape defining the tensor's dimensions. Can be a simple integer
                 sequence or a hierarchical structure ((m,n),(p,q))
    :type shape: Shape
    :param loc: Source location for MLIR operation tracking, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for MLIR operation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A tensor that maps each coordinate to itself
    :rtype: Tensor

    **Examples:**

    .. code-block:: python

        # Create a simple 1D coord tensor
        tensor = make_identity_tensor(6)  # [0,1,2,3,4,5]

        # Create a 2D coord tensor
        tensor = make_identity_tensor((3,2))  # [(0,0),(1,0),(2,0),(0,1),(1,1),(2,1)]

        # Create hierarchical coord tensor
        tensor = make_identity_tensor(((2,1),3))
        # [((0,0),0),((1,0),0),((0,0),1),((1,0),1),((0,0),2),((1,0),2)]

    Notes:
        - The shape parameter follows CuTe's IntTuple concept
        - Coordinates are ordered colexicographically
        - Useful for generating reference coordinates in layout transformations
    """
    shape_val = _pack_shape(shape, loc=loc, ip=ip)
    return _cute_ir.make_identity_tensor(shape_val, loc=loc, ip=ip)


@dsl_user_op
def make_rmem_tensor(
    layout_or_shape: Union[Layout, Shape], dtype: Type[Numeric], *, loc=None, ip=None
) -> Tensor:
    """Creates a tensor in register memory with the specified layout/shape and data type.

    This function allocates a tensor in register memory (rmem) usually on stack with
    either a provided layout or creates a new layout from the given shape. The tensor
    will have elements of the specified numeric data type.

    :param layout_or_shape: Either a Layout object defining the tensor's memory organization,
                          or a Shape defining its dimensions
    :type layout_or_shape: Union[Layout, Shape]
    :param dtype: The data type for tensor elements (must be a Numeric type)
    :type dtype: Type[Numeric]
    :param loc: Source location for MLIR operation tracking, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for MLIR operation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A tensor allocated in register memory
    :rtype: Tensor

    **Examples:**

    .. code-block:: python

        # Create rmem tensor with explicit layout
        layout = make_layout((128, 32))
        tensor = make_rmem_tensor(layout, cutlass.Float16)

        # Create rmem tensor directly from shape
        tensor = make_rmem_tensor((64, 64), cutlass.Float32)

    Notes:
        - Uses 32-byte alignment to support .128 load/store operations
        - Boolean types are stored as 8-bit integers
        - Handles both direct shapes and Layout objects
    """
    if not issubclass(dtype, Numeric):
        raise TypeError(f"value_type must be a type of Numeric, but got {type(dtype)}")
    elem_ty = dtype.mlir_type if dtype is not Boolean else T.i8()

    # Alignment for register memory is useless(?), pick-up large enough number
    # to allow .128 (> 16B) load store
    alignment = 32
    layout = None
    if not isinstance(layout_or_shape, Layout):
        layout = make_layout(layout_or_shape, loc=loc, ip=ip)
    elif isinstance(layout_or_shape, _ComposedLayout):
        layout = layout_or_shape.value
    else:
        layout = layout_or_shape

    ptr_ty = _cute_ir.PtrType.get(elem_ty, AddressSpace.rmem, alignment)
    res_ty = _cute_ir.MemRefType.get(ptr_ty, layout.type)
    tensor = _cute_ir.memref_alloca(res_ty, layout=layout, loc=loc, ip=ip)
    return _Tensor(tensor.value, dtype)


@dsl_user_op
@deprecated("`make_fragment` is deprecated, use `make_rmem_tensor` instead")
def make_fragment(
    layout_or_shape: Union[Layout, Shape], dtype: Type[Numeric], *, loc=None, ip=None
) -> Tensor:
    return make_rmem_tensor(layout_or_shape, dtype, loc=loc, ip=ip)


@dsl_user_op
def make_rmem_tensor_like(
    src: Union[Layout, ComposedLayout, Tensor],
    dtype: Optional[Type[Numeric]] = None,
    *,
    loc=None,
    ip=None,
) -> Tensor:
    """Creates a tensor in register memory with the same shape as the input layout but
       compact col-major strides. This is equivalent to calling `make_rmem_tensor(make_layout_like(tensor))`.

    This function allocates a tensor in register memory (rmem) usually on stack with
    with the compact layout like the source. The tensor will have elements of the
    specified numeric data type or the same as the source.

    :param src: The source layout or tensor whose shape will be matched
    :type src: Union[Layout, ComposedLayout, Tensor]
    :param dtype: The element type for the fragment tensor, defaults to None
    :type dtype: Type[Numeric], optional
    :param loc: Source location for MLIR operations, defaults to None
    :type loc: Location, optional
    :param ip: Insertion point for MLIR operations, defaults to None
    :type ip: InsertionPoint, optional

    :return: A new layout or fragment tensor with matching shape
    :rtype: Union[Layout, Tensor]

    **Examples:**

    Creating a rmem tensor from a tensor:

    .. code-block:: python

        smem_tensor = cute.make_tensor(smem_ptr, layout)
        rmem_tensor = cute.make_rmem_tensor_like(smem_tensor, cutlass.Float32)
        # frag_tensor will be a register-backed tensor with the same shape

    Creating a fragment with a different element type:

    .. code-block:: python

        tensor = cute.make_tensor(gmem_ptr, layout)
        rmem_bool_tensor = cute.make_rmem_tensor_like(tensor, cutlass.Boolean)
        # bool_frag will be a register-backed tensor with Boolean elements

    **Notes**

    - When used with a Tensor, if a type is provided, it will create a new
      fragment tensor with that element type.
    - For layouts with ScaledBasis strides, the function creates a fragment
      from the shape only.
    - This function is commonly used in GEMM and other tensor operations to
      create register storage for intermediate results.

    """
    if not isinstance(src, (Layout, ComposedLayout, Tensor)):
        raise TypeError(
            f"src must be a Layout or ComposedLayout or Tensor, got {type(src)}"
        )

    if isinstance(src, Tensor):
        if isinstance(src.type, _cute_ir.CoordTensorType):
            if dtype is None:
                raise ValueError(
                    "dtype must be provided when src is a coordinate tensor"
                )

            res_dtype = dtype
            compact_layout = make_layout(src.shape, loc=loc, ip=ip)
            src_layout = _cute_ir.make_layout_like(compact_layout, loc=loc, ip=ip)
        else:
            res_dtype = dtype or src.element_type
            src_layout = src.layout
    else:
        if dtype is None:
            raise ValueError("dtype must be provided when src is a layout")

        res_dtype = dtype
        src_layout = src

    if isinstance(src_layout, _ComposedLayout):
        src_layout = src_layout.value

    res_layout = _cute_ir.make_layout_like(src_layout, loc=loc, ip=ip)
    return make_rmem_tensor(res_layout, res_dtype, loc=loc, ip=ip)


@overload
def make_fragment_like(
    src: Tensor, dtype: Optional[Type[Numeric]], *, loc=None, ip=None
) -> Tensor: ...
@overload
def make_fragment_like(src: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def make_fragment_like(src: ComposedLayout, *, loc=None, ip=None) -> ComposedLayout: ...


@dsl_user_op
def make_fragment_like(src, dtype=None, *, loc=None, ip=None):
    # Keep code to avoid potential regression
    if isinstance(src, (Layout, _ComposedLayout)):
        if isinstance(src, _ComposedLayout):
            src = src.value
        new_layout = _cute_ir.make_fragment_like(src, loc=loc, ip=ip)

        if dtype is not None:
            # call make_rmem_tensor to convert layout to tensor
            return make_rmem_tensor(new_layout, dtype, loc=loc, ip=ip)
        else:
            return new_layout
    else:
        return make_rmem_tensor_like(src, dtype, loc=loc, ip=ip)


@dsl_user_op
def recast_tensor(
    src: Tensor, dtype: Type[Numeric], swizzle_=None, *, loc=None, ip=None
):
    if not isclass(dtype) or not issubclass(dtype, Numeric):
        raise TypeError(f"dtype must be a type of Numeric, but got {dtype}")

    if dtype is Boolean:
        dst_width = 8
    else:
        dst_width = dtype.width

    if src.element_type is Boolean:
        src_width = 8
    else:
        src_width = src.element_type.width

    src_iter = recast_ptr(src.iterator, dtype=dtype, loc=loc, ip=ip)
    src_layout = recast_layout(dst_width, src_width, src.layout, loc=loc, ip=ip)
    return make_tensor(src_iter, src_layout, loc=loc, ip=ip)


@dsl_user_op
def domain_offset(coord: Coord, tensor: Tensor, *, loc=None, ip=None) -> Tensor:
    offset = crd2idx(coord, tensor.layout, loc=loc, ip=ip)
    if isinstance(tensor.iterator, Pointer):
        return make_tensor(
            tensor.iterator.__add__(offset, loc=loc, ip=ip),
            tensor.layout,
            loc=loc,
            ip=ip,
        )
    elif is_integer(tensor.iterator) or isinstance(tensor.iterator, tuple):
        new_iter = _cute_ir.add_offset(
            _pack_int_tuple(tensor.iterator, loc=loc, ip=ip),
            _pack_int_tuple(offset, loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        return make_tensor(
            _unpack_x_tuple(new_iter, loc=loc, ip=ip),
            tensor.layout,
            loc=loc,
            ip=ip,
        )
    else:
        raise ValueError(f"unsupported tensor for domain_offset, got {tensor}")


@dsl_user_op
def print_tensor(
    tensor: Union[Tensor, "TensorSSA"], *, verbose: bool = False, loc=None, ip=None
):
    """Print content of the tensor in human readable format.

    Outputs the tensor data in a structured format showing both metadata
    and the actual data values. The output includes tensor type information,
    layout details, and a formatted array representation of the values.

    :param tensor: The tensor to print
    :type tensor: Tensor
    :param verbose: If True, includes additional debug information in the output
    :type verbose: bool
    :param loc: Source location where it's called, defaults to None
    :type loc: source location, optional
    :param ip: Insertion pointer for IR generation, defaults to None
    :type ip: insertion pointer, optional
    :raises NotImplementedError: If the tensor type doesn't support trivial dereferencing

    **Example output:**

    .. code-block:: text

        tensor(raw_ptr<@..., Float32, generic, align(4)> o (8,5):(5,1), data=
               [[-0.4326, -0.5434,  0.1238,  0.7132,  0.8042],
                [-0.8462,  0.9871,  0.4389,  0.7298,  0.6948],
                [ 0.3426,  0.5856,  0.1541,  0.2923,  0.6976],
                [-0.1649,  0.8811,  0.1788,  0.1404,  0.2568],
                [-0.2944,  0.8593,  0.4171,  0.8998,  0.1766],
                [ 0.8814,  0.7919,  0.7390,  0.4566,  0.1576],
                [ 0.9159,  0.7577,  0.6918,  0.0754,  0.0591],
                [ 0.6551,  0.1626,  0.1189,  0.0292,  0.8655]])
    """
    if isinstance(tensor, TensorSSA):
        tmp = make_rmem_tensor(tensor.shape, tensor.dtype)
        tmp.store(tensor)
        tensor = tmp

    if isinstance(tensor.type, _cute_ir.MemRefType):
        if tensor.element_type.is_integer:
            signed = tensor.element_type.signed
        else:
            signed = False
    else:
        signed = True

    _cute_ir.print_view(tensor.value, verbose=verbose, is_signed=signed, loc=loc, ip=ip)


def _get_row_and_col_map(col_maj_shape_1d: tuple, is_row_to_col: bool):
    """
    Create an index mapping mask for converting between row-major and column-major vector ordering.
    """

    # create row-major layout with compact row-major stride
    if col_maj_shape_1d is None:
        raise ValueError("vector shape for row/col map cannot be None")
    if isinstance(col_maj_shape_1d, tuple):
        row_maj_shape_1d = tuple(reversed(flatten(col_maj_shape_1d)))
    else:
        # Single dimension
        row_maj_shape_1d = col_maj_shape_1d

    flat_shape = flatten(row_maj_shape_1d)
    if isinstance(flat_shape, tuple):
        strides = []
        current_stride = 1
        flat_shape = tuple(reversed(flat_shape))
        for dim in flat_shape:
            strides.append(current_stride)
            current_stride *= dim
        row_maj_stride = tuple(reversed(strides))
    else:
        # Single dimension
        row_maj_stride = 1

    row_maj_lay_1d = make_layout(row_maj_shape_1d, stride=row_maj_stride)

    # get idx map
    shape_size = size(row_maj_shape_1d)
    mask = [0] * shape_size

    for col_index in range(shape_size):
        row_index = crd2idx(col_index, row_maj_lay_1d)
        if is_row_to_col:
            mask[row_index] = col_index
        else:
            mask[col_index] = row_index

    return mask


def _row2col(vec: ir.Value, *, shape, loc=None, ip=None) -> ir.Value:
    """
    Convert a vector or tensor from row-major order to column-major order.
    """
    row_and_col_map = _get_row_and_col_map(shape, is_row_to_col=True)
    return vector.shuffle(vec, vec, row_and_col_map, loc=loc, ip=ip)


def _col2row(vec: ir.Value, *, shape, loc=None, ip=None) -> ir.Value:
    """
    Convert a vector or tensor from column-major order to row-major order.
    """
    row_and_col_map = _get_row_and_col_map(shape, is_row_to_col=False)
    return vector.shuffle(vec, vec, row_and_col_map, loc=loc, ip=ip)


def _infer_broadcast_shape(*shapes: Shape) -> Shape:
    """
    Infer the broadcasted shape from multiple input shapes according to broadcasting rules.

    :param shapes: Variable number of tensor shapes to broadcast together.
    :type shapes: Shape
    :return: The broadcasted shape.
    :rtype: Shape
    :raises ValueError: If no shapes provided or shapes cannot be broadcast together.
    """

    if len(shapes) == 0:
        raise ValueError("At least one shape must be provided")
    elif len(shapes) == 1:
        return shapes[0]

    def _broadcast(*values):
        non_one_values = [v for v in values if v != 1]
        if len(non_one_values) == 0:
            return 1
        elif len(set(non_one_values)) == 1:
            return non_one_values[0]
        else:
            raise ValueError(f"cannot broadcast {values}")

    max_rank = max(rank(shape) for shape in shapes)
    ext_shapes = tuple(append(shape, 1, up_to_rank=max_rank) for shape in shapes)
    res_shape = transform_leaf(_broadcast, *ext_shapes)
    return res_shape


class TensorSSA(cutlass_arith.ArithValue):
    """A class representing thread local data from CuTe Tensor in value semantic and immutable.

    :param value: Flatten vector as ir.Value holding logic data of SSA Tensor
    :type value: ir.Value
    :param shape: The nested shape in CuTe of the vector
    :type shape: Shape
    :param dtype: Data type of the tensor elements
    :type dtype: Type[Numeric]

    :ivar _shape: The nested shape in CuTe of the vector
    :ivar _dtype: Data type of the tensor elements

    :raises ValueError: If shape is not static
    """

    def __init__(self, value, shape: Shape, dtype: Type[Numeric]):
        """Initialize a new TensorSSA object.

        :param value: Flatten vector as ir.Value holding logic data of SSA Tensor
        :type value: ir.Value
        :param shape: The nested shape in CuTe of the vector
        :type shape: Shape
        :param dtype: Data type of the tensor elements
        :type dtype: Type[Numeric]
        :raises ValueError: If shape is not static
        """
        if not is_static(shape):
            raise ValueError("dynamic shape is not supported")

        signed = dtype.signed if issubclass(dtype, Integer) else False
        super().__init__(value, signed)

        self._shape = shape
        self._dtype = dtype
        self._layout = None

    @property
    def dtype(self) -> Type[Numeric]:
        return self._dtype

    @property
    def element_type(self) -> Type[Numeric]:
        return self._dtype

    def __extract_mlir_values__(self):
        return [self]

    def __new_from_mlir_values__(self, values):
        return TensorSSA(values[0], self.shape, self.dtype)

    def __str__(self):
        return f"tensor_value<{self.type} o {self.shape}>"

    @property
    def shape(self):
        return self._shape

    @overload
    def _apply_op(
        self, op, other: "TensorSSA", flip=False, *, loc, ip
    ) -> "TensorSSA": ...
    @overload
    def _apply_op(
        self, op, other: cutlass_arith.ArithValue, flip=False, *, loc, ip
    ) -> "TensorSSA": ...
    @overload
    def _apply_op(
        self, op, other: Union[int, float, bool], flip=False, *, loc, ip
    ) -> "TensorSSA": ...

    def _apply_op(self, op, other, flip=False, *, loc=None, ip=None):
        # Canonicalize into Numeric
        if isinstance(other, (int, float, bool)) or (
            not isinstance(other, TensorSSA)
            and isinstance(other, cutlass_arith.ArithValue)
        ):
            other = as_numeric(other)

        # Promote types
        lhs, rhs, res_type = _binary_op_type_promote(self, other)

        # Promote scalar to vector
        if not isinstance(rhs, TensorSSA):
            assert isinstance(rhs, Numeric), (
                f"Expected rhs to be Numeric, but got {rhs}"
            )
            vect_val = vector.broadcast(lhs.type, rhs.ir_value(loc=loc, ip=ip))

            rhs = TensorSSA(vect_val, lhs.shape, lhs.dtype)

        if flip:
            lhs, rhs = rhs, lhs

        if op in (
            operator.lt,
            operator.le,
            operator.gt,
            operator.ge,
            operator.eq,
            operator.ne,
        ):
            res_type = Boolean

        assert isinstance(rhs, TensorSSA), f"rhs must be TensorSSA but got {rhs}"

        # broadcast to the same shape
        res_shape = _infer_broadcast_shape(lhs.shape, rhs.shape)
        lhs = lhs.broadcast_to(res_shape)
        rhs = rhs.broadcast_to(res_shape)

        if (
            op in (operator.add, operator.sub)
            and lhs.dtype == Boolean
            and rhs.dtype == Boolean
        ):
            res = op(lhs.to(Int32), rhs.to(Int32))
            zero = zeros_like(res)
            res = res.__ne__(zero).to(res_type)
        else:
            lhs_val = lhs.maybe_downcast()
            rhs_val = rhs.maybe_downcast()

            if issubclass(lhs.dtype, Integer):
                lhs_val = lhs_val.with_signedness(lhs.dtype.signed)

            if issubclass(rhs.dtype, Integer):
                rhs_val = rhs_val.with_signedness(rhs.dtype.signed)

            res_vect = op(lhs_val, rhs_val)
            res = TensorSSA(res_vect, lhs._shape, res_type)

        return res

    @dsl_user_op
    def apply_op(self, op, other, flip=False, *, loc=None, ip=None) -> "TensorSSA":
        """
        Apply a binary operation to this tensor and another operand.

        This is a public interface to the internal _apply_op method, providing
        a stable API for external users who need to apply custom operations.

        Args:
            op: The operation function (e.g., operator.add, operator.mul, etc.)
            other: The other operand (TensorSSA, ArithValue, or scalar)
            flip: Whether to flip the operands (for right-hand operations)
            loc: MLIR location (optional)
            ip: MLIR insertion point (optional)

        Returns:
            TensorSSA: The result of the operation

        Example:
            >>> tensor1 = cute.Tensor(...)
            >>> tensor2 = cute.Tensor(...)
            >>> result = tensor1.apply_op(operator.add, tensor2)
            >>> # Equivalent to: tensor1 + tensor2
        """
        return self._apply_op(op, other, flip=flip, loc=loc, ip=ip)

    @dsl_user_op
    def broadcast_to(self, target_shape: Shape, *, loc=None, ip=None) -> "TensorSSA":
        """
        Broadcast the tensor to the target shape.
        """
        # pad source shape to the same rank
        shape = append(self.shape, 1, up_to_rank=rank(target_shape))
        if shape == target_shape:
            return self

        def _check_broadcast(s, t):
            if s != t and s != 1:
                raise ValueError(
                    f"src_shape and target_shape must be the same when src_shape is not 1, but got {s} and {t}"
                )

        transform_leaf(_check_broadcast, shape, target_shape)

        # convert TensorSSA col-major vec to row-m to be compatible with mlir vector ops
        row_major_vec = _col2row(self, shape=shape, loc=loc, ip=ip)
        # reshape to flatten N-D vector
        flat_shp = flatten_to_tuple(shape)
        temp_ty = ir.VectorType.get(list(flat_shp), self.dtype.mlir_type)
        temp_vect = vector.shape_cast(temp_ty, row_major_vec, loc=loc, ip=ip)

        # broadcast to result N-D vector
        flat_tgt_shp = flatten_to_tuple(target_shape)
        temp_tgt_ty = ir.VectorType.get(list(flat_tgt_shp), self.dtype.mlir_type)
        temp_tgt_vect = vector.broadcast(temp_tgt_ty, temp_vect, loc=loc, ip=ip)

        return self._build_result(
            temp_tgt_vect, target_shape, row_major=True, loc=loc, ip=ip
        )

    @dsl_user_op
    def __pow__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the results of tensor^other.

        :param other: The other tensor for exponent.
        :type other: TensorSSA
        :return: The power of the tensor.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.pow, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rpow__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the results of other^tensor.

        :param other: The other tensor to compute power with.
        :type other: TensorSSA
        :return: The element-wise power of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.pow, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __add__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the sum of the tensor and another tensor.

        :param other: The other tensor to add.
        :type other: TensorSSA
        :return: The sum of the two tensors with the same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.add, other, loc=loc, ip=ip)

    @dsl_user_op
    def __radd__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the sum of the tensor and another tensor (reverse add)

        :param other: The other tensor to add.
        :type other: TensorSSA
        :return: The sum of the two tensors with the same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.add, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __sub__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the difference of the tensor and another tensor.

        :param other: The other tensor to subtract.
        :type other: TensorSSA
        :return: The subtraction of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.sub, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rsub__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the difference of the tensor and another tensor (reverse subtract)

        :param other: The other tensor to subtract.
        :type other: TensorSSA
        :return: The subtraction of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.sub, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __mul__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the multiplication of the tensor and another tensor.

        :param other: The other tensor to multiply.
        :type other: TensorSSA
        :return: The multiplication of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.mul, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rmul__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the multiplication of the tensor and another tensor (reverse multiply)

        :param other: The other tensor to multiply.
        :type other: TensorSSA
        :return: The multiplication of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.mul, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __mod__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the modulo of the tensor and another tensor.

        :param other: The other tensor to compute modulo with.
        :type other: TensorSSA
        :return: The element-wise modulo of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.mod, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rmod__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the modulo of the tensor and another tensor (reverse modulo)

        :param other: The other tensor to compute modulo with.
        :type other: TensorSSA
        :return: The element-wise modulo of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.mod, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __floordiv__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the floordiv(//) of the tensor and another tensor.

        :param other: The other tensor to compute floordiv with.
        :type other: TensorSSA
        :return: The floordiv of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.floordiv, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rfloordiv__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the floordiv(//) of the tensor and another tensor (reverse floordiv)

        :param other: The other tensor to compute floordiv with.
        :type other: TensorSSA
        :return: The floordiv of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.floordiv, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __truediv__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the truediv(/) of the tensor and another tensor.

        :param other: The other tensor to compute truediv with.
        :type other: TensorSSA
        :return: The truediv of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.truediv, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rtruediv__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the truediv(/) of the tensor and another tensor (reverse truediv)

        :param other: The other tensor to compute truediv with.
        :type other: TensorSSA
        :return: The truediv of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.truediv, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __eq__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the comparison of the tensor and another tensor as mask

        :param other: The other tensor to compare.
        :type other: TensorSSA
        :return: The comparison of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.eq, other, loc=loc, ip=ip)

    @dsl_user_op
    def __ne__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise not equal comparison of the tensor and another tensor.

        :param other: The other tensor to compare.
        :type other: TensorSSA
        :return: A boolean tensor with same shape as inputs, True where self != other.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.ne, other, loc=loc, ip=ip)

    @dsl_user_op
    def __lt__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise less than comparison of the tensor and another tensor.

        :param other: The other tensor to compare with.
        :type other: TensorSSA
        :return: A boolean tensor with same shape as inputs, True where self < other.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.lt, other, loc=loc, ip=ip)

    @dsl_user_op
    def __le__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise less than or equal comparison of the tensor and another tensor.

        :param other: The other tensor to compare with.
        :type other: TensorSSA
        :return: A boolean tensor with same shape as inputs, True where self <= other.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.le, other, loc=loc, ip=ip)

    @dsl_user_op
    def __gt__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise greater than comparison of the tensor and another tensor.

        :param other: The other tensor to compare with.
        :type other: TensorSSA
        :return: A boolean tensor with same shape as inputs, True where self > other.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.gt, other, loc=loc, ip=ip)

    @dsl_user_op
    def __ge__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise greater than or equal comparison of the tensor and another tensor.

        :param other: The other tensor to compare with.
        :type other: TensorSSA
        :return: A boolean tensor with same shape as inputs, True where self >= other.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.ge, other, loc=loc, ip=ip)

    @dsl_user_op
    def __xor__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise XOR of the tensor and another tensor.

        :param other: The other tensor to perform XOR with.
        :type other: TensorSSA
        :return: The element-wise XOR of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.xor, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rxor__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the bitwise XOR of the tensor and another tensor.

        :param other: The other tensor to compute XOR with.
        :type other: TensorSSA
        :return: The element-wise bitwise XOR of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.xor, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __or__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise OR of the tensor and another tensor.

        :param other: The other tensor to perform OR with.
        :type other: TensorSSA
        :return: The element-wise OR of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.or_, other, loc=loc, ip=ip)

    @dsl_user_op
    def __ror__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise OR of the tensor and another tensor.

        :param other: The other tensor to perform OR with.
        :type other: TensorSSA
        :return: The element-wise OR of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.or_, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __and__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise AND of the tensor and another tensor.

        :param other: The other tensor to perform AND with.
        :type other: TensorSSA
        :return: The element-wise AND of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.and_, other, loc=loc, ip=ip)

    @dsl_user_op
    def __rand__(self, other, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the element-wise AND of the tensor and another tensor.

        :param other: The other tensor to perform AND with.
        :type other: TensorSSA
        :return: The element-wise AND of two tensors with same shape as inputs.
        :rtype: TensorSSA
        """
        return self._apply_op(operator.and_, other, flip=True, loc=loc, ip=ip)

    @dsl_user_op
    def __neg__(self, *, loc=None, ip=None) -> "TensorSSA":
        """
        Returns the negation of the tensor.

        :return: The element-wise negation of the tensor
        :rtype: TensorSSA
        """

        return self._apply_op(operator.sub, 0, flip=True, loc=loc, ip=ip)

    def _flatten_shape_and_coord(self, crd, *, loc=None, ip=None):
        # Coalesce and flatten source layout at terminal of coordinate
        # (N_0,(N_1,...), ...) -> (N_0,N_1,N_2,...)
        crd_shp = product_like(self._shape, target_profile=crd, loc=loc, ip=ip)

        # Flatten coordinate
        flat_shp = flatten(crd_shp)
        assert isinstance(flat_shp, tuple) and is_static(flat_shp)
        # (C_0,(C_1,...), ...) -> (C_0,C_1,C_2,...)
        flat_crd = flatten(crd)

        assert isinstance(flat_crd, tuple) and is_static(flat_crd)
        return flat_shp, flat_crd

    def _build_result(self, res_vect, res_shp, *, row_major=False, loc=None, ip=None):
        if isinstance(res_shp, ir.Value):
            raise ValueError(f"Expected static shape, but got {self._shape}")

        # cast back to 1D vector
        res_1d_ty = ir.VectorType.get([size(res_shp)], self.type.element_type)
        res_1d_vect = vector.shape_cast(res_1d_ty, res_vect, loc=loc, ip=ip)

        if row_major:
            res_1d_vect = _row2col(res_1d_vect, shape=res_shp, loc=loc, ip=ip)

        return TensorSSA(res_1d_vect, res_shp, self.dtype)

    @dsl_user_op
    def reshape(self, shape: Shape, *, loc=None, ip=None) -> "TensorSSA":
        """Reshape the tensor to a new shape.

        :param shape: The new shape to reshape to.
        :type shape: Shape
        :return: A new tensor with the same elements but with the new shape.
        :rtype: TensorSSA
        :raises NotImplementedError: If dynamic size is not supported
        :raises ValueError: If the new shape is not compatible with the current shape
        """

        cur_size = size(self.shape, loc=loc, ip=ip)
        shp_size = size(shape, loc=loc, ip=ip)

        if type(shp_size) is not int:
            raise NotImplementedError(f"dynamic shape is not supported: {shape}")
        if cur_size != shp_size:
            raise ValueError(
                f"expected reshaped size to be the same: {self.shape} -> {shape}"
            )

        return TensorSSA(self, shape, self.dtype)

    @dsl_user_op
    def __getitem__(
        self, crd: Coord, *, loc=None, ip=None
    ) -> Union["TensorSSA", Numeric]:
        """Access or slice tensor elements using coordinates.

        This method implements tensor evaluation T(c) = *(E + L(c)) where E is the iterator/engine
        and L is the layout. It supports both direct element access and slicing operations.

        :param crd: Coordinate or slice specification for accessing tensor elements
        :type crd: Coord
        :param loc: Source location for MLIR operation tracking, defaults to None
        :type loc: Optional[Location]
        :param ip: Insertion point for MLIR operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: Tensor element value or sliced subtensor
        :rtype: Union[TensorSSA, Numeric]

        :raises ValueError: If coordinate access is invalid for the tensor layout

        **Examples:**

        .. code-block:: python

            # Create a fragment from rmem as shape (8, 4)
            layout = make_layout((8, 4))
            tensor = make_rmem_tensor(layout, Float32)
            frg = tensor.load()

            # Direct element access
            val = frg[0]  # Returns first element of fragment
            val = frg[(0, 1)]  # Returns element at (0, 1)

            # Slice access
            sliced = frg[(3, None)]  # Returns fragment slice
        """
        # short-cut to no-op
        if crd is None:
            return self

        if not has_underscore(crd):
            if self._layout is None:
                self._layout = make_layout(self._shape, loc=loc, ip=ip)
            idx = crd2idx(crd, self._layout, loc=loc, ip=ip)
            assert not isinstance(idx, tuple), "index must be scalar"
            idx_val = as_numeric(idx).ir_value(loc=loc, ip=ip)
            res_val = vector.extractelement(self, position=idx_val, loc=loc, ip=ip)
            return self.dtype(res_val)

        if not is_static(crd):
            raise ValueError("dynamic coordinate is not supported")

        flat_shp, flat_crd = self._flatten_shape_and_coord(crd, loc=loc, ip=ip)

        # convert TensorSSA col-major vec to row-m to be compatible with mlir vector ops
        row_major_vec = _col2row(self, shape=self._shape, loc=loc, ip=ip)
        multi_dim_ty = ir.VectorType.get(list(flat_shp), self.type.element_type)
        # vector<NxTy> -> vector<N_0xN_1x...xTy>
        tmp_vect = vector.shape_cast(multi_dim_ty, row_major_vec, loc=loc, ip=ip)

        # Slice and keep dims matching `_` or None
        res_shp = slice_(self._shape, crd, loc=loc, ip=ip)
        assert not isinstance(res_shp, ir.Value), (
            f"Expected static shape and coordinates, but got {self._shape} and {crd}"
        )

        # Offsets is index of coordinates if NOT `_` otherwise 0
        offsets = [c if c is not None else 0 for c in flat_crd]
        # Sizes is size of shapes if `_` otherwise 1
        sizes = [s if c is None else 1 for s, c in zip(flat_shp, flat_crd)]
        # Logic stride to index vector. Only support stride-1 by vector
        strides = [1] * rank(flat_shp)

        # Vector slice on N-D vector
        res_ty = ir.VectorType.get(list(sizes), self.type.element_type)
        res_vect = vector.extract_strided_slice(
            res_ty,
            tmp_vect,
            offsets=offsets,
            sizes=sizes,
            strides=strides,
            loc=loc,
            ip=ip,
        )

        # Slice and keep dims matching `_` or None
        res_shp = slice_(self._shape, crd, loc=loc, ip=ip)
        return self._build_result(res_vect, res_shp, row_major=True, loc=loc, ip=ip)

    @dsl_user_op
    def to(self, dtype: Type[Numeric], *, loc=None, ip=None):
        """Convert the tensor to a different numeric type.

        :param dtype: The target numeric type to cast to.
        :type dtype: Type[Numeric]
        :return: A new tensor with the same shape but with elements cast to the target type.
        :rtype: TensorSSA
        :raises TypeError: If dtype is not a subclass of Numeric.
        :raises NotImplementedError: If dtype is an unsigned integer type.
        """
        if dtype is ir.Value:
            return self

        if not isclass(dtype) or not issubclass(dtype, Numeric):
            raise TypeError(f"dtype must be a type of Numeric, but got {type(dtype)}")

        src_dtype = self.dtype
        if src_dtype == dtype:
            return self

        # maybe downcast can lose signedness
        src = self.maybe_downcast().with_signedness(self.signed)
        if src_dtype.is_float and dtype.is_float:
            if src_dtype == Float4E2M1FN and dtype in (Float16, Float32):
                res_vect = cvt_f4e2m1_f16_intrinsic(
                    src, size(self.shape), loc=loc, ip=ip
                )
                if dtype == Float32:
                    res_vect = cutlass_arith.cvtf(
                        res_vect, dtype.mlir_type, loc=loc, ip=ip
                    )
            elif src_dtype == Float8E4M3 and dtype in (Float16, Float32):
                res_vect = cvt_f8e4m3_f16_intrinsic(
                    src, size(self.shape), loc=loc, ip=ip
                )
                if dtype == Float32:
                    res_vect = cutlass_arith.cvtf(
                        res_vect, dtype.mlir_type, loc=loc, ip=ip
                    )
            else:
                res_vect = cutlass_arith.cvtf(src, dtype.mlir_type, loc=loc, ip=ip)
        elif src_dtype.is_float and issubclass(dtype, Integer):
            res_vect = cutlass_arith.fptoi(
                src, dtype.signed, dtype.mlir_type, loc=loc, ip=ip
            )
        elif issubclass(src_dtype, Integer) and dtype.is_float:
            # check if there is a fast conversion path for given data types and arch
            fast_cvt_func = None
            if src_dtype in (Int8, Uint8) and dtype == BFloat16:
                fast_cvt_func = cvt_i8_bf16_intrinsic
            elif src_dtype == Int4 and dtype == BFloat16:
                fast_cvt_func = cvt_i4_bf16_intrinsic
            arch = CuTeDSL._get_dsl().get_arch_enum()
            if fast_cvt_func is not None and arch in fast_cvt_func.supported_archs:
                res_vect = fast_cvt_func(src, size(self.shape), loc=loc, ip=ip)
            else:
                res_vect = cutlass_arith.itofp(
                    src, src_dtype.signed, dtype.mlir_type, loc=loc, ip=ip
                )
        else:
            res_vect = cutlass_arith.int_to_int(src, dtype, loc=loc, ip=ip)

        return TensorSSA(res_vect, self._shape, dtype)

    @dsl_user_op
    def ir_value(self, *, loc=None, ip=None):
        return self

    @dsl_user_op
    def ir_value_int8(self, *, loc=None, ip=None):
        """
        Returns int8 ir value of Boolean tensor.
        When we need to store Boolean tensor ssa, use ir_value_int8().

        :param loc: Source location information, defaults to None
        :type loc: Optional[Location], optional
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[InsertionPoint], optional
        :return: The int8 value of this Boolean
        :rtype: ir.Value
        """
        assert self.element_type is Boolean, (
            f"Only boolean type needs to be converted to int8, got {self.element_type}"
        )

        if not hasattr(self, "_value_int8"):
            self._value_int8 = arith.extsi(
                T.vector(self.type.shape[0], T.i8()), self, loc=loc, ip=ip
            )
        return self._value_int8

    @dsl_user_op
    def reduce(self, op, init_val, reduction_profile: Coord, *, loc=None, ip=None):
        """
        Perform reduce on selected modes with given predefined reduction op.

        :param op: The reduction operator to use (operator.add or operator.mul)
        :type op: operator
        :param init_val: The initial value for the reduction
        :type init_val: numeric
        :param reduction_profile: Specifies which dimensions to reduce. Dimensions marked with `None` are kept.
        :type reduction_profile: Coord

        :return: The reduced tensor
        :rtype: TensorSSA

        **Examples:**

        .. code-block:: python

            reduce(f32 o (4,))
              => f32

            reduce(f32 o (4, 5))
              => f32
            reduce(f32 o (4, (5, 4)), reduction_profile=(None, 1))
              => f32 o (4,)
            reduce(f32 o (4, (5, 4)), reduction_profile=(None, (None, 1)))
              => f32 o (4, (5,))
        """
        # short-cut to no-op
        if reduction_profile is None:
            return self

        if not is_weakly_congruent(reduction_profile, self.shape):
            raise ValueError(
                f"Expected reduction_profile be weakly congruent to the shape of the tensor, "
                f"but got {reduction_profile} and {self.shape}"
            )

        if op is ReductionOp.ADD:
            red_kind = vector.CombiningKind.ADD
        elif op is ReductionOp.MUL:
            red_kind = vector.CombiningKind.MUL
        elif op is ReductionOp.MAX:
            red_kind = vector.CombiningKind.MAXIMUMF
        elif op is ReductionOp.MIN:
            red_kind = vector.CombiningKind.MINIMUMF
        else:
            raise NotImplementedError(
                f"{op} is not supported, expected one of "
                f"{ReductionOp.ADD, ReductionOp.MUL, ReductionOp.MAX, ReductionOp.MIN}"
            )

        elem_type = self.element_type
        # Canonicalize to `Numeric` and convert into MLIR value
        init_val = (
            as_numeric(init_val).to(elem_type, loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
        )

        if depth(reduction_profile) == 0:
            return vector.reduction(
                elem_type.mlir_type, red_kind, self, acc=init_val, loc=loc, ip=ip
            )

        flat_shp, flat_prof = self._flatten_shape_and_coord(
            reduction_profile, loc=loc, ip=ip
        )
        assert isinstance(flat_prof, tuple), (
            f"Expected flat_prof to be a tuple, got {type(flat_prof)}"
        )
        assert depth(flat_shp) == 1 and depth(flat_prof) == 1
        assert rank(flat_shp) == rank(flat_prof)

        # convert TensorSSA col-major vec to row-m to be compatible with mlir vector ops
        row_major_vec = _col2row(self, shape=self._shape, loc=loc, ip=ip)
        temp_ty = ir.VectorType.get(list(flat_shp), elem_type.mlir_type)
        temp_vect = vector.shape_cast(temp_ty, row_major_vec, loc=loc, ip=ip)

        red_dims = [i for i, x in enumerate(flat_prof) if x is not None]

        temp_acc_shp = slice_(flat_shp, flat_prof, loc=loc, ip=ip)
        temp_acc_ty = ir.VectorType.get(list(temp_acc_shp), elem_type.mlir_type)

        init_val = vector.broadcast(temp_acc_ty, init_val, loc=loc, ip=ip)
        res_vect = vector.multi_reduction(
            red_kind, temp_vect, acc=init_val, reduction_dims=red_dims, loc=loc, ip=ip
        )

        # Slice and keep dims matching `_` or None
        res_shp = slice_(self.shape, reduction_profile, loc=loc, ip=ip)
        return self._build_result(res_vect, res_shp, row_major=True, loc=loc, ip=ip)


@dsl_user_op
def full(shape, fill_value, dtype: Type[Numeric], *, loc=None, ip=None) -> TensorSSA:
    """
    Return a new TensorSSA of given shape and type, filled with fill_value.

    :param shape: Shape of the new tensor.
    :type shape: tuple
    :param fill_value: Value to fill the tensor with.
    :type fill_value: scalar
    :param dtype: Data type of the tensor.
    :type dtype: Type[Numeric]
    :return: Tensor of fill_value with the specified shape and dtype.
    :rtype: TensorSSA
    """
    size = product(shape, loc=loc, ip=ip)
    if not is_static(size):
        raise ValueError("shape must be static")

    if isinstance(fill_value, (ir.Value, int, float, bool)):
        fill_value = dtype(fill_value)
    elif isinstance(fill_value, Numeric):
        fill_value = fill_value.to(dtype, loc=loc, ip=ip)
    else:
        raise ValueError(f"Expected fill_value be numeric type, but got {fill_value}")

    res_ty = T.vector(size, dtype.mlir_type)
    res_val = vector.splat(res_ty, fill_value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    return TensorSSA(res_val, shape, dtype)


@dsl_user_op
def full_like(
    a: Union[TensorSSA, Tensor],
    fill_value,
    dtype: Union[None, Type[Numeric]] = None,
    *,
    loc=None,
    ip=None,
) -> TensorSSA:
    """
    Return a full TensorSSA with the same shape and type as a given array.

    :param a: The shape and data-type of `a` define these same attributes of the returned array.
    :type a: array_like
    :param fill_value: Fill value.
    :type fill_value: array_like
    :param dtype: Overrides the data type of the result, defaults to None
    :type dtype: Union[None, Type[Numeric]], optional
    :return: Tensor of `fill_value` with the same shape and type as `a`.
    :rtype: TensorSSA

    .. seealso::
       :func:`empty_like`: Return an empty array with shape and type of input.
       :func:`ones_like`: Return an array of ones with shape and type of input.
       :func:`zeros_like`: Return an array of zeros with shape and type of input.
       :func:`full`: Return a new array of given shape filled with value.

    **Examples:**

    .. code-block:: python

        frg = cute.make_rmem_tensor((2, 3), Float32)
        a = frg.load()
        b = cute.full_like(a, 1.0)
    """
    if not hasattr(a, "shape"):
        raise TypeError(f"Expected `a` be shaped type, but got {type(a)}")

    res_dtype = dtype if dtype is not None else a.dtype  # type: ignore
    return full(a.shape, fill_value, res_dtype, loc=loc, ip=ip)


@dsl_user_op
def empty_like(a, dtype=None, *, loc=None, ip=None):
    """
    Return a new TensorSSA with the same shape and type as a given array, without initializing entries.

    :param a: The shape and data-type of `a` define these same attributes of the returned array.
    :type a: TensorSSA
    :param dtype: Overrides the data type of the result, defaults to None
    :type dtype: Type[Numeric], optional
    :return: Uninitialized tensor with the same shape and type (unless overridden) as `a`.
    :rtype: TensorSSA
    """
    return full_like(a, 0, dtype, loc=loc, ip=ip)


@dsl_user_op
def ones_like(a, dtype=None, *, loc=None, ip=None):
    """
    Return a TensorSSA of ones with the same shape and type as a given array.

    :param a: The shape and data-type of `a` define these same attributes of the returned array.
    :type a: TensorSSA
    :param dtype: Overrides the data type of the result, defaults to None
    :type dtype: Type[Numeric], optional
    :return: Tensor of ones with the same shape and type (unless overridden) as `a`.
    :rtype: TensorSSA
    """
    return full_like(a, 1, dtype, loc=loc, ip=ip)


@dsl_user_op
def zeros_like(a, dtype=None, *, loc=None, ip=None):
    """
    Return a TensorSSA of zeros with the same shape and type as a given array.

    :param a: The shape and data-type of `a` define these same attributes of the returned array.
    :type a: TensorSSA
    :param dtype: Overrides the data type of the result, defaults to None
    :type dtype: Type[Numeric], optional
    :return: Tensor of zeros with the same shape and type (unless overridden) as `a`.
    :rtype: TensorSSA
    """
    return full_like(a, 0, dtype, loc=loc, ip=ip)


@dsl_user_op
def where(
    cond: TensorSSA,
    x: Union[TensorSSA, Numeric],
    y: Union[TensorSSA, Numeric],
    *,
    loc=None,
    ip=None,
) -> TensorSSA:
    """
    Return elements chosen from x or y depending on condition; will auto broadcast x or y if needed.

    :param cond: Where True, yield x, where False, yield y.
    :type cond: TensorSSA
    :param x: Values from which to choose when condition is True.
    :type x: Union[TensorSSA, Numeric]
    :param y: Values from which to choose when condition is False.
    :type y: Union[TensorSSA, Numeric]
    :return: A tensor with elements from x where condition is True, and elements from y where condition is False.
    :rtype: TensorSSA
    """

    # Helper function to promote scalars to tensors or broadcast tensors to target shape
    def promote_and_broadcast(v, shape):
        if isinstance(v, TensorSSA):
            return v.broadcast_to(shape)
        elif isinstance(v, (bool, int, float, ir.Value, Numeric)):
            v = as_numeric(v)
            return full(shape, v, v.dtype)
        else:
            raise ValueError(f"cannot promote {type(v)} to tensor")

    # Determine shapes for broadcasting - at least one input must be a tensor
    x_is_tensor = isinstance(x, TensorSSA)
    y_is_tensor = isinstance(y, TensorSSA)
    if not (x_is_tensor or y_is_tensor):
        raise ValueError(
            f"at least one of x and y must be tensor, but got {type(x)} and {type(y)}"
        )
    x_shape = x.shape if x_is_tensor else y.shape
    y_shape = y.shape if y_is_tensor else x.shape

    # Promote both operands to tensors with broadcast shape
    res_shape = _infer_broadcast_shape(cond.shape, x_shape, y_shape)
    cond = promote_and_broadcast(cond, res_shape)
    x = promote_and_broadcast(x, res_shape)
    y = promote_and_broadcast(y, res_shape)

    if x.dtype != y.dtype:
        raise ValueError(
            f"x and y must have the same dtype, but got {x.dtype} and {y.dtype}"
        )

    if cond.dtype != Boolean:
        raise ValueError(f"cond must be Boolean type, but got {cond.dtype}")

    cond_val = cond.ir_value(loc=loc, ip=ip)
    res_val = arith.select(cond_val, x, y, loc=loc, ip=ip)
    return TensorSSA(res_val, x.shape, x.dtype)


@dsl_user_op
def any_(x: TensorSSA, *, loc=None, ip=None) -> Boolean:
    """
    Test whether any tensor element evaluates to True.

    :param x: Input tensor.
    :type x: TensorSSA
    :return: Returns a TensorSSA scalar containing True if any element of x is True, False otherwise.
    :rtype: TensorSSA
    """
    is_true = x != full_like(x, 0, x.dtype, loc=loc, ip=ip)
    return Boolean(
        vector.reduction(T.bool(), vector.CombiningKind.OR, is_true, loc=loc, ip=ip)
    )


@dsl_user_op
def all_(x: TensorSSA, *, loc=None, ip=None) -> Boolean:
    """
    Test whether all tensor elements evaluate to True.

    :param x: Input tensor.
    :type x: TensorSSA
    :return: Returns a TensorSSA scalar containing True if all elements of x are True, False otherwise.
    :rtype: TensorSSA
    """
    is_true = x != full_like(x, 0, x.dtype, loc=loc, ip=ip)
    return Boolean(
        vector.reduction(T.bool(), vector.CombiningKind.AND, is_true, loc=loc, ip=ip)
    )
