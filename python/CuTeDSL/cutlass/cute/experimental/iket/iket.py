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


from typing import Any, List, Optional

from cutlass._mlir.dialects import iket, arith
from cutlass.cutlass_dsl import Boolean, dsl_user_op, if_generate, is_dynamic_expression
from cutlass.base_dsl.typing import Numeric
from cutlass._mlir import ir


def _as_raw_ir_value(v: Any) -> Any:
    # Pytree unflatten wraps raw ir.Values into Numeric for leaves marked
    # is_numeric=True. RangeToken stores _is_none_val as a raw ir.Value, so
    # unwrap any Numeric we get back before re-extracting — otherwise the
    # next _flatten_mlir_values call silently drops it (it only matches
    # ir.Value/list/dict) and the template/flat shape diverges across staged
    # control-flow boundaries.
    if isinstance(v, Numeric):
        return v.ir_value()
    return v


def _infer_payload_signedness(payload: Any) -> Optional[str]:
    """
    Infers whether the payload's dtype is signed or unsigned integer.
    """
    dtype = getattr(payload, "dtype", None)
    if dtype is None:
        return None
    if not getattr(dtype, "is_integer", False):
        return None
    signed = getattr(dtype, "signed", None)
    if signed is None:
        return None
    return "signed" if signed else "unsigned"


def _coerce_imm_payload(
    payload: Any,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Any:
    """
    Convert a raw Python int or float immediate value to an MLIR constant ir.Value.
    int -> signless i32 constant; float -> f32 constant.
    DSL typed values or ir.Value objects are returned unchanged.
    """
    if isinstance(payload, bool):
        # bool is a subclass of int; treat as i1
        i1 = ir.IntegerType.get_signless(1)
        return arith.ConstantOp(
            i1, ir.IntegerAttr.get(i1, int(payload)), loc=loc, ip=ip
        ).result
    if isinstance(payload, int):
        i32 = ir.IntegerType.get_signless(32)
        return arith.ConstantOp(
            i32, ir.IntegerAttr.get(i32, payload), loc=loc, ip=ip
        ).result
    if isinstance(payload, float):
        f32 = ir.F32Type.get()
        return arith.ConstantOp(
            f32, ir.FloatAttr.get(f32, payload), loc=loc, ip=ip
        ).result
    return payload


def _attach_payload_signedness_attr(op: Any, payload: Any) -> Any:
    """
    Attaches a payload_signedness attribute to the given op if the payload has a signedness (signed/unsigned),
    inferring it from the payload's dtype.
    """
    payload_signedness = _infer_payload_signedness(payload)
    if payload_signedness is None:
        return op
    operation = getattr(op, "operation", None)
    if operation is None:
        operation = getattr(op, "owner", None)
    if operation is None:
        return op
    operation.attributes["payload_signedness"] = ir.StringAttr.get(payload_signedness)
    return op


def _make_i1_constant(
    value: bool,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Any:
    """Create an i1 MLIR constant (0 or 1)."""
    i1 = ir.IntegerType.get_signless(1)
    return arith.ConstantOp(
        i1, ir.IntegerAttr.get(i1, int(value)), loc=loc, ip=ip
    ).result


class RangeToken:
    """A token representing a range, carrying an ``!iket.range.token`` SSA value
    and an ``i1`` flag indicating whether the token is a *none* (sentinel) token.

    Implements the DynamicExpression protocol (``__extract_mlir_values__`` /
    ``__new_from_mlir_values__``) so the DSL compiler can thread it through
    ``scf.for`` as a loop-carried variable.
    """

    def __init__(self) -> None:
        self.token = ir.Type.parse("!iket.range.token")
        self.region = ir.InsertionPoint.current
        self.op: Any = None
        self._is_none_val: Any = None
        self._event_name: Optional[str] = None

    # -- DynamicExpression protocol ------------------------------------------

    def __extract_mlir_values__(self) -> List[Any]:
        return [self.op, _as_raw_ir_value(self._is_none_val)]

    def __new_from_mlir_values__(self, values: List[Any]) -> "RangeToken":
        new = RangeToken.__new__(RangeToken)
        new.token = self.token
        new.region = self.region
        new.op = values[0]
        new._is_none_val = _as_raw_ir_value(values[1])
        new._event_name = self._event_name
        return new


@dsl_user_op
def mark(
    event_name: str,
    payload: Any = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Any:
    """
    Mark an event in the kernel, optionally with a payload value.

    When used without a payload, generates a simple checkpoint marker.
    When used with a payload, the payload is dumped alongside the timestamp
    for analysis. Payload support requires NativeDump instrumentation method.
    Supported payload types: i8, i16, i32, f32 (32-bit), i64, and pointer (64-bit).

    :param event_name: Name of the event to mark
    :type event_name: str
    :param payload: Optional payload value to attach to the event
    :type payload: Any numeric type (Int8, Int16, Int32, Int64, Float32, Index), optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    """

    if payload is not None:
        if is_dynamic_expression(payload):
            payload_value = payload.ir_value(loc=loc, ip=ip)
        else:
            payload_value = _coerce_imm_payload(payload, loc=loc, ip=ip)
        op = iket.mark(event_name, payload=payload_value, loc=loc, ip=ip)
        return _attach_payload_signedness_attr(op, payload)
    return iket.mark(event_name, loc=loc, ip=ip)


@dsl_user_op
def sentinel_token(
    event_name: str,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> RangeToken:
    """Create a sentinel range token for initializing loop-carried variables.

    The returned :class:`RangeToken` carries a valid ``!iket.range.token`` SSA
    value but is marked as sentinel (``is_none = true``).  When passed to
    :func:`range_end`, no instrumentation IR is emitted at runtime.  The
    ``event_name`` is required so that the correct event metadata is preserved
    when the token flows through ``scf.for`` loop-carried variables.

    Example::

        mma_k_tile_token = cute.experimental.iket.sentinel_token("MMA_K_Tile")
        for k_tile in cutlass.range(k_tile_cnt):
            cute.experimental.iket.range_end(mma_k_tile_token)   # no-op on first iteration
            mma_k_tile_token = cute.experimental.iket.range_start("MMA_K_Tile")
            ...

    :param event_name: The event name matching the :func:`range_start` that
        will produce real tokens in the loop body.
    :type event_name: str
    :return: A sentinel RangeToken safe to pass to ``range_end``
    :rtype: RangeToken
    """

    token = RangeToken()
    token.op = iket.sentinel_token(token.token, loc=loc, ip=ip)
    token._is_none_val = _make_i1_constant(True, loc=loc, ip=ip)
    token._event_name = event_name
    return token


@dsl_user_op
def range_start(
    event_name: str,
    payload: Any = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> RangeToken:
    """
    Mark the beginning of a range, optionally with a payload value.

    The payload is dumped alongside the timestamp for analysis.
    Payload support requires NativeDump instrumentation method.
    For a START_END range, the matching range_end must use the same payload
    shape as range_start. Do not mix payload and no-payload forms, and do not
    change payload width between the start and end of the same range.

    :param event_name: Name of the event/range to start
    :type event_name: str
    :param payload: Optional payload value to attach to the range start event
    :type payload: Any numeric type (Int8, Int16, Int32, Int64, Float32, Index), optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    :return: A RangeToken to be used with range_end
    :rtype: RangeToken
    """

    token = RangeToken()
    if payload is not None:
        if is_dynamic_expression(payload):
            payload_value = payload.ir_value(loc=loc, ip=ip)
        else:
            payload_value = _coerce_imm_payload(payload, loc=loc, ip=ip)
        token.op = iket.range_start(
            token.token, event_name, payload=payload_value, loc=loc, ip=ip
        )
        _attach_payload_signedness_attr(token.op, payload)
    else:
        token.op = iket.range_start(token.token, event_name, loc=loc, ip=ip)
    token._is_none_val = _make_i1_constant(False, loc=loc, ip=ip)
    token._event_name = event_name
    return token


@dsl_user_op
def range_end(
    token: RangeToken,
    payload: Any = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Mark the end of a range, optionally with a payload value.

    If *token* is a sentinel token (from :func:`sentinel_token`), no
    instrumentation IR is emitted.
    For a START_END range, this payload must match the payload usage of the
    corresponding range_start. If the range was started with a payload, end it
    with a payload of the same type/width; if it was started without payload,
    end it without payload.

    :param token: The RangeToken from range_start (or sentinel_token)
    :type token: RangeToken
    :param payload: Optional payload value to attach to the range end event
    :type payload: Any numeric type (Int8, Int16, Int32, Int64, Float32, Index), optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    """

    def _emit_range_end() -> None:
        event_name_kwarg = {}
        if token._event_name is not None:
            event_name_kwarg["event_name"] = token._event_name

        if payload is not None:
            if is_dynamic_expression(payload):
                payload_value = payload.ir_value(loc=loc, ip=ip)
            else:
                payload_value = _coerce_imm_payload(payload, loc=loc, ip=ip)
            op = iket.range_end(
                token.op,
                payload=payload_value,
                loc=loc,
                ip=ip,
                **event_name_kwarg,
            )
            _attach_payload_signedness_attr(op, payload)
        else:
            op = iket.range_end(token.op, loc=loc, ip=ip, **event_name_kwarg)

    is_not_none = Boolean(token._is_none_val) == 0
    if_generate(is_not_none, _emit_range_end, loc=loc, ip=ip)


@dsl_user_op
def range_push(
    event_name: str,
    payload: Any = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Any:
    """
    Push a range onto the stack, optionally with a payload value.

    This marks the start of a push/pop range using a stack-based model.
    Unlike range_start/range_end which use SSA tokens for pairing, push/pop
    ranges are paired using a LIFO stack - each pop matches the most recent push.

    Payload support requires NativeDump instrumentation method.

    :param event_name: Name of the event to push
    :type event_name: str
    :param payload: Optional payload value to attach to the push event
    :type payload: Any numeric type (Int8, Int16, Int32, Int64, Float32, Index), optional
    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    """

    if payload is not None:
        if is_dynamic_expression(payload):
            payload_value = payload.ir_value(loc=loc, ip=ip)
        else:
            payload_value = _coerce_imm_payload(payload, loc=loc, ip=ip)
        op = iket.range_push(event_name, payload=payload_value, loc=loc, ip=ip)
        return _attach_payload_signedness_attr(op, payload)
    return iket.range_push(event_name, loc=loc, ip=ip)


@dsl_user_op
def range_pop(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Any:
    """
    Pop a range from the stack.

    This marks the end of the most recent push/pop range.
    Uses a reserved event ID (31) - no event name needed.

    :param loc: Source location for MLIR, defaults to None
    :type loc: Optional[Location], optional
    :param ip: Insertion point for MLIR, defaults to None
    :type ip: Optional[InsertionPoint], optional
    """

    return iket.range_pop(loc=loc, ip=ip)
