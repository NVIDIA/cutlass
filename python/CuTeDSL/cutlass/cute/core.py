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

from functools import partial, reduce
from inspect import isclass
from typing import Any, Dict, List, Optional, Tuple, Type, Union, overload

from typing_extensions import deprecated

from cutlass._mlir import ir
from cutlass._mlir.dialects import builtin, llvm
from cutlass._mlir.dialects import cute as _cute_ir
from cutlass._mlir.dialects.cute import (
    Ratio as _Ratio,
)
from cutlass._mlir.dialects.cute import (
    ReductionOp as ReductionOp,
)
from cutlass._mlir.dialects.cute import (
    ScaledBasis as _ScaledBasis,
)
from cutlass.cutlass_dsl import (
    T,
    const,
    cutlass_arith,
    dsl_user_op,
    extract_mlir_values,
    is_dynamic_expression,
    lru_cache_ir,
    not_,
)

from .tuple import find_if, flatten_to_tuple, product_each, transform_leaf, wrap
from .typing import (
    AddressSpace,
    Boolean,
    ComposedLayout,
    Coord,
    Float32,
    Int,
    Int16,
    Int32,
    Int64,
    Integer,
    IntTuple,
    Layout,
    Numeric,
    NumericMeta,
    Pointer,
    Shape,
    Stride,
    Tensor,
    Tile,
    Tiler,
    XTuple,
    is_int_tuple,
    is_integer,
)

####################################################################################################
#
# Internal IntTuple helpers
#
####################################################################################################


def _get_typed_value(x):
    if isinstance(x, Integer):
        x = x.ir_value()

    if isinstance(x, IntValue):
        return x.get_typed_value()
    else:
        return x


def _pack_x(x, packer, op, *, loc=None, ip=None) -> ir.Value:
    x = transform_leaf(_get_typed_value, x)
    res_ty, dyn_elems = packer(x)
    # <"0"> is deduced from type inference which should be removed for make_... operations
    dyn_elems = [t for t in dyn_elems if not is_static(t)]
    return op(res_ty, dyn_elems, loc=loc, ip=ip).result


def _pack_shape(shape: Shape, *, loc=None, ip=None) -> ir.Value:
    _check_shape(shape)
    return _pack_x(shape, _cute_ir.pack_shape, _cute_ir.MakeShapeOp, loc=loc, ip=ip)


def _pack_stride(stride: Stride, *, loc=None, ip=None) -> ir.Value:
    _check_stride(stride)
    dyn_elems = map(_get_typed_value, extract_mlir_values(stride))
    # Convert basis elements to the base class before _pack_x
    stride = transform_leaf(
        lambda x: (
            x.to(_cute_ir.ScaledBasis)
            if isinstance(x, ScaledBasis)
            else _get_typed_value(x)
        ),
        stride,
    )
    res_ty, _ = _cute_ir.pack_stride(stride)
    return _cute_ir.MakeStrideOp(res_ty, dyn_elems, loc=loc, ip=ip).result


def _pack_coord(coord: Coord, *, loc=None, ip=None) -> ir.Value:
    _check_coord(coord)
    return _pack_x(coord, _cute_ir.pack_coord, _cute_ir.MakeCoordOp, loc=loc, ip=ip)


def _pack_int_tuple(int_tuple: IntTuple, *, loc=None, ip=None) -> ir.Value:
    _check_int_tuple(int_tuple)
    return _pack_x(
        int_tuple, _cute_ir.pack_int_tuple, _cute_ir.MakeIntTupleOp, loc=loc, ip=ip
    )


def _pack_tile(tile: Tile, *, loc=None, ip=None) -> ir.Value:
    _check_tile(tile)

    def expand_leaves(tile) -> list:
        leaves = []
        for e in tile:
            if isinstance(e, _Layout):
                leaves.extend(list(flatten_to_tuple(e.shape)))
                leaves.extend(list(flatten_to_tuple(e.stride)))
            else:
                leaves.append(e)
        return leaves

    layout_leaves = flatten_to_tuple(tile)
    dyn_elems = expand_leaves(layout_leaves)
    dyn_elems = [
        _get_typed_value(x) for x in dyn_elems if isinstance(x, (Integer, ir.Value))
    ]

    res_ty = _cute_ir.pack_tile(tile)
    return _cute_ir.make_tile(res_ty, dyn_elems, loc=loc, ip=ip)


def _unpack_x_tuple(t: Union[ir.Type, ir.Value], *, loc=None, ip=None) -> XTuple:
    # If t is an MLIR type, make sure it's static and make a Value
    if isinstance(t, ir.Type):
        if not _cute_ir.is_static(t):
            raise ValueError()
        t = static(t, loc=loc, ip=ip)

    if isinstance(t, ir.Value):
        input_ty = t.type
        if t.type.rank == 0:
            # Handle this case separately, _cute_ir.get_leaves will return an Op in this case
            vals = []
        else:
            vals = get_leaves(t, loc=loc, ip=ip)
            if not isinstance(vals, list):
                vals = [vals]
    else:
        raise TypeError(f"expects static type or value, but got {t}")

    # CuTe IR only supports Int32 for now. Need to support detection of other types
    res = _cute_ir.unpack_x_tuple(input_ty, vals, loc=loc)

    def post_process(x):
        if isinstance(x, _cute_ir.ScaledBasis):
            return ScaledBasis(post_process(x.get_value()), x.get_mode())
        elif isinstance(x, _cute_ir.Ratio):
            return Ratio(x.numerator, x.denominator)
        else:
            return x

    return transform_leaf(post_process, res)


####################################################################################################
# Validation helpers
####################################################################################################


def _check_shape(shape: Shape) -> None:
    if is_integer(shape):
        if isinstance(shape, int):
            if shape <= 0:
                raise ValueError(
                    f"Expected size in shape to be strictly positive, but got {shape}"
                )
        elif isinstance(shape, Integer) or (
            isinstance(shape, ir.Value) and isinstance(shape.type, ir.IntegerType)
        ):
            pass
        else:
            raise TypeError(f"Expected size be int or Integer, but got {type(shape)}")
    elif isinstance(shape, tuple):
        for s in shape:
            _check_shape(s)
    else:
        raise ValueError(
            f"Expected Shape, which is a positive integer or tuple of Shapes, but got {shape}"
        )


def _check_coord(coord: Coord) -> None:
    flat_coord = flatten_to_tuple(coord)
    if not all(is_integer(c) or c is None for c in flat_coord):
        raise ValueError(
            f"Expected Coord, whose leaves are integers or None, but got {coord}"
        )


def _check_stride(stride: Stride) -> None:
    flat_stride = flatten_to_tuple(stride)
    if not all(is_integer(s) or isinstance(s, ScaledBasis) for s in flat_stride):
        raise ValueError(
            f"Expected Stride, whose leaves are integers or ScaledBasis, but got {stride}"
        )


def _check_int_tuple(int_tuple: IntTuple) -> None:
    flat_int_tuple = flatten_to_tuple(int_tuple)
    if not all(is_integer(d) for d in flat_int_tuple):
        raise ValueError(
            f"Expected IntTuple, whose leaves are integers, but got {int_tuple}"
        )


def _check_tile(tile: Tile) -> None:
    flat_tile = flatten_to_tuple(tile)
    if not all(is_integer(t) or isinstance(t, _Layout) or t is None for t in flat_tile):
        raise ValueError(
            f"Expected Tile, whose leaves are integers or Layout or None, but got {tile}"
        )


####################################################################################################
#
# Core types
#
####################################################################################################


class IntValue(cutlass_arith.ArithValue):
    """Internal representation of constrained integer types with divisibility information.

    IntValue serves as a proxy for constrained integer types in the CuTe IR. Rather than
    directly storing values of IntTupleType with depth=0, it stores the result of the
    `cute.get_scalars` operation applied to such values.

    This class represents the following sequence of operations in the IR:
      %0 = ... : (...) -> !cute.int_tuple<"?">
      %1 = cute.get_scalars(%0) : (!cute.int_tuple<"?">) -> i32

    where the first operation produces a `cute.int_tuple<"?">` with depth=0 and rank=1. It
    automatically emit `cute.get_scalars` and track it.

    IntValue inherits behavior from ArithValue with the following extensions:
      * Overloaded operations that accept IntTupleType values to propagate divisibility information
      * Support for CuTe operations that utilize divisibility constraints

    API for interacting with IntValue:
      * get_typed_value() - Returns the value as an IntTupleType
      * get_divisibility() - Returns the divisibility constraint of the value
    """

    @dsl_user_op
    def __init__(self, v, signed=True, *, loc=None, ip=None):
        # Cute Constrained Int Type is always signed
        if isinstance(v, int):
            v = _pack_int_tuple(v, loc=loc, ip=ip)

        if isinstance(v.type, _cute_ir.IntTupleType):
            scalar_val = _cute_ir.get_scalars(v, loc=loc, ip=ip)
            super().__init__(scalar_val, True, loc=loc, ip=ip)
        else:
            super().__init__(v, True, loc=loc, ip=ip)

    @dsl_user_op
    def get_typed_value(self, *, loc=None, ip=None):
        if isinstance(self.type, ir.IntegerType):
            def_op = self.owner.operation
            if def_op.name == "cute.get_scalars":
                return def_op.operands[0]

        assert not isinstance(self.type, _cute_ir.IntTupleType)

        # get_typed_value is called by _pack_int_tuple, copy code to avoid
        # recursive calls
        res_ty, _ = _cute_ir.pack_int_tuple(self)
        return _cute_ir.MakeIntTupleOp(res_ty, [self], loc=loc, ip=ip).result

    @property
    def divisibility(self):
        assert isinstance(
            self.get_typed_value().type, _cute_ir.IntTupleType
        ), f"expected self.get_typed_value() to be int_tuple type, but got {self.get_typed_value().type}"
        return self.get_typed_value().type.get_divisibility([0])

    def __str__(self):
        if self.divisibility == 1:
            return "?"
        else:
            return f"?{{div={self.divisibility}}}"

    def __repr__(self):
        parent_name = cutlass_arith.ArithValue.__name__
        return super().__str__().replace(parent_name, IntValue.__name__)

    def pretty_str(self):
        return self.__str__()

    def _binary_op(op):
        def wrapper(self, other, **kwargs):
            if isinstance(other, IntValue):
                other_val = other.get_typed_value()
            elif isinstance(other, ir.Value) and isinstance(
                other.type, _cute_ir.IntTupleType
            ):
                other_val = other
            elif isinstance(other, ir.Value) and isinstance(other.type, ir.IntegerType):
                other_val = _pack_int_tuple(other)
            elif isinstance(other, (int, bool)):
                other_val = _pack_int_tuple(int(other))
            else:
                # Dispatch to `__rmul__` of `other`
                return NotImplemented

            return IntValue(op(self, other_val, **kwargs))

        return wrapper

    @dsl_user_op
    @_binary_op
    def __add__(self, other, *, loc=None, ip=None):
        return _cute_ir.add_offset(
            self.get_typed_value(loc=loc, ip=ip), other, loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __sub__(self, other, *, loc=None, ip=None):
        return _cute_ir.tuple_sub(
            self.get_typed_value(loc=loc, ip=ip), other, loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __mul__(self, other, *, loc=None, ip=None):
        return _cute_ir.tuple_mul(
            self.get_typed_value(loc=loc, ip=ip), other, loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __floordiv__(self, other, *, loc=None, ip=None) -> "IntValue":
        return _cute_ir.tuple_div(
            self.get_typed_value(loc=loc, ip=ip), other, loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __mod__(self, other, *, loc=None, ip=None) -> cutlass_arith.ArithValue:
        return _cute_ir.tuple_mod(
            self.get_typed_value(loc=loc, ip=ip), other, loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __radd__(self, other, *, loc=None, ip=None) -> "IntValue":
        return _cute_ir.add_offset(
            other, self.get_typed_value(loc=loc, ip=ip), loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __rsub__(self, other, *, loc=None, ip=None) -> "IntValue":
        return _cute_ir.tuple_sub(
            other, self.get_typed_value(loc=loc, ip=ip), loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __rmul__(self, other, *, loc=None, ip=None):
        return _cute_ir.tuple_mul(
            other, self.get_typed_value(loc=loc, ip=ip), loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __rfloordiv__(self, other, *, loc=None, ip=None) -> "IntValue":
        return _cute_ir.tuple_div(
            other, self.get_typed_value(loc=loc, ip=ip), loc=loc, ip=ip
        )

    @dsl_user_op
    @_binary_op
    def __rmod__(self, other, *, loc=None, ip=None) -> "IntValue":
        return _cute_ir.tuple_mod(
            other, self.get_typed_value(loc=loc, ip=ip), loc=loc, ip=ip
        )


class Ratio(_Ratio):
    """A class representing a rational number as a ratio of two integers.

    Ratio is used in CuTe to represent exact fractional values that arise in
    tensor layout operations, particularly in composition operations where
    divisibility conditions may not be satisfied.

    :param numerator: The numerator of the ratio
    :type numerator: int
    :param denominator: The denominator of the ratio
    :type denominator: int
    :raises TypeError: If numerator or denominator are not integers
    """

    def __init__(self, numerator: int, denominator: int):
        if not isinstance(numerator, int) or not isinstance(denominator, int):
            raise TypeError(
                f"numerator and denominator must be integers, but got {numerator} and {denominator}"
            )
        super().__init__(numerator, denominator)

    def is_integral(self) -> bool:
        """Check if the ratio represents an integer value.

        :return: True if the numerator is divisible by the denominator
        :rtype: bool
        """
        return super().is_integral()

    def reduced(self) -> "Ratio":
        """Return a new Ratio with the numerator and denominator reduced to lowest terms.

        :return: A new Ratio in reduced form
        :rtype: Ratio
        """
        res = super().reduced()
        return Ratio(res.numerator, res.denominator)

    def __mul__(self, other):
        """Multiply this ratio by another ratio or an integer.

        :param other: The value to multiply by
        :type other: Union[Ratio, int]
        :return: A new ratio representing the product
        :rtype: Ratio
        :raises TypeError: If other is not a Ratio or int
        """
        if isinstance(other, Ratio):
            return Ratio(
                self.numerator * other.numerator,
                self.denominator * other.denominator,
            )
        elif isinstance(other, int):
            return Ratio(self.numerator * other, self.denominator)
        else:
            raise TypeError(f"Cannot multiply Ratio with {type(other)}")

    def __rmul__(self, other):
        """Right multiplication operation.

        :param other: The value to multiply by
        :type other: Union[Ratio, int]
        :return: A new ratio representing the product
        :rtype: Ratio
        """
        return self.__mul__(other)

    def __str__(self):
        """String representation of the ratio.

        :return: String in the format "numerator/denominator"
        :rtype: str
        """
        return super().__str__()

    def to(self, dtype):
        """Convert the ratio to another type.

        :param dtype: The target type for conversion
        :type dtype: type
        :return: The ratio converted to the specified type
        :raises TypeError: If conversion to the specified type is not supported
        """
        if dtype is Ratio:
            return self
        elif dtype is float:
            return self.numerator / self.denominator
        elif dtype is int:
            return self.numerator // self.denominator
        elif issubclass(dtype, _Ratio):
            return self
        else:
            raise TypeError(f"Cannot convert Ratio to {dtype}")


class ScaledBasis:
    """A class representing a scaled basis element in CuTe's layout algebra.

    ScaledBasis is used to represent elements in the layout algebra, particularly
    in the context of composition operations. It consists of a value (scale) and
    a mode that identifies mode of the basis element.

    :param value: The scale value
    :type value: Union[int, Integer, Ratio, ir.Value]
    :param mode: The mode identifying the basis element
    :type mode: Union[int, List[int]]
    :raises TypeError: If mode is not an integer or list of integers

    **Examples:**

    .. code-block:: python

        # Create a scaled basis with integer scale and mode
        sb1 = ScaledBasis(2, 0)  # 2 * E(0)

        # Create a scaled basis with a Ratio scale
        sb2 = ScaledBasis(Ratio(1, 2), 1)  # (1/2) * E(1)

        # Create a scaled basis with a list of modes
        sb3 = ScaledBasis(4, [0, 1])  # 4 * E([0, 1])

        # Scaled basis elements are commonly used in layout strides
        layout = make_layout((4, 8), stride=(ScaledBasis(2, 0), ScaledBasis(1, 1)))

        # This creates a layout with strides (2@0, 1@1) representing
        # a coordinate system where each dimension has its own basis

        # Example: Mapping coordinates to indices using the layout
        coord = (2, 3)
        idx = crd2idx(coord, layout)  # Maps (2, 3) to (4, 3)
    """

    def __init__(self, value, mode) -> None:
        if isinstance(mode, int):
            self._mode = [mode]
        else:
            if any(not isinstance(x, int) for x in mode):
                raise TypeError(f"Mode must be a list of integers, but got {mode}")
            self._mode = mode

        self._value = value

    def is_static(self) -> bool:
        """Check if the value is statically known.

        :return: True if the value is not a dynamic expression
        :rtype: bool
        """
        return not is_dynamic_expression(self._value)

    @dsl_user_op
    def to(self, dtype, *, loc=None, ip=None):
        """Convert to another type.

        :param dtype: The target type for conversion
        :type dtype: type
        :param loc: The source location for the operation, defaults to None
        :type loc: Location, optional
        :param ip: The insertion point for the operation, defaults to None
        :type ip: InsertionPoint, optional
        :return: The ScaledBasis converted to the specified type
        :raises TypeError: If conversion to the specified type is not supported
        """
        if dtype is ScaledBasis:
            return self
        elif dtype is _ScaledBasis:
            if isinstance(self._value, Ratio):
                return _ScaledBasis(self._value, self._mode)

            if isinstance(self._value, Integer):
                scale = self._value.ir_value(loc=loc, ip=ip)
                return _ScaledBasis(scale, self._mode, get_divisibility(scale))
            else:
                scale = self._value
                return _ScaledBasis(scale, self._mode)
        else:
            raise TypeError(f"Cannot convert ScaledBasis to {dtype}")

    def __str__(self):
        return f"{self.to(_ScaledBasis).__str__()}"

    def __hash__(self):
        return hash((self.value, tuple(self.mode)))

    @property
    def value(self):
        """Get the scale value.

        :return: The scale value
        """
        return self._value

    @property
    def mode(self) -> List[int]:
        """Get the mode identifying the basis element.

        :return: The mode as a list of integers
        :rtype: List[int]
        """
        return self._mode

    def __eq__(self, other):
        if isinstance(other, ScaledBasis):
            return self.value == other.value and self.mode == other.mode
        else:
            return False

    def __rmul__(
        self, scale: Union[Int, ir.Value, Ratio], *, loc=None, ip=None
    ) -> "ScaledBasis":
        """Right multiplication by a scale factor.

        This operation is used in layout algebra to scale basis elements,
        which is essential for operations like composition and partitioning.

        :param scale: The scale factor
        :type scale: Union[Int, ir.Value, Ratio]
        :param loc: The source location for the operation, defaults to None
        :type loc: Location, optional
        :param ip: The insertion point for the operation, defaults to None
        :type ip: InsertionPoint, optional
        :return: A new scaled basis element
        :rtype: ScaledBasis
        :raises TypeError: If scale is not of a supported type
        :raises NotImplementedError: If scaling a basis element with a ratio value
        """
        if not isinstance(scale, (int, Integer, Ratio, ir.Value)):
            raise TypeError(
                f"scale must be an integer or a ratio, but got {type(scale)}"
            )
        if isinstance(self.value, Ratio):
            raise NotImplementedError(
                "scaling a basis element having a ratio is not supported"
            )

        value = self.value

        if not isinstance(value, (Integer, Ratio, int, cutlass_arith.ArithValue)):
            raise TypeError(f"Don't support {type(value)} for ScaledBasis")

        # Lift to IntValue type to preserve type info as much as possible
        if isinstance(scale, cutlass_arith.ArithValue):
            scale = IntValue(_pack_int_tuple(scale))

        if isinstance(value, cutlass_arith.ArithValue):
            value = IntValue(_pack_int_tuple(value))
        elif isinstance(value, Integer):
            value = value.ir_value(loc=loc, ip=ip)

        return ScaledBasis(scale * value, self.mode)  # type: ignore

    def __extract_mlir_values__(self):
        if isinstance(self.value, Ratio):
            # Ratio is always static
            return []
        else:
            return extract_mlir_values(self.value)


def E(mode: Union[int, List[int]]) -> ScaledBasis:
    """Create a unit ScaledBasis element with the specified mode.

    This function creates a ScaledBasis with value 1 and the given mode.
    The mode represents the coordinate axis or dimension in the layout.

    :param mode: The mode (dimension) for the basis element, either a single integer or a list of integers
    :type mode: Union[int, List[int]]
    :return: A ScaledBasis with value 1 and the specified mode
    :rtype: ScaledBasis
    :raises TypeError: If mode is not an integer or a list

    **Examples:**

    .. code-block:: python

        # Create a basis element for the first dimension (mode 0)
        e0 = E(0)

        # Create a basis element for the second dimension (mode 1)
        e1 = E(1)

        # Create a basis element for a hierarchical dimension
        e_hier = E([0, 1])
    """
    if isinstance(mode, int):
        mode = [mode]

    if any(not isinstance(x, int) for x in mode):
        raise TypeError(f"mode must be a list of integers, but got {mode}")

    if not mode:
        return 1

    return ScaledBasis(1, mode)


def get_divisibility(x: Union[int, Integer]) -> int:
    if isinstance(x, int):
        return x

    if isinstance(x, Integer):
        x = x.value

    if isinstance(x, IntValue):
        return x.divisibility
    else:
        return 1


@ir.register_value_caster(_cute_ir.SwizzleType.get_static_typeid(), replace=True)
class Swizzle(ir.Value):
    """
    Swizzle is a transformation that permutes the elements of a layout.

    Swizzles are used to rearrange data elements to improve memory access patterns
    and computational efficiency.

    Swizzle is defined by three parameters:
    - MBase: The number of least-significant bits to keep constant
    - BBits: The number of bits in the mask
    - SShift: The distance to shift the mask

    The mask is applied to the least-significant bits of the layout.

    .. code-block::

        0bxxxxxxxxxxxxxxxYYYxxxxxxxZZZxxxx
                                      ^--^ MBase is the number of least-sig bits to keep constant
                         ^-^       ^-^     BBits is the number of bits in the mask
                           ^---------^     SShift is the distance to shift the YYY mask
                                              (pos shifts YYY to the right, neg shifts YYY to the left)

        e.g. Given
        0bxxxxxxxxxxxxxxxxYYxxxxxxxxxZZxxx

        the result is
        0bxxxxxxxxxxxxxxxxYYxxxxxxxxxAAxxx where AA = ZZ `xor` YY

    """

    def __str__(self):
        # Cut off the MLIR type's string for making pretty_str more concise
        return self.type.__str__()[15 : 15 + 8]


@ir.register_value_caster(_cute_ir.LayoutType.get_static_typeid(), replace=True)
class _Layout(Layout):
    """Layout is CuTe's core abstraction for representing tensor layouts.

    A Layout maps from a logical coordinate space to an index space, defined by a
    pair of (Shape, Stride). The Shape defines the abstract dimensions of the Layout,
    while the Stride defines how coordinates within the Shape map to linear indices.

    Layouts present a common interface to multidimensional array access that abstracts
    away the details of how array elements are organized in memory. This allows algorithms
    to be written generically, so that layouts can change without requiring code changes.

    CuTe layouts are inherently hierarchical, constructed from smaller, nested layouts
    that can represent complex mappings required by GPU tensor instructions. They support
    a rich algebra of operations including concatenation, coalescence, composition,
    complement, and inversion.

    :ivar shape: An IntTuple representing the dimensions of the layout.
    :ivar stride: An IntTuple representing the strides of the layout.
    :ivar max_alignment: The maximum alignment of the layout.

    **Examples:**

    .. code-block:: python

        # Creating a layout with shape (4,8) and default stride (layout left / "column major")
        layout = cute.make_layout((4, 8))

        # Creating a layout with explicit shape and stride
        layout = cute.make_layout((4, 8), stride=(8, 1))

        # Accessing a specific coordinate: (2, 3) -> 2 * 8 + 3 * 1 = 19
        idx = cute.crd2idx((2, 3), layout)
    """

    def __init__(self, op_result) -> None:
        """Initialize a Layout object.

        :param op_result: The operation result value to wrap.
        """
        super().__init__(op_result)

    def __str__(self) -> str:
        """Return a string representation of the layout.

        :return: A string in the format "shape:stride".
        """
        return f"{pretty_str(self.shape)}:{pretty_str(self.stride)}"

    @property
    @dsl_user_op
    @lru_cache_ir()
    def shape(self, *, loc=None, ip=None) -> Shape:
        """Get the shape of the layout.

        The shape defines the dimensions and structure of the layout's
        coordinate space.

        :return: The hierarchical shape of the layout.
        """
        return _unpack_x_tuple(_cute_ir.get_shape(self, loc=loc, ip=ip), loc=loc, ip=ip)

    @property
    @dsl_user_op
    @lru_cache_ir()
    def stride(self, *, loc=None, ip=None) -> Stride:
        """Get the stride of the layout.

        The stride defines how coordinates map to linear indices in memory.

        :return: The hierarchical stride of the layout.
        """
        return _unpack_x_tuple(
            _cute_ir.get_stride(self, loc=loc, ip=ip), loc=loc, ip=ip
        )

    @property
    def max_alignment(self) -> int:
        """Get the maximum alignment of the layout.

        :return: The maximum alignment in bytes.
        """
        return self.type.max_alignment

    def __eq__(self, other) -> Union[bool, Boolean]:
        """Check if this layout is equal to another layout.

        Two layouts are equal if they have the same shape and stride.

        :param other: The layout to compare with.
        :return: True if layouts are equal, False otherwise.
            May return an IR value for dynamic layouts.
        """
        if isinstance(other, Layout):
            if is_static(self.type) and is_static(other.type):
                return self.type == other.type
            return Boolean(_cute_ir.equal(self, other))
        else:
            return False

    def __req__(self, other) -> Union[bool, Boolean]:
        """Reflected equality check.

        :param other: The layout to compare with.
        :return: Result of other.__eq__(self).
        """
        if isinstance(other, Layout):
            return other.__eq__(self)
        return False

    def __ne__(self, other) -> Union[bool, Boolean]:
        """Check if this layout is not equal to another layout.

        :param other: The layout to compare with.
        :return: True if layouts are not equal, False otherwise.
        """
        if isinstance(other, Layout):
            if is_static(self.type) and is_static(other.type):
                return self.type != other.type
            return Boolean(not_(_cute_ir.equal(self, other)))
        else:
            return True

    def __rne__(self, other) -> Union[bool, Boolean]:
        """Reflected inequality check.

        :param other: The layout to compare with.
        :return: Result of other.__ne__(self).
        """
        if isinstance(other, Layout):
            return other.__ne__(self)
        return True

    def __getitem__(self, idx: int) -> Layout:
        """
        Top-level `get` to provide a syntax similar to `tuple`.
        """
        return get(self, mode=[idx])

    @dsl_user_op
    def __call__(self, coord: Coord, loc=None, ip=None) -> IntTuple:
        if has_underscore(coord):
            crd_val = _pack_coord(coord, loc=loc, ip=ip)
            return _cute_ir.slice(self, crd_val, loc=loc, ip=ip)
        else:
            return crd2idx(coord, self, loc=loc, ip=ip)

    @dsl_user_op
    def get_hier_coord(self, idx, *, loc=None, ip=None) -> Coord:
        """Get the hierarchical coordinate corresponding to a linear index.

        This method maps from a linear index back to the logical coordinate
        in the layout's coordinate space.

        :param idx: The linear index to convert.
        :return: The hierarchical coordinate corresponding to the index.

        **Examples:**

        .. code-block:: python

            layout = make_layout((4, 8), stride=(8, 1))

            # map linear index back to coordinate: 5 -> (1, 1)
            coord = get_hier_coord(5, layout)
        """
        idx_val = Int32(idx).ir_value(loc=loc, ip=ip)
        crd = _cute_ir.get_hier_coord(idx_val, self, loc=loc, ip=ip)
        return _unpack_x_tuple(crd, loc=loc, ip=ip)

    @dsl_user_op
    def get_flat_coord(self, idx, *, loc=None, ip=None) -> Coord:
        idx_val = Int32(idx).ir_value(loc=loc, ip=ip)
        res = _cute_ir.get_flat_coord(idx_val, self, loc=loc, ip=ip)
        return _unpack_x_tuple(res, loc=loc, ip=ip)


@ir.register_value_caster(_cute_ir.ComposedLayoutType.get_static_typeid(), replace=True)
class _ComposedLayout(ComposedLayout):
    """DSL wrapper of built-in ComposedLayout of CuTe IR where inner layout is one of following:
    - Swizzle
    - normal Layout

    The generalized composed layout can support arbitrary function mapping from coordinate
    to coordinate as inner layout.
    """

    def __init__(self, value) -> None:
        """Initialize a ComposedLayout object.

        :param value: The operation result value to wrap.
        """
        self.value = value

    def __str__(self) -> str:
        return f"{pretty_str(self.inner)} o {pretty_str(self.offset)} o {pretty_str(self.outer)}"

    @property
    def type(self) -> ir.Type:
        return self.value.type

    @property
    def is_normal(self) -> bool:
        return self.type.is_normal_layout

    @property
    @dsl_user_op
    def inner(self, *, loc=None, ip=None) -> Union[Swizzle, Layout]:
        return _cute_ir.composed_get_inner(self.value, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def offset(self, *, loc=None, ip=None) -> IntTuple:
        return _unpack_x_tuple(
            _cute_ir.composed_get_offset(self.value, loc=loc, ip=ip), loc=loc, ip=ip
        )

    @property
    @dsl_user_op
    def outer(self, *, loc=None, ip=None) -> Layout:
        return _cute_ir.composed_get_outer(self.value, loc=loc, ip=ip)

    @property
    @dsl_user_op
    def shape(self, *, loc=None, ip=None) -> Shape:
        return _unpack_x_tuple(
            _cute_ir.get_shape(self.value, loc=loc, ip=ip), loc=loc, ip=ip
        )

    @property
    def max_alignment(self) -> int:
        return self.type.max_alignment

    def __eq__(self, other) -> Union[bool, Boolean]:
        if isinstance(other, _ComposedLayout):
            if is_static(self.type) and is_static(other.type):
                return self.type == other.type
            else:
                raise NotImplementedError(
                    f"runtime comparison of composed layouts is not supported, got `{self}` and `{other}`"
                )
        else:
            return False

    def __req__(self, other) -> Union[bool, Boolean]:
        if isinstance(other, _ComposedLayout):
            return Boolean(other.__eq__(self))
        return False

    def __ne__(self, other) -> Union[bool, Boolean]:
        return not self.__eq__(other)

    def __rne__(self, other) -> Union[bool, Boolean]:
        if isinstance(other, _ComposedLayout):
            return other.__ne__(self)
        return True

    @dsl_user_op
    def __getitem__(self, idx: int, *, loc=None, ip=None) -> "_ComposedLayout":
        """
        Top-level `get` to provide a syntax similar to `tuple`.
        """
        return get(self, mode=[idx], loc=loc, ip=ip)

    @dsl_user_op
    def __call__(self, coord: Coord, loc=None, ip=None) -> IntTuple:
        return crd2idx(coord, self, loc=loc, ip=ip)

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        # Only expecting single value of _ComposedLayout or ir.Value
        # In this context, a _ComposedLayout instance is an encapsulated ir.Value which is automatically created
        # by value caster for ComposedLayout typed values
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        assert isinstance(
            values[0], (_ComposedLayout, ir.Value)
        ), f"Expected _ComposedLayout or ir.Value, but got {type(values[0])}"
        return _ComposedLayout(
            values[0] if isinstance(values[0], ir.Value) else values[0].value,
        )


@ir.register_value_caster(_cute_ir.PtrType.get_static_typeid(), replace=True)
class _Pointer(Pointer):
    """
    A pointer class representing a memory address with specific properties.

    Pointers are a fundamental type of iterator/engine that support random-access operations.
    They can be offset by elements of a layout's codomain and dereferenced to produce values.

    :param value: The MLIR operation result value to initialize the pointer with
    :type value: ir.Value

    :ivar type: The MLIR type of the pointer
    :vartype type: Type
    :ivar value_type: The type of value this pointer points to
    :vartype value_type: Type
    :ivar memspace: The memory space where the pointer data resides (e.g., gmem, smem, rmem)
    :vartype memspace: AddressSpace

    :note: When composed with a layout, a pointer forms a tensor: T = E ∘ L, where E is the pointer
           and L is the layout. The tensor evaluates the layout by mapping a coordinate c to the
           codomain, offsets the pointer accordingly, and dereferences the result:
           T(c) = (E ∘ L)(c) = *(E + L(c))
    """

    def __init__(self, value) -> None:
        assert isinstance(value, ir.Value)
        self.value = ir.Value(value)

    def __str__(self) -> str:
        # Cut off the MLIR type's string for making pretty_str more concise
        return self.type.__str__()[6:]

    def __get_mlir_types__(self):
        return [self.value.type]

    def __extract_mlir_values__(self):
        return [self.value]

    def __new_from_mlir_values__(self, values):
        # Only expecting single value of _Pointer instance or ir.Value
        # In this context, a _Pointer instance is an encapsulated ir.Value which is automatically created
        # by value caster for cute.ptr typed values
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        assert isinstance(
            values[0], (_Pointer, ir.Value)
        ), f"Expected _Pointer or ir.Value, but got {type(values[0])}"
        return _Pointer(
            values[0] if isinstance(values[0], ir.Value) else values[0].value
        )

    @property
    @lru_cache_ir()
    def dtype(self) -> Union[Type[Numeric], _cute_ir.SparseElemType]:
        if isinstance(self.value.type.value_type, _cute_ir.SparseElemType):
            return self.value.type.value_type
        else:
            return Numeric.from_mlir_type(self.value.type.value_type)

    @property
    def alignment(self) -> int:
        return self.type.alignment

    @property
    def max_alignment(self) -> int:
        return self.type.max_alignment

    @property
    @lru_cache_ir()
    def memspace(self) -> AddressSpace:
        return AddressSpace(self.type.address_space)

    # Make it behave as if it inherited from ir.Value
    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    # Only use if you absolutely need to get the LLVM pointer Value
    @property
    @dsl_user_op
    @lru_cache_ir()
    def llvm_ptr(self, *, loc=None, ip=None) -> ir.Value:
        """
        Get the LLVM pointer representation of this pointer.

        :return: The LLVM pointer representation
        :rtype: ir.Value
        """
        llvm_ptr_ty = llvm.PointerType.get(self.memspace.value)
        return builtin.unrealized_conversion_cast(
            [llvm_ptr_ty], [self.value], loc=loc, ip=ip
        )

    @dsl_user_op
    def __add__(self, offset: Int, *, loc=None, ip=None) -> Pointer:
        """
        Offset the pointer by elements of a layout's codomain.

        :param offset: The offset to add to the pointer
        :type offset: Int
        :return: A new pointer offset by the specified amount
        :rtype: ir.Value
        """
        offset = _pack_int_tuple(offset, loc=loc, ip=ip)  # type: ignore
        return _cute_ir.add_offset(self.value, offset=offset, loc=loc, ip=ip)

    @dsl_user_op
    def __radd__(self, offset: Int, *, loc=None, ip=None) -> Pointer:
        return self.__add__(offset, loc=loc, ip=ip)

    @dsl_user_op
    def __sub__(self, offset: Int, *, loc=None, ip=None) -> Pointer:
        return self.__add__(-offset, loc=loc, ip=ip)  # type: ignore

    @dsl_user_op
    @lru_cache_ir()
    def toint(self, *, loc=None, ip=None):
        if self.memspace in (AddressSpace.gmem, AddressSpace.generic):
            res_type = Int64
        else:
            res_type = Int32

        return res_type(
            _cute_ir.ptrtoint(res_type.mlir_type, self.value, loc=loc, ip=ip)
        )

    @dsl_user_op
    def align(self, min_align: int, *, loc=None, ip=None) -> Pointer:
        """
        Align a pointer to a specified byte alignment.

        :param min_align: The minimum byte alignment requirement. Must be a power of 2.
        :type min_align: int
        :param loc: The source location for the operation, defaults to None
        :type loc: Location, optional
        :param ip: The insertion point for the operation, defaults to None
        :type ip: InsertionPoint, optional
        :return: The aligned new pointer that satisfies alignment request.
        :rtype: Pointer
        :raises ValueError: If the alignment is not a power of 2.
        :raises TypeError: If pointer is in tmem address space.
        """

        if (min_align & (min_align - 1)) != 0:
            raise ValueError("Alignment must be a power of 2")

        assert isinstance(self.type, _cute_ir.PtrType)
        if self.memspace is AddressSpace.tmem:
            raise ValueError("aligning a TMEM pointer is not supported")

        if min_align <= self.alignment:
            return self

        dtype = Numeric.from_mlir_type(self.type.value_type)
        # Convert pointer to integer
        address_int = self.toint(loc=loc, ip=ip)
        # Align the address
        aligned_address = (address_int + min_align - 1) & ~(min_align - 1)

        return make_ptr(
            dtype,
            aligned_address,
            self.memspace,
            assumed_align=min_align,
            loc=loc,
            ip=ip,
        )


####################################################################################################
#
# Core API
#
####################################################################################################


def _op_wrapper(op_fn, input):
    from .tensor import _Tensor

    if isinstance(input, Tensor):
        res = op_fn(input.value)
        return _Tensor(res, dtype=input.element_type)
    elif isinstance(input, _ComposedLayout):
        return op_fn(input.value)
    else:
        return op_fn(input)


#
# Utilities
#


def is_valid_leaf(a) -> bool:
    """
    Returns whether `a` has a type that is valid for a CuTe tuple's leaf.
    """
    return (
        is_integer(a)
        or (a is None)
        or isinstance(a, (ScaledBasis, Layout, ComposedLayout))
    )


def is_static(x: Any) -> bool:
    """Check if a value is statically known at compile time.

    In CuTe, static values are those whose values are known at compile time,
    as opposed to dynamic values which are only known at runtime.

    This function checks if a value is static by recursively traversing its type hierarchy
    and checking if all components are static.

    Static values include:
    - Python literals (bool, int, float, None)
    - Static ScaledBasis objects
    - Static ComposedLayout objects
    - Static IR types
    - Tuples containing only static values

    Dynamic values include:
    - Numeric objects (representing runtime values)
    - Dynamic expressions
    - Any tuple containing dynamic values

    :param x: The value to check
    :type x: Any
    :return: True if the value is static, False otherwise
    :rtype: bool
    :raises TypeError: If an unsupported type is provided
    """
    if isinstance(x, ir.Type):
        return _cute_ir.is_static(x)
    elif isinstance(x, tuple):
        return all(is_static(a) for a in x)
    # Can it be a static int?
    elif isinstance(x, Numeric):
        return False
    elif isinstance(x, ScaledBasis):
        return x.is_static()
    elif isinstance(x, _ComposedLayout):
        return _cute_ir.is_static(x.type)
    elif is_dynamic_expression(x):
        return _cute_ir.is_static(x.type)
    elif isinstance(x, (bool, int, float)) or x is None:
        return True
    else:
        raise TypeError(f"unsupported type {x}")


def has_underscore(a: XTuple) -> bool:
    if type(a) is tuple:
        return any([has_underscore(x) for x in a])
    else:
        return a is None


def has_scaled_basis(a: XTuple) -> bool:
    """Check if a tuple or its nested elements contain ScaledBasis objects.

    ScaledBasis objects are fundamental components in CuTe layouts,
    representing the basis vectors of coordinate systems.

    :param a: The tuple to check
    :type a: XTuple
    :return: True if the tuple contains ScaledBasis objects, False otherwise
    :rtype: bool
    """
    if type(a) is tuple:
        return any([has_scaled_basis(x) for x in a])
    else:
        return isinstance(a, ScaledBasis)


def _tuple_str(t: Tuple[Any, ...]) -> str:
    """
    Constructs a string representation of a python tuple without calling __repr__ on its elements.
    """

    def construct_inner_str(t) -> str:
        if not isinstance(t, tuple):
            return pretty_str(t)
        res = ""
        l = len(t)
        for i in range(l):
            res += pretty_str(t[i])
            if i < l - 1:
                res += ","
        return res

    res = "(" + construct_inner_str(t) + ")"
    return res


def pretty_str(arg) -> str:
    """
    Constructs a concise readable pretty string.
    """
    if isinstance(arg, tuple):
        # _tuple_str for tuples
        return _tuple_str(arg)
    elif arg is None:
        # We interpret None as underscores for slicers
        return "_"
    else:
        # Fallback to __str__
        return arg.__str__()


@dsl_user_op
def printf(*args, loc=None, ip=None) -> None:
    """
    Print one or more values with optional formatting.

    This function provides printf-style formatted printing capabilities. It can print values directly
    or format them using C-style format strings. The function supports printing various types including
    layouts, numeric values, tensors, and other CuTe objects.

    The function accepts either:
    1. A list of values to print directly
    2. A format string followed by values to format

    :param args: Variable length argument list containing either:
                - One or more values to print directly
                - A format string followed by values to format
    :type args: Any
    :param loc: Source location information for debugging, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for code generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :raises ValueError: If no arguments are provided
    :raises TypeError: If an unsupported argument type is passed

    **Examples:**

    Direct printing of values:

    .. code-block:: python

        a = cute.make_layout(shape=(10, 10), stride=(10, 1))
        b = cutlass.Float32(1.234)
        cute.printf(a, b)  # Prints values directly

    Formatted printing:

    .. code-block:: python

        # Using format string with generic format specifiers
        cute.printf("a={}, b={}", a, b)

        # Using format string with C-style format specifiers
        cute.printf("a={}, b=%.2f", a, b)
    """
    from .tensor import _Tensor

    if len(args) == 0:
        raise ValueError("expects at least one argument to print")

    if isinstance(args[0], str):
        fmt = args[0] + "\n"
        args = args[1:]
    else:
        fmt = "{}" + ", {}" * (len(args) - 1) + "\n"

    def process_arg(arg):
        arg0 = arg.value if isinstance(arg, Numeric) else arg

        if isinstance(arg0, ir.Value):
            return arg0
        elif isinstance(arg0, bool):
            return const(arg0, Boolean)
        elif isinstance(arg0, int):
            return const(arg0, Int32)
        elif isinstance(arg0, float):
            return const(arg0, Float32)
        elif has_underscore(arg0):
            # Assume it's a coordinate
            return _pack_coord(arg0)
        elif has_scaled_basis(arg0):
            # Assume it's a stride
            return _pack_stride(arg0)
        elif is_int_tuple(arg0):
            return _pack_int_tuple(arg0)
        elif isinstance(arg0, tuple):
            # Assume it's a tile
            return _pack_tile(arg0)
        elif isinstance(arg0, (_Tensor, _Pointer, _ComposedLayout)):
            return arg0.value
        else:
            raise TypeError(f"unsupported argument type in printf, got {type(arg)}")

    args = [process_arg(a) for a in args]
    _cute_ir.print_(args, fmt=fmt, loc=loc, ip=ip)


@dsl_user_op
def front(input, *, loc=None, ip=None):
    """Recursively get the first element of input.

    This function traverses a hierarchical structure (like a layout or tensor)
    and returns the first element at the deepest level. It's particularly useful
    for accessing the first stride value in a layout to determine properties like
    majorness.

    :param input: The hierarchical structure to traverse
    :type input: Union[Tensor, Layout, Stride]
    :param loc: Source location where it's called, defaults to None
    :type loc: source location, optional
    :param ip: Insertion pointer for IR generation, defaults to None
    :type ip: insertion pointer, optional
    :return: The first element at the deepest level of the input structure
    :rtype: Union[int, float, bool, ir.Value]
    """
    if rank(input) == 1 and depth(input) == 0:
        return input
    else:
        return front(get(input, mode=[0], loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def is_major(mode, stride: Stride, *, loc=None, ip=None) -> bool:
    """
    Check whether a mode in stride is the major mode.
    """
    first_stride = front(get(stride, mode=[mode], loc=loc, ip=ip), loc=loc, ip=ip)
    if is_dynamic_expression(first_stride):
        return False
    return True if first_stride == 1 else False


@dsl_user_op
def assume(src, divby=None, *, loc=None, ip=None):
    if divby is None:
        return src

    if isinstance(src, Integer):
        width = type(src).width
        src_val = src.ir_value(loc=loc, ip=ip)
    else:
        width = src.type.width
        src_val = src

    res_ty = _cute_ir.ConstrainedIntType.get(divby, width)
    assumed_val = _cute_ir.assume(res_ty, src_val, loc=loc, ip=ip)
    return type(src)(IntValue(_pack_int_tuple(assumed_val, loc=loc, ip=ip)))


@dsl_user_op
def make_swizzle(b, m, s, *, loc=None, ip=None):
    # canonicalize to <0, 4, 3> for identity swizzle (as compiler assumes <0, 4, 3>)
    if b == 0:
        m, s = 4, 3
    ty = ir.Type.parse(f'!cute.swizzle<"S<{b},{m},{s}>">')
    return Swizzle(static(ty, loc=loc, ip=ip))


@dsl_user_op
def make_sparse_elem(num_logical, num_phys, elem_type, *, loc=None, ip=None):
    return _cute_ir.SparseElemType.get(num_logical, num_phys, elem_type.mlir_type)


@dsl_user_op
def static(value, *, loc=None, ip=None):
    return _cute_ir.static(value, loc=loc, ip=ip)


@dsl_user_op
def get_leaves(value, *, loc=None, ip=None):
    return _cute_ir.get_leaves(value, loc=loc, ip=ip)


#
# Tuple API (also used by layouts and tensors)
#


def depth(a: Union[XTuple, Layout, "ComposedLayout"]) -> int:
    """Returns the depth (nesting level) of a tuple, layout, or tensor.

    The depth of a tuple is the maximum depth of its elements plus 1.
    For an empty tuple, the depth is 1. For layouts and tensors, the depth
    is determined by the depth of their shape. For non-tuple values (e.g., integers),
    the depth is considered 0.

    :param a: The object whose depth is to be determined
    :type a: Union[XTuple, Layout, ComposedLayout, Tensor, Any]
    :return: The depth of the input object
    :rtype: int

    **Example:**

    .. code-block:: python

        >>> depth(1)
        0
        >>> depth((1, 2))
        1
        >>> depth(((1, 2), (3, 4)))
        2
    """
    if type(a) is tuple:
        if not a:
            return 1
        return max(depth(x) for x in a) + 1
    elif isinstance(a, (Layout, ComposedLayout, Tensor)):
        return depth(a.shape)
    else:
        return 0


@lru_cache_ir()
def rank(a: Union[XTuple, Layout, "ComposedLayout"], mode: List[int] = []) -> int:  # type: ignore
    """Returns the rank (dimensionality) of a tuple, layout, or tensor.

    The rank of a tuple is its length. For layouts and tensors, the rank is
    determined by the rank of their shape. For non-tuple values (e.g., integers),
    the rank is considered 1 for convenience.

    :param a: The object whose rank is to be determined
    :type a: Union[XTuple, Layout, ComposedLayout, Tensor, Any]
    :return: The rank of the input object
    :rtype: int

    This function is used in layout algebra to determine the dimensionality
    of tensors and layouts for operations like slicing and evaluation.
    """
    if isinstance(a, (Layout, ComposedLayout, Tensor)):
        return rank(a.shape, mode)

    if (not isinstance(mode, list)) or any(not isinstance(m, int) for m in mode):
        raise ValueError(f"Expected 'mode' to be a list of int, but got {mode}")

    if mode:
        for x in mode:
            a = a[x]

    if isinstance(a, tuple):
        return len(a)
    elif depth(a) == 0:
        return 1
    else:
        raise TypeError(f"unsupported type in rank, got {type(a)}")

def is_congruent(
    a: Union[XTuple, Layout, ComposedLayout, Tensor],
    b: Union[XTuple, Layout, ComposedLayout, Tensor],
) -> bool:
    """
    Returns whether a is congruent to b.

    Congruence is an equivalence relation between hierarchical structures.

    Two objects are congruent if:
    * They have the same rank, AND
    * They are both non-tuple values, OR
    * They are both tuples AND all corresponding elements are congruent.

    Congruence requires type matching at each level -- scalar values match with
    scalar values, and tuples match with tuples of the same rank.

    :param a: First object to compare
    :type a: Union[XTuple, Layout, ComposedLayout, Tensor]
    :param b: Second object to compare
    :type b: Union[XTuple, Layout, ComposedLayout, Tensor]
    :return: True if a and b are congruent, False otherwise
    :rtype: bool
    """
    if isinstance(a, (Layout, ComposedLayout, Tensor)):
        a = a.shape
    if isinstance(b, (Layout, ComposedLayout, Tensor)):
        b = b.shape
    if isinstance(a, tuple) and isinstance(b, tuple):
        return (len(a) == len(b)) and all(is_congruent(x, y) for x, y in zip(a, b))
    if isinstance(a, tuple) or isinstance(b, tuple):
        return False
    return True


def is_weakly_congruent(
    a: Union[XTuple, Layout, ComposedLayout, Tensor],
    b: Union[XTuple, Layout, ComposedLayout, Tensor],
) -> bool:
    """
    Returns whether a is weakly congruent to b.

    Weak congruence is a partial order on hierarchical structures.

    Object X is weakly congruent to object Y if:
    * X is a non-tuple value, OR
    * X and Y are both tuples of the same rank AND all corresponding elements are weakly congruent.

    Weak congruence allows scalar values to match with tuples, making it useful
    for determining whether an object has a hierarchical structure "up to" another.

    :param a: First object to compare
    :type a: Union[XTuple, Layout, ComposedLayout, Tensor]
    :param b: Second object to compare
    :type b: Union[XTuple, Layout, ComposedLayout, Tensor]
    :return: True if a and b are weakly congruent, False otherwise
    :rtype: bool
    """
    if isinstance(a, (Layout, ComposedLayout, Tensor)):
        a = a.shape
    if isinstance(b, (Layout, ComposedLayout, Tensor)):
        b = b.shape
    if not isinstance(a, tuple):
        return True
    # a and b are both tuple
    if isinstance(b, tuple):
        return (len(a) == len(b)) and all(
            is_weakly_congruent(x, y) for x, y in zip(a, b)
        )
    # a is a tuple, b is not a tuple
    return False


@overload
def get(input: Layout, mode, *, loc=None, ip=None) -> Layout: ...
@overload
def get(input: ComposedLayout, mode, *, loc=None, ip=None) -> ComposedLayout: ...
@overload
def get(input: XTuple, mode, *, loc=None, ip=None) -> XTuple: ...


def get(input, mode: List[int], *, loc=None, ip=None):
    """Extract a specific element or sub-layout from a layout or tuple.

    This function recursively traverses the input according to the mode indices,
    extracting the element at the specified path. For layouts, this operation
    corresponds to extracting a specific sub-layout.

    :param input: The input layout or tuple to extract from
    :type input: Layout, ComposedLayout, tuple
    :param mode: Indices specifying the path to traverse for extraction
    :type mode: List[int]
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: The extracted element or sub-layout
    :rtype: Layout, ComposedLayout, or element type
    :raises ValueError: If any index in mode is out of range
    :raises TypeError: If mode contains non-integer elements or if input has unsupported type

    :postcondition: ``get(t, mode=find(x,t)) == x if find(x,t) != None else True``

    **Examples:**

    .. code-block:: python

        layout = make_layout(((4, 8), (16, 1), 8), stride=((1, 4), (32, 0), 512))
        sub_layout = get(layout, mode=[0, 1])   # 8:4
        sub_layout = get(layout, mode=[1])      # (16, 1):(32, 0)
    """
    # Empty mode returns input and terminates the recursive call
    if not mode:
        return input

    if rank(input) <= mode[0]:
        raise ValueError(
            f"elements in mode must be less than rank({input}), got {mode}"
        )

    if depth(input) == 0:
        return input
    elif isinstance(input, tuple):
        if not isinstance(mode[0], int):
            raise TypeError(
                f"invalid element in mode, expects int, got {type(mode[0])}"
            )
        return get(input[mode[0]], mode=mode[1:])
    else:
        if not isinstance(input, (Layout, ComposedLayout)):
            raise TypeError(f"unsupported type of input, got {type(input)}")

        if isinstance(input, _ComposedLayout):
            input = input.value
        res_ty = input.type.get_op_res_type(mode=mode)  # type: ignore
        return _cute_ir.get(res_ty, input, mode=mode, loc=loc, ip=ip)


@overload
def select(input: Layout, mode, *, loc=None, ip=None) -> Layout: ...
@overload
def select(input: ComposedLayout, mode, *, loc=None, ip=None) -> ComposedLayout: ...
@overload
def select(input: XTuple, mode, *, loc=None, ip=None) -> XTuple: ...


@dsl_user_op
def select(input, mode: List[int], *, loc=None, ip=None):
    """Select modes from input.

    :param input: Input to select from
    :type input: Layout, ComposedLayout, tuple
    :param mode: Indices specifying which dimensions or elements to select
    :type mode: List[int]
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: A new instance with selected dimensions/elements
    :rtype: Layout, ComposedLayout, tuple
    :raises ValueError: If any index in mode is out of range
    :raises TypeError: If the input type is invalid

    **Examples:**

    .. code-block:: python

        # Select specific dimensions from a layout
        layout = make_layout((4, 8, 16), stride=(32, 4, 1))
        selected = select(layout, mode=[0, 2])  # Select mode 0 and mode 2
        # Result: (4, 16):(32, 1)

        # Select elements from a tuple
        t = (1, 2, 3, 4, 5)
        selected = select(t, mode=[0, 2, 4])  # Select mode 0, mode 2, and mode 4
        # Result: (1, 3, 5)
    """
    if any((not isinstance(i, int)) or (i >= rank(input)) for i in mode):
        raise ValueError(
            f"invalid mode element for input of rank {rank(input)}, got {mode=}"
        )

    if isinstance(input, tuple):
        return tuple(input[i] for i in mode)

    if not isinstance(input, (Layout, ComposedLayout)):
        raise TypeError(f"unsupported type of input, got {type(input)}")

    if isinstance(input, _ComposedLayout):
        input = input.value

    return _cute_ir.select(input, mode=mode, loc=loc, ip=ip)


@overload
def group_modes(
    input: Layout, begin: int, end: int, *, loc=None, ip=None
) -> Layout: ...
@overload
def group_modes(
    input: ComposedLayout, begin: int, end: int, *, loc=None, ip=None
) -> ComposedLayout: ...
@overload
def group_modes(
    input: Tensor, begin: int, end: int, *, loc=None, ip=None
) -> Tensor: ...
@overload
def group_modes(
    input: XTuple, begin: int, end: int, *, loc=None, ip=None
) -> XTuple: ...


@dsl_user_op
def group_modes(input, begin: int, end: Optional[int] = None, *, loc=None, ip=None):
    """Group modes of a hierarchical tuple or layout into a single mode.

    This function groups a range of modes from the input object into a single mode,
    creating a hierarchical structure. For tuples, it creates a nested tuple containing
    the specified range of elements. For layouts and other CuTe objects, it creates
    a hierarchical representation where the specified modes are grouped together.

    :param input: Input object to group modes from (layout, tuple, etc.)
    :type input: Layout, ComposedLayout, tuple, Shape, Stride, etc.
    :param beg: Beginning index of the range to group (inclusive)
    :type beg: int
    :param end: Ending index of the range to group (exclusive)
    :type end: int
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: A new object with the specified modes grouped
    :rtype: Same type as input with modified structure

    **Examples:**

    .. code-block:: python

        # Group modes in a tuple
        t = (2, 3, 4, 5)
        grouped = group_modes(t, 1, 3)  # (2, (3, 4), 5)

        # Group modes in a layout
        layout = make_layout((2, 3, 4, 5))
        grouped_layout = group_modes(layout, 1, 3)  # Layout with shape (2, (3, 4), 5)

        # Group modes in a shape
        shape = make_shape(2, 3, 4, 5)
        grouped_shape = group_modes(shape, 0, 2)  # Shape ((2, 3), 4, 5)
    """
    if end is None:
        end = rank(input)

    r = rank(input)
    begin = max(begin + r, 0) if begin < 0 else begin
    end = end + r if end < 0 else end

    if begin >= end:
        raise ValueError(f"Expected begin < end, but got {begin} >= {end}")

    if depth(input) == 0 and is_integer(input):
        return (input,)

    if isinstance(input, tuple):
        return (*input[:begin], (input[begin:end]), *input[end:])

    return _op_wrapper(
        partial(_cute_ir.group_modes, begin=begin, end=end, loc=loc, ip=ip), input
    )


@overload
def slice_(src: Layout, coord: Coord, *, loc=None, ip=None) -> Layout: ...
@overload
def slice_(
    src: _ComposedLayout, coord: Coord, *, loc=None, ip=None
) -> _ComposedLayout: ...
@overload
def slice_(src: Tensor, coord: Coord, *, loc=None, ip=None) -> Tensor: ...
@overload
def slice_(src: XTuple, coord: Coord, *, loc=None, ip=None) -> XTuple: ...


@dsl_user_op
def slice_(src, coord: Coord, *, loc=None, ip=None):
    """Perform a slice operation on a source object using the given coordinate.

    This function implements CuTe's slicing operation which extracts a subset of elements
    from a source object (tensor, layout, etc.) based on a coordinate pattern. The slice
    operation preserves the structure of the source while selecting specific elements.

    :param src: Source object to be sliced (tensor, layout, tuple, etc.)
    :type src: Union[Tensor, Layout, IntTuple, Value]
    :param coord: Coordinate pattern specifying which elements to select
    :type coord: Coord
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A new object containing the sliced elements
    :rtype: Union[Tensor, Layout, IntTuple, tuple]
    :raises ValueError: If the coordinate pattern is incompatible with source

    **Examples:**

    .. code-block:: python

        # Layout slicing
        layout = make_layout((4,4))

        # Select 1st index of first mode and keep all elements in second mode
        sub_layout = slice_(layout, (1, None))

    .. code-block:: python

        # Basic tensor slicing
        tensor = make_tensor(...)           # Create a 2D tensor

        # Select 1st index of first mode and keep all elements in second mode
        sliced = slice_(tensor, (1, None))

    .. code-block:: python

        # Select 2nd index of second mode and keep all elements in first mode
        sliced = slice_(tensor, (None, 2))

    Note:
        - `None` represents keeping all elements in that mode
        - Slicing preserves the layout/structure of the original object
        - Can be used for:
          * Extracting sub-tensors/sub-layouts
          * Creating views into data
          * Selecting specific patterns of elements
    """

    def lift_slice(a, b):
        if isinstance(a, tuple):
            if (not isinstance(b, tuple)) or (len(a) != len(b)):
                raise ValueError("coord must be weakly congruent to src in slice_")
            return reduce(
                lambda p, q: p + q, (lift_slice(x, y) for x, y in zip(a, b)), ()
            )
        elif a is None:
            return (b,)
        else:
            return ()

    if is_integer(src) or isinstance(src, tuple):
        if isinstance(coord, tuple):
            if (not isinstance(src, tuple)) or (len(coord) != len(src)):
                raise ValueError("coord must be weakly congruent to src in slice_")
            return reduce(
                lambda p, q: p + q, (lift_slice(x, y) for x, y in zip(coord, src)), ()
            )
        elif coord is None:
            return src
        else:
            return ()

    coord_val = _pack_coord(coord, loc=loc, ip=ip)
    return _op_wrapper(partial(_cute_ir.slice, coord=coord_val, loc=loc, ip=ip), src)


@overload
def dice(src: Layout, dicer: Coord, *, loc=None, ip=None) -> Layout: ...
@overload
def dice(src: ComposedLayout, dicer: Coord, *, loc=None, ip=None) -> ComposedLayout: ...
@overload
def dice(src: XTuple, dicer: Coord, *, loc=None, ip=None) -> XTuple: ...


@dsl_user_op
@lru_cache_ir()
def dice(src, dicer, *, loc=None, ip=None):
    """Keep modes in input when it is paired with an integer in dicer.

    This function performs dicing operation on the input based on the dicer coordinate.
    Dicing is a fundamental operation in CuTe that allows selecting specific modes from
    a tensor or layout based on a coordinate pattern.

    :param dicer: A static coordinate indicating how to dice the input
    :type dicer: Coord
    :param input: The operand to be diced on
    :type input: Union[IntTuple, Shape, Stride, Coord, Layout, ComposedLayout]
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: The diced result with selected modes from the input
    :rtype: Union[IntTuple, Shape, Stride, Coord, Layout, ComposedLayout]
    :raises TypeError: If dicer has an unsupported type
    :raises ValueError: If input is not provided

    **Examples:**

    .. code-block:: python

        # Basic dicing of a layout
        layout = make_layout((32,16,8))

        # Keep only first and last modes
        diced = dice((1,None,1), layout)

    Note:
        - The dicer coordinate must be static
        - Use underscore (_) to remove a mode
    """
    if not is_static(dicer):
        raise ValueError(f"expects dicer to be static, but got {dicer}")

    def lift_dice(a, b):
        if isinstance(a, tuple):
            if (not isinstance(b, tuple)) or (len(a) != len(b)):
                raise ValueError("dicer must be weakly congruent to input in dice")
            return reduce(
                lambda p, q: p + q, (lift_dice(x, y) for x, y in zip(a, b)), ()
            )
        elif a is None:
            return ()
        else:
            return (b,)

    if is_integer(src) or isinstance(src, tuple):
        if isinstance(dicer, tuple):
            if (not isinstance(src, tuple)) or (len(dicer) != len(src)):
                raise ValueError("dicer must be weakly congruent to src in dice")
            return reduce(
                lambda p, q: p + q, (lift_dice(x, y) for x, y in zip(dicer, src)), ()
            )
        elif dicer is None:
            return ()
        else:
            return src

    dicer_val = _pack_coord(dicer, loc=loc, ip=ip)
    return _op_wrapper(
        partial(_cute_ir.dice, coord=dicer_val.type.attribute, loc=loc, ip=ip), src
    )


def _extend(func, input, elem, up_to_rank, loc, ip):
    if input is None:
        raise ValueError("No input provided for input")

    if isinstance(input, (_Layout, _ComposedLayout)):
        if elem is None:
            elem = make_layout(1)
        elif not isinstance(elem, Layout):
            raise TypeError(f"Input type of elem ({type(elem)}) is not accepted!")
        N = rank(input) + 1 if up_to_rank is None else up_to_rank

        return _op_wrapper(partial(func, N, element=elem, loc=loc, ip=ip), input)

    if is_valid_leaf(input) or isinstance(input, tuple):
        if elem is None:
            elem = 1
        if (not isinstance(elem, tuple)) and (not is_valid_leaf(elem)):
            raise TypeError(f"Input type of elem ({type(elem)}) is not accepted!")

        input = wrap(input)
        repeat_cnt = 1 if up_to_rank is None else up_to_rank - rank(input)
        if repeat_cnt == 0:
            return input
        elif repeat_cnt < 0:
            raise ValueError("up_to_rank must be >= rank(input)")
        else:
            if func is _cute_ir.prepend_to_rank:
                return (elem,) * repeat_cnt + input
            else:
                return input + (elem,) * repeat_cnt

    raise TypeError(f"invalid type for input, got {type(input)}")


@overload
def prepend(
    input: Layout, elem: Layout, up_to_rank=None, *, loc=None, ip=None
) -> Layout: ...
@overload
def prepend(
    input: ComposedLayout, elem: Layout, up_to_rank=None, *, loc=None, ip=None
) -> ComposedLayout: ...
@overload
def prepend(
    input: XTuple, elem: XTuple, up_to_rank=None, *, loc=None, ip=None
) -> XTuple: ...


@dsl_user_op
def prepend(input, elem, up_to_rank: Union[None, int] = None, *, loc=None, ip=None):
    """Extend input to rank up_to_rank by prepending elem in front of input.

    This function extends the input object by prepending elements to reach a desired rank.
    It supports various CuTe types including shapes, layouts, tensors etc.

    :param input: Source to be prepended to
    :type input: Union[Shape, Stride, Coord, IntTuple, Tile, Layout, ComposedLayout, Tensor]
    :param elem: Element to prepend to input
    :type elem: Union[Shape, Stride, Coord, IntTuple, Tile, Layout]
    :param up_to_rank: The target rank after extension, defaults to None
    :type up_to_rank: Union[None, int], optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: The extended result with prepended elements
    :rtype: Union[Shape, Stride, Coord, IntTuple, Tile, Layout, ComposedLayout, Tensor]
    :raises ValueError: If up_to_rank is less than input's current rank
    :raises TypeError: If input or elem has unsupported type

    **Examples:**

    .. code-block:: python

        # Prepend to a Shape
        shape = (4,4)
        prepend(shape, 2)                   # Returns (2,4,4)

        # Prepend to a Layout
        layout = make_layout((8,8))
        prepend(layout, make_layout((2,)))  # Returns (2,8,8):(1,1,8)

        # Prepend with target rank
        coord = (1,1)
        prepend(coord, 0, up_to_rank=4)     # Returns (0,0,1,1)
    """
    return _extend(_cute_ir.prepend_to_rank, input, elem, up_to_rank, loc=loc, ip=ip)


@overload
def append(
    input: Layout, elem: Layout, up_to_rank=None, *, loc=None, ip=None
) -> Layout: ...
@overload
def append(
    input: ComposedLayout, elem: Layout, up_to_rank=None, *, loc=None, ip=None
) -> ComposedLayout: ...
@overload
def append(
    input: XTuple, elem: XTuple, up_to_rank=None, *, loc=None, ip=None
) -> XTuple: ...


@dsl_user_op
def append(input, elem, up_to_rank: Union[None, int] = None, *, loc=None, ip=None):
    """Extend input to rank up_to_rank by appending elem to the end of input.

    This function extends the input object by appending elements to reach a desired rank.
    It supports various CuTe types including shapes, layouts, tensors etc.

    :param input: Source to be appended to
    :type input: Union[Shape, Stride, Coord, IntTuple, Tile, Layout, ComposedLayout, Tensor]
    :param elem: Element to append to input
    :type elem: Union[Shape, Stride, Coord, IntTuple, Tile, Layout]
    :param up_to_rank: The target rank after extension, defaults to None
    :type up_to_rank: Union[None, int], optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: The extended result with appended elements
    :rtype: Union[Shape, Stride, Coord, IntTuple, Tile, Layout, ComposedLayout, Tensor]
    :raises ValueError: If up_to_rank is less than input's current rank
    :raises TypeError: If input or elem has unsupported type

    **Examples:**

    .. code-block:: python

        # Append to a Shape
        shape = (4,4)
        append(shape, 2)                   # Returns (4,4,2)

        # Append to a Layout
        layout = make_layout((8,8))
        append(layout, make_layout((2,)))  # Returns (8,8,2):(1,8,1)

        # Append with target rank
        coord = (1,1)
        append(coord, 0, up_to_rank=4)     # Returns (1,1,0,0)

    Note:
        - The function preserves the structure of the input while extending it
        - Can be used to extend tensors, layouts, shapes and other CuTe types
        - When up_to_rank is specified, fills remaining positions with elem
        - Useful for tensor reshaping and layout transformations
    """
    return _extend(_cute_ir.append_to_rank, input, elem, up_to_rank, loc=loc, ip=ip)


@dsl_user_op
def prepend_ones(
    t: Tensor, up_to_rank: Union[None, int] = None, *, loc=None, ip=None
) -> Tensor:
    from .tensor import make_tensor

    return make_tensor(
        t.iterator, prepend(t.layout, make_layout(1), up_to_rank), loc=loc, ip=ip
    )


@overload
def append_ones(
    t: Layout, up_to_rank: Union[None, int] = None, *, loc=None, ip=None
) -> Layout: ...


@overload
def append_ones(
    t: Tensor, up_to_rank: Union[None, int] = None, *, loc=None, ip=None
) -> Tensor: ...


@dsl_user_op
def append_ones(t, up_to_rank: Union[None, int] = None, *, loc=None, ip=None):
    from .tensor import make_tensor

    if isinstance(t, Tensor):
        return make_tensor(
            t.iterator, append(t.layout, make_layout(1), up_to_rank), loc=loc, ip=ip
        )
    elif isinstance(t, Layout):
        return append(t, make_layout(1), up_to_rank)
    else:
        raise TypeError(f"expects Tensor or Layout, but got {type(t)}")


def repeat_as_tuple(x, n) -> tuple:
    """Creates a tuple with x repeated n times.

    This function creates a tuple by repeating the input value x n times.

    :param x: The value to repeat
    :type x: Any
    :param n: Number of times to repeat x
    :type n: int
    :return: A tuple containing x repeated n times
    :rtype: tuple

    **Examples:**

    .. code-block:: python

        repeat_as_tuple(1, 1)     # Returns (1,)
        repeat_as_tuple(1, 3)     # Returns (1, 1, 1)
        repeat_as_tuple(None, 4)  # Returns (None, None, None, None)
    """
    if n < 1:
        raise ValueError("n must be >= 1")

    return (x,) * n


def repeat(x, n):
    """Creates an object by repeating x n times.

    This function creates an object by repeating the input value x n times.
    If n=1, returns x directly, otherwise returns a tuple of x repeated n times.

    :param x: The value to repeat
    :type x: Any
    :param n: Number of times to repeat x
    :type n: int
    :return: x if n=1, otherwise a tuple containing x repeated n times
    :rtype: Union[Any, tuple]
    :raises ValueError: If n is less than 1

    **Examples:**

    .. code-block:: python

        repeat(1, 1)     # Returns 1
        repeat(1, 3)     # Returns (1, 1, 1)
        repeat(None, 4)  # Returns (None, None, None, None)
    """
    if n < 1:
        raise ValueError("n must be >= 1")

    return x if n == 1 else (x,) * n


def repeat_like(x, target):
    """Creates an object congruent to target and filled with x.

    This function recursively creates a nested tuple structure that matches the structure
    of the target, with each leaf node filled with the value x.

    :param x: The value to fill the resulting structure with
    :type x: Any
    :param target: The structure to mimic
    :type target: Union[tuple, Any]
    :return: A structure matching target but filled with x
    :rtype: Union[tuple, Any]

    **Examples:**

    .. code-block:: python

        repeat_like(0, (1, 2, 3))      # Returns (0, 0, 0)
        repeat_like(1, ((1, 2), 3))    # Returns ((1, 1), 1)
        repeat_like(2, 5)              # Returns 2
    """
    if not isinstance(target, tuple):
        return x
    if not target:
        return ()
    if len(target) == 1:
        return (repeat_like(x, target[0]),)
    return tuple(repeat_like(x, t) for t in target)


@overload
def flatten(a: Layout) -> Layout: ...


@overload
def flatten(a: Tensor) -> Tensor: ...
@overload
def flatten(a: XTuple) -> XTuple: ...


def flatten(a):
    """Flattens a CuTe data structure into a simpler form.

    For tuples, this function flattens the structure into a single-level tuple.
    For layouts, it returns a new layout with flattened shape and stride.
    For tensors, it returns a new tensor with flattened layout.
    For other types, it returns the input unchanged.

    :param a: The structure to flatten
    :type a: Union[IntTuple, Coord, Shape, Stride, Layout, Tensor]
    :return: The flattened structure
    :rtype: Union[tuple, Any]

    **Examples:**

    .. code-block:: python

        flatten((1, 2, 3))                      # Returns (1, 2, 3)
        flatten(((1, 2), (3, 4)))               # Returns (1, 2, 3, 4)
        flatten(5)                              # Returns 5
        flatten(Layout(shape, stride))          # Returns Layout(flatten(shape), flatten(stride))
        flatten(Tensor(layout))                 # Returns Tensor(flatten(layout))

    """
    from .tensor import make_tensor

    if isinstance(a, Tensor):
        return make_tensor(a.iterator, flatten(a.layout))
    elif isinstance(a, Layout):
        return make_layout(flatten(a.shape), stride=flatten(a.stride))
    elif isinstance(a, tuple):
        return flatten_to_tuple(a)
    else:
        return a


@overload
def filter_zeros(
    input: Layout, *, target_profile=None, loc=None, ip=None
) -> Layout: ...
@overload
def filter_zeros(
    input: Tensor, *, target_profile=None, loc=None, ip=None
) -> Tensor: ...


@dsl_user_op
def filter_zeros(input, *, target_profile=None, loc=None, ip=None):
    """Filter out zeros from a layout or tensor.

    This function removes zero-stride dimensions from a layout or tensor.
    Refer to https://github.com/NVIDIA/cutlass/blob/main/media/docs/cpp/cute/02_layout_algebra.md
    for more layout algebra operations.

    :param input: The input layout or tensor to filter
    :type input: Layout or Tensor
    :param target_profile: Target stride profile for the filtered result, defaults to None
    :type target_profile: Stride, optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: The filtered layout or tensor with zeros removed
    :rtype: Layout or Tensor
    :raises TypeError: If input is not a Layout or Tensor
    """
    if not isinstance(input, (Layout, Tensor)):
        raise TypeError(f"Expected layout or tensor as input, but got {type(input)=}")
    if isinstance(input, Tensor):
        input = input.value
    return _cute_ir.filter_zeros(input, target_profile=target_profile, loc=loc, ip=ip)


@overload
def filter(input: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def filter(input: ComposedLayout, *, loc=None, ip=None) -> ComposedLayout: ...
@overload
def filter(input: Tensor, *, loc=None, ip=None) -> Tensor: ...


@dsl_user_op
def filter(input, *, loc=None, ip=None):
    """Filter a layout or tensor.

    This function filters a layout or tensor according to CuTe's filtering rules.

    :param input: The input layout or tensor to filter
    :type input: Layout or Tensor
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: The filtered layout or tensor
    :rtype: Layout or Tensor
    :raises TypeError: If input is not a Layout or Tensor
    """
    from .tensor import _Tensor

    if not isinstance(input, (Layout, Tensor, ComposedLayout)):
        raise TypeError(f"Expected layout or tensor as input, but got {type(input)=}")

    if isinstance(input, ComposedLayout):
        return make_composed_layout(
            input.inner, input.offset, filter(input.outer, loc=loc, ip=ip)
        )
    elif isinstance(input, _Tensor):
        return _cute_ir.filter(input.value, loc=loc, ip=ip)
    else:
        return _cute_ir.filter(input, loc=loc, ip=ip)


@dsl_user_op
def size(
    a: Union[IntTuple, Shape, Layout, ComposedLayout, Tensor],
    mode: List[int] = [],
    *,
    loc=None,
    ip=None,
) -> Int:
    """Return size of domain of layout or tensor.

    Computes the size (number of elements) in the domain of a layout or tensor.
    For layouts, this corresponds to the shape of the coordinate space.
    See https://github.com/NVIDIA/cutlass/blob/main/media/docs/cpp/cute/01_layout.md
    for more details on layout domains.

    :param a: The input object whose size to compute
    :type a: IntTuple, Shape, Layout, ComposedLayout or Tensor
    :param mode: List of mode(s) for size calculation. If empty, computes total size, defaults to []
    :type mode: list of int, optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: Static size of layout or tensor if static, otherwise a Value
    :rtype: int or Value
    :raises ValueError: If mode contains non-integer elements
    """
    from .atom import TiledCopy, TiledMma

    if any(not isinstance(m, int) for m in mode):
        raise ValueError(f"Expected integer elements in mode, but got {mode}")

    if isinstance(a, (TiledMma, TiledCopy)):
        return a.size
    a_val = None
    if not isinstance(a, (Layout, ComposedLayout, Tensor)):
        a_val = _pack_int_tuple(a, loc=loc, ip=ip)
    elif isinstance(a, (ComposedLayout, Tensor)):
        a_val = a.value
    else:
        a_val = a

    res = _cute_ir.size(a_val, mode=mode, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)  # type: ignore


@dsl_user_op
def shape_div(lhs: Shape, rhs: Shape, *, loc=None, ip=None) -> Shape:
    """Perform element-wise division of shapes.

    This function performs element-wise division between two shapes.

    :param lhs: Left-hand side shape
    :type lhs: Shape
    :param rhs: Right-hand side shape
    :type rhs: Shape
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: The result of element-wise division
    :rtype: Shape
    """
    lhs = _pack_shape(lhs, loc=loc, ip=ip)
    rhs = _pack_shape(rhs, loc=loc, ip=ip)
    res = _cute_ir.shape_div(lhs, rhs, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)


@dsl_user_op
def ceil_div(input: Shape, tiler: Tiler, *, loc=None, ip=None) -> Shape:
    """
    Compute the ceiling division of a target shape by a tiling specification.

    This function computes the number of tiles required to cover the target domain.
    It is equivalent to the second mode of `zipped_divide(input, tiler)`.

    :param input: A tuple of integers representing the dimensions of the target domain.
    :type input: Shape
    :param tiler: The tiling specification.
    :type tiler: Union[Layout, Shape, Tile]
    :param loc: Optional location information for IR diagnostics.
    :type loc: optional
    :param ip: Optional instruction pointer or context for underlying IR functions.
    :type ip: optional
    :return: A tuple of integers representing the number of tiles required along each dimension,
             i.e. the result of the ceiling division of the input dimensions by the tiler dimensions.
    :rtype: Shape

    Example:

    .. code-block:: python

        import cutlass.cute as cute
        @cute.jit
        def foo():
            input = (10, 6)
            tiler = (3, 4)
            result = cute.ceil_div(input, tiler)
            print(result)  # Outputs: (4, 2)
    """
    input_val = _pack_int_tuple(input, loc=loc, ip=ip)
    tiler_val = _pack_tile(tiler, loc=loc, ip=ip)
    res = _cute_ir.ceil_div(input=input_val, tiler=tiler_val, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)


def round_up(a: IntTuple, b: IntTuple) -> IntTuple:
    """
    Rounds up elements of a using elements of b.
    """
    if isinstance(a, tuple):
        if not a:
            raise ValueError("inputs cannot be empty")
        if not isinstance(b, tuple):
            raise TypeError(
                f"Expected both inputs to be tuple, but got {type(a)} and {type(b)}"
            )
        if rank(a) < rank(b):
            raise ValueError(
                f"Expected rank(a) to be greater or equal than rank(b), but got {a}, {b}"
            )
        b = append(b, 1, rank(a))
        return tuple(round_up(x, y) for x, y in zip(a, b))

    if isinstance(b, tuple):
        raise TypeError(
            f"Expected `b` to be a single integer when `a` is not a tuple, but got {b}"
        )

    return ((a + b - 1) // b) * b


#
# Layout API (also used by tensors)
#


@dsl_user_op
def make_layout(
    shape: Shape, *, stride: Union[Stride, None] = None, loc=None, ip=None
) -> Layout:
    """Create a CuTe Layout object from shape and optional stride information.

    A Layout in CuTe represents the mapping between logical and physical coordinates of a tensor.
    This function creates a Layout object that defines how tensor elements are arranged in memory.

    :param shape: Shape of the layout defining the size of each mode
    :type shape: Shape
    :param stride: Optional stride values for each mode, defaults to None
    :type stride: Union[Stride, None]
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A new Layout object with the specified shape and stride
    :rtype: Layout

    **Examples:**

    .. code-block:: python

        # Create a 2D compact left-most layout with shape (4,4)
        layout = make_layout((4,4))                     # compact left-most layout

        # Create a left-most layout with custom strides
        layout = make_layout((4,4), stride=(1,4))       # left-most layout with strides (1,4)

        # Create a layout for a 3D tensor
        layout = make_layout((32,16,8))                 # left-most layout

        # Create a layout with custom strides
        layout = make_layout((2,2,2), stride=(4,1,2))   # layout with strides (4,1,2)

    Note:
        - If stride is not provided, a default compact left-most stride is computed based on the shape
        - The resulting layout maps logical coordinates to physical memory locations
        - The layout object can be used for tensor creation and memory access patterns
        - Strides can be used to implement:
          * Row-major vs column-major layouts
          * Padding and alignment
          * Blocked/tiled memory arrangements
          * Interleaved data formats
        - Stride is keyword only argument to improve readability, e.g.
          * make_layout((3,4), (1,4)) can be confusing with make_layout(((3,4), (1,4)))
          * make_layout((3,4), stride=(1,4)) is more readable
    """
    if stride is not None and not is_congruent(shape, stride):
        raise ValueError("shape and stride must be congruent")

    shape_val = _pack_shape(shape, loc=loc, ip=ip)
    if stride is not None:
        stride_val = _pack_stride(stride, loc=loc, ip=ip)
        layout_ty = _cute_ir.LayoutType.get(shape_val, stride_val)
    else:
        stride_val = None
        layout_ty = _cute_ir.LayoutType.get(shape_val)

    return _cute_ir.make_layout(
        layout_ty, shape=shape_val, stride=stride_val, loc=loc, ip=ip
    )


@dsl_user_op
def make_identity_layout(shape: Shape, *, loc=None, ip=None) -> Layout:
    """Create an identity layout with the given shape.

    An identity layout maps logical coordinates directly to themselves without any transformation.
    This is equivalent to a layout with stride (1@0,1@1,...,1@(N-1)).

    :param shape: The shape of the layout
    :type shape: Shape
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A new identity Layout object with the specified shape
    :rtype: Layout

    **Examples:**

    .. code-block:: python

        # Create a 2D identity layout with shape (4,4)
        layout = make_identity_layout((4,4))     # stride=(1@0,1@1)

        # Create a 3D identity layout
        layout = make_identity_layout((32,16,8)) # stride=(1@0,1@1,1@2)

    Note:
        - An identity layout is a special case where each coordinate maps to itself
        - Useful for direct coordinate mapping without any transformation
    """
    if not is_int_tuple(shape):
        raise TypeError(f"expects a shape input, got {type(shape)}")
    shape_val = _pack_shape(shape, loc=loc, ip=ip)
    return _cute_ir.make_identity_layout(shape_val, loc=loc, ip=ip)


@dsl_user_op
def make_ordered_layout(shape: Shape, order: Shape, *, loc=None, ip=None) -> Layout:
    """Create a layout with a specific ordering of dimensions.

    This function creates a layout where the dimensions are ordered according to the
    specified order parameter, allowing for custom dimension ordering in the layout.

    :param shape: The shape of the layout
    :type shape: Shape
    :param order: The ordering of dimensions
    :type order: Shape
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A new Layout object with the specified shape and dimension ordering
    :rtype: Layout

    **Examples:**

    .. code-block:: python

        # Create a row-major layout
        layout = make_ordered_layout((4,4), order=(1,0))

        # Create a column-major layout
        layout = make_ordered_layout((4,4), order=(0,1))         # stride=(1,4)

        # Create a layout with custom dimension ordering for a 3D tensor
        layout = make_ordered_layout((32,16,8), order=(2,0,1))   # stride=(128,1,16)

    Note:
        - The order parameter specifies the ordering of dimensions from fastest-varying to slowest-varying
        - For a 2D tensor, (0,1) creates a column-major layout, while (1,0) creates a row-major layout
        - The length of order must match the rank of the shape
    """
    shape_val = _pack_shape(shape, loc=loc, ip=ip)
    order_val = _pack_int_tuple(order, loc=loc, ip=ip)
    return _cute_ir.make_ordered_layout(
        shape=shape_val, order=order_val, loc=loc, ip=ip
    )


@dsl_user_op
def make_layout_like(input: Union[Layout, Tensor], *, loc=None, ip=None) -> Layout:
    if isinstance(input, Tensor):
        layout = input.layout
    else:
        layout = input
    return _cute_ir.make_layout_like(layout, loc=loc, ip=ip)


class _ComposedLayoutWithInnerFunc(ComposedLayout):
    @dsl_user_op
    def __init__(self, inner, offset, outer, *, loc=None, ip=None):
        self._inner = inner
        self._offset = offset
        self._outer = outer

        self._offset_val = _pack_int_tuple(offset, loc=loc, ip=ip)

    @dsl_user_op
    def __call__(self, coord, *, loc=None, ip=None):
        delta = self._outer(coord)

        delta_val = _pack_int_tuple(delta, loc=loc, ip=ip)
        offset_val_new = _cute_ir.add_offset(
            self._offset_val, delta_val, loc=loc, ip=ip
        )
        offset_new = _unpack_x_tuple(offset_val_new, loc=loc, ip=ip)

        return self._inner(offset_new)

    def __str__(self):
        return f"({self._inner} o {self._offset} o {self._outer})"

    @property
    def type(self):
        raise ValueError("type is not supported for customized composed layouts")

    @property
    def is_normal(self):
        return False

    @property
    def inner(self, *, loc=None, ip=None):
        return self._inner

    @property
    def offset(self, *, loc=None, ip=None):
        return self._offset

    @property
    def outer(self, *, loc=None, ip=None):
        return self._outer

    @property
    def shape(self, *, loc=None, ip=None):
        return self._outer.shape


@dsl_user_op
def make_composed_layout(
    inner, offset: IntTuple, outer: Layout, *, loc=None, ip=None
) -> ComposedLayout:
    """Create a composed layout by composing an inner transformation with an outer layout.

    A composed layout applies a sequence of transformations
    to coordinates. The composition is defined as (inner ∘ offset ∘ outer), where the operations
    are applied from right to left.

    :param inner: The inner transformation (can be a Layout or Swizzle)
    :type inner: Union[Layout, Swizzle]
    :param offset: An integral offset applied between transformations
    :type offset: IntTuple
    :param outer: The outer (right-most) layout that is applied first
    :type outer: Layout
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: A new ComposedLayout representing the composition
    :rtype: ComposedLayout

    **Examples:**

    .. code-block:: python

        # Create a basic layout
        inner = make_layout(...)
        outer = make_layout((4,4), stride=(E(0), E(1)))

        # Create a composed layout with an offset
        composed = make_composed_layout(inner, (2,0), outer)

    Note:
        - The composition applies transformations in the order: outer → offset → inner
        - The stride divisibility condition must be satisfied for valid composition
        - Certain compositions (like Swizzle with scaled basis) are invalid and will raise errors
        - Composed layouts inherit many properties from the outer layout
    """
    if not isinstance(outer, Layout):
        raise TypeError(
            f"expects the outer (or right-most or effectively visible) layout to be an affine layout, but got {outer}"
        )
    if isinstance(inner, Swizzle) and has_scaled_basis(outer.stride):
        raise TypeError(f"invalid composition {inner} o {offset} o {outer}")

    if isinstance(inner, (Layout, Swizzle)):
        offset_val = _pack_int_tuple(offset, loc=loc, ip=ip)
        return _cute_ir.make_composed_layout(inner, offset_val, outer, loc=loc, ip=ip)

    return _ComposedLayoutWithInnerFunc(inner, offset, outer, loc=loc, ip=ip)


@dsl_user_op
def cosize(
    a: Union[Layout, ComposedLayout, Tensor], mode: List[int] = [], *, loc=None, ip=None
):
    """Return size of codomain of layout or tensor. Return static value if type is static.

    For a layout ``L = S:D`` where ``S`` is the shape and ``D`` is the stride, the codomain size is the
    minimum size needed to store all possible offsets generated by the layout. This is calculated
    by taking the maximum offset plus 1.

    For example, given a layout ``L = (4,(3,2)):(2,(8,1))``:
        - Shape ``S = (4,(3,2))``
        - Stride ``D = (2,(8,1))``
        - Maximum offset = ``2*(4-1) + 8*(3-1) + 1*(2-1) = 6 + 16 + 1 = 23``
        - Therefore ``cosize(L) = 24``

    **Examples:**

    .. code-block:: python

        L = cute.make_layout((4,(3,2)), stride=(2,(8,1))) # L = (4,(3,2)):(2,(8,1))
        print(cute.cosize(L))  # => 24

    :param a: Layout, ComposedLayout, or Tensor object
    :type a: Union[Layout, ComposedLayout, Tensor]
    :param mode: List of mode(s) for cosize calculation. If empty, calculates over all modes.
                If specified, calculates cosize only for the given modes.
    :type mode: List[int], optional
    :param loc: Location information for diagnostics, defaults to None
    :type loc: optional
    :param ip: Instruction pointer for diagnostics, defaults to None
    :type ip: optional
    :return: Static size of layout or tensor (fast fold) if static, or a dynamic Value
    :rtype: Union[int, Value]
    """
    from .tensor import _Tensor

    if any(not is_static(m) for m in mode):
        raise ValueError(f"expects static mode, but got {mode}")

    if isinstance(a, (_Tensor, _ComposedLayout)):
        res = _cute_ir.cosize(a.value, mode=mode, loc=loc, ip=ip)
    else:
        res = _cute_ir.cosize(a, mode=mode, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)


@dsl_user_op
def size_in_bytes(
    dtype: Type[Numeric],
    layout: Union[Layout, ComposedLayout, None],
    *,
    loc=None,
    ip=None,
) -> Union[int, Integer]:
    """Calculate the size in bytes based on its data type and layout. The result is rounded up to the nearest byte.

    :param dtype: The DSL numeric data type
    :type dtype: Type[Numeric]
    :param layout: The layout of the elements. If None, the function returns 0
    :type layout: Layout, optional
    :param loc: Location information for diagnostics, defaults to None
    :type loc: optional
    :param ip: Instruction pointer for diagnostics, defaults to None
    :type ip: optional
    :return: The total size in bytes. Returns 0 if the layout is None
    :rtype: int
    """
    if not isinstance(dtype, NumericMeta):
        raise TypeError(f"dtype must be a Numeric, but got {dtype}")

    size_in_elem = 0
    if layout is None:
        size_in_elem = 0

    elif isinstance(layout, ComposedLayout):
        if isinstance(layout.inner, Swizzle):
            # Swizzle layout is short-cut to cosize of outer
            # User of swizzle must guarantee swizzle mapping with codomain
            size_in_elem = cosize(layout.outer, loc=loc, ip=ip)
        elif isinstance(layout.inner, Layout):
            size_in_elem = cosize(layout.inner, loc=loc, ip=ip)
        else:
            raise TypeError(
                "Only support size when inner layout is Swizzle or normal Layout"
            )
    else:
        size_in_elem = cosize(layout, loc=loc, ip=ip)

    return ceil_div(size_in_elem * dtype.width, 8, loc=loc, ip=ip)  # type: ignore


@dsl_user_op
def coalesce(input, *, target_profile: Coord = None, loc=None, ip=None):
    if target_profile:
        profile_val = _pack_coord(target_profile, loc=loc, ip=ip)
    else:
        profile_val = None

    return _op_wrapper(
        partial(_cute_ir.coalesce, target_profile=profile_val, loc=loc, ip=ip), input
    )


@dsl_user_op
def crd2idx(coord: Coord, layout, *, loc=None, ip=None):
    """
    Convert a multi-dimensional coordinate into a value using the specified layout.

    This function computes the inner product of the flattened coordinate and stride:

        index = sum(flatten(coord)[i] * flatten(stride)[i] for i in range(len(coord)))

    :param coord: A tuple or list representing the multi-dimensional coordinate
                  (e.g., (i, j) for a 2D layout).
    :type coord: Coord
    :param layout: A layout object that defines the memory storage layout, including shape and stride,
                   used to compute the inner product.
    :type layout: Layout or ComposedLayout
    :param loc: Optional location information for IR diagnostics.
    :type loc: optional
    :param ip: Optional instruction pointer or context for underlying IR functions.
    :type ip: optional
    :returns: The result of applying the layout transformation to the provided coordinate.
    :rtype: Any type that the layout maps to

    **Example:**

    .. code-block:: python

        import cutlass.cute as cute
        @cute.jit
        def foo():
            L = cute.make_layout((5, 4), stride=(4, 1))
            idx = cute.crd2idx((2, 3), L)
            # Computed as: 2 * 4 + 3 = 11
            print(idx)
        foo()  # Expected output: 11
    """
    crd_val = _pack_coord(coord, loc=loc, ip=ip)
    if isinstance(layout, (tuple, int)):
        layout = make_layout(layout, loc=loc, ip=ip)
    elif isinstance(layout, _ComposedLayout):
        layout = layout.value

    res = _cute_ir.crd2idx(crd_val, layout, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)  # type: ignore


@overload
def idx2crd(idx: Int, shape: Int, *, loc=None, ip=None) -> Int: ...


@overload
def idx2crd(idx: IntTuple, shape: Tuple, *, loc=None, ip=None) -> Tuple: ...


@dsl_user_op
def idx2crd(idx, shape, *, loc=None, ip=None):
    """
    Convert a linear index back into a multi-dimensional coordinate using the specified layout.

    Mapping from a linear index to the corresponding multi-dimensional coordinate in the layout's coordinate space.
    It essentially "unfolds" a linear index into its constituent coordinate components.

    :param idx: The linear index to convert back to coordinates.
    :type idx: : int/Integer/Tuple
    :param shape: Shape of the layout defining the size of each mode
    :type shape: Shape
    :param loc: Optional location information for IR diagnostics.
    :type loc: optional
    :param ip: Optional instruction pointer or context for underlying IR functions.
    :type ip: optional
    :return: The result of applying the layout transformation to the provided coordinate.
    :rtype: Coord

    **Examples:**

    .. code-block:: python

        import cutlass.cute as cute
        @cute.jit
        def foo():
            coord = cute.idx2crd(11, (5,4))
            # Computed as: 11 = 2 * 4 + 3, so coordinate is (2, 3)
            print(coord)
        foo()  # Expected output: (2, 3)

    **Note:**
        Python DSL is aligned with C++ DSL.
    """
    if is_integer(idx) and is_integer(shape):
        return idx
    idx_val = _pack_int_tuple(idx, loc=loc, ip=ip)
    shape_val = _pack_shape(shape, loc=loc, ip=ip)
    res = _cute_ir.idx2crd(idx_val, shape_val, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)


@dsl_user_op
def recast_layout(new_type_bits, old_type_bits, src_layout, *, loc=None, ip=None):
    if isinstance(src_layout, _ComposedLayout):
        src_layout = src_layout.value
    return _cute_ir.recast_layout(
        new_type_bits, old_type_bits, src_layout, loc=loc, ip=ip
    )  # type: ignore


@dsl_user_op
def slice_and_offset(coord, src, *, loc=None, ip=None):
    layout = slice_(src, coord, loc=loc, ip=ip)
    offset = crd2idx(coord, src, loc=loc, ip=ip)
    return layout, offset


@dsl_user_op
@lru_cache_ir()
def shape(
    input: Union[Shape, Tensor, Layout, Tile], *, mode=None, loc=None, ip=None
) -> Shape:
    """Returns the shape of a tensor, layout or tiler.

    For shapes, this function is identical to get.

    This function extracts the shape information from the input object. For tensors and layouts,
    it returns their internal shape property. For tilers, it unpacks the shape from the tile
    representation.

    :param input: The object to extract shape from
    :type input: Union[Tensor, Layout, Tile]
    :param mode: Optional mode selector to extract specific dimensions from the shape
    :type mode: Optional[int]
    :param loc: Source location for MLIR operation tracking
    :type loc: Optional[Location]
    :param ip: Insertion point for MLIR operation
    :type ip: Optional[InsertionPoint]
    :return: The shape of the input object, optionally filtered by mode
    :rtype: Shape

    **Example:**

    .. code-block:: python

        # Get shape of a layout
        l0 = cute.make_layout((2, 3, 4))
        s0 = cute.shape(l0)  # => (2, 3, 4)

        # Get shape of a hierarchical tiler
        l1 = cute.make_layout(1)
        s1 = cute.shape((l0, l1))  # => ((2, 3, 4), 1)

        # Get specific mode from a shape
        s2 = cute.shape(l0, mode=0)  # => 2
    """
    if is_int_tuple(input):
        return get(input, mode=mode)

    if isinstance(input, (Tensor, Layout, ComposedLayout)):
        shp = input.shape
    else:
        val = _cute_ir.get_shape(_pack_tile(input, loc=loc, ip=ip))
        shp = _unpack_x_tuple(val, loc=loc, ip=ip)
    return get(shp, mode=mode)


#
# Pointer API
#


@dsl_user_op
def recast_ptr(
    ptr: Pointer,
    swizzle_=None,
    dtype: Optional[Type[Numeric]] = None,
    loc=None,
    ip=None,
) -> Pointer:
    if dtype is not None:
        if isinstance(dtype, _cute_ir.SparseElemType):
            # use SparseElemType as dtype
            pass
        else:
            if not isclass(dtype) or not issubclass(dtype, Numeric):
                raise TypeError(f"dtype must be a type of Numeric, but got {dtype}")
            dtype = dtype.mlir_type

    value_type = ptr.type.value_type if dtype is None else dtype
    swizzle = swizzle_.type.attribute if swizzle_ is not None else None
    res_ty = _cute_ir.PtrType.get(value_type, ptr.memspace, ptr.alignment, swizzle)
    return _cute_ir.recast_iter(res_ty, ptr.value, loc=loc, ip=ip)


@dsl_user_op
def make_ptr(
    dtype: Union[Type[Numeric], None],
    value,
    mem_space: AddressSpace = AddressSpace.generic,
    *,
    assumed_align=None,
    loc=None,
    ip=None,
) -> Pointer:
    if dtype is None or not isinstance(dtype, NumericMeta):
        raise TypeError(f"expects dtype to be a type of Numeric, but got {dtype}")

    if not isinstance(mem_space, AddressSpace):
        raise TypeError(f"expects mem_space to be an AddressSpace, but got {mem_space}")

    if isinstance(value, ir.Value) and llvm.PointerType.isinstance(value.type):
        value = llvm.ptrtoint(T.i64(), value)

    if not isinstance(mem_space, AddressSpace):
        raise TypeError(f"expects mem_space to be an AddressSpace, but got {mem_space}")

    if isinstance(value, ir.Value) and llvm.PointerType.isinstance(value.type):
        value = llvm.ptrtoint(T.i64(), value)

    if not is_integer(value):
        raise TypeError(f"expects integer value, but got {type(value)}")
    value = Int32(value) if mem_space == AddressSpace.tmem else Int64(value)
    value = Int32(value) if mem_space == AddressSpace.tmem else Int64(value)

    bytes_per_elt = max(1, dtype.width // 8)
    if assumed_align is None:
        assumed_align = bytes_per_elt

    if bytes_per_elt % assumed_align != 0 and assumed_align % bytes_per_elt != 0:
        raise ValueError(
            f"{bytes_per_elt=} is not a multiple of {assumed_align=} and vice versa."
        )

    aligned_ty = _cute_ir.ConstrainedIntType.get(assumed_align, type(value).width)
    aligned_intptr = _cute_ir.assume(
        aligned_ty, value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip
    )

    data_ty = T.i8() if dtype is None else dtype.mlir_type
    ptr_ty = _cute_ir.PtrType.get(data_ty, mem_space, assumed_align)
    return _cute_ir.inttoptr(ptr_ty, aligned_intptr, loc=loc, ip=ip)


#
# Layout algebra
#


@overload
def composition(
    lhs: Layout, rhs: Union[Layout, Shape, Tile], *, loc=None, ip=None
) -> Layout: ...
@overload
def composition(
    lhs: ComposedLayout, rhs: Union[Layout, Shape, Tile], *, loc=None, ip=None
) -> ComposedLayout: ...
@overload
def composition(
    lhs: Tensor, rhs: Union[Layout, Shape, Tile], *, loc=None, ip=None
) -> Tensor: ...


@dsl_user_op
def composition(lhs, rhs: Union[Layout, Shape, Tile], *, loc=None, ip=None):
    """
    Compose two layout representations using the CuTe layout algebra.

    Compose a left-hand layout (or tensor) with a right-hand operand into a new layout R, such that
    for every coordinate c in the domain of the right-hand operand, the composed layout satisfies:

        R(c) = A(B(c))

    where A is the left-hand operand provided as ``lhs`` and B is the right-hand operand provided as
    ``rhs``. In this formulation, B defines the coordinate domain while A applies its transformation to
    B's output, and the resulting layout R inherits the stride and shape adjustments from A.

    Satisfies:
        cute.shape(cute.composition(lhs, rhs)) is compatible with cute.shape(rhs)

    :param lhs: The left-hand operand representing the transformation to be applied.
    :type lhs: Layout or Tensor
    :param rhs: The right-hand operand defining the coordinate domain. If provided as an int or tuple,
                it will be converted to a tile layout.
    :type rhs: Layout, Shape, or Tile, or int or tuple
    :param loc: Optional location information for IR diagnostics.
    :type loc: optional
    :param ip: Optional instruction pointer or context for underlying IR functions.
    :type ip: optional
    :returns: A new composed layout R, such that for all coordinates c in the domain of ``rhs``,
              R(c) = lhs(rhs(c)).
    :rtype: Layout or Tensor

    **Example:**

    .. code-block:: python

        import cutlass.cute as cute
        @cute.jit
        def foo():
            # Create a layout that maps (i,j) to i*4 + j
            L1 = cute.make_layout((2, 3), stride=(4, 1))
            # Create a layout that maps (i,j) to i*3 + j
            L2 = cute.make_layout((3, 4), stride=(3, 1))
            # Compose L1 and L2
            L3 = cute.composition(L1, L2)
            # L3 now maps coordinates through L2 then L1
    """
    from .tensor import _Tensor

    rhs_val = rhs
    if not isinstance(rhs, Layout) and isinstance(rhs, (int, tuple)):
        rhs_val = _pack_tile(rhs, loc=loc, ip=ip)
    if isinstance(lhs, (_Tensor, _ComposedLayout)):
        lhs = lhs.value
    return _cute_ir.composition(lhs, rhs_val, loc=loc, ip=ip)


@dsl_user_op
def complement(
    input: Layout, cotarget: Union[Layout, Shape], *, loc=None, ip=None
) -> Layout:
    """
    Compute the complement layout of the input layout with respect to the cotarget.

    The complement of a layout A with respect to cotarget n is a layout A* such that
    for every k in Z_n and c in the domain of A, there exists a unique c* in the domain
    of A* where k = A(c) + A*(c*).

    This operation is useful for creating layouts that partition a space in complementary ways,
    such as row and column layouts that together cover a matrix.

    :param input: The layout to compute the complement of
    :type input: Layout
    :param cotarget: The target layout or shape that defines the codomain
    :type cotarget: Union[Layout, Shape]
    :param loc: Optional location information for IR diagnostics
    :type loc: optional
    :param ip: Optional instruction pointer or context for underlying IR functions
    :type ip: optional
    :returns: The complement layout
    :rtype: Layout

    **Example:**

    .. code-block:: python

        import cutlass.cute as cute
        @cute.jit
        def foo():
            # Create a right-major layout for a 4x4 matrix
            row_layout = cute.make_layout((4, 4), stride=(4, 1))
            # Create a left-major layout that complements the row layout
            col_layout = cute.complement(row_layout, 16)
            # The two layouts are complementary under 16
    """
    if isinstance(cotarget, Layout):
        return _cute_ir.complement(input, cotarget=cotarget, loc=loc, ip=ip)
    else:
        cotarget_val = _pack_shape(cotarget, loc=loc, ip=ip)
        return _cute_ir.complement(input, cotarget=cotarget_val, loc=loc, ip=ip)


@dsl_user_op
def right_inverse(input: Layout, *, loc=None, ip=None) -> Layout:
    if not isinstance(input, Layout):
        raise TypeError(f"Expected input of type Layout, but got {type(input)}")

    return _cute_ir.right_inverse(input=input, loc=loc, ip=ip)


@dsl_user_op
def left_inverse(input: Layout, *, loc=None, ip=None) -> Layout:
    if not isinstance(input, Layout):
        raise TypeError(f"Expected input of type Layout, but got {type(input)}")

    return _cute_ir.left_inverse(input=input, loc=loc, ip=ip)


@overload
def logical_product(block: Layout, tiler: Tile, *, loc=None, ip=None) -> Layout: ...
@overload
def logical_product(
    block: ComposedLayout, tiler: Tile, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def logical_product(block, tiler: Tile, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        block = block.value

    tiler_val = tiler
    if isinstance(tiler, Layout):
        return _cute_ir.logical_product(input=block, tiler=tiler_val, loc=loc, ip=ip)
    if tiler is None:
        return block
    if is_integer(tiler):
        return _cute_ir.logical_product(
            input=block, tiler=make_layout(tiler_val), loc=loc, ip=ip
        )
    assert rank(tiler_val) <= rank(block), "logical_product: Too many modes in tiler."
    tiler_rank = rank(tiler_val)
    block_rank = rank(block)
    res = tuple(
        logical_product(block[i], tiler_val[i]) if i < tiler_rank else block[i]
        for i in range(block_rank)
    )

    res_shape = tuple(res[i].shape for i in range(block_rank))
    res_stride = tuple(res[i].stride for i in range(block_rank))
    return make_layout(res_shape, stride=res_stride, loc=loc, ip=ip)


@overload
def zipped_product(block: Layout, tiler: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def zipped_product(
    block: ComposedLayout, tiler: Layout, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def zipped_product(block, tiler: Layout, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        return _cute_ir.zipped_product(input=block.value, tiler=tiler, loc=loc, ip=ip)
    else:
        return _cute_ir.zipped_product(input=block, tiler=tiler, loc=loc, ip=ip)


@overload
def tiled_product(block: Layout, tiler: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def tiled_product(
    block: ComposedLayout, tiler: Layout, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def tiled_product(block, tiler: Layout, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        return _cute_ir.tiled_product(input=block.value, tiler=tiler, loc=loc, ip=ip)
    else:
        return _cute_ir.tiled_product(input=block, tiler=tiler, loc=loc, ip=ip)


@overload
def flat_product(block: Layout, tiler: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def flat_product(
    block: ComposedLayout, tiler: Layout, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def flat_product(block, tiler: Layout, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        return _cute_ir.flat_product(input=block.value, tiler=tiler, loc=loc, ip=ip)
    else:
        return _cute_ir.flat_product(input=block, tiler=tiler, loc=loc, ip=ip)


@overload
def raked_product(block: Layout, tiler: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def raked_product(
    block: ComposedLayout, tiler: Layout, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def raked_product(block, tiler: Layout, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        return _cute_ir.raked_product(input=block.value, tiler=tiler, loc=loc, ip=ip)
    else:
        return _cute_ir.raked_product(input=block, tiler=tiler, loc=loc, ip=ip)


@overload
def blocked_product(block: Layout, tiler: Layout, *, loc=None, ip=None) -> Layout: ...
@overload
def blocked_product(
    block: ComposedLayout, tiler: Layout, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def blocked_product(block, tiler: Layout, *, loc=None, ip=None):
    if isinstance(block, _ComposedLayout):
        return _cute_ir.blocked_product(input=block.value, tiler=tiler, loc=loc, ip=ip)
    else:
        return _cute_ir.blocked_product(input=block, tiler=tiler, loc=loc, ip=ip)


@overload
def logical_divide(target: Layout, tiler: Tiler, *, loc=None, ip=None) -> Layout: ...
@overload
def logical_divide(target: Tensor, tiler: Tiler, *, loc=None, ip=None) -> Tensor: ...


@dsl_user_op
def logical_divide(target, tiler: Tiler, *, loc=None, ip=None):
    if isinstance(tiler, tuple):
        tiler = _pack_tile(tiler, loc=loc, ip=ip)  # type: ignore
    return _op_wrapper(
        partial(_cute_ir.logical_divide, tiler=tiler, loc=loc, ip=ip), target
    )


@overload
def zipped_divide(target: Layout, tiler: Tiler, *, loc=None, ip=None) -> Layout: ...
@overload
def zipped_divide(target: Tensor, tiler: Tiler, *, loc=None, ip=None) -> Tensor: ...


@dsl_user_op
def zipped_divide(target, tiler: Tiler, *, loc=None, ip=None):
    if isinstance(tiler, tuple):
        tiler = _pack_tile(tiler, loc=loc, ip=ip)  # type: ignore
    return _op_wrapper(
        partial(_cute_ir.zipped_divide, tiler=tiler, loc=loc, ip=ip), target
    )


@overload
def tiled_divide(target: Layout, tiler: Tiler, *, loc=None, ip=None) -> Layout: ...
@overload
def tiled_divide(target: Tensor, tiler: Tiler, *, loc=None, ip=None) -> Tensor: ...


@dsl_user_op
def tiled_divide(target, tiler: Tiler, *, loc=None, ip=None):
    if isinstance(tiler, tuple):
        tiler = _pack_tile(tiler, loc=loc, ip=ip)
    return _op_wrapper(
        partial(_cute_ir.tiled_divide, tiler=tiler, loc=loc, ip=ip), target
    )


@overload
def flat_divide(target: Layout, tiler: Tile, *, loc=None, ip=None) -> Layout: ...
@overload
def flat_divide(target: Tensor, tiler: Tile, *, loc=None, ip=None) -> Tensor: ...


@dsl_user_op
def flat_divide(target, tiler: Tile, *, loc=None, ip=None):
    if isinstance(tiler, tuple):
        tiler = _pack_tile(tiler, loc=loc, ip=ip)
    return _op_wrapper(
        partial(_cute_ir.flat_divide, tiler=tiler, loc=loc, ip=ip), target
    )


#
# Higher-level utilties
#


@dsl_user_op
def max_common_layout(
    a: Union[Layout, Tensor], b: Union[Layout, Tensor], *, loc=None, ip=None
) -> Layout:
    from .tensor import _Tensor

    a_layout = a.layout if isinstance(a, _Tensor) else a
    b_layout = b.layout if isinstance(b, _Tensor) else b

    inv_b = right_inverse(b_layout, loc=loc, ip=ip)
    common = coalesce(composition(a_layout, inv_b, loc=loc, ip=ip), loc=loc, ip=ip)

    # some_ir_value == 1 generates a new IR Value which evaluates to True!
    s = get(common.shape, mode=[0], loc=loc, ip=ip)
    d = get(common.stride, mode=[0], loc=loc, ip=ip)
    # Keep only the static identity component of the common layout
    if isinstance(s, int) and isinstance(d, int) and d == 1:
        # Truncate to the size of the contiguous vector (static stride-1 mode)
        return composition(inv_b, get(common, mode=[0], loc=loc, ip=ip), loc=loc, ip=ip)
    else:
        return make_layout(1, stride=0, loc=loc, ip=ip)


@dsl_user_op
def max_common_vector(
    a: Union[Layout, Tensor], b: Union[Layout, Tensor], *, loc=None, ip=None
) -> int:
    from .tensor import _Tensor

    a_layout = a.layout if isinstance(a, _Tensor) else a
    b_layout = b.layout if isinstance(b, _Tensor) else b

    inv_b = right_inverse(b_layout, loc=loc, ip=ip)
    common = coalesce(composition(a_layout, inv_b, loc=loc, ip=ip), loc=loc, ip=ip)

    # Keep only the static identity component of the common layout
    if (
        is_static(get(common.shape, mode=[0], loc=loc, ip=ip))
        and get(common.stride, mode=[0], loc=loc, ip=ip) == 1
    ):
        # Truncate to the size of the contiguous vector (static stride-1 mode)
        return get(common.shape, mode=[0], loc=loc, ip=ip)
    else:
        return 1


@overload
def tile_to_shape(
    atom: Layout, trg_shape: Shape, order: Shape, *, loc=None, ip=None
) -> Layout: ...
@overload
def tile_to_shape(
    atom: ComposedLayout, trg_shape: Shape, order: Shape, *, loc=None, ip=None
) -> ComposedLayout: ...


@dsl_user_op
def tile_to_shape(atom, trg_shape: Shape, order: Shape, *, loc=None, ip=None):
    trg_shape = _pack_shape(shape(trg_shape), loc=loc, ip=ip)  # type: ignore
    order = _pack_int_tuple(order, loc=loc, ip=ip)  # type: ignore

    if isinstance(atom, _ComposedLayout):
        return _cute_ir.tile_to_shape(atom.value, trg_shape, order, loc=loc, ip=ip)
    else:
        return _cute_ir.tile_to_shape(atom, trg_shape, order, loc=loc, ip=ip)


@dsl_user_op
def local_partition(
    target: Tensor,
    tiler: Union[Layout, Shape],
    index: Union[int, Numeric],
    proj: XTuple = 1,
    *,
    loc=None,
    ip=None,
) -> Tensor:
    if isinstance(index, cutlass_arith.ArithValue):
        index_val = index
    else:
        index_val = index.ir_value(loc=loc, ip=ip)
    if index_val.type.width > 32:
        raise NotImplementedError(
            f"Index value should be 32-bit or smaller integer type, but got {index_val.type}"
        )
    return _cute_ir.local_partition(
        input=target.value, tiler=dice(tiler, proj), index=index_val, loc=loc, ip=ip
    )


@dsl_user_op
def local_tile(
    input: Tensor,
    tiler: Tiler,
    coord: Coord,
    proj: XTuple = None,  # type: ignore
    *,
    loc=None,
    ip=None,
) -> Tensor:
    tiler_val = _pack_tile(tiler, loc=loc, ip=ip)
    coord_val = _pack_coord(coord, loc=loc, ip=ip)
    if proj is not None:
        if not isinstance(proj, tuple):
            raise TypeError(f"Expected tuple for proj, but got {type(proj)}")
        proj_val = _pack_coord(proj, loc=loc, ip=ip)
        proj = proj_val.type.attribute

    return _cute_ir.local_tile(
        input=input.value,
        tile=tiler_val,
        static_tile=None,
        coord=coord_val,
        static_coord=None,
        proj=proj,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_layout_image_mask(
    lay: Layout, coord: Coord, mode: int, *, loc=None, ip=None
) -> Int16:
    """
    Makes a 16-bit integer mask of the image of a layout sliced at a given mode
    and accounting for the offset given by the input coordinate for the other modes.
    """
    if not is_static(lay):
        raise ValueError(
            f"make_layout_image_mask requires the layout to be static, but got {pretty_str(lay)}"
        )
    r = rank(lay)
    if rank(coord) != r:
        raise ValueError(
            f"the rank of the coordinate must be equal to the one of the layout, but got {pretty_str(coord)}"
        )
    if mode > r or mode < 0:
        raise ValueError(f"expects `mode` to be in [0,rank(lay)), but got {mode}")
    # Given that we require the layout to be static, we can check that the mask fits in 16 bits
    # This might be too conservative but safe
    if cosize(lay) > 16:
        raise ValueError("the mask may not fit into a 16-bit integer")

    # Replace the mode to keep with _ in the coordinate
    slicer = tuple(None if idx == mode else x for idx, x in enumerate(coord))
    # Slice the layout with the slicer above and keep track of the offset
    sliced_lay, offset = slice_and_offset(slicer, lay, loc=loc, ip=ip)
    # Given that we replace only one mode with _, the rank of the slice should be 1
    assert rank(sliced_lay) == 1

    if not is_static(sliced_lay):
        raise ValueError("make_layout_image_mask requires the layout to be static")

    # Create the mask of the image
    mcast_mask = Int16(0)
    for i in range(size(sliced_lay)):  # type: ignore
        mcast_mask = mcast_mask | (1 << sliced_lay(i))
    mcast_mask <<= offset
    return Int16(mcast_mask)


def leading_dim(shape: Shape, stride: Stride) -> Union[int, Tuple[int, ...], None]:  # type: ignore
    """
    Find the leading dimension of a shape and stride.

    :param shape: The shape of the tensor or layout
    :type shape: Shape
    :param stride: The stride of the tensor or layout
    :type stride: Stride
    :return: The leading dimension index or indices
    :rtype: Union[int, Tuple[int, ...], None]

    The return value depends on the stride pattern:

        * If a single leading dimension is found, returns an integer index
        * If nested leading dimensions are found, returns a tuple of indices
        * If no leading dimension is found, returns None
    """

    def pred_fn(val, pos):
        # skip dynamic values which can't be compared
        # find the candidate target val, stride at this position is 1
        if (not is_dynamic_expression(val)) and (val == 1):
            # extract the shape at this position
            mode = [pos] if isinstance(pos, int) else list(pos)
            s = get(shape, mode)
            if is_dynamic_expression(s) or s != 1:
                # shape at this position is dynamic value or not 1
                # we found the leading dimension
                return True
        return False

    return find_if(stride, pred_fn=pred_fn)


@dsl_user_op
def make_layout_tv(
    thr_layout: Layout, val_layout: Layout, *, loc=None, ip=None
) -> Tuple[Shape, Layout]:
    """Create a thread-value layout by repeating the val_layout over the thr_layout.

    This function creates a thread-value layout that maps between ``(thread_idx, value_idx)``
    coordinates and logical ``(M,N)`` coordinates. The thread and value layouts must be compact to ensure
    proper partitioning.

    This implements the thread-value partitioning pattern where data is partitioned
    across threads and values within each thread.

    :param thr_layout: Layout mapping from ``(TileM,TileN)`` coordinates to thread IDs (must be compact)
    :type thr_layout: Layout
    :param val_layout: Layout mapping from ``(ValueM,ValueN)`` coordinates to value IDs within each thread
    :type val_layout: Layout
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point, defaults to None
    :type ip: Optional[InsertionPoint], optional
    :return: A tuple containing ``tiler_mn`` and ``layout_tv``
    :rtype: Tuple[Shape, Layout]

    where:
        * ``tiler_mn`` is tiler and ``shape(tiler_mn)`` is compatible with ``shape(zipped_divide(x, tiler_mn))[0]``
        * ``layout_tv``: Thread-value layout mapping (thread_idx, value_idx) -> (M,N)

    **Example:**

    The below code creates a TV Layout that maps thread/value coordinates to the logical coordinates in a ``(4,6)`` tensor:
        - *Tiler MN*: ``(4,6)``
        - *TV Layout*: ``((3,2),(2,2)):((8,2),(4,1))``

    .. code-block:: python

        thr_layout = cute.make_layout((2, 3), stride=(3, 1))
        val_layout = cute.make_layout((2, 2), stride=(2, 1))
        tiler_mn, layout_tv = cute.make_layout_tv(thr_layout, val_layout)

    .. table:: TV Layout
       :widths: auto

       +---+-----+-----+-----+-----+-----+-----+
       |   |  0  |  1  |  2  |  3  |  4  |  5  |
       +---+-----+-----+-----+-----+-----+-----+
       |  0| T0, | T0, | T1, | T1, | T2, | T2, |
       |   | V0  | V1  | V0  | V1  | V0  | V1  |
       +---+-----+-----+-----+-----+-----+-----+
       |  1| T0, | T0, | T1, | T1, | T2, | T2, |
       |   | V2  | V3  | V2  | V3  | V2  | V3  |
       +---+-----+-----+-----+-----+-----+-----+
       |  2| T3, | T3, | T4, | T4, | T5, | T5, |
       |   | V0  | V1  | V0  | V1  | V0  | V1  |
       +---+-----+-----+-----+-----+-----+-----+
       |  3| T3, | T3, | T4, | T4, | T5, | T5, |
       |   | V2  | V3  | V2  | V3  | V2  | V3  |
       +---+-----+-----+-----+-----+-----+-----+

    """

    if not isinstance(thr_layout, Layout):
        raise TypeError(f"expected a Layout for thr_layout, but got {type(thr_layout)}")
    if not isinstance(val_layout, Layout):
        raise TypeError(f"expected a Layout for val_layout, but got {type(val_layout)}")

    # Take the raked_products to compute the Layout_MN
    # (M,N) -> (thr_idx, val_idx)
    layout_mn = raked_product(thr_layout, val_layout, loc=loc, ip=ip)
    thr_size = size(thr_layout, loc=loc, ip=ip)
    val_size = size(val_layout, loc=loc, ip=ip)
    tmp = make_layout((thr_size, val_size), loc=loc, ip=ip)
    # (thr_idx, val_idx) -> (M,N)
    layout_tv = composition(
        right_inverse(layout_mn, loc=loc, ip=ip), tmp, loc=loc, ip=ip
    )

    tiler_mn = product_each(layout_mn.shape, loc=loc, ip=ip)

    return (tiler_mn, layout_tv)


##############################################################################
# User defined struct
##############################################################################


class struct:
    """
    Decorator to abstract C structure in Python DSL.

    **Usage:**

    .. code-block:: python

        # Supports base_dsl scalar int/float elements, array and nested struct:
        @cute.struct
        class complex:
            real : cutlass.Float32
            imag : cutlass.Float32


        @cute.struct
        class StorageA:
            mbarA : cute.struct.MemRange[cutlass.Int64, stage]
            compA : complex
            intA : cutlass.Int16


        # Supports alignment for its elements:
        @cute.struct
        class StorageB:
            a: cute.struct.Align[
                cute.struct.MemRange[cutlass.Float32, size_a], 1024
            ]
            b: cute.struct.Align[
                cute.struct.MemRange[cutlass.Float32, size_b], 1024
            ]
            x: cute.struct.Align[cutlass.Int32, 16]
            compA: cute.struct.Align[complex, 16]


        # Statically get size and alignment:
        size = StorageB.__sizeof__()
        align = StorageB.__alignof__()

        # Allocate and referencing elements:
        storage = allocator.allocate(StorageB)

        storage.a[0] ...
        storage.x ...
        storage.compA.real ...

    :param cls: The struct class with annotations.
    :return: The decorated struct class.
    """

    # inner class for defining a continuous memory region
    class _MemRangeMeta(type):
        """
        A metaclass for creating MemRange classes.

        This metaclass is used to dynamically create MemRange classes with specific
        data types and sizes.

        :ivar _dtype: The data type of the MemRange.
        :ivar _size: The size of the MemRange.
        """

        _dtype = None
        _size = None

        def __new__(cls, name, bases, dct):
            new_cls = super().__new__(cls, name, bases, dct)
            return new_cls

        def __getitem__(cls, params) -> Type["struct.MemRange"]:
            # get params from syntax: struct.MemRange[dtype, size]
            if len(params) == 2:
                dtype, size = params
            else:
                raise TypeError("Invalid struct.MemRange Arguments")

            if not struct._is_scalar_type(dtype):
                raise TypeError("MemRange only support dsl scalar type!")

            # Create new class with proper name and parameters
            new_cls = type(
                f"struct.MemRange[{dtype.__name__}, {size}]",
                (struct.MemRange,),
                {"_dtype": dtype, "_size": size},
            )
            return new_cls

        @property
        def size(cls):
            return cls._size

        @property
        def elem_width(cls):
            return cls._dtype.width

        @property
        def size_in_bytes(cls):
            return cls.size * cls.elem_width // 8

    class MemRange(metaclass=_MemRangeMeta):
        """
        Defines a range of memory by `MemRange[T, size]`.
        """

        pass

    class _MemRangeData:
        """
        Represents a range of memory.

        :param dtype: The data type.
        :param size: The size of the memory range in bytes.
        :param base: The base address of the memory range.
        """

        def __init__(self, dtype, size, base):
            """
            Initializes a new memory range.

            :param dtype: The data type.
            :param size: Size of the memory range in bytes. A size of **0** is accepted, but in that
                         case the range can only be used for its address (e.g. as a partition marker).
            :param base: The base address of the memory range.
            """
            self._dtype = dtype
            self._size = size
            self._base = base

        def data_ptr(self):
            """
            Returns start pointer to the data in this memory range.

            :return: A pointer to the start of the memory range.
            :raises AssertionError: If the size of the memory range is negative.
            """
            assert self._size >= 0
            return recast_ptr(self._base, dtype=self._dtype)

        def get_tensor(self, layout, swizzle=None, dtype=None):
            """
            Creates a tensor from the memory range.

            :param layout: The layout of the tensor.
            :param swizzle: Optional swizzle pattern.
            :param dtype: Optional data type; defaults to the memory range's data type if not specified.
            :return: A tensor representing the memory range.
            :raises TypeError: If the layout is incompatible with the swizzle.
            :raises AssertionError: If the size of the memory range is not greater than zero.
            """
            from .tensor import make_tensor

            assert self._size > 0
            # make tensor
            if isinstance(layout, ComposedLayout) and (swizzle is not None):
                raise TypeError("incompatible layout with swizzle")
            elem_type = self._dtype if dtype is None else dtype
            ptr = recast_ptr(self._base, swizzle, dtype=elem_type)
            res = make_tensor(ptr, layout)
            return res

        def __getitem__(self, index: int) -> Any:
            """
            Returns the element at the specified index in the memory range.

            :param index: The index of the element to retrieve.
            :return: The element at the specified index.
            :raises AssertionError: If the index is out of range.
            """
            assert (index >= 0) and (index < self._size)
            return self.data_ptr() + index

    # inner class for aligning a member type
    class _AlignMeta(type):
        """
        Aligns the given object by setting its alignment attribute.

        :param v: The object to align. Must be a struct, MemRange, or a scalar type.
        :param align: The alignment value to set.
        :raises TypeError: If the object is not a struct, MemRange, or a scalar type.

        :ivar _dtype: The data type to be aligned.
        :ivar _align: The alignment of the data type.
        """

        _dtype = None
        _align = None

        def __new__(cls, name, bases, dct):
            return super().__new__(cls, name, bases, dct)

        def __getitem__(cls, params) -> Any:
            if len(params) == 2:
                dtype, align = params
                assert align > 0
            else:
                raise TypeError("Invalid struct.Align Arguments")

            if not struct._is_scalar_type(dtype) and not isinstance(
                dtype, (struct, struct._MemRangeMeta)
            ):
                raise TypeError(
                    "align only can be applied to struct/MemRange/base_dsl scalar"
                )

            # Create new class with alignment
            new_cls = type(
                f"struct.Align[{dtype.__name__}, {align}]",
                (struct.Align,),
                {"_dtype": dtype, "_align": align},
            )
            return new_cls

        @property
        def dtype(cls):
            return cls._dtype

        @property
        def align(cls):
            return cls._align

    class Align(metaclass=_AlignMeta):
        """
        Aligns the given type by `Align[T, alignment]`.
        """

        pass

    # util func for base dsl scalar types
    @staticmethod
    def _is_scalar_type(dtype):
        """
        Checks if the given type is a scalar numeric type.

        :param dtype: The type to check.
        :return: True if the type is a subclass of Numeric, False otherwise.
        """
        return isinstance(dtype, type) and issubclass(dtype, Numeric)

    # calculate size and alignment
    def __init__(self, cls):
        """
        Initializes a new struct decorator instance.

        :param cls: The class representing the structured data type.
        :raises TypeError: If the struct is empty.
        """
        self._cls = cls
        self.__name__ = f"struct::{cls.__name__}"
        # Get the class annotations
        self._annotations = getattr(cls, "__annotations__", {})
        # Create a dictionary to store the offsets
        self._offsets: Dict[str, int] = {}

        # Calculate the offsets and alignment
        offset = 0
        alignment = 1
        if len(self._annotations) == 0:
            raise TypeError("Empty struct is not supported!")
        for name, object in self._annotations.items():
            # get alignment of object
            sub_align = 1
            if isinstance(object, struct._AlignMeta):
                sub_align = object.align
                object = object.dtype

            # switch addition order to support dynamic size
            def add_offset(val):
                return val + offset if isinstance(val, ir.Value) else offset + val

            # size of scalar
            if struct._is_scalar_type(object):
                dtype_size = max(1, object.width // 8)
                sub_align = max(dtype_size, sub_align)
                offset = self.align_offset(offset, sub_align)
                self._offsets[name] = offset
                offset = add_offset(dtype_size)
            # size of array is size_in_bytes, alignment is elem_size
            elif isinstance(object, struct._MemRangeMeta):
                # Allow empty array as a free marker-only struct member.
                # Use max(sub_align, ) because we might have in the future some
                # object.elem_width less than 8, such as fp4, bit and others,
                # and align_offset() does not support an alignment of 0.
                sub_align = max(object.elem_width // 8, sub_align)
                offset = self.align_offset(offset, sub_align)
                self._offsets[name] = offset
                offset = add_offset(object.size_in_bytes)
            # size of struct
            elif isinstance(object, struct):
                sub_align = max(object.__alignof__(), sub_align)
                offset = self.align_offset(offset, sub_align)
                self._offsets[name] = offset
                offset = add_offset(object.__sizeof__())
            else:
                raise TypeError(
                    f"Struct element only support struct/array/base_dsl scalar, "
                    f"but got {object}"
                )
            # Total alignment determined by the strictest requirement
            alignment = max(alignment, sub_align)
        # Total size determined by alignment
        self._align_of = alignment
        self._size_of = self.align_offset(offset, alignment)

    # create the __init__ method for decorated struct
    def __call__(self, base: Any) -> None:
        """
        Creates a new instance of the decorated struct.

        :param base: The base address of the struct.
        :return: An instance of the decorated struct.
        :raises TypeError: If the base pointer is not byte-sized.
        """
        if base.type.value_type.width != 8:
            raise TypeError("struct base ptr value type must be byte sized.")
        # make an new object of user-defined decorated struct
        # otherwise it will override same self._cls when new instance created
        cls = self._cls()
        setattr(cls, "_base", base)
        for name, off in self._offsets.items():
            obj = self._annotations[name]
            if isinstance(obj, struct._AlignMeta):
                obj = obj.dtype
            if struct._is_scalar_type(obj):
                new_obj = recast_ptr(base + off, dtype=obj)
                setattr(cls, name, new_obj)
            elif isinstance(obj, struct._MemRangeMeta):
                new_obj = struct._MemRangeData(obj._dtype, obj._size, base + off)
                setattr(cls, name, new_obj)
            elif isinstance(obj, struct):
                new_obj = obj(base + off)
                setattr(cls, name, new_obj)
            else:
                raise TypeError(
                    f"Struct element only support struct/array/base_dsl scalar, "
                    f"but got {obj}"
                )
        return cls

    # get size
    def size_in_bytes(self) -> int:
        """
        Returns the size of the struct in bytes.

        :return: The size of the struct.
        """
        return self._size_of

    # get size
    def __sizeof__(self) -> int:
        return self._size_of

    # get alignment
    def __alignof__(self) -> int:
        return self._align_of

    # util func for aligning offset
    @staticmethod
    def align_offset(offset, align):
        """
        Return the round-up offset up to the next multiple of align.
        """
        assert align > 0 and not (
            align & (align - 1)
        ), "align should be a strictly positive power of 2."
        return (offset + (align - 1)) & ~(align - 1)


class union(struct):
    """
    Decorator to abstract C union in Python DSL.

    Similar to cute.struct, but lays out objects as a union:
    - All objects start at offset 0
    - The alignment is the maximum alignment of all objects
    - The size is the maximum size of all objects

    **Usage:**

    .. code-block:: python

        # Define a union with scalar int/float elements:
        @cute.union
        class value_union:
            as_int : cutlass.Int32
            as_float : cutlass.Float32


        @cute.union
        class data_union:
            small : cutlass.Int16
            medium : cutlass.Int32
            large : cutlass.Int64


        # Supports alignment for its elements:
        @cute.union
        class aligned_union:
            a: cute.struct.Align[cutlass.Float32, 16]
            b: cute.struct.Align[cutlass.Int32, 8]


        # Statically get size and alignment:
        size = data_union.__sizeof__()
        align = data_union.__alignof__()

        # Allocate and reference elements:
        allocator = cutlass.utils.SmemAllocator()
        value = allocator.allocate(data_union)

        # Access union members (all at the same offset):
        value.small ...
        value.medium ...
        value.large ...

    :param cls: The union class with annotations.
    :return: The decorated union class.
    """

    def __init__(self, cls):
        """
        Initializes a new cute.union decorator instance.

        :param cls: The class representing the union data type.
        :raises TypeError: If the union is empty.
        """
        self._cls = cls
        self.__name__ = f"cute.union::{cls.__name__}"
        # Get the class annotations
        self._annotations = getattr(cls, "__annotations__", {})
        # Create a dictionary to store the offsets (all zeros for union)
        self._offsets: Dict[str, int] = {}

        # Calculate the maximum size and alignment
        max_size = 0
        max_alignment = 1
        if len(self._annotations) == 0:
            raise TypeError("Empty union is not supported!")

        for name, object in self._annotations.items():
            # All offsets are 0 for a union
            self._offsets[name] = 0

            # Get alignment of object
            sub_align = 1
            if isinstance(object, struct._AlignMeta):
                sub_align = object.align
                object = object.dtype

            # Calculate size and alignment based on object type
            if struct._is_scalar_type(object):
                dtype_size = max(1, object.width // 8)
                sub_align = max(dtype_size, sub_align)
                max_size = max(max_size, dtype_size)
            elif isinstance(object, struct._MemRangeMeta):
                sub_align = max(object.elem_width // 8, sub_align)
                max_size = max(max_size, object.size_in_bytes)
            elif isinstance(object, struct):
                sub_align = max(object.__alignof__(), sub_align)
                max_size = max(max_size, object.__sizeof__())
            else:
                raise TypeError(
                    f"Union element only support struct/array/base_dsl scalar, "
                    f"but got {object}"
                )
            # Union alignment is the maximum alignment of all members
            max_alignment = max(max_alignment, sub_align)

        # Union size is the maximum size, aligned to the maximum alignment
        self._align_of = max_alignment
        self._size_of = struct.align_offset(max_size, max_alignment)

    def __call__(self, base: Any) -> None:
        """
        Creates a new instance of the decorated union.

        :param base: The base address of the union.
        :return: An instance of the decorated union.
        :raises TypeError: If the base pointer is not byte-sized.
        """
        if base.type.value_type.width != 8:
            raise TypeError("union base ptr value type must be byte sized.")
        # Make a new object of user-defined decorated union
        cls = self._cls()
        setattr(cls, "_base", base)
        for name, off in self._offsets.items():
            obj = self._annotations[name]
            if isinstance(obj, struct._AlignMeta):
                obj = obj.dtype
            if struct._is_scalar_type(obj):
                new_obj = recast_ptr(base + off, dtype=obj)
                setattr(cls, name, new_obj)
            elif isinstance(obj, struct._MemRangeMeta):
                new_obj = struct._MemRangeData(obj._dtype, obj._size, base + off)
                setattr(cls, name, new_obj)
            elif isinstance(obj, struct):
                new_obj = obj(base + off)
                setattr(cls, name, new_obj)
            else:
                raise TypeError(
                    f"Union element only support struct/array/base_dsl scalar, "
                    f"but got {obj}"
                )
        return cls

    def size_in_bytes(self) -> int:
        """
        Returns the size of the union in bytes.

        :return: The size of the union.
        """
        return self._size_of

    def __sizeof__(self) -> int:
        """
        Returns the size of the union in bytes.

        :return: The size of the union.
        """
        return self._size_of

    def __alignof__(self) -> int:
        """
        Returns the alignment of the union in bytes.

        :return: The alignment of the union.
        """
        return self._align_of


# Deprecated usage but keep them to avoid breaking some examples uses `cute.core.ThrMma`

from .atom import ThrCopy as _ThrCopy
from .atom import ThrMma as _ThrMma


@deprecated("cute.core.ThrMma is deprecated, use cute.ThrMma instead")
class ThrMma(_ThrMma):
    pass


@deprecated("cute.core.ThrCopy is deprecated, use cute.ThrCopy instead")
class ThrCopy(_ThrCopy):
    pass
