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

from .core import TensorSSA
from cutlass._mlir.dialects import math, arith


def acos(a: TensorSSA) -> TensorSSA:
    """Compute element-wise arc cosine of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :return: Tensor containing the arc cosine of each element in input tensor
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = acos(y)  # Compute arc cosine
    """
    return TensorSSA(math.acos(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def asin(a: TensorSSA) -> TensorSSA:
    """Compute element-wise arc sine of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :return: Tensor containing the arc sine of each element in input tensor
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = asin(y)  # Compute arc sine
    """
    return TensorSSA(math.asin(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def atan(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise arc tangent of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the arc tangent of each element in input tensor
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = atan(y)  # Compute arc tangent
    """
    raise NotImplementedError("atan is not implemented")
    return TensorSSA(math.atan(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def atan2(a: TensorSSA, b: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise arc tangent of two tensors.

    Computes atan2(a, b) element-wise. The function atan2(a, b) is the angle in radians
    between the positive x-axis and the point given by the coordinates (b, a).

    :param a: First input tensor (y-coordinates)
    :type a: TensorSSA
    :param b: Second input tensor (x-coordinates)
    :type b: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the arc tangent of a/b element-wise
    :rtype: TensorSSA

    Example:

    .. code-block::

        y = cute.make_fragment(ptr1, layout).load()  # y coordinates
        x = cute.make_fragment(ptr2, layout).load()  # x coordinates
        theta = atan2(y, x)  # Compute angles
    """
    return TensorSSA(
        math.atan2(a, b, fastmath=arith.FastMathFlags.none), a.shape, a.dtype
    )


def cos(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise cosine of the input tensor.

    :param a: Input tensor (in radians)
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the cosine of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = cos(y)  # Compute cosine
    """
    return TensorSSA(math.cos(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def erf(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise error function of the input tensor.

    The error function is defined as:
    erf(x) = 2/√π ∫[0 to x] exp(-t²) dt

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the error function value for each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = erf(y)  # Compute error function
    """
    return TensorSSA(math.erf(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def exp2(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise base-2 exponential of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing 2 raised to the power of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = exp2(y)  # Compute 2^x
    """
    return TensorSSA(math.exp2(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def log(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise natural logarithm of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the natural logarithm of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = log(y)  # Compute natural logarithm
    """
    return TensorSSA(math.log(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def log2(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise base-2 logarithm of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the base-2 logarithm of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = log2(y)  # Compute log base 2
    """
    return TensorSSA(math.log2(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def log10(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise base-10 logarithm of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the base-10 logarithm of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = log10(y)  # Compute log base 10
    """
    return TensorSSA(math.log10(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def rsqrt(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise reciprocal square root of the input tensor.

    Computes 1/√x element-wise.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the reciprocal square root of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = rsqrt(y)  # Compute 1/√x
    """
    return TensorSSA(math.rsqrt(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def sin(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise sine of the input tensor.

    :param a: Input tensor (in radians)
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the sine of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = sin(y)  # Compute sine
    """
    return TensorSSA(math.sin(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def sqrt(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise square root of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the square root of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = sqrt(y)  # Compute square root
    """
    return TensorSSA(math.sqrt(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def tan(a: TensorSSA) -> TensorSSA:
    """Compute element-wise tangent of the input tensor.

    :param a: Input tensor (in radians)
    :type a: TensorSSA
    :return: Tensor containing the tangent of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = tan(y)  # Compute tangent
    """
    return TensorSSA(math.tan(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


def tanh(a: TensorSSA, fastmath: bool = False) -> TensorSSA:
    """Compute element-wise hyperbolic tangent of the input tensor.

    :param a: Input tensor
    :type a: TensorSSA
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :return: Tensor containing the hyperbolic tangent of each element
    :rtype: TensorSSA

    Example:

    .. code-block::

        x = cute.make_fragment(layout)  # Create tensor
        y = x.load()  # Load values
        z = tanh(y)  # Compute hyperbolic tangent
    """
    return TensorSSA(math.tanh(a, fastmath=arith.FastMathFlags.none), a.shape, a.dtype)


__all__ = [
    "acos",
    "asin",
    "atan",
    "atan2",
    "cos",
    "erf",
    "exp2",
    "log",
    "log10",
    "log2",
    "rsqrt",
    "sin",
    "sqrt",
    "tan",
    "tanh",
]
