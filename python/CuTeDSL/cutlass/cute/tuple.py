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

from inspect import signature
from itertools import chain
from typing import Any, Callable, Union, Tuple, List, Iterable

from cutlass.cutlass_dsl import is_dynamic_expression, dsl_user_op
from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir

from .typing import XTuple, IntTuple, Shape, Coord, Boolean, is_integer


def wrap(x) -> Tuple[Any, ...]:
    """
    Wraps the input into a tuple if not a tuple.
    """
    if isinstance(x, tuple):
        return x
    return (x,)


def flatten_to_tuple(a: XTuple) -> Tuple[Any, ...]:
    """Flattens a potentially nested tuple structure into a flat tuple.

    This function recursively traverses the input structure and flattens it into
    a single-level tuple, preserving the order of elements.

    :param a: The structure to flatten
    :type a: Union[IntTuple, Coord, Shape, Stride]
    :return: A flattened tuple containing all elements from the input
    :rtype: tuple

    **Examples:**

    .. code-block:: python

        flatten_to_tuple((1, 2, 3))       # Returns (1, 2, 3)
        flatten_to_tuple(((1, 2), 3))     # Returns (1, 2, 3)
        flatten_to_tuple((1, (2, (3,))))  # Returns (1, 2, 3)
    """
    if not isinstance(a, tuple):
        return wrap(a)
    else:
        return tuple(chain.from_iterable(tuple(flatten_to_tuple(x) for x in a)))


def unflatten(
    sequence: Union[Tuple[Any, ...], List[Any], Iterable[Any]], profile: XTuple
) -> XTuple:
    """Unflatten a flat tuple into a nested tuple structure according to a profile.

    This function transforms a flat sequence of elements into a nested tuple structure
    that matches the structure defined by the profile parameter. It traverses the profile
    structure and populates it with elements from the sequence.

    sequence must be long enough to fill the profile. Raises RuntimeError if it is not.

    :param sequence: A flat sequence of elements to be restructured
    :type sequence: Union[Tuple[Any, ...], List[Any], Iterable[Any]]
    :param profile: A nested tuple structure that defines the shape of the output
    :type profile: XTuple
    :return: A nested tuple with the same structure as profile but containing elements from sequence
    :rtype: XTuple

    **Examples:**

    .. code-block:: python

        unflatten([1, 2, 3, 4], ((0, 0), (0, 0)))  # Returns ((1, 2), (3, 4))
    """

    def _make_generator():
        for element in sequence:
            yield element

    xs = _make_generator()
    return transform_leaf(lambda _: next(xs), profile)


@dsl_user_op
def product(a: Union[IntTuple, Shape], *, loc=None, ip=None):
    # Local import to avoid circular dependency
    from .core import _pack_int_tuple, _unpack_x_tuple

    """Return product of the given IntTuple or Shape.

    Computes the product of all elements in the input tuple or shape.

    Returns static value if type is static otherwise dynamic value.

    :param a: The input tuple or shape
    :type a: IntTuple or Shape
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: Static product of IntTuple or Shape if static, otherwise a Value
    :rtype: int or Value
    :raises TypeError: If input is not an IntTuple or Shape
    """
    if is_integer(a):
        return a
    if isinstance(a, tuple):
        a_val = _pack_int_tuple(a, loc=loc, ip=ip)
        res = _cute_ir.tuple_product(a_val, loc=loc, ip=ip)
        return _unpack_x_tuple(res, loc=loc, ip=ip)
    else:
        raise TypeError(f"expects IntTuple or Shape, but got {type(a)}")


@dsl_user_op
def product_like(a: IntTuple, target_profile: XTuple, *, loc=None, ip=None) -> IntTuple:
    """Return product of the given IntTuple or Shape at leaves of `target_profile`.

    This function computes products according to the structure defined by target_profile.

    :param a: The input tuple or shape
    :type a: IntTuple or Shape
    :param target_profile: The profile that guides how products are computed
    :type target_profile: XTuple
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: The resulting tuple with products computed according to target_profile
    :rtype: IntTuple or Shape
    :raises TypeError: If inputs have incompatible types
    :raises ValueError: If inputs have incompatible shapes
    """
    # Perform product at leaf of `target_profile`
    if not isinstance(target_profile, tuple):
        return product(a, loc=loc, ip=ip)

    if not isinstance(a, tuple):
        raise TypeError(f"expects `a` tuple but got {a}")

    if len(a) != len(target_profile):
        raise ValueError("expects `a` and `guide` have the same rank")

    return tuple(product_like(x, g, loc=loc, ip=ip) for x, g in zip(a, target_profile))


@dsl_user_op
def product_each(a: IntTuple, *, loc=None, ip=None) -> IntTuple:
    from .core import _pack_int_tuple, _unpack_x_tuple

    """Compute products for each component of the input.

    Returns a rank(a) tuple result such that ``get(result, mode=[i]) == product(get(a, mode=[i]))``

    :param a: The input IntTuple or Shape
    :type a: IntTuple or Shape
    :param loc: Source location for MLIR, defaults to None
    :type loc: optional
    :param ip: Insertion point, defaults to None
    :type ip: optional
    :return: A tuple containing products for each component
    :rtype: tuple
    :raises TypeError: If input is not an IntTuple or Shape
    """
    if is_integer(a):
        return a

    if not isinstance(a, tuple):
        raise TypeError(f"expects IntTuple or Shape, but got {type(a)}")

    if a == ():
        return 1

    a_val = _pack_int_tuple(a, loc=loc, ip=ip)
    res = _cute_ir.tuple_product_each(a_val, loc=loc, ip=ip)
    return _unpack_x_tuple(res, loc=loc, ip=ip)


def find_if(
    t: Union[tuple, ir.Value, int],
    pred_fn: Callable[[int, Tuple[int, ...]], bool],
    *,
    loc=None,
    ip=None,
) -> Union[int, Tuple[int, ...], None]:
    from .core import rank, get

    """Find the first position in t where pred_fn(val, pos) returns True.

    :param t: The search space
    :type t: Union[tuple, ir.Value, int]
    :param pred_fn: A callable object (lambda, function, etc.) that predicates the value and position in t.
                    It takes the current leaf value and position, returns True if the value or position is satisfied.
    :type pred_fn: Callable[[int, Tuple[int, ...]], bool]
    :return: Index if found at top level, tuple of indices showing nested position, or None if not found
    :rtype: Union[int, Tuple[int, ...], None]

    **Examples:**

    .. code-block:: python

        # Find the first position of x in t
        t = (3, 4)
        find_if(t, pred_fn=lambda val, pos: val == x)

    .. code-block:: python

        # find the leading dimension
        shape = (3, 4)
        stride = (4, 1)
        # Find value 1 in stride where the corresponding shape is not 1
        def pred_fn(val, pos):
            mode = [pos] if isinstance(pos, int) else list(pos)
            return val == 1 and get(shape, mode) != 1
        find_if(stride, pred_fn=pred_fn)
    """

    def _find_if_impl(curr, pos, *, loc=None, ip=None):
        if isinstance(curr, tuple):
            # Recursively search nested tuple
            for i in range(rank(curr)):
                sub_curr = get(curr, mode=[i], loc=loc, ip=ip)
                sub_pos = (pos, i) if isinstance(pos, int) else pos + (i,)
                res_pos = _find_if_impl(sub_curr, sub_pos, loc=loc, ip=ip)
                if res_pos is not None:
                    return res_pos
        else:
            # For leaf values, check if it matches x
            if pred_fn(curr, pos):
                return pos
        return None

    def _check_pred_fn():
        if not callable(pred_fn):
            raise TypeError(f"pred_fn must be callable, but got {type(pred_fn)}")

        sig = signature(pred_fn)
        if len(sig.parameters) != 2:
            raise ValueError(
                f"pred_fn must have two parameters (value, pos), but got {len(sig.parameters)}"
            )

    _check_pred_fn()

    for i in range(rank(t)):
        curr = get(t, mode=[i], loc=loc, ip=ip)
        res_pos = _find_if_impl(curr, i, loc=loc, ip=ip)
        if res_pos is not None:
            return res_pos
    return None


@dsl_user_op
def find(
    t: Union[tuple, ir.Value, int], x: int, *, loc=None, ip=None
) -> Union[int, Tuple[int, ...], None]:
    """Find the first position of a value ``x`` in a hierarchical structure ``t``.

    Searches for the first occurrence of x in t, optionally excluding positions
    where a comparison value matches. The search can traverse nested structures
    and returns either a single index or a tuple of indices for nested positions.

    :param t: The search space
    :type t: Union[tuple, ir.Value, int]
    :param x: The static integer x to search for
    :type x: int
    :return: Index if found at top level, tuple of indices showing nested position, or None if not found
    :rtype: Union[int, Tuple[int, ...], None]
    """
    if not isinstance(x, int):
        raise TypeError(f"find() requires a static x to search for, but got {x}")

    def pred_fn(val, pos):
        # Skip dynamic values which can't be compared
        return not is_dynamic_expression(val) and val == x

    return find_if(t, pred_fn=pred_fn, loc=loc, ip=ip)


def transform_leaf(f, *args):
    """
    Apply a function to the leaf nodes of nested tuple structures.

    This function traverses nested tuple structures in parallel and applies the function f
    to corresponding leaf nodes. All input tuples must have the same nested structure.

    :param f: Function to apply to leaf nodes
    :type f: Callable
    :param args: One or more nested tuple structures with matching profiles
    :return: A new nested tuple with the same structure as the inputs, but with leaf values transformed by f
    :raises TypeError: If the input tuples have different nested structures

    **Example:**

    .. code-block:: python

        >>> transform_leaf(lambda x: x + 1, (1, 2))
        (2, 3)
        >>> transform_leaf(lambda x, y: x + y, (1, 2), (3, 4))
        (4, 6)
        >>> transform_leaf(lambda x: x * 2, ((1, 2), (3, 4)))
        ((2, 4), (6, 8))
    """
    if all(isinstance(t, tuple) for t in args):
        return tuple(transform_leaf(f, *_args) for _args in zip(*args))
    elif all(not isinstance(t, tuple) for t in args):
        return f(*args)
    else:
        raise TypeError(f"profile of input tuples doesn't match: {args}")


@dsl_user_op
def elem_less(
    lhs: Union[Shape, IntTuple, Coord],
    rhs: Union[Shape, IntTuple, Coord],
    *,
    loc=None,
    ip=None,
) -> Boolean:
    from .core import _pack_coord

    # Coord is super set of IntTuple and Shape
    lhs_val = _pack_coord(lhs, loc=loc, ip=ip)
    rhs_val = _pack_coord(rhs, loc=loc, ip=ip)
    return Boolean(_cute_ir.elem_less(lhs_val, rhs_val, loc=loc, ip=ip))
