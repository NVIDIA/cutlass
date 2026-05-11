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
This module provides runtime utilities for JIT argument conversion in DSL.
"""

from functools import wraps
from typing import Callable, Any, Optional, get_origin
from inspect import Parameter
from dataclasses import is_dataclass, fields
from itertools import chain


# Local modules imports
from ..common import DSLRuntimeError
from ..typing import (
    Constexpr,
    Int32,
    Float32,
    Boolean,
    NumericMeta,
    cast,
    get_c_pointers,
    get_mlir_types,
    implements_jit_argument,
    implements_dynamic_expression,
)
from ..utils.tree_utils import is_constexpr_field
from ..._mlir import ir


def is_arg_annotation_constexpr(
    arg_annotation: Any,
    arg_name: str,
    arg_index: int,
    owning_func: Optional[Callable[..., Any]],
) -> bool:
    """
    Check if the argument annotation is a constexpr.
    """

    def _is_reserved_python_func_arg(
        arg_index: int, arg_name: str, func: Optional[Callable[..., Any]]
    ) -> bool:
        """
        Check if the argument is a reserved python function argument.
        """

        if arg_index != 0:
            return False

        if arg_name == "self":
            return True

        if func:
            is_classmethod = isinstance(func, classmethod) or (
                hasattr(func, "__func__") and isinstance(func.__func__, classmethod)
            )
            return arg_name == "cls" and is_classmethod
        return False

    return (
        _is_reserved_python_func_arg(arg_index, arg_name, owning_func)
        or (isinstance(arg_annotation, type) and issubclass(arg_annotation, Constexpr))
        or (get_origin(arg_annotation) is Constexpr)
    )


def is_argument_constexpr(
    arg: Any,
    arg_annotation: Any,
    arg_name: str,
    arg_index: int,
    owning_func: Callable[..., Any],
) -> bool:
    """
    Check if the argument is a constexpr.
    """

    def _is_type_argument(arg: Any, arg_annotation: Any) -> bool:
        """
        Check if the argument is a type argument like Type[X]
        """

        return isinstance(arg, type) and (
            arg_annotation is Parameter.empty or get_origin(arg_annotation) is type
        )

    return (
        is_arg_annotation_constexpr(arg_annotation, arg_name, arg_index, owning_func)
        or _is_type_argument(arg, arg_annotation)
        or arg is None
    )


class JitArgAdapterRegistry:
    """
    A registry to keep track of the JIT argument adapters.

    An adapter is a callable that converts a Python type to a type with following protocols supported:
    - JitArgument
    - DynamicExpression
    The converted type can then be further processed by DSL to generate arguments for JIT functions.
    """

    # A dictionary with key=type and value=callable
    jit_arg_adapter_registry: dict[type, Any] = {}

    # Default adapters for arguments we don't know type names beforehand
    # Default dataclass adapter
    default_dataclass_adapter: Callable[[object], Any] | None = None

    @classmethod
    def register_jit_arg_adapter(cls, *dargs: Any, **dkwargs: Any) -> Any:
        """
        Register a JIT argument adapter callable

        This can be used as a decorator on any callable like:

        @register_jit_arg_adapter(my_py_type)
        def my_adapter_for_my_py_type(arg):
            ...

        @register_jit_arg_adapter(my_py_type)
        class MyAdapterForMyPythonType:
            ...

        The adapters are registered per type. If a type is already registerd, an error will be raised.
        """

        def decorator(*dargs: Any, **dkwargs: Any) -> Any:
            darg_python_ty = dargs[0]

            @wraps(darg_python_ty)
            def wrapper(*args: Any, **kwargs: Any) -> Any:
                if len(args) != 1 or not callable(args[0]):
                    raise DSLRuntimeError(
                        "a callable must be provided for registering JIT argument adapter"
                    )
                adapter = args[0]

                if darg_python_ty in cls.jit_arg_adapter_registry:
                    raise DSLRuntimeError(
                        f"JIT argument adapter for {darg_python_ty} is already registered!",
                        context={
                            "Registered adapter": cls.jit_arg_adapter_registry[
                                darg_python_ty
                            ],
                            "Adapter to be registered": adapter,
                        },
                    )
                cls.jit_arg_adapter_registry[darg_python_ty] = adapter
                return adapter

            return wrapper

        if len(dargs) > 0:
            return decorator(*dargs, **dkwargs)
        else:
            raise DSLRuntimeError(
                "a Python type must be provided for registering JIT argument adapter"
            )

    @classmethod
    def get_registered_adapter(cls, arg: object) -> Any:
        """
        Get the registered JIT argument adapter for the given argument.
        """
        adapter = cls.jit_arg_adapter_registry.get(type(arg), None)
        if adapter is None:
            if (cls.default_dataclass_adapter
                and not implements_jit_argument(arg, partial=True)
                and not implements_dynamic_expression(arg, partial=True)
                and is_dataclass(arg)
                and len(vars(arg)) == len(fields(arg))):  # no extra/missing instance attrs
                adapter = cls.default_dataclass_adapter
        return adapter

    @classmethod
    def set_default_dataclass_adapter(cls, adapter: Callable[[object], Any]) -> None:
        """
        Set up a default dataclass adapter. If any user defined dataclass implements the JitArgument/DynamicExpression protocol,
        those impls will be honored instead of this default adapter.
        """
        cls.default_dataclass_adapter = adapter


class DefaultDataclassAdapter:
    """
    Adapter for dataclass typed JIT arguments.
    """
    def __init__(self, arg: object) -> None:
        self._ir_fields: dict[str, object] = {}
        self._ir_fields_len: dict[str, int] = {}
        self._arg = arg
        for f in fields(arg): # type: ignore[arg-type]
            arg_field = getattr(arg, f.name)
            if not is_constexpr_field(f):
                if isinstance(f.type, NumericMeta) and not isinstance(arg_field, f.type):
                    self._ir_fields[f.name] = cast(arg_field, f.type) # type: ignore[arg-type]
                else:
                    # Allow the nested fields to be adapted
                    arg_adapter = JitArgAdapterRegistry.get_registered_adapter(arg_field)
                    if arg_adapter is not None:
                        self._ir_fields[f.name] = arg_adapter(arg_field)
                    else:
                        self._ir_fields[f.name] = arg_field

    def __c_pointers__(self) -> list[Any]:
        return list(chain.from_iterable(get_c_pointers(v) for v in self._ir_fields.values()))

    def __get_mlir_types__(self) -> list[Any]:
        ir_types = []
        for f, v in self._ir_fields.items():
            types = get_mlir_types(v)
            self._ir_fields_len[f] = len(types)
            ir_types.extend(types)
        return ir_types

    def __new_from_mlir_values__(self, values: list[Any]) -> Any:
        from ..dsl import new_from_mlir_values  # deferred to avoid circular import

        kwargs = {}
        idx = 0
        for f in fields(self._arg): # type: ignore[arg-type]
            if is_constexpr_field(f):
                kwargs[f.name] = getattr(self._arg, f.name)
            else:
                kwargs[f.name] = new_from_mlir_values(self._ir_fields[f.name], values[idx : idx + self._ir_fields_len[f.name]])
                idx += self._ir_fields_len[f.name]
        return type(self._arg)(**kwargs)

    def __extract_mlir_values__(self) -> list[ir.Value]:
        from ..dsl import extract_mlir_values  # deferred to avoid circular import

        return list(chain.from_iterable(extract_mlir_values(v) for v in self._ir_fields.values()))


JitArgAdapterRegistry.set_default_dataclass_adapter(DefaultDataclassAdapter)


# =============================================================================
# JIT Argument Adapters
# =============================================================================


@JitArgAdapterRegistry.register_jit_arg_adapter(int)
@JitArgAdapterRegistry.register_jit_arg_adapter(float)
@JitArgAdapterRegistry.register_jit_arg_adapter(bool)
def _convert_python_scalar(arg: Any) -> Any:
    """
    Convert a Python scalar to a DSL type.
    """
    conversion_map = {
        int: Int32,
        float: Float32,
        bool: Boolean,
    }
    return conversion_map.get(type(arg))(arg)  # type: ignore[misc]


@JitArgAdapterRegistry.register_jit_arg_adapter(tuple)
@JitArgAdapterRegistry.register_jit_arg_adapter(list)
def _convert_python_sequence(arg: Any) -> Any:
    """
    Go through each element in the sequence and convert it to a type that can be
    further processed by DSL to generate the corresponding JIT argument(s).
    """
    adapted_arg = []
    for elem in arg:
        adapter = JitArgAdapterRegistry.get_registered_adapter(elem)
        if adapter is not None:
            converted_elem = adapter(elem)
            adapted_arg.append(converted_elem)
        else:
            # If no registered adapter is found, just return the original element
            adapted_arg.append(elem)

    assert len(adapted_arg) == len(arg)
    return type(arg)(adapted_arg)
