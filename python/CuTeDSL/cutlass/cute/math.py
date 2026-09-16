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

"""CuTeDSL math API — Array-aware wrappers over :mod:`cutlass._mlir_helpers.math`.

All math implementations live in the foundation module. This file is the
canonical CuTeDSL-side surface and adds ``Array`` support on top of the
foundation ops: each op unwraps an ``Array``'s underlying ``Vector`` before
delegating, then rewraps the result as an ``Array`` when appropriate.

For ``TensorSSA`` / ``Vector`` / scalar inputs the wrapper is transparent.
``TensorSSA`` inherits from ``Vector``, so the foundation's Vector dispatch
path handles CuTeDSL tensor values directly — no unwrap happens — and
per-element ops preserve a ``TensorSSA``'s CuTe nested shape via the
``_wrap_like`` polymorphic hook on the ``Vector`` base class.

``abs`` is also aliased to ``absf`` for backwards compatibility with the
historical CuTeDSL name.
"""

import functools
from typing import Any, Callable

from cutlass._mlir_helpers import math as _base_math
from cutlass._mlir_helpers.op import dsl_user_op
from cutlass._mlir_helpers.vector import Vector
from cutlass.base_dsl.typing import Array

# Re-export non-callable public symbols straight through.
from cutlass._mlir_helpers.math import RoundingMode, MathOperand  # noqa: F401


# =============================================================================
# Array unwrap / rewrap helpers
# =============================================================================


def _unwrap(x: Any) -> Any:
    """Return x's underlying Vector when x is an Array(Vector); else x."""
    if isinstance(x, Array) and isinstance(x._impl, Vector):
        return x._impl
    return x


def _first_array(*ops: Any) -> "Array | None":
    """First operand that is an Array(Vector), or None."""
    for op in ops:
        if isinstance(op, Array) and isinstance(op._impl, Vector):
            return op
    return None


def _rewrap(result: Any, ref: "Array | None") -> Any:
    """Rewrap ``result`` as ``Array(Vector)`` when ``ref`` was one.

    ``sincos`` returns a ``(sin, cos)`` tuple, so tuple results are rewrapped
    element-wise — each ``Vector`` element becomes an ``Array``; everything
    else (and all results when ``ref`` is ``None``) passes through unchanged.
    """
    if isinstance(result, tuple):
        return tuple(_rewrap(r, ref) for r in result)
    if ref is not None and isinstance(result, Vector):
        return Array(_impl=Vector(result, dtype=ref._impl._dtype))
    return result


def _make_wrapper(base_fn: Callable[..., Any], arity: int) -> Callable[..., Any]:
    """Build an Array-aware wrapper of fixed positional ``arity``."""

    @functools.wraps(base_fn)
    @dsl_user_op
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        ops = args[:arity]
        extras = args[arity:]
        ref = _first_array(*ops)
        unwrapped = tuple(_unwrap(op) for op in ops)
        result = base_fn(*unwrapped, *extras, **kwargs)
        return _rewrap(result, ref)

    return wrapper


# =============================================================================
# Bind Array-aware wrappers for every foundation op
# =============================================================================

_UNARY = (
    # Trigonometric
    "sin", "cos", "tan", "acos", "asin", "atan",
    # Hyperbolic
    "sinh", "cosh", "tanh", "acosh", "asinh", "atanh",
    # Exponential / logarithmic
    "exp", "exp2", "expm1", "log", "log2", "log10", "log1p",
    # Error functions
    "erf", "erfc",
    # Power / root
    "sqrt", "rsqrt", "cbrt", "rcp",
    # Absolute / sign / negation
    "abs", "absi", "neg",
    # Rounding
    "ceil", "floor", "round", "roundeven", "trunc",
    # Combined
    "sincos",
    # FP predicates
    "isnan", "isinf", "isfinite", "isnormal",
)  # fmt: skip

_BINARY = (
    "atan2", "pow", "fpowi", "ipowi", "copysign",
    "add", "sub", "mul", "div", "rem",
    "min", "max",
)  # fmt: skip

_TERNARY = ("fma", "clamp")


for _name in _UNARY:
    globals()[_name] = _make_wrapper(getattr(_base_math, _name), 1)

for _name in _BINARY:
    globals()[_name] = _make_wrapper(getattr(_base_math, _name), 2)

for _name in _TERNARY:
    globals()[_name] = _make_wrapper(getattr(_base_math, _name), 3)


# Historical CuTeDSL name for ``abs`` (Array-aware, same wrapper).
absf = globals()["abs"]


# Same public surface as the foundation, plus the ``absf`` alias.
__all__ = [*_base_math.__all__, "absf"]
