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

import ctypes
from abc import abstractmethod
from itertools import chain
import numpy as np
import operator
from typing import (
    TYPE_CHECKING,
    Annotated,
    Callable,
    ClassVar,
    Generic,
    Optional,
    Protocol,
    Literal,
    TypeAlias,
    Union,
    Any,
    Type,
    TypeVar,
    overload,
    runtime_checkable,
)

from .common import *
from .common import DSLRuntimeError as DSLRuntimeError
from .diagnostics import DiagId
from .._mlir_helpers import arith as arith_helper
from .._mlir_helpers.arith import ArithValue
from .._mlir_helpers.vector import Vector
from .._mlir_helpers.op import dsl_user_op

from .._mlir import ir
from .._mlir.extras import types as T
from .._mlir.dialects import arith, llvm, nvvm, vector

from .address_space import AddressSpace

# =============================================================================
# Dynamic Expression Protocol
# =============================================================================


@runtime_checkable
class DynamicExpression(Protocol):
    """Protocol defining the interface for object holding dynamic values in the DSL.

    This protocol enables classes to represent dynamic values in the DSL. Classes implementing
    this protocol can be used in JIT-compiled functions and dynamic value generation.

    It is required for custom data types to work correctly with following JIT features:
    * as function argument to call another JIT function from JIT function
    * as return value from JIT function
    * for constructions like if-else, while-loop, etc.

    :param value: The MLIR operation result value to initialize the object with
    :type value: ir.Value

    **Required Methods**

    * ``__extract_mlir_values__``: Extract MLIR values from the object
    * ``__new_from_mlir_values__``: Create new instance from MLIR values

    **Implementation Example**

    To implement a custom data type that works with the DSL:

    .. code-block:: python

        class CustomData(metaclass=DslType):
            def __init__(self, int_value):
                self.int_value = int_value

            def __extract_mlir_values__(self):
                return [self.int_value]

            def __new_from_mlir_values__(self, values):
                return CustomData(values[0])

    **Usage in JIT Functions**

    When used in JIT-compiled functions, the DSL automatically extracts MLIR values:

    .. code-block:: python

        @jit
        def caller():
            x = CustomData(1)
            return foo(x)

    This generates MLIR like:

    .. code-block:: mlir

        func @caller() -> i32 {
            %0 = func.call @foo(%arg0) : (i32) -> i32
            return %0 : i32
        }
    """

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Extract MLIR values from this object.

        :return: List of MLIR values representing this object's data
        :rtype: List[ir.Value]
        """
        raise NotImplementedError

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "DynamicExpression":
        """Create a new instance from MLIR values.

        :param values: List of MLIR values to construct the object from
        :type values: List[ir.Value]
        :return: New instance of the implementing class
        :rtype: Any
        """
        raise NotImplementedError


@runtime_checkable
class JitArgument(Protocol):
    """
    Protocol class defining the interface for JIT function argument generation.

    This protocol enables classes to provide the necessary information for generating
    JIT function arguments and allow the DSL JIT executor to call JIT compiled functions.

    **Required Methods**

    * ``__c_pointers__``: Returns ctypes pointers for runtime execution
    * ``__get_mlir_types__``: Returns MLIR types for function definition
    * ``__new_from_mlir_values__``: Creates new instances from MLIR values

    **Example**

    .. code-block:: python

        class CustomData:
            def __init__(self, int_value, ...):
                self.int_value = int_value
                ...

            def __c_pointers__(self):
                return [ctypes.pointer(ctypes.c_int32(self.int_value)), ...]

            def __get_mlir_types__(self):
                return [ir.IntegerType.get(32), ...]

            def __new_from_mlir_values__(self, values):
                return CustomData(values[0], ...)

        @jit
        def foo(x: CustomData):
            a = x.int_value + 1
            ...

        # `CustomData` is an argument of `foo`
        foo(CustomData(1, ...))

    When called like ``y = foo(x)``, the following steps occur:

    1. JIT compiler generates MLIR function definition using ``__get_mlir_types__``

    .. code-block:: mlir

        func.func @foo(%arg0: i32, ...) {
            ...

            return
        }

    2. JIT function can't use values from Python, so it needs to reconstruct the object from
    MLIR values, a.k.a `%arg0`, with ``__new_from_mlir_values__`` and pass it to `foo`.

    Following code demonstrates how JIT compiler reconstructs the object and pass to Python.

    .. code-block:: python

        # Implementation of IR tracing
        new_x = CustomData(ir.Value(%arg0), ...)
        y = foo(new_x)
        # `x.int_value` is %arg0 rather than `c1` defined by Python.

    3. For Python runtime execution, JIT engine invokes compiled function using ``__c_pointers__``
    pointing to the underlying data object passing to JIT compiled function.

    .. code-block:: python

        jit_engine.invoke(compiled_foo, concat([x.__c_pointers__(), ...]))
    """

    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        """
        Generate a list of ctypes pointers for the current object.

        :return: List of ctypes pointers
        :rtype: List[ctypes.c_void_p]
        """
        raise NotImplementedError

    def __get_mlir_types__(self) -> list[ir.Type]:
        """
        Generate a list of MLIR types for the current object.

        :return: List of MLIR types
        :rtype: List[ir.Type]
        """
        raise NotImplementedError

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "JitArgument":
        """
        Create a new object from MLIR values.

        :param values: List of MLIR values
        :type values: List[ir.Value]
        :return: A new object that represents the given MLIR values
        :rtype: Any
        """
        raise NotImplementedError


def get_c_pointers(obj: Any) -> list[ctypes.c_void_p]:
    """
    Given the `obj`, recursively go through it to extract all contained C pointers
    """
    if hasattr(obj, "__c_pointers__"):
        return obj.__c_pointers__()
    elif isinstance(obj, (tuple, list)):
        return list(chain.from_iterable(get_c_pointers(x) for x in obj))
    elif isinstance(obj, set):
        raise DSLUserCodeError(
            DiagId.ARG_UNORDERED_CONTAINER,
        )
    return []


def get_mlir_types(obj: Any) -> list[ir.Type]:
    """
    Given the `obj`, recursively go through it to extract all contained MLIR types
    """
    if hasattr(obj, "__get_mlir_types__"):
        return obj.__get_mlir_types__()
    elif hasattr(obj, "__extract_mlir_values__"):
        return [v.type for v in obj.__extract_mlir_values__()]
    elif isinstance(obj, ir.Value):
        return [obj.type]
    elif isinstance(obj, (tuple, list)):
        return sum((get_mlir_types(x) for x in obj), [])
    elif isinstance(obj, set):
        raise DSLUserCodeError(
            DiagId.ARG_UNORDERED_CONTAINER,
        )
    return []



def implements_jit_argument(obj: Any, *, partial: bool = False) -> bool:
    """
    Check if the object implements the JitArgument protocol.
    When partial=True, returns True if any protocol method is present.
    """
    check = any if partial else all
    return check(
        hasattr(obj, attr)
        for attr in ("__c_pointers__", "__get_mlir_types__", "__new_from_mlir_values__")
    )


def implements_dynamic_expression(obj: Any, *, partial: bool = False) -> bool:
    """
    Check if the object implements the DynamicExpression protocol.
    When partial=True, returns True if any protocol method is present.
    """
    check = any if partial else all
    return check(
        hasattr(obj, attr)
        for attr in ("__extract_mlir_values__", "__new_from_mlir_values__")
    )


class DslType(type):
    """Metaclass for all DSL types in the system.

    This metaclass provides type system infrastructure for DSL types, handling MLIR
    type mappings and NumPy type conversions.

    All data types in DSL must provide the following methods:

    :param mlir_type: Corresponding MLIR type for this DSL type
    :type mlir_type: Any, optional
    :param is_abstract: Whether this type is abstract, defaults to False
    :type is_abstract: bool, optional

    **Required Methods**

    * ``__str__`` (classmethod): Return string representation of the type
    * ``__c_pointers__`` (optional): Return list of ctypes pointers of data used to invoke JIT function
    * ``__get_mlir_types__``: Return list of MLIR types of the MLIR values contained in the instance
    * ``__extract_mlir_values__``: Return list of MLIR values contained in the instance
    * ``__new_from_mlir_values__``: Return a new instance from list of MLIR values

    **Attributes**

    :ivar _ir: MLIR provider
    :vartype _ir: Any
    :ivar _T: MLIR Type system provider
    :vartype _T: Any

    **Properties**

    :property mlir_type: Returns the corresponding MLIR type for this DSL type
    :type mlir_type: Any

    """

    _is_abstract: bool

    def __new__(
        cls,
        name: str,
        bases: tuple,
        attrs: dict,
        is_abstract: bool = False,
        **kwargs: Any,
    ) -> Any:
        new_cls = super().__new__(cls, name, bases, attrs)

        new_cls._is_abstract = is_abstract

        return new_cls

    @property
    def is_abstract(cls) -> bool:
        return cls._is_abstract


class NumericMeta(DslType):
    """Metaclass for numeric types providing width and numpy dtype information.

    :param width: Bit width of one storage unit, defaults to 8.
        For unpacked dtypes this is the element width. Packed view dtypes
        use the width of one packed tensor element.
    :type width: int
    :param np_dtype: Corresponding NumPy dtype
    :type np_dtype: numpy.dtype, optional
    :param mlir_type: Corresponding MLIR type
    :type mlir_type: Any, optional
    :param is_abstract: Whether the type is abstract, defaults to False
    :type is_abstract: bool, optional
    :ivar width: Bit width of the numeric type
    :type width: int
    :ivar _np_dtype: Corresponding NumPy dtype
    :type _np_dtype: Union[numpy.dtype, None]

    :property numpy_dtype: Returns the corresponding NumPy dtype
    :rtype numpy_dtype: numpy.dtype
    """

    width: int
    bytes: int

    # Placeholder type
    _mlir_type = Any
    _np_dtype: Optional[type]

    def __new__(
        cls,
        name: str,
        bases: tuple,
        attrs: dict,
        width: int = 8,
        np_dtype: Optional[type] = None,
        mlir_type: Optional[Callable[[], ir.Type]] = None,
        is_abstract: bool = False,
        **kwargs: Any,
    ) -> Any:
        def _extract_mlir_values(self: "Numeric") -> list[ir.Value]:
            return [self.ir_value()]

        def _new_from_mlir_values(self: "Numeric", values: list[ir.Value]) -> "Numeric":
            res_ty = type(self)
            return res_ty(values[0])

        new_attrs = {
            "__extract_mlir_values__": _extract_mlir_values,
            "__new_from_mlir_values__": _new_from_mlir_values,
        }
        new_cls = super().__new__(
            cls,
            name,
            bases,
            new_attrs | attrs,
            is_abstract=is_abstract,
            **kwargs,
        )

        if mlir_type is not None:
            new_cls._mlir_type = staticmethod(mlir_type)

        new_cls.width = width
        new_cls.bytes = max(1, (width + 7) // 8)
        new_cls._np_dtype = np_dtype
        return new_cls

    def n_bytes(cls, n_elements: int) -> int:
        """Return the storage byte count for ``n_elements`` dtype elements."""

        return n_elements * cls.bytes

    @property
    def numpy_dtype(cls) -> Optional[type]:
        return cls._np_dtype

    @property
    @abstractmethod
    def is_integer(cls) -> bool: ...

    @property
    @abstractmethod
    def is_float(cls) -> bool: ...

    @property
    @abstractmethod
    def zero(cls) -> Union[int, float]: ...

    def is_same_kind(cls, other: Type) -> bool:
        return cls.is_integer == other.is_integer or cls.is_float == other.is_float

    def isinstance(cls, value: Any) -> bool:
        """
        Check if the value is an compatible type with the numeric type.

        :param value: The value to check
        :type value: Any
        :return: True if the value is a compatible type with the numeric type, False otherwise
        :rtype: bool
        """
        if isinstance(value, Numeric):
            return value.dtype is cls
        elif isinstance(value, arith_helper.ArithValue):
            elem_ty = arith_helper.element_type(value.type)
            return Numeric.from_mlir_type(elem_ty) is cls
        elif isinstance(value, int):
            return cls.is_integer
        elif isinstance(value, float):
            return cls.is_float
        elif isinstance(value, bool):
            return cls.is_integer
        else:
            return False

    @staticmethod
    def from_python(value: Union[bool, int, float]) -> Type["Numeric"]:
        """
        Deduce the DSL type from a Python value.
        """
        if isinstance(value, int):
            return Int32
        elif isinstance(value, float):
            return Float32
        elif isinstance(value, bool):
            return Boolean
        raise DSLRuntimeError(
            f"Could not deduce Type[Numeric] from python value: {value} :{type(value)}"
        )

    @property
    def mlir_type(cls) -> ir.Type:
        return cls._mlir_type()


Value = TypeVar("Value")


def cast(
    obj: Union[bool, int, float, Value, "Numeric"], type_: Type["Numeric"]
) -> "Numeric":
    """Cast an object to the specified numeric type.

    :param obj: Object to be cast
    :type obj: Union[bool, int, float, Value, Numeric]
    :param type_: Target numeric type
    :type type_: Type[Numeric]
    :raises TypeError: If casting to an abstract type or unsupported type conversion
    :return: Object cast to the target numeric type
    :rtype: Numeric

    Example::
        >>> x = cast(5, Int32)  # Cast integer to Int32
        >>> y = cast(3.14, Float32)  # Cast float to Float32
    """
    res: "Numeric"
    if type_.is_abstract:
        if not isinstance(obj, type_):
            raise TypeError(
                f"can't cast {obj} to {type_}. Pass in concrete type instead, "
                "e.g. Int32, Float32, etc."
            )
        # If target_type is abstract, and value is instance of target_type,
        # then we can return value as is
        res = obj
    else:
        # Implicit cast based on using annotation type
        res = type_(obj)  # type: ignore[arg-type]
    return res


# Option 1: use ir.Value as base
# class IntegerMeta(DslType, type(ir.Value)):
class IntegerMeta(NumericMeta):
    """Metaclass for integer types providing signedness information.

    :param width: Bit width of the integer type, defaults to 32
    :type width: int
    :param signed: Whether the integer type is signed, defaults to True
    :type signed: bool
    :param mlir_type: Corresponding MLIR type, defaults to None
    :type mlir_type: Any, optional

    :ivar signed: Whether the integer type is signed
    :vartype signed: bool
    :ivar arith: Arithmetic operations interface
    :vartype arith: Any
    """

    signed: bool

    def __new__(
        cls,
        name: str,
        bases: tuple,
        attrs: dict,
        width: int = 32,
        signed: bool = True,
        mlir_type: Optional[Callable[[], ir.Type]] = None,
        is_abstract: bool = False,
    ) -> Any:
        if width == 1:
            np_dtype = np.bool_
        elif width == 128:
            np_dtype = None
        elif width == 4:
            np_dtype = None
        elif signed:
            np_dtype = getattr(np, f"int{width}")
        else:
            np_dtype = getattr(np, f"uint{width}")

        def _c_pointers(self: "Integer") -> list[ctypes.c_void_p]:
            if width == 1:
                c_value = ctypes.c_bool(self.value)  # type: ignore[arg-type]
            elif signed:
                c_value = getattr(ctypes, f"c_int{width}")(self.value)
            else:
                c_value = getattr(ctypes, f"c_uint{width}")(self.value)

            return [ctypes.cast(ctypes.pointer(c_value), ctypes.c_void_p)]

        new_attrs = {
            "__c_pointers__": _c_pointers,
        }
        new_cls = super().__new__(
            cls, name, bases, attrs | new_attrs, width, np_dtype, mlir_type, is_abstract
        )
        new_cls.signed = signed
        return new_cls

    def __str__(cls) -> str:
        return f"{cls.__name__}"

    @property
    def is_integer(cls) -> bool:
        return True

    @property
    def is_float(cls) -> bool:
        return False

    @property
    def zero(cls) -> int:
        return 0

    @property
    def min(cls) -> int:
        if cls.signed:
            return -(2 ** (cls.width - 1))
        else:
            return 0

    @property
    def max(cls) -> int:
        if cls.signed:
            return 2 ** (cls.width - 1) - 1
        else:
            return 2**cls.width - 1

    def recast_width(cls, width: int) -> Type["Integer"]:
        type_map = {
            8: Int8,
            16: Int16,
            32: Int32,
            64: Int64,
            128: Int128,
        }
        if width not in type_map:
            raise TypeError(f"Unsupported width: {width}")
        return type_map[width]


class FloatMeta(NumericMeta):
    """Metaclass for floating-point types.

    This metaclass provides type system infrastructure for floating-point types in the DSL,
    handling MLIR type mappings and NumPy type conversions.

    :param width: Bit width of one storage unit, defaults to 32. Packed view
        dtypes may use a wider storage-unit width here than their logical
        floating-point element width.
    :type width: int
    :param mlir_type: Corresponding MLIR type, defaults to None
    :type mlir_type: Any, optional
    :param is_abstract: Whether this is an abstract base class, defaults to False
    :type is_abstract: bool, optional

    :ivar _arith: Arithmetic operations interface
    :vartype _arith: Any
    """

    _exponent_width: int
    _mantissa_width: int

    def __new__(
        cls,
        name: str,
        bases: tuple,
        attrs: dict,
        width: int = 32,
        mlir_type: Optional[Callable[[], ir.Type]] = None,
        is_abstract: bool = False,
    ) -> Any:
        np_dtype = getattr(np, name.lower(), None)
        new_cls = super().__new__(
            cls,
            name,
            bases,
            attrs,
            width,
            np_dtype,
            mlir_type,
            is_abstract,
        )
        # Extract exponent and mantissa bits from class name if it follows Float<E><M> pattern
        # For example: Float8E4M3 -> exponent_width=4, mantissa_width=3
        import re

        if not is_abstract:
            match = re.match(r"Float(\d+)E(\d+)M(\d+)(?:.*)", name)
            if match:
                exp_bits = int(match.group(2))
                mant_bits = int(match.group(3))

                # Store extracted values as class attributes
                new_cls._exponent_width = exp_bits
                new_cls._mantissa_width = mant_bits
        # Don't have 1-to-1 mapping of narrow precision types like bfloat16, tfloat32, etc.
        return new_cls

    def __str__(cls) -> str:
        return f"{cls.__name__}"

    @property
    def is_integer(cls) -> bool:
        return False

    @property
    def is_float(cls) -> bool:
        return True

    @property
    def zero(cls) -> float:
        return 0.0

    @property
    def inf(cls) -> float:
        return float("inf")

    @property
    def nan(cls) -> float:
        return float("nan")

    @property
    def exponent_width(cls) -> int:
        return cls._exponent_width

    @property
    def mantissa_width(cls) -> int:
        return cls._mantissa_width

    def recast_width(cls, width: int) -> Type["Float"]:
        type_map = {
            16: Float16,
            32: Float32,
            64: Float64,
        }
        if width not in type_map:
            raise TypeError(f"Unsupported width: {width}")
        return type_map[width]


def _arith_signless_to_int(a: ir.Value, target_type: "IntegerMeta") -> ir.Value:
    # is_signed: sign of result type
    if target_type.width > a.type.width:
        # arith dialect consider `1` in `i1` as `-1`, treat it as unsigned for DSL
        if target_type.signed and a.type.width > 1:
            return arith.extsi(target_type.mlir_type, a)
        else:
            return arith.extui(target_type.mlir_type, a)
    elif target_type.width < a.type.width:
        return arith.trunci(target_type.mlir_type, a)
    else:
        return a


def _binary_op_type_promote(
    a: "Numeric", b: "Numeric", promote_bool: bool = False
) -> tuple["Numeric", "Numeric", Type["Numeric"]]:
    """Promote two numeric operands following type promotion rules.

    :param a: First numeric operand
    :type a: Numeric
    :param b: Second numeric operand
    :type b: Numeric
    :param promote_bool: Whether to promote boolean types to Int32 for arithmetic operations, defaults to False
    :type promote_bool: bool, optional
    :raises ValueError: If implicit float promotion is not supported between the given types
    :return: Tuple containing promoted operands and their resulting type
    :rtype: tuple[Numeric, Numeric, Type[Numeric]]

    Type promotion rules:
    1. If operands are same type and not bools needing promotion:
       - No promotion needed, return original types
    2. If either operand is float:
       a. If one is float and one is int:
          - Convert int to the float type
       b. If both are float:
          - Promote to higher precision float if width >= 16
          - For same width, promote to more general type (Float32 over TFloat32)
          - Otherwise raise ValueError for unsupported promotion
    3. Otherwise, both operands are integers. Integer promotion rules:
       a. If promote_bool is True and either operand is bool:
          - Promote bool to Int32 for arithmetic operations

    Exceptions for numpy dtype casting:
    - array(dtype=np.bool_) + array(dtype=np.bool_) -> array(dtype=np.bool_)

    What is not supported:
    - promotion with narrow precision float types which requires explicit cast by user
    """
    a_type = a.dtype
    b_type = b.dtype

    # Early return for same types (except when they're bools that need promotion)
    if a_type == b_type and not (promote_bool and a_type is Boolean):
        return a, b, a_type

    # Handle floating point promotions
    if a_type.is_float or b_type.is_float:
        # Get highest precision float type based on bitwidth
        a_width = getattr(a_type, "width", 0)
        b_width = getattr(b_type, "width", 0)

        # If one type is integer, convert it to the float type
        if a_type.is_float and not b_type.is_float:
            b_type = a_type.recast_width(max(a_width, b_width))  # type: ignore[attr-defined]
        elif b_type.is_float and not a_type.is_float:
            a_type = b_type.recast_width(max(a_width, b_width))  # type: ignore[attr-defined]

        # Both are float types - handle precision promotion
        if a_width > b_width and a_width >= 16:
            res_type = a_type
        elif b_width > a_width and b_width >= 16:
            res_type = b_type
        elif a_width == b_width:
            # Same bitwidth - handle special cases like TFloat32 -> Float32 and BFloat16 -> Float16
            if a_type is Float64 or b_type is Float64:
                res_type = Float64
            elif a_type is Float32 or b_type is Float32:
                res_type = Float32
            elif a_type is Float16 or b_type is Float16:
                res_type = Float16
            else:
                raise ValueError(
                    f"implicit float promotion of {a_type} or {b_type} is not supported, cast explicitly"
                )
        else:
            raise ValueError(
                f"implicit float promotion of {a_type} or {b_type} is not supported, cast explicitly"
            )

        # Only convert if type is different
        new_a = a.to(res_type) if a.dtype != res_type else a
        new_b = b.to(res_type) if b.dtype != res_type else b
        return new_a, new_b, res_type

    # Handle bool promotion for arithmetic operations
    if promote_bool:
        if a_type is Boolean and b_type is Boolean:
            # Only promote to Int32 when both are bool
            a = a.to(Int32)
            b = b.to(Int32)
            a_type = b_type = a.dtype

        # If both were bools, they're now same type (Int32)
        if a_type == b_type:
            return a, b, a_type

    # Same type, no promotion needed
    if a_type == b_type:
        return a, b, a_type

    # At this point both must be Integer subclasses (float branch above already returned).
    assert issubclass(a_type, Integer) and issubclass(b_type, Integer)
    a_signed = a_type.signed
    b_signed = b_type.signed
    a_width = a_type.width
    b_width = b_type.width

    # Mixed signedness case
    if a_signed != b_signed:
        unsigned_type = a_type if not a_signed else b_type
        signed_type = a_type if a_signed else b_type
        unsigned_width = a_width if not a_signed else b_width

        if unsigned_width >= signed_type.width:
            # Promote both to unsigned of larger width
            res_type = unsigned_type
        else:
            # Promote both to signed of larger width
            res_type = signed_type

        new_a = a.to(res_type) if a.dtype != res_type else a
        new_b = b.to(res_type) if b.dtype != res_type else b
        return new_a, new_b, res_type

    # Same signedness, different width - promote to larger width
    if a_width >= b_width:
        return a, b.to(a.dtype), a.dtype
    else:
        return a.to(b.dtype), b, b.dtype


def _binary_op(
    op: Callable[..., Any],
    promote_operand: bool = True,
    promote_bool: bool = False,
    flip: bool = False,
) -> Callable[..., Any]:
    """Wrapper for binary operations on Numeric types.

    This wrapper handles type promotion, operation execution, and result type determination
    for binary operations between Numeric types.

    :param op: The binary operation to perform (e.g., operator.add, operator.sub)
    :type op: callable
    :param emitter: Function that emits the MLIR operation for dynamic values
    :type emitter: callable
    :param promote_operand: Whether to promote operands to the same type, defaults to True
    :type promote_operand: bool, optional
    :param promote_bool: Whether to promote boolean results to Boolean type, defaults to False
    :type promote_bool: bool, optional
    :param flip: Whether to flip the operands when calling the operation, defaults to False
    :type flip: bool, optional

    :raises TypeError: When an unsupported operation is attempted on specific numeric types

    .. note::
        Not all operations are supported for all numeric types. In particular:

        - Subtraction is not fully supported for Integer types
        - Multiplication, floor division, and modulo operations may have limited support
        - Division (truediv) with integer types is not fully supported and converts to Float32
    """

    def wrapper(
        lhs: "Numeric",
        rhs: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        orig_lhs_type = type(lhs)
        orig_rhs_type = type(rhs)

        # When called directly with self and other
        ty = type(lhs)
        # Canonicalize to Numeric type for promotion
        if not isinstance(rhs, Numeric):
            if not isinstance(rhs, (ArithValue, int, float, bool)):
                # This allows rhs class to implement __rmul__
                return NotImplemented

            if isinstance(rhs, ArithValue):
                if isinstance(rhs.type, ir.VectorType):
                    return NotImplemented

            rhs = as_numeric(rhs)

        # default result type to left-hand-side
        res_type = ty

        if promote_operand:
            lhs, rhs, res_type = _binary_op_type_promote(lhs, rhs, promote_bool)
        else:
            rhs = ty(rhs)  # type: ignore[arg-type]

        if op in (
            operator.lt,
            operator.le,
            operator.gt,
            operator.ge,
            operator.eq,
            operator.ne,
        ):
            res_type = Boolean
        elif op == operator.truediv and isinstance(lhs, Integer):
            res_type = Float32
        elif promote_bool and orig_lhs_type == Boolean and orig_rhs_type == Boolean:
            res_type = Boolean

        lhs_val: Union[bool, int, float, ir.Value, ArithValue]
        if isinstance(lhs.value, ArithValue) and isinstance(lhs, Integer):
            lhs_val = lhs.value.with_signedness(lhs.signed)
        else:
            lhs_val = lhs.value

        rhs_val: Union[bool, int, float, ir.Value, ArithValue]
        if isinstance(rhs.value, ArithValue) and isinstance(rhs, Integer):
            rhs_val = rhs.value.with_signedness(rhs.signed)
        else:
            rhs_val = rhs.value

        if flip:
            lhs_val, rhs_val = rhs_val, lhs_val

        res_val = op(lhs_val, rhs_val)
        return res_type(res_val, loc=loc, ip=ip)

    return wrapper


class Numeric(metaclass=NumericMeta, is_abstract=True):
    """Base class for all numeric types in the DSL.

    This class provides the foundation for both Integer and Float types,
    implementing basic arithmetic operations.

    :param value: The value to store in the numeric type
    :type value: Union[bool, int, float, Value]

    :ivar value: The stored numeric value
    :vartype value: Union[bool, int, float, Value]
    """

    # Injected by NumericMeta.__new__ on every concrete subclass.
    width: ClassVar[int]
    bytes: ClassVar[int]
    _np_dtype: ClassVar[Optional[type]]

    def __init__(
        self,
        value: Union[bool, int, float, Value],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.value = value

    def __str__(self) -> str:
        # Use member's pretty-str method if member object has method.
        # This can be extended in future to have better support for IDE, jupyter notebook, etc.
        pretty_str = getattr(self.value, "pretty_str", None)
        if pretty_str is not None:
            return pretty_str()
        else:
            return "?"

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}({repr(self.value)})"

    def __hash__(self) -> int:
        return hash(type(self).__class__) ^ hash(self.value)

    @property
    def dtype(self) -> Type["Numeric"]:
        return type(self)

    @overload
    def to(
        self,
        dtype: Type["Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric": ...

    @overload
    def to(
        self,
        dtype: Type[bool],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> bool: ...

    @overload
    def to(
        self,
        dtype: Type[int],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> int: ...

    @overload
    def to(
        self,
        dtype: Type[float],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> float: ...

    @overload
    def to(
        self,
        dtype: Type[ir.Value],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value: ...

    def to(
        self,
        dtype: Type,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Any:
        """Convert this numeric value to another numeric type.

        If the target type is the same as the current type, returns self.
        Otherwise, creates a new instance of the target type with the same value.

        :param dtype: The target numeric type to convert to
        :type dtype: Union[Type["Numeric"], Type[int], Type[float], Type[bool]]
        :return: A new instance of the target type, or self if types match
        :rtype: Numeric
        :raises TypeError: If trying to convert an MLIR value to a static Python type
        :raises TypeError: If trying to convert to unsupported float types like Float8E4M3,
                          Float8E4M3B11FNUZ, Float4E2M1FN, Float6E3M2FN, or Float6E2M3FN

        .. note::

            Unsupported destination float types:
                - Float8E4M3
                - Float8E4M3B11FNUZ
                - Float4E2M1FN
                - Float6E3M2FN
                - Float6E2M3FN

        Example::

            .. code-block:: python

                # Convert between DSL numeric types
                x = Int32(5)
                y = x.to(Float32)  # Converts to Float32(5.0)

                # Convert to Python primitive types
                # They are considered as static values at JIT time
                z = x.to(int)      # Returns Python int 5
                w = y.to(float)    # Returns Python float 5.0

                # This will raise a ValueError
                mlir_val = arith.constant(T.i32(), 42)
                num = Int32(mlir_val)
                num.to(int)        # ValueError: unable to convert MLIR value to static type: <class 'int'>
        """
        if dtype in _unsupported_dst_float_types:
            raise TypeError(f"Unsupported destination float type: {dtype}")

        if isinstance(dtype, type(self)):
            return self
        elif isinstance(dtype, NumericMeta):
            return dtype(self)
        elif dtype is ir.Value:
            if isinstance(self.value, (int, float, bool)):
                res = arith_helper.const(self.value, type(self), loc=loc, ip=ip)
            elif isinstance(self.value, ir.Value):
                res = self.value
            else:
                raise ValueError(
                    f"cannot convert {type(self)} to {dtype}, "
                    f"self.value is {self.value.type}"  # type: ignore[attr-defined]
                )

            if not isinstance(res, ArithValue):
                raise ValueError(f"Expected ArithValue, got {type(res)} as {res.type}")

            return res.with_signedness(getattr(type(self), "signed", None))
        elif dtype in (int, float, bool):
            if isinstance(self.value, ir.Value):
                raise ValueError(
                    f"unable to convert {self.value} to static type: {dtype}"
                )
            return dtype(self.value)
        else:
            raise ValueError(f"unable to convert {type(self)} to {dtype}")

    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        return self.to(ir.Value, loc=loc, ip=ip)

    def bitcast(
        self,
        dtype: "Type[Numeric]",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        """Reinterpret the bits of this value as a different numeric type.

        The source and target types must have the same bit width.

        :param dtype: Target DSL type (e.g., ``Float32`` when self is ``Int32``).
        :return: A new instance of ``dtype`` with the same bit pattern.
        """
        if not isinstance(dtype, NumericMeta):
            raise TypeError(f"dtype must be a Numeric type, but got {dtype}")
        if dtype is type(self):
            return self
        ir_val = self.ir_value(loc=loc, ip=ip)
        result = arith.bitcast(dtype.mlir_type, ir_val, loc=loc, ip=ip)
        return dtype(result)

    def __dsl_not__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Union[bool, "Boolean"]:
        """DSL implementation of Python's `not` operator.

        Returns True if the value is equal to zero, False otherwise.
        This matches Python's behavior where any non-zero number is considered True.

        :param loc: The source location information, defaults to None
        :type loc: Optional[Location]
        :param ip: The insertion point for the operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: The result of the logical not operation
        :rtype: Boolean
        """
        if isinstance(self.value, (int, float, bool)):
            return not self.value
        else:
            ty = type(self)
            zero_val = arith.constant(ty.mlir_type, ty.zero)
            return self.__eq__(ty(zero_val), loc=loc, ip=ip)

    def __dsl_and__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        """DSL implementation of Python's `and` operator.

        Returns the second operand if the first is truthy, otherwise returns the first operand.
        A numeric value is considered truthy if it is non-zero.

        :param other: The right-hand operand
        :type other: Numeric
        :param loc: The source location information, defaults to None
        :type loc: Optional[Location]
        :param ip: The insertion point for the operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: The result of the logical and operation
        :rtype: Boolean

        Example::

            5 and 3 -> 3
            0 and 3 -> 0
            3 and 0 and ... -> 0
        """
        # Fast path: Boolean & Boolean → single arith.andi i1 instruction.
        # The general path promotes i1 operands to i32 via arith.extui, performs
        # arith.select, then converts back to i1 via arith.cmpi ne — generating
        # 6 unnecessary MLIR operations.  For Boolean inputs the semantics of
        # `and` are identical to bitwise AND, so delegate directly to __and__.
        if isinstance(self, Boolean) and isinstance(other, Boolean):
            return self.__and__(other, loc=loc, ip=ip)  # type: ignore[call-arg]

        is_true = self.__dsl_bool__(loc=loc, ip=ip)

        def and_op(
            lhs: Union[bool, int, float, ir.Value],
            rhs: Union[bool, int, float, ir.Value],
        ) -> Union[bool, int, float, ir.Value]:
            if isinstance(lhs, (int, float, bool)):
                if isinstance(rhs, (int, float, bool)):
                    return lhs and rhs
                else:
                    lhs = arith.constant(rhs.type, lhs)
                    return arith.select(is_true.ir_value(), rhs, lhs, loc=loc, ip=ip)
            else:
                if isinstance(rhs, (int, float, bool)):
                    rhs = arith.constant(lhs.type, rhs)
                    return arith.select(is_true.ir_value(), rhs, lhs, loc=loc, ip=ip)
                else:
                    return arith.select(is_true.ir_value(), rhs, lhs, loc=loc, ip=ip)

        return _binary_op(and_op, promote_bool=True)(self, other, loc=loc, ip=ip)

    def __dsl_or__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        """DSL implementation of Python's `or` operator.

        Returns the first operand if it is truthy, otherwise returns the second operand.
        A numeric value is considered truthy if it is non-zero.

        :param other: The right-hand operand
        :type other: Numeric
        :param loc: The source location information, defaults to None
        :type loc: Optional[Location]
        :param ip: The insertion point for the operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: The result of the logical or operation
        :rtype: Boolean

        Example::

            5 or 3 -> 5
            0 or 3 -> 3
            3 or 0 -> 3
        """
        is_true = self.__dsl_bool__(loc=loc, ip=ip)

        def or_op(
            lhs: Union[bool, int, float, ir.Value],
            rhs: Union[bool, int, float, ir.Value],
        ) -> Union[bool, int, float, ir.Value]:
            if isinstance(lhs, (int, float, bool)):
                if isinstance(rhs, (int, float, bool)):
                    return lhs or rhs
                else:
                    lhs = arith.constant(rhs.type, lhs)
                    return arith.select(is_true.ir_value(), lhs, rhs, loc=loc, ip=ip)
            else:
                if isinstance(rhs, (int, float, bool)):
                    rhs = arith.constant(lhs.type, rhs)
                    return arith.select(is_true.ir_value(), lhs, rhs, loc=loc, ip=ip)
                else:
                    return arith.select(is_true.ir_value(), lhs, rhs, loc=loc, ip=ip)

        return _binary_op(or_op, promote_bool=True)(self, other, loc=loc, ip=ip)

    def __dsl_bool__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        """DSL implementation of Python's __bool__ method.

        Returns a Boolean indicating whether this value is considered truthy.
        For numeric types, returns True if the value is non-zero.

        :param loc: The source location information, defaults to None
        :type loc: Optional[Location]
        :param ip: The insertion point for the operation, defaults to None
        :type ip: Optional[InsertionPoint]
        :return: True if this value is truthy (non-zero), False otherwise
        :rtype: Boolean
        """
        zero = type(self).zero
        return self.__ne__(zero, loc=loc, ip=ip)

    def __bool__(self) -> bool:
        if isinstance(self.value, (int, float, bool)):
            return bool(self.value)
        else:
            raise DSLUserCodeError(DiagId.PHASE_DYNAMIC_TO_STATIC_BOOL)

    def __index__(self) -> int:
        if isinstance(self.value, (int, float, bool)):
            return self.value  # type: ignore[return-value]
        else:
            raise DSLUserCodeError(DiagId.PHASE_DYNAMIC_INDEX)

    def __neg__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        if isinstance(self.value, (bool, int, float)):
            return type(self)(-self.value)
        else:
            return type(self)(-self.value, loc=loc, ip=ip)  # type: ignore[operator]

    def __abs__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        if isinstance(self.value, (bool, int, float)):
            return type(self)(abs(self.value))
        else:
            return type(self)(abs(self.value), loc=loc, ip=ip)  # type: ignore[arg-type]

    @staticmethod
    def _from_python_value(
        value: Union[bool, int, float, ArithValue, "Numeric"],
    ) -> "Numeric":
        if isinstance(value, Numeric):
            return value

        if isinstance(value, bool):
            res_type: Type["Numeric"] = Boolean
        elif isinstance(value, int):
            res_type = (
                Int32 if (value <= 2147483647) and (value >= -2147483648) else Int64
            )
        elif isinstance(value, float):
            res_type = Float32
        elif isinstance(value, ArithValue):
            res_type = Numeric.from_mlir_type(value.type)
        else:
            raise ValueError(
                f"unable to convert {value} in type {type(value)} to Numeric"
            )
        return res_type(value)

    @dsl_user_op
    def __add__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.add, promote_bool=True)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __sub__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.sub, promote_bool=True)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __mul__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.mul, promote_bool=True)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __floordiv__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.floordiv, promote_bool=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __truediv__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.truediv, promote_bool=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __mod__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.mod, promote_bool=True)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __radd__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return self.__add__(other, loc=loc, ip=ip)

    @dsl_user_op
    def __rsub__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.sub, promote_bool=True, flip=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __rmul__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return self.__mul__(other, loc=loc, ip=ip)

    @dsl_user_op
    def __rfloordiv__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.floordiv, promote_bool=True, flip=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __rtruediv__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.truediv, promote_bool=True, flip=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __rmod__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.mod, promote_bool=True, flip=True)(
            self, other, loc=loc, ip=ip
        )

    @dsl_user_op
    def __eq__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.eq)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __ne__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.ne)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __lt__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.lt)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __le__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.le)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __gt__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.gt)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __ge__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Boolean":
        return _binary_op(operator.ge)(self, other, loc=loc, ip=ip)

    @dsl_user_op
    def __pow__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.pow)(self, other, loc=loc, ip=ip)

    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        raise ValueError(
            f"only support built-in types: bool, (u)int{8, 16, 32, 64}, float{32, 64}, but got {type(self)}"
        )

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [type(self).mlir_type]

    @staticmethod
    def from_mlir_type(mlir_type: ir.Type) -> Type["Numeric"]:
        type_map = {
            T.bool(): Boolean,
            T.f64(): Float64,
            T.f32(): Float32,
            T.tf32(): TFloat32,
            T.f16(): Float16,
            T.bf16(): BFloat16,
            T.i(128): Int128,
            T.i64(): Int64,
            T.i32(): Int32,
            T.i16(): Int16,
            T.i8(): Int8,
            T.IntegerType.get_signless(4): Int4,
            T.si(128): Int128,
            T.si64(): Int64,
            T.si32(): Int32,
            T.si16(): Int16,
            T.si8(): Int8,
            T.IntegerType.get_signed(4): Int4,
            T.ui(128): Uint128,
            T.ui64(): Uint64,
            T.ui32(): Uint32,
            T.ui16(): Uint16,
            T.ui8(): Uint8,
            T.f8E5M2(): Float8E5M2,
            T.f8E4M3(): Float8E4M3,
            T.f8E4M3FN(): Float8E4M3FN,
            T.f8E4M3B11FNUZ(): Float8E4M3B11FNUZ,
            T.f4E2M1FN(): Float4E2M1FN,
            T.f6E2M3FN(): Float6E2M3FN,
            T.f6E3M2FN(): Float6E3M2FN,
            T.f8E8M0FNU(): Float8E8M0FNU,
        }
        if mlir_type not in type_map:
            raise DSLRuntimeError(f"Unsupported DSL type: {mlir_type}")
        return type_map[mlir_type]


def as_numeric(obj: Union[bool, int, float, ir.Value, Numeric]) -> Numeric:
    """Convert a Python primitive value to a Numeric type.

    :param obj: Python primitive value to convert
    :type obj: Union[bool, int, float]
    :return: The converted Numeric object
    :rtype: Numeric

    Example::

        .. code-block:: python

            x = as_numeric(5)  # Converts to Int32
            y = as_numeric(3.14)  # Converts to Float32
            z = as_numeric(True)  # Converts to Boolean
    """
    if isinstance(obj, Numeric):
        return obj
    return Numeric._from_python_value(obj)


class Integer(Numeric, metaclass=IntegerMeta, mlir_type=T.i32, is_abstract=True):
    """A class representing integer values with specific width and signedness.

    This class provides functionality to create and manipulate integer values with
    configurable width and signedness. It supports conversion from various input types
    including Python scalars, MLIR Values, and other numeric types.

    :param x: The input value to convert to this integer type
    :type x: Union[bool, int, float, ir.Value, Integer, Float]

    :return: A new Integer instance with the converted value
    :rtype: Integer

    :raises AssertionError: If the type's numpy_dtype is None
    :raises NotImplementedError: If converting between different Integer types
    :raises ValueError: If the input type is not supported for conversion
    :raises OverflowError: If converting float infinity to integer

    Type conversion behavior:

    * Python scalars (bool, int, float):
        * Converted through numpy dtype casting
        * NaN and infinity values are rejected
        * Example: Int8(256) -> -256 (overflow behavior)

    * MLIR Value with IntegerType:
        * Width differences handled by signless to signed/unsigned conversion
        * Example: i8 -> i8/ui8 depending on target type

    * MLIR Value with FloatType:
        * Uses MLIR float-to-int conversion
        * NaN and infinity values is undefined behavior
        * Example: f32 -> i32/ui32 depending on target type

    * Integer:
        * Uses MLIR float-to-int conversion or numpy dtype casting
        * Example: Int32(Int32(5)) => 5

    * Float:
        * Uses MLIR float-to-int conversion
        * Example: Int32(Float(5.7)) -> 5

    Example usage:

    .. code-block:: python

        x = Int32(5)  # From integer
        y = Int32(True)  # From boolean
        z = Int32(3.7)  # From float (truncates)
        w = Int32(x)  # From same Integer type
        c5 = arith.constant(5, T.i32())
        a = Int32(c5)  # Treat c5 as int32 bitwise
    """

    # Injected by IntegerMeta.__new__ on every concrete subclass.
    signed: ClassVar[bool]

    def __init__(
        self,
        x: Union[bool, int, float, ir.Value, "Integer", "Float"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        ty = type(self)
        if isinstance(x, (bool, int, float)):
            # Add check for NaN before numpy conversion
            if isinstance(x, float):
                if np.isnan(x):
                    raise ValueError("Cannot convert float NaN to integer")
                elif np.isinf(x):
                    raise OverflowError("Cannot convert float infinity to integer")

            np_dtype = ty.numpy_dtype
            assert np_dtype is not None, f"expects numpy.dtype, but got {np_dtype}"
            x_val = int(np.array(x).astype(np_dtype))
        elif type(x) == ty:
            x_val = x.value  # type: ignore[assignment]
        elif isinstance(x, ir.Value):
            x_val = x
            if isinstance(x.type, ir.IntegerType):
                if x.type.width != ty.width:
                    # signless -> (u)int
                    x_val = _arith_signless_to_int(x, ty)
            elif isinstance(x.type, ir.FloatType):
                # float -> (u)int
                x_val = arith_helper.fptoi(x, ty.signed, ty.mlir_type, loc=loc, ip=ip)
        elif isinstance(x, Integer):
            if isinstance(x.value, ir.Value):
                x_val = arith_helper.int_to_int(x.ir_value(), ty)
            else:
                # For non-MLIR values, use numpy casting
                src_val = np.array(x.value, dtype=type(x).numpy_dtype)
                x_val = int(src_val.astype(ty.numpy_dtype))
        elif isinstance(x, Float):
            # float -> int is handled by Integer.__init__ recursively
            Integer.__init__(self, x.value)
            return
        else:
            raise DSLRuntimeError(f"{x} to integer conversion is not supported")

        super().__init__(x_val)

    def __invert__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Integer":
        res_type = type(self)
        return res_type(self.ir_value(loc=loc, ip=ip).__invert__(loc=loc, ip=ip))

    def __lshift__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.lshift)(self, other, loc=loc, ip=ip)

    def __rlshift__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        other_ = as_numeric(other)
        if not isinstance(other_, Integer):
            raise ValueError(f"Cannot left shift {other_} with {self}")
        return other_.__lshift__(self, loc=loc, ip=ip)  # type: ignore[call-arg]

    def __rshift__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.rshift)(self, other, loc=loc, ip=ip)

    def __rrshift__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        other_ = as_numeric(other)
        if not isinstance(other_, Integer):
            raise ValueError(f"Cannot right shift {other_} with {self}")
        return other_.__rshift__(self, loc=loc, ip=ip)  # type: ignore[call-arg]

    def __and__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.and_)(self, other, loc=loc, ip=ip)

    def __rand__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return self.__and__(other, loc=loc, ip=ip)  # type: ignore[call-arg]

    def __or__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.or_)(self, other, loc=loc, ip=ip)

    def __ror__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return self.__or__(other, loc=loc, ip=ip)  # type: ignore[call-arg]

    def __xor__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return _binary_op(operator.xor)(self, other, loc=loc, ip=ip)

    def __rxor__(
        self,
        other: Union[int, float, bool, "Numeric"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        return self.__xor__(other, loc=loc, ip=ip)  # type: ignore[call-arg]

    def __tvm_ffi_int__(self) -> Union[int, ir.Value]:
        return self.value


class Float(Numeric, metaclass=FloatMeta, mlir_type=T.f32, is_abstract=True):
    """A class representing floating-point values.

    :param x: The input value to convert to this float type.
    :type x: Union[bool, int, float, ir.Value, Integer, Float]

    Type conversion behavior:

    1. Python scalars (bool, int, float):
       - Converted through numpy dtype casting
       - Example: Float32(1.7) -> 1.7

    2. MLIR Value with FloatType:
       - If width differs: converts between float types
       - Example: f16 -> f32

    3. MLIR Value with IntegerType:
       - Not supported, raises ValueError

    4. Integer:
       - Converts using MLIR int-to-float operation
       - Example: Float32(Int32(5)) -> 5.0

    5. Float:
       - Direct conversion between float types
       - Example: Float32(Float32(1.5)) -> 1.5

    .. note::
        The following narrow precision types are only supported in device code:

        8-bit float types:
            - Float8E5M2
            - Float8E4M3
            - Float8E4M3FN
            - Float8E8M0FNU
            - Float8E4M3B11FNUZ

        6-bit float types:
            - Float6E3M2FN
            - Float6E2M3FN

        4-bit float types:
            - Float4E2M1FN

        Narrow precision types and special floating-point formats support matrix on device:

    :raises AssertionError: If the type's numpy_dtype is None
    :raises ValueError: If conversion from the input type is not supported
    """

    def __init__(
        self,
        x: Union[bool, int, float, ir.Value, "Integer", "Float"],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        ty = type(self)
        if isinstance(x, (bool, int, float)):
            # Why we need to convert x to with numpy?
            # np_dtype = ty.numpy_dtype
            # assert np_dtype is not None, f"expects numpy.dtype, but got {np_dtype}"
            # x = float(np.array(x).astype(np_dtype))
            super().__init__(float(x))
        elif isinstance(x, ir.Value):
            if isinstance(x.type, ir.IntegerType):
                raise DSLRuntimeError("signless to float conversion is not implemented")
            elif isinstance(x.type, ir.FloatType):
                if x.type != ty.mlir_type:
                    x = arith_helper.cvtf(x, ty.mlir_type, loc=loc, ip=ip)
            super().__init__(x)
        elif isinstance(x, Integer):
            if isinstance(x.value, ir.Value):
                x = arith_helper.itofp(
                    x.value, type(x).signed, ty.mlir_type, loc=loc, ip=ip
                )
            else:
                x = float(x.value)  # type: ignore[arg-type]
            super().__init__(x)
        elif isinstance(x, Float):
            Float.__init__(self, x.value)
        else:
            raise DSLRuntimeError(f"{x} to Float conversion is not supported")

    def __tvm_ffi_float__(self) -> Union[float, ir.Value]:
        return self.value


class Boolean(Integer, metaclass=IntegerMeta, width=1, signed=True, mlir_type=T.bool):
    """Boolean type representation in the DSL.

    This class represents boolean values in the DSL, with a width of 1 bit.
    It supports conversion from various types to boolean values.

    :param a: Value to convert to Boolean
    :type a: Union[bool, int, float, "Value", Numeric]
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR operations, defaults to None
    :type ip: Optional[InsertionPoint], optional
    :raises DSLRuntimeError: If the input value cannot be converted to Boolean

    Conversion rules:

    1. Python bool/int/float:
       - Converted using Python's bool() function
       - Example: Boolean(1) -> True, Boolean(0) -> False

    2. Numeric:
       - Uses the Numeric.value to construct Boolean recursively

    3. MLIR Value with IntegerType:
       - If width is 1: Direct assignment
       - Otherwise: Compares with 0 using arith.cmpi

    4. MLIR Value with FloatType:
       - Compares with 0.0 using arith.cmpf
       - Uses unordered comparison to handle NaN values
    """

    def __init__(
        self,
        a: Union[bool, int, float, ir.Value, Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        value = None
        if isinstance(a, (bool, int, float)):
            value = bool(a)
        elif isinstance(a, Numeric):
            Boolean.__init__(self, a.value, loc=loc, ip=ip)
            return
        elif isinstance(a, ArithValue):
            if a.type == T.bool():
                value = a
            else:
                value = a != arith_helper.const(0, a.type, loc=loc, ip=ip)
        if value is None:
            raise DSLRuntimeError(f"Cannot convert {a} to Boolean")
        super().__init__(value, loc=loc, ip=ip)
        self._value_int8 = None

    def ir_value_int8(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        """
        Returns int8 ir value of Boolean.
        When we need to store Boolean tensor element, use ir_value_int8().

        :param loc: Source location information, defaults to None
        :type loc: Optional[Location], optional
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[InsertionPoint], optional
        :return: The int8 value of this Boolean
        :rtype: ir.Value
        """
        if self._value_int8 is not None:
            return self._value_int8
        self._value_int8 = Int8(self.value, loc=loc, ip=ip).ir_value()
        return self._value_int8

    def __neg__(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Numeric":
        """Negation operator is not supported for boolean type.

        :param loc: Source location information, defaults to None
        :type loc: Optional[Location], optional
        :param ip: Insertion point for MLIR operations, defaults to None
        :type ip: Optional[InsertionPoint], optional
        :raises TypeError: Always raises this error as negation is not supported
        """
        raise TypeError("Negation, the operator `-` is not supported for boolean type")



class Int4(
    Integer,
    metaclass=IntegerMeta,
    width=4,
    signed=True,
    mlir_type=lambda: T.IntegerType.get_signless(4),
): ...


class Int8(Integer, metaclass=IntegerMeta, width=8, signed=True, mlir_type=T.i8): ...


class Int16(Integer, metaclass=IntegerMeta, width=16, signed=True, mlir_type=T.i16): ...


class Int32(Integer, metaclass=IntegerMeta, width=32, signed=True, mlir_type=T.i32): ...


class Int64(Integer, metaclass=IntegerMeta, width=64, signed=True, mlir_type=T.i64): ...


class Int128(
    Integer, metaclass=IntegerMeta, width=128, signed=True, mlir_type=lambda: T.i(128)
): ...


class Uint8(Integer, metaclass=IntegerMeta, width=8, signed=False, mlir_type=T.i8): ...


class Uint16(
    Integer, metaclass=IntegerMeta, width=16, signed=False, mlir_type=T.i16
): ...


class Uint32(
    Integer, metaclass=IntegerMeta, width=32, signed=False, mlir_type=T.i32
): ...


class Uint64(
    Integer, metaclass=IntegerMeta, width=64, signed=False, mlir_type=T.i64
): ...


class Uint128(
    Integer, metaclass=IntegerMeta, width=128, signed=False, mlir_type=lambda: T.i(128)
): ...


class Float64(Float, metaclass=FloatMeta, width=64, mlir_type=T.f64):
    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        if not isinstance(self.value, float):
            raise ValueError("only float is supported")

        return [
            ctypes.cast(ctypes.pointer(ctypes.c_double(self.value)), ctypes.c_void_p)
        ]


class Float32(Float, metaclass=FloatMeta, width=32, mlir_type=T.f32):
    @staticmethod
    def _get_c_pointer(value: float) -> ctypes.c_void_p:
        return ctypes.cast(ctypes.pointer(ctypes.c_float(value)), ctypes.c_void_p)

    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        if not isinstance(self.value, float):
            raise ValueError("only float is supported")

        return [Float32._get_c_pointer(self.value)]


class TFloat32(Float, metaclass=FloatMeta, width=32, mlir_type=T.tf32):
    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        if not isinstance(self.value, float):
            raise ValueError("only float is supported")
        return [Float32._get_c_pointer(self.value)]


class Float16(Float, metaclass=FloatMeta, width=16, mlir_type=T.f16):
    @staticmethod
    def _get_c_pointer(value: float) -> ctypes.c_void_p:
        # Convert float to float16 binary representation
        # First convert to numpy float16 to handle the conversion
        f16_val = np.float16(value)
        # Get the raw bits as a 16-bit integer
        bits: int = int(f16_val.view(np.uint16))
        # Create a short (16-bit int) with those bits
        c_val = ctypes.c_short(int(bits))
        return ctypes.cast(ctypes.pointer(c_val), ctypes.c_void_p)

    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        if not isinstance(self.value, float):
            raise ValueError("only float is supported")
        return [Float16._get_c_pointer(self.value)]


class BFloat16(Float, metaclass=FloatMeta, width=16, mlir_type=T.bf16):
    def __c_pointers__(self) -> list[ctypes.c_void_p]:
        if not isinstance(self.value, float):
            raise ValueError("only float is supported")
        # Convert float32 to bfloat16 representation
        # First convert the value to float32 bit representation
        f32_val = np.float32(self.value)
        # Get the 32-bit integer representation
        bits = int(f32_val.view(np.uint32))
        # Truncate to 16 bits, keeping the high 16 bits
        bf16_bits = np.uint16(bits >> 16)
        # Create a short (16-bit int) with those bits
        c_val = ctypes.c_short(bf16_bits)  # type: ignore[arg-type]
        c_pointer = ctypes.cast(ctypes.pointer(c_val), ctypes.c_void_p)
        return [c_pointer]


class Float8E5M2(Float, metaclass=FloatMeta, width=8, mlir_type=T.f8E5M2): ...


class Float8E4M3FN(Float, metaclass=FloatMeta, width=8, mlir_type=T.f8E4M3FN): ...


class Float8E4M3B11FNUZ(
    Float, metaclass=FloatMeta, width=8, mlir_type=T.f8E4M3B11FNUZ
): ...



# Added missing float types
class Float8E4M3(Float, metaclass=FloatMeta, width=8, mlir_type=T.f8E4M3): ...


class Float8E8M0FNU(Float, metaclass=FloatMeta, width=8, mlir_type=T.f8E8M0FNU): ...


class Float4E2M1FN(Float, metaclass=FloatMeta, width=4, mlir_type=T.f4E2M1FN): ...


class Float6E3M2FN(Float, metaclass=FloatMeta, width=6, mlir_type=T.f6E3M2FN): ...


class Float6E2M3FN(Float, metaclass=FloatMeta, width=6, mlir_type=T.f6E2M3FN): ...


# Packed narrow-float views. For FP4x2, the MLIR element type is the packed
# storage container (`i8`) so generic pointer vector loads/stores move packed
# bytes correctly. The class identity carries the floating-point packing
# semantics (`x2` in the name). `width` is the width of one packed tensor
# element: 8 bits for FP4x2. Naming follows torch: `float4_e2m1fn_x2`.
class Float4E2M1FNx2(
    Float,
    metaclass=FloatMeta,
    width=8,
    mlir_type=T.i8,
):
    """Packed FP4 E2M1 — 2 elements per byte (matches ``torch.float4_e2m1fn_x2``).

    Shape and strides on any layout carrying this dtype are interpreted
    in **fp4x2 tensor-element units**. One tensor element is already one
    packed storage unit, so ``create_tensor_map_tiled_from_tensor`` uses
    ``width == 8`` directly when converting stride units for TMA.

    ``width`` is the packed 8-bit tensor-element width and ``mlir_type`` is
    the packed storage type ``i8``. Internal helpers that still need scalar
    FP4 lane precision treat this packed dtype specially by class identity.

    Use this dtype when the input is already organized in packed fp4x2
    storage units (for example a ``torch.uint8`` buffer viewed as
    ``torch.float4_e2m1fn_x2``) or when the kernel allocates layouts
    directly from packed extents.

    """



def _element_precision_width(dtype: Type["Numeric"]) -> int:
    """Return scalar lane precision for packed narrow-float view dtypes."""

    if dtype is Float4E2M1FNx2:
        return 4
    return dtype.width


_unsupported_dst_float_types = [
    Float8E4M3,
    Float8E4M3B11FNUZ,
    Float4E2M1FN,
    Float6E3M2FN,
    Float6E2M3FN,
    Float4E2M1FNx2,
]


ALL_DTYPES = {
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
    Uint128,
    BFloat16,
    Float16,
    Float32,
    TFloat32,
    Float64,
    Float8E5M2,
    Float8E4M3,
    Float8E4M3FN,
    Float8E8M0FNU,
    Float8E4M3B11FNUZ,
    Float4E2M1FN,
    Float6E2M3FN,
    Float6E3M2FN,
    Float4E2M1FNx2,
}
__STR_TO_DTYPE__ = {dt.__name__: dt for dt in ALL_DTYPES}


def dtype(dtype_: str) -> Type[Numeric]:
    t = None
    if isinstance(dtype_, str) and dtype_ in __STR_TO_DTYPE__:
        t = __STR_TO_DTYPE__[dtype_]
    else:
        raise TypeError(f"can't interpret {dtype_} as data type")

    return t


##############################################################
# Tensor
##############################################################


class TensorMeta(DslType):
    _element_type = Any
    _shape = Any

    """
    Examples:
        >>> Tensor[Int32, (3,)]
        >>> Tensor[Float32, (3, 4)]
        >>> T = TypeVar("T")
        >>> Tensor[T, (3, 4, 5)]
    """

    def __new__(
        cls,
        name: str,
        bases: tuple,
        attrs: dict,
        element_type: Any = Any,
        shape: Any = Any,
    ) -> Any:
        new_cls = super().__new__(cls, name, bases, attrs)
        new_cls._element_type = element_type
        new_cls._shape = shape
        return new_cls


# Generic type
TY = TypeVar("TY")


if TYPE_CHECKING:
    # Static-analysis: Constexpr[T] is transparent and treated as T.
    Constexpr = Annotated[TY, "constexpr"]
else:

    class Constexpr(Generic[TY]):
        """Value is passed and computed by python interpreter"""

        pass


class _GridConstantMarker:
    """Type marker that indicates a kernel argument as CUDA grid constant."""

    def __extract_mlir_attributes__(self) -> list[ir.DictAttr]:
        return [ir.DictAttr.get({"cuda.grid_constant": ir.UnitAttr.get()})]


# Singleton instance of the grid constant marker
grid_constant: _GridConstantMarker = _GridConstantMarker()

# Type alias for ``Annotated[TY, grid_constant]``
GridConstant: TypeAlias = Annotated[TY, grid_constant]


class align(int):
    def __new__(cls, value: int) -> "align":
        if value <= 0 or (value & (value - 1)) != 0:
            raise DSLUserCodeError(DiagId.ARG_INVALID_ALIGNMENT)
        return super().__new__(cls, value)

    def __str__(self) -> str:
        return f"align({super().__str__()})"



class TypedPointer:
    """Type annotation object for a ``Pointer`` element type and memory space.

    ``Pointer[dtype, space]`` returns a ``TypedPointer`` for use in kernel/JIT
    signatures. It is not an LLVM pointer value itself; it carries the metadata
    needed to derive the corresponding MLIR argument type.

    :param dtype: Element type such as ``Float32`` or ``Int8``.
    :param space: Memory space such as ``cutlass.AddressSpace.gmem`` or its integer
        address-space value.

    Example::

        def kernel(data: cutlass.Pointer[Float32, cutlass.AddressSpace.gmem]):
            ...

    ``__get_mlir_types__`` reads ``space.value`` when present, otherwise treats
    ``space`` as the raw LLVM address-space integer.
    """

    def __init__(self, dtype: Any, space: Any):
        self.dtype = dtype
        self.space = space

    def __repr__(self) -> str:
        return f"TypedPointer[{self.dtype}, {self.space}]"

    def __get_mlir_types__(self) -> list[ir.Type]:
        addrspace = getattr(self.space, "value", self.space)
        return [llvm.PointerType.get(int(addrspace))]


def _normalize_address_space(space: Any) -> AddressSpace:
    if isinstance(space, AddressSpace):
        return space
    if isinstance(space, bool):
        raise TypeError(
            f"space=bool is not allowed; pass a cutlass.AddressSpace member "
            f"or its int value. Got {space!r}."
        )
    if isinstance(space, int):
        try:
            return AddressSpace(space)
        except ValueError:
            valid = sorted(int(m) for m in AddressSpace)
            raise ValueError(
                f"space={space!r} is not a valid cutlass.AddressSpace int. "
                f"Valid ints: {valid}."
            ) from None
    raise TypeError(
        f"space must be a cutlass.AddressSpace member or int; got "
        f"{type(space).__name__} ({space!r})."
    )


MemOrdering = Literal[
    "not_atomic",
    "monotonic",
    "acquire",
    "release",
    "acq_rel",
    "seq_cst",
]
MemScope = Literal["cta", "cluster", "gpu", "sys"]
SharedSpace = Literal["cta", "cluster"]
LoadCacheModifier = Literal["ca", "cg", "cs", "lu", "cv"]
StoreCacheModifier = Literal["wb", "cg", "cs", "wt"]
EvictPriority = Literal["first", "last", "normal", "unchanged", "noallocate"]
L2PrefetchSize = Literal["size_64b", "size_128b", "size_256b"]
L1EvictKind = Literal[
    "evict_normal",
    "evict_first",
    "evict_last",
    "evict_no_allocate",
    "evict_unchanged",
]

MLIR_DYNAMIC_INDEX = -(2**31)


def _to_llvm_compatible_type(elem_type: ir.Type) -> ir.Type:
    """Convert non-LLVM-compatible element types to same-width integer types."""
    compatible_float_widths = {16, 32, 64, 80, 128}
    if isinstance(elem_type, ir.FloatType):
        width = elem_type.width
        if width not in compatible_float_widths:
            return ir.IntegerType.get_signless(width)
    return elem_type


def _gep(
    base: ir.Value,
    elem_type: ir.Type,
    *,
    static_indices: list[int] | None = None,
    dynamic_indices: list[ir.Value] | None = None,
    loc: object = None,
    ip: object = None,
) -> ir.Value:
    """Helper for LLVM getelementptr operations."""
    if static_indices is None:
        static_indices = []
    if dynamic_indices is None:
        dynamic_indices = []

    return llvm.getelementptr(
        base.type,
        base,
        dynamic_indices,
        static_indices,
        _to_llvm_compatible_type(elem_type),
        no_wrap_flags="None",
        loc=loc,
        ip=ip,
    )


class Pointer(ir.Value):
    """An ``llvm.ptr`` value with element dtype metadata.

    ``Pointer`` is the canonical low-level DSL pointer type in the ``cutlass``
    namespace. It subclasses ``ir.Value`` so it can be passed directly to MLIR
    ops that require a pointer operand.
    """

    _dtype: Type[Numeric]
    _mlir_type: ir.Type
    _addrspace: int
    _base: ir.Value

    def __init__(
        self,
        base: ir.Value,
        *,
        dtype: Type[Numeric] | None = None,
        space: AddressSpace | int | None = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        if hasattr(base, "to_llvm_ptr"):
            base = base.to_llvm_ptr(loc=loc, ip=ip)
        elif hasattr(base, "ir_value") and not isinstance(base, ir.Value):
            base = base.ir_value(loc=loc, ip=ip)
        if not isinstance(base, ir.Value):
            raise TypeError(f"Pointer expects an MLIR value, got {type(base).__name__}")

        super().__init__(base)
        self._base = base
        self._dtype = dtype or Int8
        self._mlir_type = self._dtype.mlir_type

        if space is not None:
            self._addrspace = _normalize_address_space(space).value
        else:
            try:
                self._addrspace = llvm.PointerType(base.type).address_space
            except Exception:
                self._addrspace = AddressSpace.generic.value

    @classmethod
    def _from_raw_ptr(
        cls,
        value: ir.Value,
        dtype: Type[Numeric] | None = None,
    ) -> "Pointer":
        return cls(value, dtype=dtype or Int8)

    def __class_getitem__(cls, args: Any) -> TypedPointer:
        if not isinstance(args, tuple) or len(args) != 2:
            raise DSLRuntimeError("Pointer[...] expects (dtype, memory_space)")
        return TypedPointer(*args)

    def ir_value(
        self,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> ir.Value:
        return self

    @property
    def llvm_ptr(self) -> ir.Value:
        return self

    def to_llvm_ptr(
        self,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> ir.Value:
        return self

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return [ir.Value(self)]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "Pointer":
        return Pointer._from_raw_ptr(values[0], self._dtype)

    def __str__(self) -> str:
        return f"ptr<space={self.space.name}, dtype={self.dtype}>"

    def __repr__(self) -> str:
        return self.__str__()

    @property
    def dtype(self) -> Type[Numeric]:
        return self._dtype

    @property
    def natural_alignment(self) -> int:
        return max(1, self._dtype.width // 8)

    @property
    def alignment(self) -> int:
        return self.natural_alignment

    @property
    def max_alignment(self) -> int:
        return self.natural_alignment

    @property
    def value_type(self) -> Type[Numeric]:
        return self._dtype

    @property
    def space(self) -> AddressSpace:
        try:
            return AddressSpace(self._addrspace)
        except ValueError:
            return AddressSpace.generic

    @property
    def memspace(self) -> AddressSpace:
        return self.space

    @property
    def mlir_type(self) -> ir.Type:
        return self.type

    def _effective_alignment(self, alignment: int | None) -> int:
        return alignment if alignment is not None else self.natural_alignment

    def _prepare_store_value(
        self,
        value: Any,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        if isinstance(value, Vector):
            if value._dtype is not self._dtype:
                raise TypeError(f"Expected dtype {self._dtype}, got {value._dtype}")
            return value
        if self._dtype.isinstance(value):
            if isinstance(value, (int, float, bool)):
                return arith_helper.const(value, loc=loc, ip=ip)
            if isinstance(value, Numeric):
                return value.ir_value(loc=loc, ip=ip)
            return value
        if hasattr(value, "_base") and hasattr(value, "_shape"):
            raise TypeError(
                "Cannot store Array directly. Use ptr.store(array.load()) instead."
            )
        raise TypeError(f"Expected value to be Scalar or Vector, got {type(value)}")

    @dsl_user_op
    def tospace(
        self,
        space: AddressSpace | int,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        target = _normalize_address_space(space)
        if target.value == self._addrspace:
            return self
        if self._addrspace != 0 and target.value != 0:
            raise ValueError(
                "cannot cast from non-generic memory space to another non-generic memory space"
            )
        res_ptr = llvm.addrspacecast(
            llvm.PointerType.get(target.value),
            self._base,
            loc=loc,
            ip=ip,
        )
        return Pointer(res_ptr, dtype=self._dtype, space=target)

    def _as_tmem_offset(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Int32":
        if isinstance(offset, int):
            return Int32(offset)
        if isinstance(offset, Integer):
            return Int32(offset, loc=loc, ip=ip)
        if isinstance(offset, ir.Value) and ir.IntegerType.isinstance(offset.type):
            return Int32(offset, loc=loc, ip=ip)
        raise ValueError(
            f"Expects static or dynamic integer value, but got {type(offset)}"
        )

    def _gep_tmem(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        # TMEM uses a packed i32 address token, so offsets are raw address
        # increments rather than LLVM GEP element indices.
        base_addr = self.toint(Int32, loc=loc, ip=ip)
        offset_addr = self._as_tmem_offset(offset, loc=loc, ip=ip)
        return self._inttoptr(
            base_addr + offset_addr,
            self._addrspace,
            self._dtype,
            loc=loc,
            ip=ip,
        )

    def _gep(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        if self._addrspace == AddressSpace.tmem.value:
            return self._gep_tmem(offset, loc=loc, ip=ip)

        if isinstance(offset, int):
            static_indices = [offset]
            dyn_indices = []
        elif isinstance(offset, Integer):
            static_indices = [MLIR_DYNAMIC_INDEX]
            dyn_indices = [offset.ir_value(loc=loc, ip=ip)]
        elif isinstance(offset, ir.Value) and ir.IntegerType.isinstance(offset.type):
            static_indices = [MLIR_DYNAMIC_INDEX]
            dyn_indices = [offset]
        else:
            raise ValueError(
                f"Expects static or dynamic integer value, but got {type(offset)}"
            )

        res_ptr = _gep(
            self._base,
            self._mlir_type,
            static_indices=static_indices,
            dynamic_indices=dyn_indices,
            loc=loc,
            ip=ip,
        )
        return Pointer(res_ptr, dtype=self._dtype, space=self.space)

    @dsl_user_op
    def toint(
        self,
        dtype: Optional[Type[Integer]] = None,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Integer:
        addrspace = self._addrspace
        if dtype is None:
            dtype = Int64
        if addrspace == 6:
            return dtype(llvm.ptrtoint(Int32.mlir_type, self._base, loc=loc, ip=ip))
        return dtype(llvm.ptrtoint(dtype.mlir_type, self._base, loc=loc, ip=ip))

    @dsl_user_op
    def load(
        self,
        alignment: Optional[int] = None,
        *,
        count: Optional[int] = None,
        is_volatile: bool = False,
        is_invariant: bool = False,
        is_invariant_group: bool = False,
        ordering: Any = "not_atomic",
        syncscope: Any | None = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        effective_alignment = self._effective_alignment(alignment)
        if count is None:
            res_ty = self._mlir_type
        else:
            res_ty = ir.VectorType.get([count], self._mlir_type)

        res = llvm.load(
            res_ty,
            self._base,
            alignment=effective_alignment,
            volatile_=is_volatile,
            nontemporal=False,
            invariant=is_invariant,
            invariant_group=is_invariant_group,
            ordering=(
                llvm.AtomicOrdering(ordering) if ordering != "not_atomic" else None
            ),
            syncscope=syncscope,
            loc=loc,
            ip=ip,
        )
        if count is None:
            return self._dtype(res, loc=loc, ip=ip)
        if hasattr(res, "ir_value"):
            res = res.ir_value()
        return Vector(res, dtype=self._dtype)

    def nvvm_load_ext(
        self,
        *,
        count: Optional[int] = None,
        cache_modifier: Any | None = None,
        evict: Any | None = None,
        scope: Any | None = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        if count is None:
            res_ty = self._mlir_type
        else:
            res_ty = ir.VectorType.get([count], self._mlir_type)

        kwargs: dict = {}
        if cache_modifier is not None:
            name = (
                cache_modifier
                if isinstance(cache_modifier, str)
                else cache_modifier.name
            )
            kwargs["cache_modifier"] = getattr(
                nvvm.LoadCacheModifierExtKind, name.upper()
            )
        if evict is not None:
            name = evict if isinstance(evict, str) else evict.name
            kwargs["evict"] = getattr(nvvm.EvictKind, name.upper())
        if scope is not None:
            name = scope if isinstance(scope, str) else scope.name
            kwargs["scope"] = getattr(nvvm.MemScopeKind, name.upper())

        res = nvvm.load_ext(res_ty, self._base, **kwargs, loc=loc, ip=ip)
        if count is None:
            return self._dtype(res, loc=loc, ip=ip)
        if hasattr(res, "ir_value"):
            res = res.ir_value()
        return Vector(res, dtype=self._dtype)

    def store(
        self,
        value: Any,
        *,
        alignment: Optional[int] = None,
        is_volatile: bool = False,
        is_invariant_group: bool = False,
        ordering: Any = "not_atomic",
        syncscope: Any | None = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        effective_alignment = self._effective_alignment(alignment)
        ir_value = self._prepare_store_value(value, loc=loc, ip=ip)
        return llvm.store(
            ir_value,
            self._base,
            alignment=effective_alignment,
            volatile_=is_volatile,
            nontemporal=False,
            invariant_group=is_invariant_group,
            ordering=(
                llvm.AtomicOrdering(ordering) if ordering != "not_atomic" else None
            ),
            syncscope=syncscope if syncscope else None,
            loc=loc,
            ip=ip,
        )

    def nvvm_store_ext(
        self,
        value: Any,
        *,
        cache_modifier: Any | None = None,
        evict: Any | None = None,
        scope: Any | None = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        ir_value = self._prepare_store_value(value, loc=loc, ip=ip)
        kwargs: dict = {}
        if cache_modifier is not None:
            name = (
                cache_modifier
                if isinstance(cache_modifier, str)
                else cache_modifier.name
            )
            kwargs["cache_modifier"] = getattr(
                nvvm.StoreCacheModifierKind, name.upper()
            )
        if evict is not None:
            name = evict if isinstance(evict, str) else evict.name
            kwargs["evict"] = getattr(nvvm.EvictKind, name.upper())
        if scope is not None:
            name = scope if isinstance(scope, str) else scope.name
            kwargs["scope"] = getattr(nvvm.MemScopeKind, name.upper())

        return nvvm.store_ext(ir_value, self._base, **kwargs, loc=loc, ip=ip)

    @dsl_user_op
    def masked_load(
        self,
        mask: Any,
        pass_thru: Any | None = None,
        *,
        alignment: Optional[int] = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        from cutlass._mlir_helpers.vector import Vector  # noqa: PLC0415

        if not isinstance(mask, Vector):
            raise TypeError(f"mask must be a Vector, got {type(mask)}")
        mask_elem_type = mask._mlir_type
        if not (
            ir.IntegerType.isinstance(mask_elem_type)
            and ir.IntegerType(mask_elem_type).width == 1
        ):
            raise TypeError(
                f"mask must be a vector of i1, got vector of {mask_elem_type}"
            )

        vec_len = mask.shape[0]
        if pass_thru is not None:
            if not isinstance(pass_thru, Vector):
                raise TypeError(f"pass_thru must be a Vector, got {type(pass_thru)}")
            if pass_thru.shape[0] != vec_len:
                raise ValueError(
                    f"pass_thru length ({pass_thru.shape[0]}) must match mask length ({vec_len})"
                )
            if pass_thru.dtype is not self.dtype:
                raise TypeError(
                    f"pass_thru dtype ({pass_thru.dtype}) must match pointer dtype ({self.dtype})"
                )

        res_ty = ir.VectorType.get([vec_len], self.dtype.mlir_type)
        res = llvm.intr_masked_load(
            res_ty,
            self._base,
            mask,
            pass_thru=pass_thru,
            alignment=alignment or self.natural_alignment,
            loc=loc,
            ip=ip,
        )
        if isinstance(res, Vector):
            return res
        if hasattr(res, "ir_value"):
            res = res.ir_value()
        return Vector(res, dtype=self.dtype)

    @dsl_user_op
    def masked_store(
        self,
        value: Any,
        mask: Any,
        *,
        alignment: Optional[int] = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        from cutlass._mlir_helpers.vector import Vector  # noqa: PLC0415

        if not isinstance(value, Vector):
            raise TypeError(f"value must be a Vector, got {type(value)}")
        if not isinstance(mask, Vector):
            raise TypeError(f"mask must be a Vector, got {type(mask)}")

        mask_elem_type = mask._mlir_type
        if not (
            ir.IntegerType.isinstance(mask_elem_type)
            and ir.IntegerType(mask_elem_type).width == 1
        ):
            raise TypeError(
                f"mask must be a vector of i1, got vector of {mask_elem_type}"
            )
        if value.shape[0] != mask.shape[0]:
            raise ValueError(
                f"value and mask must have the same length, got {value.shape[0]} and {mask.shape[0]}"
            )
        if value.dtype is not self.dtype:
            raise TypeError(
                f"value dtype ({value.dtype}) must match pointer dtype ({self.dtype})"
            )

        llvm.intr_masked_store(
            value,
            self._base,
            mask,
            alignment=alignment or self.natural_alignment,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def masked_gather(
        self,
        offsets: Any,
        mask: Any,
        pass_thru: Any | None = None,
        *,
        alignment: Optional[int] = None,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        from cutlass._mlir_helpers.vector import Vector  # noqa: PLC0415

        if not isinstance(offsets, Vector):
            raise TypeError(f"offsets must be a Vector, got {type(offsets)}")
        if not isinstance(mask, Vector):
            raise TypeError(f"mask must be a Vector, got {type(mask)}")
        if offsets.shape[0] != mask.shape[0]:
            raise ValueError(
                f"offsets and mask must have the same length, got {offsets.shape[0]} and {mask.shape[0]}"
            )
        mask_elem_type = mask._mlir_type
        if not (
            ir.IntegerType.isinstance(mask_elem_type)
            and ir.IntegerType(mask_elem_type).width == 1
        ):
            raise TypeError(
                f"mask must be a vector of i1, got vector of {mask_elem_type}"
            )

        vec_len = offsets.shape[0]
        vec_ptr_type = ir.VectorType.get([vec_len], self.mlir_type)
        base_ptr_vec = vector.broadcast(vec_ptr_type, self._base, loc=loc, ip=ip)
        ptrs = llvm.getelementptr(
            vec_ptr_type,
            base_ptr_vec,
            [offsets],
            [MLIR_DYNAMIC_INDEX],
            self.dtype.mlir_type,
            no_wrap_flags="None",
            loc=loc,
            ip=ip,
        )
        result_type = ir.VectorType.get([vec_len], self.dtype.mlir_type)
        result = llvm.intr_masked_gather(
            result_type,
            ptrs,
            mask,
            [pass_thru] if pass_thru is not None else [],
            alignment=alignment or self.natural_alignment,
            loc=loc,
            ip=ip,
        )
        if isinstance(result, Vector):
            return result
        if hasattr(result, "ir_value"):
            result = result.ir_value()
        return Vector(result, dtype=self.dtype)

    @dsl_user_op
    def __add__(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        return self._gep(offset, loc=loc, ip=ip)

    @dsl_user_op
    def __sub__(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        if isinstance(offset, int):
            neg_offset = -offset
        else:
            neg_offset = Int32(0) - offset
        return self._gep(neg_offset, loc=loc, ip=ip)

    @dsl_user_op
    def __radd__(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        return self._gep(offset, loc=loc, ip=ip)

    @dsl_user_op
    def __iadd__(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        return self._gep(offset, loc=loc, ip=ip)

    @dsl_user_op
    def __isub__(
        self,
        offset: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        return self.__sub__(offset, loc=loc, ip=ip)

    def _inttoptr(
        self,
        value: Any,
        addrspace: int,
        dtype: Type[Numeric],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        if isinstance(value, int):
            value = (Int64 if addrspace in (0, 1) else Int32)(value)
        if hasattr(value, "ir_value"):
            value = value.ir_value(loc=loc, ip=ip)
        res_val = llvm.inttoptr(llvm.PointerType.get(addrspace), value, loc=loc, ip=ip)
        return Pointer._from_raw_ptr(res_val, dtype)

    @dsl_user_op
    def __and__(
        self,
        mask: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        masked_int = self.toint(loc=loc, ip=ip) & mask
        return self._inttoptr(masked_int, self._addrspace, self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __rand__(
        self,
        mask: Union[int, Integer, ir.Value],
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> "Pointer":
        return self.__and__(mask, loc=loc, ip=ip)

    def _validate_scalar_index(self, idx: Any) -> Any:
        if isinstance(idx, tuple):
            raise TypeError(
                "Pointer tuple indexing is not supported; use explicit "
                "load(..., alignment=...) or store(..., alignment=...) calls"
            )
        if isinstance(idx, slice):
            raise TypeError(
                "Pointer slices are not supported; use explicit "
                "load(count=...) or store(...) calls"
            )
        return idx

    def __getitem__(
        self,
        idx: Any,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> Any:
        offset = self._validate_scalar_index(idx)
        ptr = self._gep(offset, loc=loc, ip=ip)
        return ptr.load(loc=loc, ip=ip)

    @dsl_user_op
    def __setitem__(
        self,
        idx: Any,
        value: Any,
        *,
        loc: ir.Location | None = None,
        ip: ir.InsertionPoint | None = None,
    ) -> None:
        offset = self._validate_scalar_index(idx)
        ptr = self._gep(offset, loc=loc, ip=ip)
        return ptr.store(value, loc=loc, ip=ip)


class IRConst(Generic[TY]):
    """Value is passed as MLIR constant value for (arith.constant)."""

    def __init__(self, ty: TY):
        self.ty = ty


class IRValue(Generic[TY]):
    """Value is passed as MLIR dynamic value."""

    def __init__(self, ty: TY):
        self.ty = ty


class IRVariadic:
    """
    A helper class to pass a variadic number of arguments to a function.
    """

    def __init__(self, operands: list[ir.Value]) -> None:
        """
        Create a list of variadic operands. `operands` must be dynamic values.
        """
        self.operands = operands

    def block_arg_types(self) -> list[ir.Type]:
        """
        Return the list of block args types.
        """
        return [operand.type for operand in self.operands]

    def set_func_args(self, block_args: list[ir.Value]) -> None:
        """
        This function is called after entering a function. `block_args` are the
        block arguments that correspond to the passed operands. Derived classes
        may implement this function to provide convenience getters for block
        arguments.
        """
        pass

    def __len__(self) -> int:
        """
        Return the length of variadic operands.
        """
        return len(self.operands)


class FuncArgWithAttr(IRValue):
    """
    This derived class is specifically for func op arg with attr
    """

    def __init__(
        self, ty: Any, attr_name: str, attr_ty: Any, attr_value: Any = None
    ) -> None:
        super().__init__(ty)
        assert attr_name is not None and (
            attr_ty is not None or attr_value is not None
        ), "Invalid attr_name and/or attr_ty and/or attr_value for FuncArgWithAttr"
        self.attr_name = attr_name
        self.attr_ty = attr_ty
        self.attr_value = attr_value


def implicitDowncastNumericType(
    value: Union[bool, int, float, "Numeric"],
) -> Union[bool, int, float, ir.Value]:
    if isinstance(value, Numeric):
        return value.ir_value()
    return value


__all__ = [
    "DslType",
    "Numeric",
    "NumericMeta",
    "IntegerMeta",
    "FloatMeta",
    "Boolean",
    "Integer",
    "Int16",
    "Int32",
    "Int64",
    "Int128",
    "Int8",
    "Int4",
    "Uint8",
    "Uint16",
    "Uint32",
    "Uint64",
    "Uint128",
    "Float",
    "Float16",
    "BFloat16",
    "TFloat32",
    "Float32",
    "Float64",
    "Float8E5M2",
    "Float8E4M3",
    "Float8E4M3FN",
    "Float8E4M3B11FNUZ",
    "Float8E4M3",
    "Float8E8M0FNU",
    "Float4E2M1FN",
    "Float6E2M3FN",
    "Float6E3M2FN",
    "Float4E2M1FNx2",
    "as_numeric",
    "align",
    "AddressSpace",
    "Pointer",
    "TypedPointer",
    "MemOrdering",
    "MemScope",
    "SharedSpace",
    "LoadCacheModifier",
    "StoreCacheModifier",
    "EvictPriority",
    "L2PrefetchSize",
    "L1EvictKind",
    "dtype",
    "Constexpr",
    "IRConst",
    "IRValue",
    "IRVariadic",
    "implicitDowncastNumericType",
]


