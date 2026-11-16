# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Private provider access to verified facts about one traced launch.

The launch backend attaches a versioned metadata dictionary to each supported
kernel operation before tracing its body. Absent optional fields mean the
backend could not prove one static value. Missing, malformed, or unsupported
metadata raises :class:`DSLRuntimeError` instead of returning partial facts.
"""

from dataclasses import dataclass

from cutlass.cutlass_dsl import DSLRuntimeError
from cutlass.cutlass_dsl._launch_facts_metadata import (
    CLUSTER_LAUNCH_FIELD,
    COOPERATIVE_LAUNCH_FIELD,
    EXACT_BLOCK_DIM_FIELD,
    EXACT_CLUSTER_DIM_FIELD,
    EXACT_GRID_DIM_FIELD,
    LAUNCH_FACTS_ATTR,
    LAUNCH_FACTS_SCHEMA_VERSION,
    LAUNCH_FACTS_SCHEMA_VERSION_FIELD,
)
from cutlass._mlir import ir


_KERNEL_OP_NAMES = frozenset({"cuda.kernel", "lir.func"})


def _current_kernel(ip: ir.InsertionPoint | None) -> ir.Operation:
    """Return the enclosing kernel while a supported CuTe kernel is traced."""

    if ip is not None:
        current_ip = ip
    else:
        try:
            current_ip = ir.InsertionPoint.current
        except Exception as exc:
            raise DSLRuntimeError(
                "_get_launch_facts must be called while tracing a CuTe kernel"
            ) from exc

    if current_ip is None or current_ip.block is None:
        raise DSLRuntimeError(
            "_get_launch_facts must be called while tracing a CuTe kernel"
        )

    op = current_ip.block.owner
    while op is not None:
        operation = getattr(op, "operation", op)
        if operation.name in _KERNEL_OP_NAMES:
            return operation
        op = operation.parent
    raise DSLRuntimeError(
        "_get_launch_facts must be called while tracing a CuTe kernel"
    )


@dataclass(frozen=True)
class LaunchFacts:
    """Statically verified topology facts for one traced kernel launch.

    Each dimension field is a positive three-element tuple or ``None`` when the
    value is runtime-dynamic or not uniquely determined. In particular,
    ``exact_cluster_dim`` is absent when preferred and fallback cluster shapes
    differ. A launch-mode field is ``None`` when the backend cannot prove a
    static Boolean value.
    """

    exact_block_dim: tuple[int, int, int] | None = None
    exact_grid_dim: tuple[int, int, int] | None = None
    exact_cluster_dim: tuple[int, int, int] | None = None
    cooperative_launch: bool | None = None
    cluster_launch: bool | None = None


def _required_version(attrs: ir.DictAttr) -> None:
    try:
        version = ir.IntegerAttr(attrs[LAUNCH_FACTS_SCHEMA_VERSION_FIELD]).value
    except (KeyError, TypeError, ValueError) as exc:
        raise DSLRuntimeError(
            "launch facts metadata has no valid schema version"
        ) from exc
    if version != LAUNCH_FACTS_SCHEMA_VERSION:
        raise DSLRuntimeError(
            f"unsupported launch facts schema version {version}; "
            f"expected {LAUNCH_FACTS_SCHEMA_VERSION}"
        )


def _optional_dim(attrs: ir.DictAttr, name: str) -> tuple[int, int, int] | None:
    try:
        raw = attrs[name]
    except KeyError:
        return None
    try:
        values = tuple(int(value) for value in ir.DenseI64ArrayAttr(raw))
    except (TypeError, ValueError) as exc:
        raise DSLRuntimeError(
            f"launch facts field {name!r} must be a three-dimensional integer array"
        ) from exc
    if len(values) != 3 or any(value <= 0 for value in values):
        raise DSLRuntimeError(
            f"launch facts field {name!r} must contain three positive dimensions"
        )
    return values  # type: ignore[return-value]


def _optional_bool(attrs: ir.DictAttr, name: str) -> bool | None:
    try:
        raw = attrs[name]
    except KeyError:
        return None
    try:
        return ir.BoolAttr(raw).value
    except (TypeError, ValueError) as exc:
        raise DSLRuntimeError(f"launch facts field {name!r} must be a bool") from exc


def _get_launch_facts(
    *,
    ip: ir.InsertionPoint | None = None,
) -> LaunchFacts:
    """Return the static launch facts attached to the enclosing CuTe kernel.

    This private provider API is available only while tracing a ``cuda.kernel``
    or ``lir.func``. It does not expose the complete launch configuration;
    fields whose values remain dynamic are returned as ``None``.

    Raises
    ------
    DSLRuntimeError
        If no supported kernel is being traced, launch metadata is absent, or
        its dictionary, schema version, dimensions, or Boolean fields are
        malformed.
    """

    kernel = _current_kernel(ip)
    try:
        raw_attrs = kernel.attributes[LAUNCH_FACTS_ATTR]
    except KeyError as exc:
        raise DSLRuntimeError(
            "launch facts are unavailable on the enclosing CuTe kernel"
        ) from exc
    try:
        attrs = ir.DictAttr(raw_attrs)
    except (TypeError, ValueError) as exc:
        raise DSLRuntimeError("launch facts metadata must be a dictionary") from exc
    _required_version(attrs)
    return LaunchFacts(
        exact_block_dim=_optional_dim(attrs, EXACT_BLOCK_DIM_FIELD),
        exact_grid_dim=_optional_dim(attrs, EXACT_GRID_DIM_FIELD),
        exact_cluster_dim=_optional_dim(attrs, EXACT_CLUSTER_DIM_FIELD),
        cooperative_launch=_optional_bool(attrs, COOPERATIVE_LAUNCH_FIELD),
        cluster_launch=_optional_bool(attrs, CLUSTER_LAUNCH_FIELD),
    )


__all__: list[str] = []
