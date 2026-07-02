# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary

"""
Unified NVIDIA GPU math API.

This module exposes the full set of NVIDIA GPU math capabilities as a
single, stable Python surface. Each call is dispatched to the cleanest
layer that currently provides the requested semantics:

    1. MLIR ``math`` / ``arith`` dialect ops — target-agnostic,
       vectorizable, pattern-match friendly. The default and
       ``fastmath`` paths use this layer.
    2. ``nvvm.*`` dialect ops — first-class MLIR ops for a subset of
       NVIDIA-specific capabilities (``nvvm.fabs``, ``nvvm.fmin`` /
       ``fmax``, ``nvvm.rcp_approx_ftz_f``). Used where available.
    3. ``llvm.call_intrinsic "llvm.nvvm.*"`` — direct LLVM NVVM
       intrinsics for PTX modifier combinations (approx, ftz,
       specific rounding modes, ``div.full``) that don't yet have
       first-class MLIR ops.

Why this module exists
----------------------
Upstream MLIR's ``math`` / ``arith`` dialects are chartered
target-agnostic and intentionally don't carry NVIDIA-specific attributes
(approx, ftz, rounding mode, ``div.full``). The NVVM dialect
promotes a selected subset to first-class ops but deliberately
doesn't enumerate every PTX combination. That leaves a layer — the
full NVIDIA GPU math capability surface, presented to end users —
that neither upstream owner wants to fill. This module fills it.

As upstream ``math`` / ``arith`` gain rounding-mode attributes
(in progress) and the NVVM dialect promotes more PTX variants,
intrinsic-call paths here shrink. The user-facing API stays stable.

Supported operand types
-----------------------
    - Numeric scalars (Float32, Float64, Int32, etc.)
    - ArithValue / Vector (MLIR value types; subclasses like
      ``TensorSSA`` go through the Vector dispatch path automatically,
      and :meth:`Vector._wrap_like` preserves subclass-specific metadata
      on per-element results)
    - Python ``float`` / ``int`` / ``bool`` literals, promoted to
      ``Float32`` / ``Int32`` via :func:`_coerce_operand`.

Consumers that need to layer their own framework-specific types (e.g.,
memory-tracked array wrappers) can add a thin adapter that unwraps to a
supported type, delegates here, and rewraps the result.
"""

from enum import Enum
from typing import Any, Optional, Union

from .._mlir import ir
from .._mlir.extras import types as T
from .._mlir.dialects import arith, math as math_dialect, llvm, nvgpu, nvvm
from .arith import ArithValue, is_float_type, element_type
from .op import dsl_user_op
from .vector import Vector

from ..base_dsl.typing import Numeric, Float32, Int32

# =============================================================================
# Type alias
# =============================================================================

# Accepted operand types. ``Vector`` covers CuTeDSL's ``TensorSSA`` via
# inheritance (e.g., ``TensorSSA``). Additional framework-specific wrappers
# should be layered as thin adapters in their own package and delegate here.
# Python ``float``/``int``/``bool`` literals are promoted to ``Float32`` /
# ``Int32`` automatically so callers can write ``mul(x, 2.0)`` or
# ``add(x, 1)`` without manual wrapping.
MathOperand = Union[Numeric, Vector, float, int, bool]


# =============================================================================
# Enums
# =============================================================================


class RoundingMode(str, Enum):
    """IEEE 754 rounding modes for floating-point operations."""

    NEAREST_EVEN = "rn"
    ZERO = "rz"
    UP = "rp"
    DOWN = "rm"


# =============================================================================
# Internal helpers
# =============================================================================


def _coerce_operand(x: MathOperand) -> MathOperand:
    """Promote Python numeric literals to Numeric scalars.

    Python ``bool``/``int`` -> :class:`Int32`, ``float`` -> :class:`Float32`.
    ``bool`` is checked before ``int`` because ``bool`` subclasses ``int``.
    Non-literal operands (Numeric, ArithValue, Vector) pass through
    unchanged.
    """
    if isinstance(x, bool):
        return Int32(int(x))
    if isinstance(x, float):
        return Float32(x)
    if isinstance(x, int):
        return Int32(x)
    return x


def _numeric_type_name(x: MathOperand) -> str:
    """Return the scalar element type name of a coerced operand.

    Returns the class name of the scalar type (e.g. ``"Float32"``,
    ``"Int32"``). For ``Vector`` the dtype's class name is returned
    (``type(x.dtype).__name__``).
    """
    if isinstance(x, Vector):
        return type(x.dtype).__name__
    return type(x).__name__


def _validate_same_numeric_type(op_name: str, *operands: MathOperand) -> None:
    """Raise :class:`TypeError` if operands don't share one numeric type.

    Python literals are promoted via :func:`_coerce_operand` before the
    check, so the comparison is purely on Numeric / Vector element types
    after promotion.

    Mixing typed values (e.g. ``fma(Float64_val, Float32_val, Int32_val)``)
    would otherwise produce cryptic MLIR type-mismatch errors deep in the
    compiler. This helper surfaces the problem immediately.

    We promote Python literals (for ergonomics) but do *not* auto-promote
    heterogeneous typed values — if a user mixes Float32 and Float16, they
    need to convert explicitly.
    """
    coerced = [_coerce_operand(op) for op in operands]
    # Raw ArithValue operands (e.g. reduction results threaded through an
    # threaded through a task loop) don't carry a Numeric class, so comparing
    # ``type(op).__name__`` would produce false positives. Vector subclasses
    # ArithValue here, so we must exclude it explicitly.
    if any(isinstance(op, ArithValue) and not isinstance(op, Vector) for op in coerced):
        return
    type_names = [_numeric_type_name(op) for op in coerced]
    if len(set(type_names)) > 1:
        raise TypeError(
            f"All operands to {op_name} must have the same numeric type, "
            f"got {', '.join(type_names)}"
        )


def _check_vector_consistency(op_name: str, *operands: MathOperand) -> None:
    """Validate that vector-like and scalar operands aren't mixed.

    MLIR math/arith ops require all operands to share a shape. We forbid
    mixing a Vector with a Numeric scalar early so the user sees a clear
    TypeError instead of a cryptic MLIR error later.
    """
    coerced = [_coerce_operand(op) for op in operands]
    is_vector_like = [isinstance(op, Vector) for op in coerced]
    if any(is_vector_like) and not all(is_vector_like):
        vector_type = next(
            type(op).__name__ for op, is_v in zip(coerced, is_vector_like) if is_v
        )
        scalar_type = next(
            type(op).__name__ for op, is_v in zip(coerced, is_vector_like) if not is_v
        )
        raise TypeError(
            f"{op_name}: Expected all inputs to be of type {vector_type}, "
            f"but got {scalar_type} for another operand"
        )


def _get_ir_value(
    x: MathOperand, *, ip: Optional[ir.InsertionPoint] = None
) -> ir.Value:
    """Extract MLIR IR value from any supported operand type."""
    x = _coerce_operand(x)
    if isinstance(x, ir.Value):
        # Vector (and its subclasses) are already ir.Values — use directly.
        return x
    if not isinstance(x, Numeric):
        raise TypeError(f"Expected a Vector or Numeric, but got {type(x).__name__}")
    # Numeric (Float32, etc.) — has ir_value() method
    return x.ir_value(ip=ip)


def _get_element_type(x: MathOperand) -> ir.Type:
    """Get the scalar element type of an operand."""
    v = _get_ir_value(x)
    return element_type(v.type)


def _is_float(x: MathOperand) -> bool:
    """Check if operand is a floating-point type."""
    return is_float_type(_get_element_type(x))


def _is_f32(x: MathOperand) -> bool:
    return _get_element_type(x) == T.f32()


def _is_f64(x: MathOperand) -> bool:
    return _get_element_type(x) == T.f64()


def _is_unsigned_int(x: MathOperand) -> bool:
    """Check if operand is an unsigned integer type."""
    return not _is_float(x) and getattr(x, "signed", True) is False


def _wrap_result(original: MathOperand, result_ir: ir.Value) -> MathOperand:
    """Wrap an MLIR result back into the original operand's type."""
    if isinstance(original, Vector):
        # Polymorphic wrap: Vector subclasses (e.g., cute.TensorSSA) use
        # ``_wrap_like`` to preserve their own metadata (CuTe nested shape,
        # layout) when a math op returns a new SSA value. Fall back to a
        # plain Vector construction when the base-class hook isn't present
        # (compat with older Vector that doesn't yet define ``_wrap_like``).
        if hasattr(original, "_wrap_like"):
            return original._wrap_like(result_ir)
        return Vector(result_ir, dtype=original._dtype)
    if isinstance(original, ArithValue):
        return result_ir  # ArithValue IS an ir.Value
    # Coerce Python literals so we return a Numeric subclass instance instead
    # of attempting to construct e.g. ``float(ir.Value)``.
    original = _coerce_operand(original)
    # Numeric — wrap in the same Numeric subclass
    return type(original)(result_ir)


def _get_fastmath_flag(fastmath: bool) -> arith.FastMathFlags:
    return arith.FastMathFlags.fast if fastmath else arith.FastMathFlags.none


def _get_type_suffix(x: MathOperand) -> str:
    """Get NVVM type suffix: 'f' for f32, 'd' for f64."""
    if _is_f32(x):
        return "f"
    elif _is_f64(x):
        return "d"
    else:
        raise TypeError("NVVM math intrinsics require f32 or f64 scalar operands")


def _get_llvm_type(x: MathOperand) -> ir.Type:
    """Get LLVM result type for NVVM intrinsic."""
    if _is_f32(x):
        return T.f32()
    elif _is_f64(x):
        return T.f64()
    else:
        raise TypeError("NVVM math intrinsics require f32 or f64 scalar operands")


def _const_one(
    ty: ir.Type,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """Constant 1.0 of a scalar-float or vector-of-float type."""
    if isinstance(ty, ir.VectorType):
        attr = ir.DenseElementsAttr.get_splat(
            ty, ir.FloatAttr.get(ty.element_type, 1.0)
        )
        return arith.constant(ty, attr, loc=loc, ip=ip)
    return arith.constant(ty, 1.0, loc=loc, ip=ip)


# =============================================================================
# Validation
# =============================================================================


def _validate_fastmath_exclusive(
    op_name: str,
    fastmath: bool,
    *,
    approx: bool = False,
    ftz: bool = False,
    rounding: Optional[RoundingMode] = None,
    full: bool = False,
) -> None:
    """Raise if fastmath (math/arith dialect) is combined with NVVM attributes.

    Three valid modes:
    - No flags: strict MLIR math/arith op
    - fastmath=True: MLIR op with fastmath<fast> attribute
    - approx/ftz/rounding: NVVM intrinsic

    fastmath and approx/ftz/rounding are mutually exclusive because
    they target different MLIR dialects.
    """
    nvvm_attrs = []
    if approx:
        nvvm_attrs.append("approx")
    if ftz:
        nvvm_attrs.append("ftz")
    if rounding is not None:
        nvvm_attrs.append("rounding")
    if full:
        nvvm_attrs.append("full")
    if fastmath and nvvm_attrs:
        attr_str = "/".join(nvvm_attrs)
        raise ValueError(
            f"{op_name}: fastmath and {attr_str} are mutually exclusive. "
            f"fastmath uses math/arith dialect (compiler decides lowering); "
            f"{attr_str} emit NVVM intrinsics (exact instruction control)."
        )


def _validate_ftz_requires_approx(op_name: str, approx: bool, ftz: bool) -> None:
    """Raise if ftz is set without approx on transcendentals."""
    if ftz and not approx:
        raise ValueError(
            f"{op_name}: ftz requires approx=True for transcendental "
            f"functions. There is no non-approximate ftz variant."
        )


# =============================================================================
# NVVM intrinsic helpers
#
# Callers land here only when neither arith/math nor the NVVM dialect has a
# matching op for the requested (op, attributes, type) combination. Dialect-op
# coverage audit at time of writing:
#   - Scalar float add/sub/mul/fma with rounding+ftz: NVVM has only
#     *Packed*F32x2 variants; no scalar ops (nvvm.MulOp is integer).
#   - Scalar transcendental .approx (sin/cos/ex2/lg2/tanh/rsqrt/sqrt): no
#     NVVM dialect ops.
#   - Scalar div.approx / div.full / div.<rnd>: no NVVM dialect ops.
#   - Scalar sqrt.<rnd>: no NVVM dialect ops.
#   - Scalar rcp.<rnd> / rcp.approx (no ftz): no NVVM dialect ops.
# Ops that *do* have dialect coverage are used directly: nvvm.fabs (abs.ftz),
# nvvm.fmin/fmax (min/max.ftz), nvvm.rcp_approx_ftz_f (rcp scalar f32
# approx+ftz), nvgpu.rcp (vector rcp approx[.ftz]).
# =============================================================================

# NVVM intrinsics that use overloaded types (no .f/.d suffix).
_NVVM_OVERLOADED_OPS = frozenset({"ex2", "tanh"})


def _call_nvvm_unary(
    x: MathOperand,
    op_name: str,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    approx: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Call a unary NVVM intrinsic."""
    if isinstance(x, Vector):
        # NVVM intrinsics are scalar-only. For vectors (and Arrays that wrap
        # Vectors), we can't emit them without per-element unrolling (which
        # defeats vectorization). Direct users to the math/arith path (via
        # fastmath=True) so the MLIR pipeline can vectorize properly.
        attr = "approx" if approx else ("rounding" if rounding is not None else "ftz")
        raise TypeError(
            f"{op_name}: {attr} is scalar-only (NVVM intrinsics don't "
            f"vectorize). For vector inputs, use fastmath=True — the "
            f"math/arith dialect lowering will be vectorized by the compiler."
        )

    x_ir = _get_ir_value(x, ip=ip)
    result_type = _get_llvm_type(x)
    type_suffix = _get_type_suffix(x)

    intrinsic_name = f"llvm.nvvm.{op_name}"
    if approx:
        intrinsic_name += ".approx"
    elif rounding is not None:
        intrinsic_name += f".{rounding.value}"
    elif ftz:
        # ftz without explicit rounding: default to rn
        intrinsic_name += ".rn"
    if ftz:
        intrinsic_name += ".ftz"
    if op_name not in _NVVM_OVERLOADED_OPS:
        intrinsic_name += f".{type_suffix}"

    result = llvm.call_intrinsic(
        result_type,
        intrinsic_name,
        [x_ir],
        [],
        [],
        loc=loc,
        ip=ip,
    )
    return _wrap_result(x, result)


def _call_nvvm_binary(
    x: MathOperand,
    y: MathOperand,
    op_name: str,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    approx: bool = False,
    full: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Call a binary NVVM intrinsic."""
    if isinstance(x, Vector) or isinstance(y, Vector):
        # See _call_nvvm_unary: scalar-only; direct users to fastmath for
        # vectorizable math/arith lowering.
        attr = (
            "approx"
            if approx
            else ("full" if full else ("rounding" if rounding is not None else "ftz"))
        )
        raise TypeError(
            f"{op_name}: {attr} is scalar-only (NVVM intrinsics don't "
            f"vectorize). For vector inputs, use fastmath=True — the "
            f"math/arith dialect lowering will be vectorized by the compiler."
        )
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    result_type = _get_llvm_type(x)
    type_suffix = _get_type_suffix(x)

    intrinsic_name = f"llvm.nvvm.{op_name}"
    if approx:
        intrinsic_name += ".approx"
    elif full:
        intrinsic_name += ".full"
    elif rounding is not None:
        intrinsic_name += f".{rounding.value}"
    elif ftz:
        # ftz without explicit rounding: default to rn
        intrinsic_name += ".rn"
    if ftz:
        intrinsic_name += ".ftz"
    if not full:
        intrinsic_name += f".{type_suffix}"

    result = llvm.call_intrinsic(
        result_type,
        intrinsic_name,
        [x_ir, y_ir],
        [],
        [],
        loc=loc,
        ip=ip,
    )
    return _wrap_result(x, result)


def _call_nvvm_ternary(
    a: MathOperand,
    b: MathOperand,
    c: MathOperand,
    op_name: str,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Call a ternary NVVM intrinsic (e.g., fma)."""
    if any(isinstance(v, Vector) for v in (a, b, c)):
        # See _call_nvvm_unary: scalar-only; direct users to fastmath for
        # vectorizable math/arith lowering.
        attr = "rounding" if rounding is not None else "ftz"
        raise TypeError(
            f"{op_name}: {attr} is scalar-only (NVVM intrinsics don't "
            f"vectorize). For vector inputs, use fastmath=True — the "
            f"math/arith dialect lowering will be vectorized by the compiler."
        )
    a_ir = _get_ir_value(a, ip=ip)
    b_ir = _get_ir_value(b, ip=ip)
    c_ir = _get_ir_value(c, ip=ip)
    result_type = _get_llvm_type(a)
    type_suffix = _get_type_suffix(a)

    intrinsic_name = f"llvm.nvvm.{op_name}"
    if rounding is not None:
        intrinsic_name += f".{rounding.value}"
    else:
        intrinsic_name += ".rn"
    if ftz:
        intrinsic_name += ".ftz"
    intrinsic_name += f".{type_suffix}"

    result = llvm.call_intrinsic(
        result_type,
        intrinsic_name,
        [a_ir, b_ir, c_ir],
        [],
        [],
        loc=loc,
        ip=ip,
    )
    return _wrap_result(a, result)


def _needs_nvvm_intrinsic(rounding: Optional[RoundingMode], ftz: bool) -> bool:
    """Check if we need NVVM intrinsics (any explicit rounding or ftz)."""
    if ftz:
        return True
    if rounding is not None:
        return True
    return False


# =============================================================================
# Unary math helper
# =============================================================================


def _unary_math_op(
    x: MathOperand,
    float_op: Any,
    int_op: Any = None,
    fastmath: bool = False,
    op_name: str = "math_op",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Apply a unary MLIR math operation."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)

    if _is_float(x):
        result = float_op(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    else:
        if int_op is None:
            raise TypeError(f"{op_name} is only supported for floating-point types")
        result = int_op(x_ir, loc=loc, ip=ip)

    return _wrap_result(x, result)


# =============================================================================
# Transcendentals with NVVM approx intrinsics
# =============================================================================


@dsl_user_op
def sin(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise sine of the input operand.

    :param a: Input operand (in radians)
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the sine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = sin(a)  # Compute sine
    """
    _validate_fastmath_exclusive("sin", fastmath, approx=approx, ftz=ftz)
    _validate_ftz_requires_approx("sin", approx, ftz)
    if approx:
        return _call_nvvm_unary(x, "sin", approx=True, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.sin, None, fastmath, "sin", loc=loc, ip=ip)


@dsl_user_op
def cos(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise cosine of the input operand.

    :param a: Input operand (in radians)
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the cosine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = cos(a)  # Compute cosine
    """
    _validate_fastmath_exclusive("cos", fastmath, approx=approx, ftz=ftz)
    _validate_ftz_requires_approx("cos", approx, ftz)
    if approx:
        return _call_nvvm_unary(x, "cos", approx=True, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.cos, None, fastmath, "cos", loc=loc, ip=ip)


@dsl_user_op
def exp(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise exponential of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the exponential of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = exp(a)  # Compute exponential
    """
    return _unary_math_op(x, math_dialect.exp, None, fastmath, "exp", loc=loc, ip=ip)


@dsl_user_op
def exp2(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise base-2 exponential of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing 2 raised to the power of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = exp2(a)  # Compute 2^x
    """
    _validate_fastmath_exclusive("exp2", fastmath, approx=approx, ftz=ftz)
    _validate_ftz_requires_approx("exp2", approx, ftz)
    if approx:
        return _call_nvvm_unary(x, "ex2", approx=True, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.exp2, None, fastmath, "exp2", loc=loc, ip=ip)


@dsl_user_op
def log(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise natural logarithm of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the natural logarithm of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = log(a)  # Compute natural logarithm
    """
    return _unary_math_op(x, math_dialect.log, None, fastmath, "log", loc=loc, ip=ip)


@dsl_user_op
def log2(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise base-2 logarithm of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the base-2 logarithm of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = log2(a)  # Compute log base 2
    """
    _validate_fastmath_exclusive("log2", fastmath, approx=approx, ftz=ftz)
    _validate_ftz_requires_approx("log2", approx, ftz)
    if approx:
        return _call_nvvm_unary(x, "lg2", approx=True, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.log2, None, fastmath, "log2", loc=loc, ip=ip)


@dsl_user_op
def log10(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise base-10 logarithm of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the base-10 logarithm of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = log10(a)  # Compute log base 10
    """
    return _unary_math_op(
        x, math_dialect.log10, None, fastmath, "log10", loc=loc, ip=ip
    )


@dsl_user_op
def tanh(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise hyperbolic tangent of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the hyperbolic tangent of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = tanh(a)  # Compute hyperbolic tangent
    """
    _validate_fastmath_exclusive("tanh", fastmath, approx=approx)
    if approx:
        return _call_nvvm_unary(x, "tanh", approx=True, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.tanh, None, fastmath, "tanh", loc=loc, ip=ip)


@dsl_user_op
def rsqrt(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise reciprocal square root of the input operand.

    Computes 1/√x element-wise.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the reciprocal square root of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = rsqrt(a)  # Compute 1/√x
    """
    _validate_fastmath_exclusive("rsqrt", fastmath, approx=approx, ftz=ftz)
    _validate_ftz_requires_approx("rsqrt", approx, ftz)
    if approx:
        return _call_nvvm_unary(x, "rsqrt", approx=True, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(
        x, math_dialect.rsqrt, None, fastmath, "rsqrt", loc=loc, ip=ip
    )


@dsl_user_op
def sqrt(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    rounding: Optional[RoundingMode] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise square root of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the square root of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = sqrt(a)  # Compute square root
    """
    _validate_fastmath_exclusive(
        "sqrt", fastmath, approx=approx, ftz=ftz, rounding=rounding
    )
    if approx:
        return _call_nvvm_unary(x, "sqrt", approx=True, ftz=ftz, loc=loc, ip=ip)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_unary(x, "sqrt", rounding=rounding, ftz=ftz, loc=loc, ip=ip)
    return _unary_math_op(x, math_dialect.sqrt, None, fastmath, "sqrt", loc=loc, ip=ip)


# =============================================================================
# MLIR-only transcendentals (no NVVM approx intrinsic)
# =============================================================================


@dsl_user_op
def erf(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise error function of the input operand.

    The error function is defined as:
    erf(x) = 2/√π ∫[0 to x] exp(-t²) dt

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the error function value for each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = erf(a)  # Compute error function
    """
    return _unary_math_op(x, math_dialect.erf, None, fastmath, "erf", loc=loc, ip=ip)


@dsl_user_op
def tan(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise tangent of the input operand.

    :param a: Input operand (in radians)
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the tangent of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = tan(a)  # Compute tangent
    """
    return _unary_math_op(x, math_dialect.tan, None, fastmath, "tan", loc=loc, ip=ip)


@dsl_user_op
def acos(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise arc cosine of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the arc cosine of each element in input operand
    :rtype: MathOperand

    Example:

    .. code-block::

        y = acos(a)  # Compute arc cosine
    """
    return _unary_math_op(x, math_dialect.acos, None, fastmath, "acos", loc=loc, ip=ip)


@dsl_user_op
def asin(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise arc sine of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the arc sine of each element in input operand
    :rtype: MathOperand

    Example:

    .. code-block::

        y = asin(a)  # Compute arc sine
    """
    return _unary_math_op(x, math_dialect.asin, None, fastmath, "asin", loc=loc, ip=ip)


@dsl_user_op
def atan(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise arc tangent of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the arc tangent of each element in input operand
    :rtype: MathOperand

    Example:

    .. code-block::

        y = atan(a)  # Compute arc tangent
    """
    return _unary_math_op(x, math_dialect.atan, None, fastmath, "atan", loc=loc, ip=ip)


@dsl_user_op
def atan2(
    y: MathOperand,
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise arc tangent of two tensors.

    Computes atan2(a, b) element-wise. The function atan2(a, b) is the angle in radians
    between the positive x-axis and the point given by the coordinates (b, a).

    :param a: First input operand (y-coordinates)
    :type a: MathOperand
    :param b: Second input operand (x-coordinates)
    :type b: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the arc tangent of a/b element-wise
    :rtype: MathOperand

    Example:

    .. code-block::

        theta = atan2(y, x)  # Compute angles
    """
    _check_vector_consistency("atan2", y, x)
    _validate_same_numeric_type("atan2", y, x)
    y_ir = _get_ir_value(y, ip=ip)
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = math_dialect.atan2(y_ir, x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(y, result)


@dsl_user_op
def sinh(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise hyperbolic sine of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the hyperbolic sine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = sinh(a)  # Compute hyperbolic sine
    """
    return _unary_math_op(x, math_dialect.sinh, None, fastmath, "sinh", loc=loc, ip=ip)


@dsl_user_op
def cosh(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise hyperbolic cosine of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the hyperbolic cosine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = cosh(a)  # Compute hyperbolic cosine
    """
    return _unary_math_op(x, math_dialect.cosh, None, fastmath, "cosh", loc=loc, ip=ip)


@dsl_user_op
def pow(
    base: MathOperand,
    exponent: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise power of the input tensors.

    :param a: Input operand (base)
    :type a: MathOperand
    :param b: Input operand (exponent)
    :type b: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing a raised to the power b for each element
    :rtype: MathOperand

    Example:

    .. code-block::

        z = pow(a, b)  # Compute a^b
    """
    _check_vector_consistency("pow", base, exponent)
    _validate_same_numeric_type("pow", base, exponent)
    base_ir = _get_ir_value(base, ip=ip)
    exp_ir = _get_ir_value(exponent, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = math_dialect.powf(base_ir, exp_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(base, result)


@dsl_user_op
def cbrt(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise cube root of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the cube root of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = cbrt(a)  # Compute cube root
    """
    return _unary_math_op(x, math_dialect.cbrt, None, fastmath, "cbrt", loc=loc, ip=ip)


@dsl_user_op
def expm1(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise exp(x) - 1 of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing exp(x) - 1 of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = expm1(a)  # Compute exp(x) - 1
    """
    return _unary_math_op(
        x, math_dialect.expm1, None, fastmath, "expm1", loc=loc, ip=ip
    )


@dsl_user_op
def log1p(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise log(1 + x) of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing log(1 + x) of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = log1p(a)  # Compute log(1 + x)
    """
    return _unary_math_op(
        x, math_dialect.log1p, None, fastmath, "log1p", loc=loc, ip=ip
    )


# =============================================================================
# Absolute value, sign, rounding
# =============================================================================


@dsl_user_op
def abs(
    x: MathOperand,
    fastmath: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Absolute value (float or integer).

    :param ftz: Flush denormals to zero (float only, uses nvvm.fabs)
    """
    _validate_fastmath_exclusive("abs", fastmath, ftz=ftz)
    if ftz and _is_float(x):
        x_ir = _get_ir_value(x, ip=ip)
        result = nvvm.fabs(x_ir, ftz=True, loc=loc, ip=ip)
        return _wrap_result(x, result)
    return _unary_math_op(
        x,
        math_dialect.absf,
        math_dialect.absi,
        fastmath,
        "abs",
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def copysign(
    mag: MathOperand,
    sign: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise copysign, combining magnitude of a with sign of b.

    :param a: Input operand (magnitude source)
    :type a: MathOperand
    :param b: Input operand (sign source)
    :type b: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the copysign of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        z = copysign(a, b)  # Copy sign of b to magnitude of a
    """
    _check_vector_consistency("copysign", mag, sign)
    _validate_same_numeric_type("copysign", mag, sign)
    mag_ir = _get_ir_value(mag, ip=ip)
    sign_ir = _get_ir_value(sign, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = math_dialect.copysign(
        mag_ir, sign_ir, fastmath=fastmath_flag, loc=loc, ip=ip
    )
    return _wrap_result(mag, result)


@dsl_user_op
def ceil(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise ceiling of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the ceiling of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = ceil(a)  # Compute ceiling
    """
    return _unary_math_op(x, math_dialect.ceil, None, fastmath, "ceil", loc=loc, ip=ip)


@dsl_user_op
def floor(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise floor of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the largest integer less than or equal to each element in input operand
    :rtype: MathOperand

    Example:

    .. code-block::

        y = floor(a)  # Compute floor
    """
    return _unary_math_op(
        x, math_dialect.floor, None, fastmath, "floor", loc=loc, ip=ip
    )


@dsl_user_op
def round(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise round to nearest integer (ties away from zero) of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the rounded value of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = round(a)  # Round to nearest integer
    """
    return _unary_math_op(
        x, math_dialect.round, None, fastmath, "round", loc=loc, ip=ip
    )


@dsl_user_op
def roundeven(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise round to nearest integer (ties to even) of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the rounded value of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = roundeven(a)  # Round to nearest integer (ties to even)
    """
    return _unary_math_op(
        x, math_dialect.roundeven, None, fastmath, "roundeven", loc=loc, ip=ip
    )


@dsl_user_op
def trunc(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise truncation toward zero of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the truncated value of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = trunc(a)  # Truncate toward zero
    """
    return _unary_math_op(
        x, math_dialect.trunc, None, fastmath, "trunc", loc=loc, ip=ip
    )


# =============================================================================
# Min / Max
# =============================================================================


@dsl_user_op
def min(
    x: MathOperand,
    y: MathOperand,
    propagate_nan: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Element-wise minimum.

    :param propagate_nan: If True, NaN propagates (IEEE 754 minimum).
        If False, NaN is ignored (IEEE 754 minimumNumber).
    :param ftz: Flush denormals to zero (float only, uses nvvm.fmin).
    """
    _check_vector_consistency("min", x, y)
    _validate_same_numeric_type("min", x, y)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    if _is_float(x):
        if ftz:
            result = nvvm.fmin(x_ir, y_ir, ftz=True, nan=propagate_nan, loc=loc, ip=ip)
        elif propagate_nan:
            result = arith.minimumf(x_ir, y_ir, loc=loc, ip=ip)
        else:
            result = arith.minnumf(x_ir, y_ir, loc=loc, ip=ip)
    elif _is_unsigned_int(x):
        result = arith.minui(x_ir, y_ir, loc=loc, ip=ip)
    else:
        result = arith.minsi(x_ir, y_ir, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def max(
    x: MathOperand,
    y: MathOperand,
    propagate_nan: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Element-wise maximum.

    :param propagate_nan: If True, NaN propagates (IEEE 754 maximum).
        If False, NaN is ignored (IEEE 754 maximumNumber).
    :param ftz: Flush denormals to zero (float only, uses nvvm.fmax).
    """
    _check_vector_consistency("max", x, y)
    _validate_same_numeric_type("max", x, y)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    if _is_float(x):
        if ftz:
            result = nvvm.fmax(x_ir, y_ir, ftz=True, nan=propagate_nan, loc=loc, ip=ip)
        elif propagate_nan:
            result = arith.maximumf(x_ir, y_ir, loc=loc, ip=ip)
        else:
            result = arith.maxnumf(x_ir, y_ir, loc=loc, ip=ip)
    elif _is_unsigned_int(x):
        result = arith.maxui(x_ir, y_ir, loc=loc, ip=ip)
    else:
        result = arith.maxsi(x_ir, y_ir, loc=loc, ip=ip)
    return _wrap_result(x, result)


# =============================================================================
# FMA
# =============================================================================


@dsl_user_op
def fma(
    a: MathOperand,
    b: MathOperand,
    c: MathOperand,
    fastmath: bool = False,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Fused multiply-add: a * b + c."""
    _check_vector_consistency("fma", a, b, c)
    _validate_same_numeric_type("fma", a, b, c)
    _validate_fastmath_exclusive("fma", fastmath, ftz=ftz, rounding=rounding)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_ternary(a, b, c, "fma", rounding, ftz, loc=loc, ip=ip)
    a_ir = _get_ir_value(a, ip=ip)
    b_ir = _get_ir_value(b, ip=ip)
    c_ir = _get_ir_value(c, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = math_dialect.fma(a_ir, b_ir, c_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(a, result)


# =============================================================================
# Arithmetic with fastmath / rounding / ftz
# =============================================================================


@dsl_user_op
def add(
    x: MathOperand,
    y: MathOperand,
    fastmath: bool = False,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point addition."""
    _check_vector_consistency("add", x, y)
    _validate_same_numeric_type("add", x, y)
    _validate_fastmath_exclusive("add", fastmath, ftz=ftz, rounding=rounding)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_binary(x, y, "add", rounding, ftz, loc=loc, ip=ip)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = arith.addf(x_ir, y_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def sub(
    x: MathOperand,
    y: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point subtraction.

    Note: NVVM sub uses a different intrinsic convention (rounding as an
    integer arg), so rounding/ftz are not supported here. Callers that
    need explicit rounding control on subtraction should emit the
    PTX-level ``sub.<rn|rz|rm|rp>[.ftz].f32`` intrinsic directly.
    """
    _check_vector_consistency("sub", x, y)
    _validate_same_numeric_type("sub", x, y)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = arith.subf(x_ir, y_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def mul(
    x: MathOperand,
    y: MathOperand,
    fastmath: bool = False,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point multiplication."""
    _check_vector_consistency("mul", x, y)
    _validate_same_numeric_type("mul", x, y)
    _validate_fastmath_exclusive("mul", fastmath, ftz=ftz, rounding=rounding)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_binary(x, y, "mul", rounding, ftz, loc=loc, ip=ip)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = arith.mulf(x_ir, y_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def div(
    x: MathOperand,
    y: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    ftz: bool = False,
    full: bool = False,
    rounding: Optional[RoundingMode] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point division."""
    _check_vector_consistency("div", x, y)
    _validate_same_numeric_type("div", x, y)
    _validate_fastmath_exclusive(
        "div", fastmath, approx=approx, ftz=ftz, rounding=rounding, full=full
    )
    if fastmath:
        x_ir = _get_ir_value(x, ip=ip)
        y_ir = _get_ir_value(y, ip=ip)
        fastmath_flag = _get_fastmath_flag(True)
        result = arith.divf(x_ir, y_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
        return _wrap_result(x, result)
    if approx:
        return _call_nvvm_binary(x, y, "div", approx=True, ftz=ftz, loc=loc, ip=ip)
    if full:
        return _call_nvvm_binary(x, y, "div", full=True, ftz=ftz, loc=loc, ip=ip)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_binary(x, y, "div", rounding, ftz, loc=loc, ip=ip)
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    result = arith.divf(x_ir, y_ir, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def rcp(
    x: MathOperand,
    fastmath: bool = False,
    approx: bool = False,
    rounding: Optional[RoundingMode] = None,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Reciprocal (1/x)."""
    _validate_fastmath_exclusive(
        "rcp", fastmath, approx=approx, ftz=ftz, rounding=rounding
    )
    if fastmath:
        x_ir = _get_ir_value(x, ip=ip)
        one = _const_one(x_ir.type, loc=loc, ip=ip)
        fastmath_flag = _get_fastmath_flag(True)
        result = arith.divf(one, x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
        return _wrap_result(x, result)
    if approx:
        if isinstance(x, Vector):
            x_ir = _get_ir_value(x, ip=ip)
            result = nvgpu.rcp(
                x_ir,
                rounding=nvgpu.RcpRoundingMode.APPROX,
                ftz=ftz or None,
                loc=loc,
                ip=ip,
            )
            return _wrap_result(x, result)
        # Scalar approx+ftz on f32 has a first-class NVVM dialect op.
        # Prefer it over llvm.call_intrinsic for better pattern-match/
        # canonicalization visibility.
        if ftz and _is_f32(x):
            x_ir = _get_ir_value(x, ip=ip)
            result = nvvm.rcp_approx_ftz_f(x_ir, loc=loc, ip=ip)
            return _wrap_result(x, result)
        return _call_nvvm_unary(x, "rcp", approx=True, ftz=ftz, loc=loc, ip=ip)
    if _needs_nvvm_intrinsic(rounding, ftz):
        return _call_nvvm_unary(x, "rcp", rounding=rounding, ftz=ftz, loc=loc, ip=ip)
    # Default semantics: IEEE round-to-nearest reciprocal.
    # Scalar f32/f64: emit nvvm.rcp.rn.{f32,f64} (one PTX rcp instruction).
    # Vector or scalar element type without an NVVM scalar-rcp intrinsic
    # (e.g., f16): lower to arith.divf(1, x) — same IEEE semantics,
    # vectorizable by the compiler.
    if isinstance(x, Vector) or not (_is_f32(x) or _is_f64(x)):
        x_ir = _get_ir_value(x, ip=ip)
        one = _const_one(x_ir.type, loc=loc, ip=ip)
        result = arith.divf(one, x_ir, loc=loc, ip=ip)
        return _wrap_result(x, result)
    return _call_nvvm_unary(
        x, "rcp", rounding=RoundingMode.NEAREST_EVEN, loc=loc, ip=ip
    )


# =============================================================================
# Inverse hyperbolic
# =============================================================================


@dsl_user_op
def acosh(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise inverse hyperbolic cosine of the input operand.

    :param a: Input operand (must be >= 1.0)
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the inverse hyperbolic cosine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = acosh(a)  # Compute inverse hyperbolic cosine
    """
    return _unary_math_op(
        x, math_dialect.acosh, None, fastmath, "acosh", loc=loc, ip=ip
    )


@dsl_user_op
def asinh(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise inverse hyperbolic sine of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the inverse hyperbolic sine of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = asinh(a)  # Compute inverse hyperbolic sine
    """
    return _unary_math_op(
        x, math_dialect.asinh, None, fastmath, "asinh", loc=loc, ip=ip
    )


@dsl_user_op
def atanh(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise inverse hyperbolic tangent of the input operand.

    :param a: Input operand (must be in (-1, 1))
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the inverse hyperbolic tangent of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = atanh(a)  # Compute inverse hyperbolic tangent
    """
    return _unary_math_op(
        x, math_dialect.atanh, None, fastmath, "atanh", loc=loc, ip=ip
    )


# =============================================================================
# Complementary error function
# =============================================================================


@dsl_user_op
def erfc(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Compute element-wise complementary error function of the input operand.

    :param a: Input operand
    :type a: MathOperand
    :param fastmath: Enable fast math optimizations, defaults to False
    :type fastmath: bool, optional
    :param loc: Source location information, defaults to None
    :type loc: Optional[Location]
    :param ip: Insertion point for IR generation, defaults to None
    :type ip: Optional[InsertionPoint]
    :return: Result containing the complementary error function of each element
    :rtype: MathOperand

    Example:

    .. code-block::

        y = erfc(a)  # Compute complementary error function
    """
    return _unary_math_op(x, math_dialect.erfc, None, fastmath, "erfc", loc=loc, ip=ip)


# =============================================================================
# Combined sin+cos
# =============================================================================


@dsl_user_op
def sincos(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple:
    """Combined sine and cosine: returns (sin(x), cos(x)).

    More efficient than separate sin() and cos() calls.
    """
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    op = math_dialect.SincosOp(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return (_wrap_result(x, op.sin), _wrap_result(x, op.cos))


# =============================================================================
# Power variants
# =============================================================================


@dsl_user_op
def fpowi(
    base: MathOperand,
    exponent: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Float raised to integer power: base^exponent (exponent is integer)."""
    base_ir = _get_ir_value(base, ip=ip)
    exp_ir = _get_ir_value(exponent, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = math_dialect.fpowi(base_ir, exp_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(base, result)


@dsl_user_op
def ipowi(
    base: MathOperand,
    exponent: MathOperand,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Integer raised to integer power: base^exponent."""
    base_ir = _get_ir_value(base, ip=ip)
    exp_ir = _get_ir_value(exponent, ip=ip)
    result = math_dialect.ipowi(base_ir, exp_ir, loc=loc, ip=ip)
    return _wrap_result(base, result)


# =============================================================================
# Clamp (native math dialect op)
# =============================================================================


@dsl_user_op
def clamp(
    x: MathOperand,
    lo: MathOperand,
    hi: MathOperand,
    fastmath: bool = False,
    propagate_nan: bool = False,
    ftz: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Clamp value to range [lo, hi].

    Lowered unconditionally as ``max(lo, min(x, hi))``. The math dialect's
    ``clampf`` op currently has no LLVM translation interface registered, so
    a direct lowering fails at JIT time on scalar f16 inputs (and any other
    type). Composition via min/max picks up the right per-type lowering
    (``arith.minnumf`` / ``arith.maximumf`` / ``nvvm.fmin`` / ``nvvm.fmax``).
    """
    _validate_fastmath_exclusive("clamp", fastmath, ftz=ftz)
    inner = min(x, hi, propagate_nan=propagate_nan, ftz=ftz, loc=loc, ip=ip)
    return max(lo, inner, propagate_nan=propagate_nan, ftz=ftz, loc=loc, ip=ip)


# =============================================================================
# FP classification predicates
# =============================================================================


@dsl_user_op
def isnan(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Test if value is NaN. Returns i1."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    return math_dialect.isnan(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)


@dsl_user_op
def isinf(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Test if value is infinite. Returns i1."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    return math_dialect.isinf(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)


@dsl_user_op
def isfinite(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Test if value is finite. Returns i1."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    return math_dialect.isfinite(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)


@dsl_user_op
def isnormal(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Test if value is normal (not zero, subnormal, inf, or NaN). Returns i1."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    return math_dialect.isnormal(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)


# =============================================================================
# Integer math
# =============================================================================


@dsl_user_op
def absi(
    x: MathOperand,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Integer absolute value."""
    x_ir = _get_ir_value(x, ip=ip)
    result = math_dialect.absi(x_ir, loc=loc, ip=ip)
    return _wrap_result(x, result)


# =============================================================================
# Negation and remainder (arith dialect)
# =============================================================================


@dsl_user_op
def neg(
    x: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point negation."""
    x_ir = _get_ir_value(x, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = arith.negf(x_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(x, result)


@dsl_user_op
def rem(
    x: MathOperand,
    y: MathOperand,
    fastmath: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> MathOperand:
    """Floating-point remainder."""
    x_ir = _get_ir_value(x, ip=ip)
    y_ir = _get_ir_value(y, ip=ip)
    fastmath_flag = _get_fastmath_flag(fastmath)
    result = arith.remf(x_ir, y_ir, fastmath=fastmath_flag, loc=loc, ip=ip)
    return _wrap_result(x, result)


# =============================================================================
# __all__
# =============================================================================

__all__ = [
    "RoundingMode",
    "MathOperand",
    # Transcendentals with NVVM approx (hardware instructions)
    "sin",
    "cos",
    "exp2",
    "log2",
    "tanh",
    "rsqrt",
    "sqrt",
    # Transcendentals without hardware approx
    "exp",
    "log",
    "log10",
    # Trigonometric
    "tan",
    "acos",
    "asin",
    "atan",
    "atan2",
    # Hyperbolic
    "sinh",
    "cosh",
    "acosh",
    "asinh",
    "atanh",
    # Error functions
    "erf",
    "erfc",
    # Power / root / exponential
    "pow",
    "fpowi",
    "ipowi",
    "cbrt",
    "expm1",
    "log1p",
    # Combined
    "sincos",
    # Absolute value, sign, rounding
    "abs",
    "absi",
    "copysign",
    "neg",
    "ceil",
    "floor",
    "round",
    "roundeven",
    "trunc",
    # Clamp
    "clamp",
    # Min / Max
    "min",
    "max",
    # FP predicates
    "isnan",
    "isinf",
    "isfinite",
    "isnormal",
    # FMA
    "fma",
    # Arithmetic
    "add",
    "sub",
    "mul",
    "div",
    "rem",
    "rcp",
]
