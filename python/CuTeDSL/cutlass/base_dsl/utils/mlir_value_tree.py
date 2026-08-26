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

"""
Helpers for walking Python objects that carry MLIR values.

These functions recursively traverse arbitrary Python containers, dataclasses,
namespaces, and objects implementing the DSL value protocols
(``__extract_mlir_values__`` / ``__new_from_mlir_values__`` /
``__extract_mlir_attributes__``) to extract, flatten, rebuild, and enumerate the
MLIR values/attributes they contain. They are agnostic of ``BaseDSL`` and are
factored out of ``dsl.py`` so the core DSL class stays focused on JIT
orchestration.
"""

import dataclasses
from types import SimpleNamespace
from typing import Any, get_origin

from ..common import DSLUserCodeError
from ..diagnostics import DiagId
from ..typing import Constexpr, get_mlir_types
from .tree_utils import (
    is_namedtuple_instance,
    _flatten_mlir_values,
    _unflatten_mlir_values,
)
from ..._mlir import ir


def is_dynamic_expression(value: object) -> bool:
    """
    Given the `value`, check if itself is an IR value or recursively go through it to check if it contains IR value
    """
    if isinstance(value, (tuple, list)):
        for x in value:
            if is_dynamic_expression(x):
                return True
    elif isinstance(value, (ir.Value, ir.BlockArgumentList)) or hasattr(
        value, "__extract_mlir_values__"
    ):
        return True
    return False


def extract_mlir_values(obj: object, *, structured: bool = False) -> Any:
    """
    Given the `obj`, recursively go through it to extract all contained IR values.

    Args:
        obj: The object to extract MLIR values from
        structured: If False (default), returns a flat list of MLIR values.
                   If True, returns whatever __extract_mlir_values__ returns directly
                   (for tree-based debugging approach).

    Returns:
        If structured=False: list[ir.Value] - flat list of MLIR values
        If structured=True: the direct result of __extract_mlir_values__ (dict/list/ir.Value)
    """
    if structured:
        # Tree-structured mode: return __extract_mlir_values__ result directly
        if hasattr(obj, "__extract_mlir_values__"):
            return obj.__extract_mlir_values__()
        elif dataclasses.is_dataclass(obj) and not isinstance(obj, type):
            return {
                field.name: extract_mlir_values(
                    getattr(obj, field.name), structured=True
                )
                for field in dataclasses.fields(obj)
            }
        elif isinstance(obj, (tuple, list)):
            return [extract_mlir_values(x, structured=True) for x in obj]
        elif isinstance(obj, SimpleNamespace):
            return {
                k: extract_mlir_values(v, structured=True)
                for k, v in obj.__dict__.items()
            }
        elif isinstance(obj, ir.Value):
            return obj
        elif isinstance(obj, ir.BlockArgumentList):
            return list(obj)
        else:
            return None
    else:
        # Flat list mode (original behavior)
        res = []
        if hasattr(obj, "__extract_mlir_values__"):
            # Flatten whatever __extract_mlir_values__ returns to ensure we always get a flat list
            res = flatten_mlir_values(obj.__extract_mlir_values__())
        elif isinstance(obj, (tuple, list)):
            res = sum((extract_mlir_values(x) for x in obj), [])
        elif isinstance(obj, SimpleNamespace):
            res = []
            for k, v in obj.__dict__.items():
                res.extend(extract_mlir_values(v))
        elif isinstance(obj, set):
            raise DSLUserCodeError(
                DiagId.ARG_UNORDERED_CONTAINER,
            )
        elif isinstance(obj, ir.Value):
            res = [obj]
        elif isinstance(obj, ir.BlockArgumentList):
            res = list(obj)

        return res


# Canonical implementations live in utils/tree_utils (the lower-level module this
# one already depends on). Re-exported here under their public names so existing
# ``flatten_mlir_values`` / ``unflatten_mlir_values`` call sites keep working
# without carrying a duplicate copy.
flatten_mlir_values = _flatten_mlir_values
unflatten_mlir_values = _unflatten_mlir_values


def extract_mlir_attributes(obj: object) -> list[Any]:
    """
    Given the `obj`, recursively go through it to extract all contained IR attributes as list of MLIR attributes.
    This is used for generating kernel function argument attributes.
    """
    res = []
    if hasattr(obj, "__extract_mlir_attributes__"):
        res = obj.__extract_mlir_attributes__()
    elif isinstance(obj, (tuple, list)):
        res = sum((extract_mlir_attributes(x) for x in obj), [])
    elif isinstance(obj, SimpleNamespace):
        res = []
        for k, v in obj.__dict__.items():
            res.extend(extract_mlir_attributes(v))
    elif dataclasses.is_dataclass(obj) and not isinstance(obj, type):
        # Recurse into dataclass fields so per-field arg attrs (e.g.
        # `cute_nvgpu.grid_constant` carried by a TMA atom) survive when the
        # field is wrapped in a dataclass that customises
        # `__extract_mlir_values__` but not `__extract_mlir_attributes__`.
        # Without this the fallback below returns empty DictAttrs and the
        # downstream `cute_nvgpu.atom.make_exec_tma` lowering can't trace
        # back to the byval load, failing legalization.
        res = []
        for f in dataclasses.fields(obj):
            v = getattr(obj, f.name)
            # Skip static-value fields that don't contribute kernel args:
            # - None (optional/unset)
            # - class objects (e.g. a `dtype = Float32` field whose value is a
            #   Numeric subclass; `isinstance(v, type)` catches classes with any
            #   metaclass, including cutlass `NumericMeta`)
            # - exact-type primitives (int/float/bool/str); use `type(v) in (...)`
            #   so that subclass instances carrying their own DSL hooks (e.g.
            #   `numpy.float64`) still get recursed into
            if v is None or isinstance(v, type) or type(v) in (int, float, bool, str):
                continue
            ftype = f.type
            origin = get_origin(ftype) if not isinstance(ftype, str) else None
            if ftype is Constexpr or origin is Constexpr:
                continue
            res.extend(extract_mlir_attributes(v))
    # Can't call is_dynamic_expression as _is_dynamic_expression depends on extract_mlir_values
    elif isinstance(obj, set):
        raise DSLUserCodeError(
            DiagId.ARG_UNORDERED_CONTAINER,
        )
    elif isinstance(obj, ir.Value):
        res = [ir.DictAttr.get({})]
    elif isinstance(obj, ir.BlockArgumentList):
        res = [ir.DictAttr.get({})] * len(obj)
    else:
        # Unlike extract_mlir_values we expand in the default case that we do not have an __extract_mlir_attributes__
        res = [ir.DictAttr.get({})] * len(get_mlir_types(obj))

    return res


def new_from_mlir_values(obj: Any, values: Any, *, structured: bool = False) -> Any:
    """
    Create a new python object by populating containing MLIR values with new values.

    Args:
        obj: The original object to use as a template
        values: Either a flat list of MLIR values (structured=False) or
                a nested structure matching __extract_mlir_values__ output (structured=True)
        structured: If False (default), values is a flat list sliced by type counts.
                   If True, values is passed directly to __new_from_mlir_values__.

    Returns:
        A new object of the same type as obj, with MLIR values replaced
    """
    # Objects with __new_from_mlir_values__ always receive values directly
    if hasattr(obj, "__new_from_mlir_values__"):
        return obj.__new_from_mlir_values__(values)

    if structured:
        # Tree-structured mode
        if dataclasses.is_dataclass(obj) and not isinstance(obj, type):
            new_field_values = {
                field.name: new_from_mlir_values(
                    getattr(obj, field.name), values[field.name], structured=True
                )
                for field in dataclasses.fields(obj)
            }
            return type(obj)(**new_field_values)
        elif isinstance(obj, (tuple, list)):
            res = [
                new_from_mlir_values(x, v, structured=True) for x, v in zip(obj, values)
            ]
            if is_namedtuple_instance(obj):
                return type(obj)(*res)
            return type(obj)(res)
        elif isinstance(obj, SimpleNamespace):
            ns = SimpleNamespace()
            for k, v in obj.__dict__.items():
                ns.__dict__[k] = new_from_mlir_values(v, values[k], structured=True)
            return ns
        elif isinstance(obj, ir.Value):
            return values
        elif is_dynamic_expression(obj):
            return values
        else:
            return obj
    else:
        # Flat list mode (original behavior)
        if isinstance(obj, (tuple, list)):
            res = []
            for x in obj:
                n_items = len(get_mlir_types(x))
                res.append(new_from_mlir_values(x, values[:n_items]))
                values = values[n_items:]
            obj_ty = type(obj)
            if is_namedtuple_instance(obj):
                return obj_ty(*res)
            return obj_ty(res)
        elif isinstance(obj, SimpleNamespace):
            ns = SimpleNamespace()
            for k, v in obj.__dict__.items():
                n_items = len(get_mlir_types(v))
                ns.__dict__[k] = new_from_mlir_values(v, values[:n_items])
                values = values[n_items:]
            return ns
        elif isinstance(obj, set):
            raise DSLUserCodeError(
                DiagId.ARG_UNORDERED_CONTAINER,
            )
        elif is_dynamic_expression(obj):
            if len(values) == 0:
                return obj

            assert len(values) == 1
            return values[0]
        else:
            assert len(values) == 0, f"{obj} expects 0 values, but got {values}"
            return obj
